# 生产镜像:scratch 基础 + Go 静态二进制 + 前端 dist,由 nginx 托管。
# 保密红线:本目录(build 上下文)只允许出现下列 COPY 来源,源码永不进镜像。
FROM scratch AS backend
COPY backend/bin/server /server

FROM nginx:1.27-alpine
# 后端二进制
COPY --from=backend /server /app/server
# 前端构建产物
COPY frontend/dist /usr/share/nginx/html
# nginx 配置:静态资源 + /api 反代后端
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["/bin/sh", "-c", "/app/server & nginx -g 'daemon off;'"]
