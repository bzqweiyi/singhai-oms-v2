// Package auth 会话鉴权中间件(骨架版)。
// 权限位模型对标旧仓 web_core 的 _can_*:角色/权限数据从 users/role_permissions
// 原样搬迁;阶段 3 接入完整权限树,本中间件只换内部实现,接口不变。
package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/bzqweiyi/singhai-oms-v2/internal/config"
	"github.com/bzqweiyi/singhai-oms-v2/internal/system/resp"
)

const CookieName = "session"

type ctxKey string

const CtxUserID ctxKey = "user_id"

// Middleware 校验会话 cookie;骨架阶段只验证存在性,真实现等登录域翻译时接上
func Middleware(cfg config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		if _, err := c.Cookie(CookieName); err != nil {
			resp.Fail(c, 401, "unauthorized")
			c.AbortWithStatus(http.StatusOK)
			return
		}
		// TODO:校验会话有效性并写入 c.Set(CtxUserID, uid)
		c.Next()
	}
}
