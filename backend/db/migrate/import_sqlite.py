#!/usr/bin/env python3
"""SQLite → PostgreSQL 开发数据搬运(阶段 0 基线资产)。

幂等可重跑:每次先 DROP/CREATE schema,再逐表 TRUNCATE + COPY。
口径:表结构照抄不改(schema.sql 直译),只搬数据;对拍用 regress-baseline.json。

用法:
    python3 backend/db/migrate/import_sqlite.py /path/to/cargo.db

要求:psql 在 PATH(开发机用 PGDG apt 装的 /usr/lib/postgresql/16/bin,
     或 docker compose 内的 PG 均可),
     由环境变量 PGDATABASE/PGUSER/PGHOST/PGPORT/PGPASSWORD 定位目标库。
"""
import csv
import io
import os
import sqlite3
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCHEMA = os.path.join(HERE, "..", "schema", "schema.sql")
NULL_SENTINEL = "__OMS_NULL__"


def run_psql(sql, stdin_data=None):
    """单条命令/元命令(-c 模式)。给 \\copy 用:命令走 -c,数据走 stdin。
    -tA 让 COUNT 这类查询只回裸值,便于解析。"""
    cmd = ["psql", "-v", "ON_ERROR_STOP=1", "-q", "-X", "-tA", "-c", sql]
    return subprocess.run(cmd, input=stdin_data, text=True,
                          capture_output=True)


def run_psql_script(script_text):
    """多语句脚本(stdin -f - 模式):每条语句独立事务,
    一句失败不拖垮全部——schema 导入必须用这种方式
    (-c 模式会把多语句挤进一个事务,一句失败全部回滚)。"""
    cmd = ["psql", "-v", "ON_ERROR_STOP=1", "-q", "-X", "-f", "-"]
    return subprocess.run(cmd, input=script_text, text=True,
                          capture_output=True)


def list_tables(con):
    return [r[0] for r in con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name")]


def dump_table(con, table, numeric_cols=None):
    """一张表 → CSV 文本(带列头,NULL 用哨兵)。

    numeric_cols:PG 侧为 double precision/numeric 的列名集合。SQLite 列是
    动态类型,REAL 列里可能塞着文本垃圾(如 "+1.00 (OCR partial)"、"N/A"、""),
    PG 严格类型必拒;这里统一置 NULL 并计数上报(搬的是开发快照,口径以
    regress-baseline.json 的派生数字为准,脏文本无业务含义)。"""
    cur = con.execute(f'SELECT * FROM "{table}"')
    cols = [d[0] for d in cur.description]
    idx = [cols.index(c) for c in (numeric_cols or set()) if c in cols]
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(cols)
    dirty = 0
    for row in cur:
        row = list(row)
        for i in idx:
            v = row[i]
            if v is None:
                continue
            try:
                float(v)
            except (TypeError, ValueError):
                row[i] = None
                dirty += 1
        w.writerow([NULL_SENTINEL if v is None else v for v in row])
    return buf.getvalue(), dirty


def main():
    if len(sys.argv) < 2:
        sys.exit("用法: import_sqlite.py /path/to/cargo.db")
    db_path = sys.argv[1]
    con = sqlite3.connect(db_path)
    tables = list_tables(con)

    # 1. 重建 schema(stdin 模式,逐语句提交)
    with open(SCHEMA, encoding="utf-8") as f:
        r = run_psql_script(f.read())
    if r.returncode != 0:
        sys.exit(f"schema 导入失败:\n{r.stderr}")

    # 2. 逐表搬运
    # 2a. 查 PG 侧数值列(做脏数据清洗),并暂时禁用全库触发器:
    #     SQLite 从不开 FK,源库本就存在悬空引用(bunker_orders→counterparties 等),
    #     schema 照抄口径下触发器不能少,搬运期挂起、搬完即恢复。
    r = run_psql(
        "SELECT table_name || ':' || string_agg(column_name, ',') "
        "FROM information_schema.columns "
        "WHERE data_type IN ('double precision','numeric','real') "
        "AND table_schema='public' GROUP BY table_name;")
    numeric_map = {}
    for line in r.stdout.splitlines():
        if ':' in line:
            t, cs = line.split(':', 1)
            numeric_map[t] = set(cs.split(','))

    trig_sql = "".join(f'ALTER TABLE "{t}" DISABLE TRIGGER ALL;\n' for t in tables)
    run_psql_script(trig_sql)

    ok, fail = 0, []
    dirty_total = {}
    for t in tables:
        csv_text, dirty = dump_table(con, t, numeric_map.get(t))
        if dirty:
            dirty_total[t] = dirty
        sql = (f'\\copy "{t}" FROM STDIN WITH (FORMAT csv, HEADER true, '
               f"NULL '{NULL_SENTINEL}')")
        r = run_psql(sql, stdin_data=csv_text)
        if r.returncode != 0:
            fail.append((t, r.stderr.strip()[-200:]))
        else:
            ok += 1
    con.close()

    trig_sql = "".join(f'ALTER TABLE "{t}" ENABLE TRIGGER ALL;\n' for t in tables)
    run_psql_script(trig_sql)

    print(f"搬运完成:{ok}/{len(tables)} 张表成功")
    for t, err in fail:
        print(f"  ✗ {t}: {err}")
    if dirty_total:
        print("脏文本已置 NULL(SQLite REAL 列里的非数值文本):")
        for t, n in sorted(dirty_total.items()):
            print(f"  ⚠ {t}: {n} 处")

    # 3. 行数核对(SQLite 侧 vs PG 侧)
    checks = []
    for t in tables:
        n_src = sqlite3.connect(db_path).execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
        r = run_psql(f'SELECT COUNT(*) FROM "{t}";')
        n_dst = int(r.stdout.strip()) if r.returncode == 0 else -1
        mark = "✓" if n_src == n_dst else "✗"
        checks.append(f"  {mark} {t}: {n_src} → {n_dst}")
    diff = [c for c in checks if c.strip().startswith("✗")]
    print("行数核对:")
    print("\n".join(checks))
    if fail or diff:
        sys.exit(1)
    print("全部一致 ✓")


if __name__ == "__main__":
    main()
