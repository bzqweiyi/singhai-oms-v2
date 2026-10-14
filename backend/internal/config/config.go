// Package config 环境配置:全部从环境变量读取,.env 仅供开发(密钥永不经仓库)。
package config

import (
	"os"
)

type Config struct {
	Addr          string
	DatabaseURL   string
	SessionSecret string
	CORSOrigins   string
}

func Load() Config {
	return Config{
		Addr:          get("ADDR", ":8080"),
		DatabaseURL:   get("DATABASE_URL", "postgres://singhai:singhai@localhost:5432/singhai?sslmode=disable"),
		SessionSecret: get("SESSION_SECRET", "dev-only-not-secret"),
		CORSOrigins:   get("CORS_ORIGINS", ""),
	}
}

func get(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
