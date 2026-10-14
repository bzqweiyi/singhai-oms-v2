// Package health 部署探活
package health

import (
	"github.com/gin-gonic/gin"

	"github.com/bzqweiyi/singhai-oms-v2/internal/system/resp"
)

func Get(c *gin.Context) {
	resp.OK(c, gin.H{"status": "ok"})
}
