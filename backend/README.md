# backend

Go 1.25 + Gin + sqlc/pgx + PostgreSQL 16。

## 目录

| 路径 | 职责 |
|---|---|
| `cmd/server/` | 服务入口(只装配,不写业务) |
| `internal/` | 按域分包:orders / finance / masterdata / system(横切件) |
| `db/schema/` | PG16 DDL(由生产 SQLite 直译,结构照抄不改) |
| `db/queries/` | sqlc 口径 SQL(静态);动态拼接集中各域 repository 层 |
| `db/migrate/` | SQLite→PG 开发数据搬运(幂等可重跑) |
| `docker-compose.yml` | PG16 容器(CI/生产口径);开发机无 docker 时用 PGDG apt 装 PG16 等价 |

## 开发机起 PG(无 docker 时,smy 实测路径)

conda 装 PG16 在磁盘紧张时会 NoSpaceLeftError 且环境半残,弃用。用 PGDG apt:

```bash
# Ubuntu 22.04,装一次即可
echo "deb http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg
apt-get update && apt-get install -y postgresql-16
pg_createcluster 16 main   # 若装完没有现成 cluster
su - postgres -c "psql -c \"ALTER USER singhai PASSWORD 'singhai'\" -c 'ALTER USER singhai WITH SUPERUSER'" 2>/dev/null || \
  su - postgres -c "psql -c \"CREATE USER singhai WITH SUPERUSER PASSWORD 'singhai'\""
su - postgres -c "createdb -O singhai singhai" 2>/dev/null || true
```

## 导入开发数据(幂等,可重跑)

```bash
export PATH=/usr/lib/postgresql/16/bin:$PATH
export PGPASSWORD=singhai PGUSER=singhai PGHOST=127.0.0.1 PGPORT=5432 PGDATABASE=singhai
python3 db/migrate/import_sqlite.py /path/to/cargo.db   # 用生产副本
```

脚本行为:DROP/CREATE schema(照抄不改)→ 暂禁全库触发器搬运(源库本有悬空
FK,SQLite 从不开约束)→ 搬完恢复触发器 → 逐表行数核对,全 ✓ 才算过。
SQLite REAL 列里的文本垃圾(OCR 残字/"N/A"/空串)统一置 NULL 并逐表上报。
