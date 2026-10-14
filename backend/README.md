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
| `docker-compose.yml` | PG16 容器(CI/生产口径);开发机无 docker 时用 conda PG 等价 |

## 开发机起 PG(无 docker 时)

```bash
/root/miniconda3/bin/conda create -n v2db -c conda-forge postgresql=16 -y
chmod o+x /root /root/miniconda3 /root/miniconda3/envs /root/miniconda3/envs/v2db  # PG 拒绝 root 运行
mkdir -p /var/lib/singhai-pg && chown nobody:nogroup /var/lib/singhai-pg
su -s /bin/bash nobody -c "/root/miniconda3/envs/v2db/bin/initdb -D /var/lib/singhai-pg/data -E UTF8 --locale=C -U singhai"
su -s /bin/bash nobody -c "/root/miniconda3/envs/v2db/bin/pg_ctl -D /var/lib/singhai-pg/data -o '-p 5433 -c listen_addresses=127.0.0.1' -l /var/lib/singhai-pg/log start"
PGPASSWORD= PGUSER=singhai PGHOST=127.0.0.1 PGPORT=5433 /root/miniconda3/envs/v2db/bin/createdb -h 127.0.0.1 -p 5433 -U singhai singhai
```

## 导入开发数据(幂等,可重跑)

```bash
export PATH=/root/miniconda3/envs/v2db/bin:$PATH
export PGUSER=singhai PGHOST=127.0.0.1 PGPORT=5433 PGDATABASE=singhai
python3 db/migrate/import_sqlite.py /path/to/cargo.db   # 用生产副本
```
