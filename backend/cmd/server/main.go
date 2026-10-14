// Package main 服务入口:装配 Gin、中间件、路由。
// 域路由在各 internal/<domain>/route.go 注册,main 只做装配,不写业务。
package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"github.com/bzqweiyi/singhai-oms-v2/internal/config"
	"github.com/bzqweiyi/singhai-oms-v2/internal/system/auth"
	"github.com/bzqweiyi/singhai-oms-v2/internal/system/errx"
	"github.com/bzqweiyi/singhai-oms-v2/internal/system/health"
	"github.com/bzqweiyi/singhai-oms-v2/internal/system/resp"
)

func main() {
	cfg := config.Load()

	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())
	r.Use(errx.Middleware()) // 统一错误兜底:业务错误→统一响应体,panic→500

	// 健康检查(部署探活用,无鉴权)
	r.GET("/health", health.Get)

	// 业务路由:system 域(登录/会话)无鉴权;其余全部挂鉴权中间件
	api := r.Group("/api")
	api.Use(resp.Middleware())
	systemRoutes := api.Group("/")
	systemRoutes.Use(auth.Middleware(cfg)) // 骨架阶段:仅校验会话 cookie 存在
	_ = systemRoutes

	// TODO(阶段1):按域注册——orders/finance/masterdata 等,域划分照抄旧仓 routers/

	log.Printf("singhai-oms-v2 listening on %s", cfg.Addr)
	if err := r.Run(cfg.Addr); err != nil {
		log.Fatal(err)
	}
}
