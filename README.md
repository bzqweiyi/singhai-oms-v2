# singhai-oms-v2

SingHai OMS 全量重构版(Go + Vue3/TS + PostgreSQL 16)。

> 内部专有系统,**不开放源代码、不授予任何使用许可**(仓库不挂 LICENSE 即保留全部权利)。
> 未经授权复制、传播、二次使用本仓库代码的行为被禁止。

- 后端:Go 1.25 + Gin + sqlc/pgx → `backend/`
- 前端:Vue 3 + Vite + TS + Pinia + Element Plus + AG Grid Vue → `frontend/`
- 设计文档与口径清单 → `docs/`
- 重构总计划与决策记录见旧仓 `docs/rewrite-go-vue-plan.md`(过渡期同步维护,
  最终归档到本仓 docs/decisions/)

## 口径铁律

1. **db.py 是规格书**:翻译口径,不做"顺手改进";里程碑验收 = 对拍 0 差异。
2. 复杂 SQL 一律显式可见:静态走 sqlc 生成,动态拼接集中 repository 层 pgx 手写;
   禁止 ORM 全映射把口径藏进 struct tag。
3. 错误处理:handler 层统一兜底,业务代码错误向上透传不吞。
4. DTO 宽松反序列化:多传不漏、缺字段显式 400(记住旧系统 response_model
   静默裁字段的教训)。
5. 生产只交付制品:docker image(Go 二进制 + dist),服务器无源码无 git。

## 本地起服务

```bash
# 数据库(PG16)
cd backend && docker compose up -d

# 后端(需 Go 1.25+)
cd backend && go run ./cmd/server

# 前端(需 Node 20+;连调旧 FastAPI 时改 .env 的 VITE_API_BASE)
cd frontend && npm install && npm run dev
```
