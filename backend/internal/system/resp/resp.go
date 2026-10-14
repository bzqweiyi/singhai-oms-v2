// Package resp 统一返回体:{"code":0,"data":...,"msg":""}。
// 旧系统教训:FastAPI response_model 静默裁字段——本系统 DTO 一律宽松反序列化,
// 多传不漏;缺字段在绑定层显式 400。
package resp

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Body struct {
	Code int         `json:"code"`
	Data interface{} `json:"data,omitempty"`
	Msg  string      `json:"msg,omitempty"`
}

// OK 成功响应
func OK(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Body{Code: 0, Data: data})
}

// Fail 业务错误响应(code 非 0,HTTP 仍 200,与旧系统前端约定一致)
func Fail(c *gin.Context, code int, msg string) {
	c.JSON(http.StatusOK, Body{Code: code, Msg: msg})
}

// Middleware 预留:跨域/请求上下文注入,骨架阶段仅按配置加 CORS 头
func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}
