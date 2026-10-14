// Package errx 业务错误与集中兜底。
// 约定:业务代码错误一律向上透传不吞;handler 返回 error 即由本中间件转成统一响应体,
// 避免 if err != nil 在每个 handler 里重复写响应。
package errx

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/bzqweiyi/singhai-oms-v2/internal/system/resp"
)

// BizError 带错误码的业务错误
type BizError struct {
	Code int
	Msg  string
}

func (e *BizError) Error() string { return e.Msg }

func New(code int, msg string) *BizError { return &BizError{Code: code, Msg: msg} }

// Middleware 统一错误兜底:BizError→统一响应体;其余→500 不泄露内部细节
func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) == 0 {
			return
		}
		err := c.Errors.Last().Err
		var biz *BizError
		if errors.As(err, &biz) {
			resp.Fail(c, biz.Code, biz.Msg)
			return
		}
		c.JSON(http.StatusInternalServerError, resp.Body{Code: 500, Msg: "internal error"})
	}
}
