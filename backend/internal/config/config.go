package config

import (
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port        string
	AppName     string
	Environment string
	DBHost      string
	DBPort      string
	DBUser      string
	DBPassword  string
	DBName      string
	DBSSLMode   string
	JWTSecret   string
	JWTExpiresIn time.Duration
	JWTRefreshExpiresIn time.Duration
	N8NWebhookURL string
	CORSAllowedOrigins []string
	RateLimitRequests int
	RateLimitDuration time.Duration
}

func Load() *Config {
	return &Config{
		Port:        getEnv("PORT", "8080"),
		AppName:     getEnv("APP_NAME", "Financial API"),
		Environment: getEnv("ENVIRONMENT", "development"),
		DBHost:      getEnv("DB_HOST", "localhost"),
		DBPort:      getEnv("DB_PORT", "5432"),
		DBUser:      getEnv("DB_USER", "postgres"),
		DBPassword:  getEnv("DB_PASSWORD", "yourpassword"),
		DBName:      getEnv("DB_NAME", "financial_db"),
		DBSSLMode:   getEnv("DB_SSL_MODE", "disable"),
		JWTSecret:   getEnv("JWT_SECRET", "super-secret-key"),
		JWTExpiresIn: getEnvAsDuration("JWT_EXPIRES_IN", 24*time.Hour),
		JWTRefreshExpiresIn: getEnvAsDuration("JWT_REFRESH_EXPIRES_IN", 7*24*time.Hour),
		N8NWebhookURL: getEnv("N8N_WEBHOOK_URL", "http://localhost:5678/webhook/process"),
		CORSAllowedOrigins: strings.Split(getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173"), ","),
		RateLimitRequests: getEnvAsInt("RATE_LIMIT_REQUESTS", 100),
		RateLimitDuration: getEnvAsDuration("RATE_LIMIT_DURATION", 1*time.Minute),
	}
}

func getEnv(key, def string) string { if v := os.Getenv(key); v != "" { return v }; return def }
func getEnvAsInt(key string, def int) int { if v := os.Getenv(key); v != "" { if i, err := strconv.Atoi(v); err == nil { return i } }; return def }
func getEnvAsDuration(key string, def time.Duration) time.Duration { if v := os.Getenv(key); v != "" { if d, err := time.ParseDuration(v); err == nil { return d } }; return def }
