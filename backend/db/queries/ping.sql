-- sqlc 查询样例(骨架阶段占位):真实口径 SQL 翻译时按域建文件。
-- 命名约定:<域>_<操作>.sql;每条 SQL 上方注释标注旧仓出处(函数名+行号)。

-- name: Ping :one
SELECT 1 AS ok;
