#!/usr/bin/env python3
"""SQLite → PostgreSQL 开发数据搬运(阶段 0 基线资产)。

幂等可重跑:每次先 DROP/CREATE schema,再逐表 TRUNCATE + COPY。
口径:表结构照抄不改(schema.sql 直译),只搬数据;对拍用 regress-baseline.json。

用法:
    python3 backend/db/migrate/import_sqlite.py /path/to/cargo.db

要求:psql 在 PATH(conda 环境 v2db 或 docker compose 内的 PG 均可),
     由环境变量 PGDATABASE/PGUSER/PGHOST/PGPORT 定位目标库。
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
    """跑一段 psql;有数据就通过 stdin 喂。"""
    cmd = ["psql", "-v", "ON_ERROR_STOP=1", "-q", "-X"]
    return subprocess.run(cmd, input=stdin_data, text=True,
                          capture_output=True)


def list_tables(con):
    return [r[0] for r in con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name")]


def dump_table(con, table):
    """一张表 → CSV 文本(带列头,NULL 用哨兵)。BOOLEAN 列 PG 吃 '0'/'1'。"""
    cur = con.execute(f'SELECT * FROM "{table}"')
    cols = [d[0] for d in cur.description]
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(cols)
    for row in cur:
        w.writerow([NULL_SENTINEL if v is None else v for v in row])
    return buf.getvalue(), len(cols)


def main():
    if len(sys.argv) < 2:
        sys.exit("用法: import_sqlite.py /path/to/cargo.db")
    db_path = sys.argv[1]
    con = sqlite3.connect(db_path)
    tables = list_tables(con)

    # 1. 重建 schema
    with open(SCHEMA, encoding="utf-8") as f:
        r = run_psql(f.read())
    if r.returncode != 0:
        sys.exit(f"schema 导入失败:\n{r.stderr}")

    # 2. 逐表搬运
    ok, fail = 0, []
    for t in tables:
        csv_text, _ = dump_table(con, t)
        sql = (f'\\copy "{t}" FROM STDIN WITH (FORMAT csv, HEADER true, '
               f"NULL '{NULL_SENTINEL}')")
        r = run_psql(sql, stdin_data=csv_text)
        if r.returncode != 0:
            fail.append((t, r.stderr.strip().split("\n")[-1]))
        else:
            ok += 1
    con.close()

    print(f"搬运完成:{ok}/{len(tables)} 张表成功")
    for t, err in fail:
        print(f"  ✗ {t}: {err}")

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
