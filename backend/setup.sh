#!/bin/bash

# ============================================
# ایجاد پوشه‌ها
# ============================================
mkdir -p cmd/api internal/{config,database,handlers,models,repositories,services,middleware,utils} migrations

# ============================================
# فایل go.mod
# ============================================
cat > go.mod << 'GOMOD'
module github.com/AliasgharHeidari/financial-management

go 1.23.0

require (
	github.com/gofiber/fiber/v2 v2.52.5
	github.com/golang-jwt/jwt/v5 v5.2.1
	github.com/joho/godotenv v1.5.1
	golang.org/x/crypto v0.31.0
	gorm.io/driver/postgres v1.5.9
	gorm.io/gorm v1.25.12
)
GOMOD

# ============================================
# فایل cmd/api/main.go
# ============================================
cat > cmd/api/main.go << 'MAIN'
package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
	"github.com/AliasgharHeidari/financial-management/internal/api"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/database"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️ No .env file found")
	}

	cfg := config.Load()
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		log.Fatalf("❌ Failed to connect to database: %v", err)
	}

	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("❌ Failed to run migrations: %v", err)
	}

	server := api.NewServer(cfg, db)
	server.SetupMiddleware()
	server.SetupRoutes()

	go func() {
		if err := server.Start(); err != nil {
			log.Fatalf("❌ Failed to start server: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Shutting down server...")
	if err := server.Shutdown(); err != nil {
		log.Fatalf("❌ Server shutdown error: %v", err)
	}
	log.Println("✅ Server stopped")
}
MAIN

# ============================================
# فایل internal/config/config.go
# ============================================
cat > internal/config/config.go << 'CONFIG'
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
CONFIG

# ============================================
# فایل internal/database/postgres.go
# ============================================
cat > internal/database/postgres.go << 'DB'
package database

import (
	"fmt"
	"log"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func NewPostgresDB(cfg *config.Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s TimeZone=Asia/Tehran",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBSSLMode)
	return gorm.Open(postgres.Open(dsn), &gorm.Config{Logger: logger.Default.LogMode(logger.Info)})
}

func RunMigrations(db *gorm.DB) error {
	log.Println("🔄 Running migrations...")
	if err := db.AutoMigrate(&models.User{}, &models.Category{}, &models.Transaction{}); err != nil {
		return err
	}
	seedCategories(db)
	log.Println("✅ Migrations done")
	return nil
}

func seedCategories(db *gorm.DB) {
	cats := []models.Category{
		{Name: "خوراک", Icon: "🍔", Type: "expense"},
		{Name: "حمل و نقل", Icon: "🚗", Type: "expense"},
		{Name: "قبوض", Icon: "📄", Type: "expense"},
		{Name: "تحصیل", Icon: "📚", Type: "expense"},
		{Name: "تفریح", Icon: "🎮", Type: "expense"},
		{Name: "سلامت", Icon: "🏥", Type: "expense"},
		{Name: "خرید", Icon: "🛍️", Type: "expense"},
		{Name: "درآمد", Icon: "💰", Type: "income"},
		{Name: "سایر", Icon: "📌", Type: "expense"},
	}
	for _, c := range cats {
		db.FirstOrCreate(&c, models.Category{Name: c.Name})
	}
}
DB

# ============================================
# فایل internal/models/user.go
# ============================================
cat > internal/models/user.go << 'USER'
package models

import "time"
import "gorm.io/gorm"

type User struct {
	ID        uint `gorm:"primaryKey" json:"id"`
	Username  string `gorm:"unique;not null;size:50" json:"username"`
	Email     string `gorm:"unique;not null;size:100" json:"email"`
	Password  string `gorm:"not null" json:"-"`
	FullName  string `gorm:"size:100" json:"full_name"`
	IsActive  bool `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

type RegisterRequest struct {
	Username string `json:"username" validate:"required"`
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
	FullName string `json:"full_name"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type LoginResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}
USER

# ============================================
# فایل internal/models/category.go
# ============================================
cat > internal/models/category.go << 'CAT'
package models

import "time"
import "gorm.io/gorm"

type Category struct {
	ID        uint `gorm:"primaryKey" json:"id"`
	Name      string `gorm:"unique;not null;size:50" json:"name"`
	Icon      string `gorm:"size:10" json:"icon"`
	Color     string `gorm:"size:20" json:"color"`
	Type      string `gorm:"not null;size:20" json:"type"`
	IsDefault bool `gorm:"default:false" json:"is_default"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}
CAT

# ============================================
# فایل internal/models/transaction.go
# ============================================
cat > internal/models/transaction.go << 'TXN'
package models

import "time"
import "gorm.io/gorm"

type Transaction struct {
	ID          uint `gorm:"primaryKey" json:"id"`
	UserID      uint `gorm:"not null;index" json:"user_id"`
	CategoryID  uint `gorm:"not null;index" json:"category_id"`
	Amount      float64 `gorm:"not null" json:"amount"`
	Description string `gorm:"size:500" json:"description"`
	Type        string `gorm:"not null;size:20" json:"type"`
	Date        time.Time `gorm:"not null;index" json:"date"`
	Notes       string `gorm:"size:500" json:"notes"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	User        User `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Category    Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
}

type CreateTransactionRequest struct {
	CategoryID  uint    `json:"category_id" validate:"required"`
	Amount      float64 `json:"amount" validate:"required,gt=0"`
	Description string  `json:"description" validate:"required"`
	Type        string  `json:"type" validate:"required,oneof=income expense"`
	Date        string  `json:"date"`
	Notes       string  `json:"notes"`
}
TXN

# ============================================
# فایل internal/api/server.go
# ============================================
cat > internal/api/server.go << 'SERVER'
package api

import (
	"log"
	"time"
	"strings"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"gorm.io/gorm"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/handlers"
	"github.com/AliasgharHeidari/financial-management/internal/middleware"
	"github.com/AliasgharHeidari/financial-management/internal/repositories"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type Server struct {
	app *fiber.App
	cfg *config.Config
	db  *gorm.DB
}

func NewServer(cfg *config.Config, db *gorm.DB) *Server {
	return &Server{app: fiber.New(fiber.Config{AppName: cfg.AppName}), cfg: cfg, db: db}
}

func (s *Server) SetupMiddleware() {
	s.app.Use(recover.New())
	s.app.Use(logger.New())
	s.app.Use(cors.New(cors.Config{
		AllowOrigins: strings.Join(s.cfg.CORSAllowedOrigins, ","),
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
	}))
	s.app.Use(limiter.New(limiter.Config{
		Max: s.cfg.RateLimitRequests,
		Expiration: s.cfg.RateLimitDuration,
	}))
}

func (s *Server) SetupRoutes() {
	s.app.Get("/api/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "time": time.Now().Format(time.RFC3339)})
	})

	api := s.app.Group("/api/v1")

	// Auth
	authHandler := s.setupAuthHandler()
	auth := api.Group("/auth")
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)

	// Protected
	protected := api.Group("/", middleware.AuthRequired(s.cfg))

	// Transactions
	txnHandler := s.setupTransactionHandler()
	txns := protected.Group("/transactions")
	txns.Post("/", txnHandler.Create)
	txns.Get("/", txnHandler.GetAll)
	txns.Get("/:id", txnHandler.GetByID)
	txns.Put("/:id", txnHandler.Update)
	txns.Delete("/:id", txnHandler.Delete)
	txns.Get("/summary", txnHandler.GetSummary)

	// AI
	aiHandler := s.setupAIHandler()
	ai := protected.Group("/ai")
	ai.Post("/process", aiHandler.ProcessTransaction)
}

func (s *Server) setupAuthHandler() *handlers.AuthHandler {
	repo := repositories.NewUserRepository(s.db)
	svc := services.NewAuthService(repo, s.cfg)
	return handlers.NewAuthHandler(svc)
}

func (s *Server) setupTransactionHandler() *handlers.TransactionHandler {
	repo := repositories.NewTransactionRepository(s.db)
	catRepo := repositories.NewCategoryRepository(s.db)
	svc := services.NewTransactionService(repo, catRepo)
	return handlers.NewTransactionHandler(svc)
}

func (s *Server) setupAIHandler() *handlers.AIHandler {
	svc := services.NewAIService(s.cfg)
	return handlers.NewAIHandler(svc)
}

func (s *Server) Start() error {
	log.Printf("🚀 Server on http://localhost:%s", s.cfg.Port)
	return s.app.Listen(":" + s.cfg.Port)
}

func (s *Server) Shutdown() error { return s.app.Shutdown() }
SERVER

# ============================================
# فایل internal/middleware/auth.go
# ============================================
cat > internal/middleware/auth.go << 'AUTH'
package middleware

import (
	"strings"
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/utils"
)

func AuthRequired(cfg *config.Config) fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth := c.Get("Authorization")
		if auth == "" {
			return c.Status(401).JSON(fiber.Map{"error": "Authorization header required"})
		}
		parts := strings.Split(auth, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(401).JSON(fiber.Map{"error": "Invalid token format"})
		}
		claims, err := utils.ValidateToken(parts[1], cfg.JWTSecret)
		if err != nil {
			return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired token"})
		}
		c.Locals("user_id", claims.UserID)
		return c.Next()
	}
}
AUTH

# ============================================
# فایل internal/utils/jwt.go
# ============================================
cat > internal/utils/jwt.go << 'JWT'
package utils

import (
	"time"
	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID uint `json:"user_id"`
	jwt.RegisteredClaims
}

func GenerateToken(userID uint, secret string, exp time.Duration) (string, error) {
	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(exp)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func GenerateRefreshToken(userID uint, secret string, exp time.Duration) (string, error) {
	return GenerateToken(userID, secret, exp)
}

func ValidateToken(tokenString string, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, jwt.ErrSignatureInvalid
}
JWT

# ============================================
# فایل internal/repositories/user_repo.go
# ============================================
cat > internal/repositories/user_repo.go << 'UREPO'
package repositories

import (
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"gorm.io/gorm"
)

type UserRepository struct{ db *gorm.DB }

func NewUserRepository(db *gorm.DB) *UserRepository { return &UserRepository{db: db} }

func (r *UserRepository) Create(user *models.User) error { return r.db.Create(user).Error }
func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var u models.User
	err := r.db.Where("email = ?", email).First(&u).Error
	return &u, err
}
func (r *UserRepository) FindByID(id uint) (*models.User, error) {
	var u models.User
	err := r.db.First(&u, id).Error
	return &u, err
}
func (r *UserRepository) ExistsByEmail(email string) (bool, error) {
	var count int64
	err := r.db.Model(&models.User{}).Where("email = ?", email).Count(&count).Error
	return count > 0, err
}
UREPO

# ============================================
# فایل internal/repositories/transaction_repo.go
# ============================================
cat > internal/repositories/transaction_repo.go << 'TREPO'
package repositories

import (
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"gorm.io/gorm"
)

type TransactionRepository struct{ db *gorm.DB }

func NewTransactionRepository(db *gorm.DB) *TransactionRepository { return &TransactionRepository{db: db} }

func (r *TransactionRepository) Create(t *models.Transaction) error { return r.db.Create(t).Error }
func (r *TransactionRepository) FindByID(id uint) (*models.Transaction, error) {
	var t models.Transaction
	err := r.db.Preload("Category").First(&t, id).Error
	return &t, err
}
func (r *TransactionRepository) FindByUserID(userID uint, limit, offset int) ([]models.Transaction, error) {
	var txns []models.Transaction
	err := r.db.Preload("Category").Where("user_id = ?", userID).Order("date DESC").Limit(limit).Offset(offset).Find(&txns).Error
	return txns, err
}
func (r *TransactionRepository) Update(t *models.Transaction) error { return r.db.Save(t).Error }
func (r *TransactionRepository) Delete(id uint) error { return r.db.Delete(&models.Transaction{}, id).Error }
TREPO

# ============================================
# فایل internal/repositories/category_repo.go
# ============================================
cat > internal/repositories/category_repo.go << 'CREPO'
package repositories

import (
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"gorm.io/gorm"
)

type CategoryRepository struct{ db *gorm.DB }

func NewCategoryRepository(db *gorm.DB) *CategoryRepository { return &CategoryRepository{db: db} }
func (r *CategoryRepository) FindByID(id uint) (*models.Category, error) {
	var c models.Category
	err := r.db.First(&c, id).Error
	return &c, err
}
func (r *CategoryRepository) FindByName(name string) (*models.Category, error) {
	var c models.Category
	err := r.db.Where("name = ?", name).First(&c).Error
	return &c, err
}
func (r *CategoryRepository) GetAll() ([]models.Category, error) {
	var cats []models.Category
	err := r.db.Order("name").Find(&cats).Error
	return cats, err
}
CREPO

# ============================================
# فایل internal/services/auth_service.go
# ============================================
cat > internal/services/auth_service.go << 'ASVC'
package services

import (
	"errors"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/repositories"
	"github.com/AliasgharHeidari/financial-management/internal/utils"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	repo *repositories.UserRepository
	cfg  *config.Config
}

func NewAuthService(repo *repositories.UserRepository, cfg *config.Config) *AuthService {
	return &AuthService{repo: repo, cfg: cfg}
}

func (s *AuthService) Register(req *models.RegisterRequest) (*models.User, error) {
	if exists, _ := s.repo.ExistsByEmail(req.Email); exists {
		return nil, errors.New("email already exists")
	}
	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	user := &models.User{Username: req.Username, Email: req.Email, Password: string(hash), FullName: req.FullName, IsActive: true}
	return user, s.repo.Create(user)
}

func (s *AuthService) Login(req *models.LoginRequest) (*models.LoginResponse, error) {
	user, err := s.repo.FindByEmail(req.Email)
	if err != nil || bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)) != nil {
		return nil, errors.New("invalid credentials")
	}
	token, _ := utils.GenerateToken(user.ID, s.cfg.JWTSecret, s.cfg.JWTExpiresIn)
	refresh, _ := utils.GenerateRefreshToken(user.ID, s.cfg.JWTSecret, s.cfg.JWTRefreshExpiresIn)
	return &models.LoginResponse{Token: token, RefreshToken: refresh, User: *user}, nil
}
ASVC

# ============================================
# فایل internal/services/transaction_service.go
# ============================================
cat > internal/services/transaction_service.go << 'TSVC'
package services

import (
	"errors"
	"time"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/repositories"
)

type TransactionService struct {
	repo     *repositories.TransactionRepository
	catRepo  *repositories.CategoryRepository
}

func NewTransactionService(repo *repositories.TransactionRepository, catRepo *repositories.CategoryRepository) *TransactionService {
	return &TransactionService{repo: repo, catRepo: catRepo}
}

func (s *TransactionService) Create(userID uint, req *models.CreateTransactionRequest) (*models.Transaction, error) {
	if _, err := s.catRepo.FindByID(req.CategoryID); err != nil {
		return nil, errors.New("category not found")
	}
	date := time.Now()
	if req.Date != "" {
		if d, err := time.Parse("2006-01-02", req.Date); err == nil { date = d }
	}
	txn := &models.Transaction{
		UserID: userID, CategoryID: req.CategoryID, Amount: req.Amount,
		Description: req.Description, Type: req.Type, Date: date, Notes: req.Notes,
	}
	return txn, s.repo.Create(txn)
}

func (s *TransactionService) GetByID(id uint) (*models.Transaction, error) { return s.repo.FindByID(id) }
func (s *TransactionService) GetAll(userID uint, limit, offset int) ([]models.Transaction, error) {
	return s.repo.FindByUserID(userID, limit, offset)
}
func (s *TransactionService) Update(userID uint, id uint, req *models.CreateTransactionRequest) (*models.Transaction, error) {
	txn, err := s.repo.FindByID(id)
	if err != nil || txn.UserID != userID { return nil, errors.New("not found or unauthorized") }
	if req.CategoryID != 0 { if _, err := s.catRepo.FindByID(req.CategoryID); err == nil { txn.CategoryID = req.CategoryID } }
	if req.Amount != 0 { txn.Amount = req.Amount }
	if req.Description != "" { txn.Description = req.Description }
	if req.Type != "" { txn.Type = req.Type }
	return txn, s.repo.Update(txn)
}
func (s *TransactionService) Delete(userID uint, id uint) error {
	txn, err := s.repo.FindByID(id)
	if err != nil || txn.UserID != userID { return errors.New("not found or unauthorized") }
	return s.repo.Delete(id)
}
TSVC

# ============================================
# فایل internal/services/ai_service.go
# ============================================
cat > internal/services/ai_service.go << 'AISVC'
package services

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"
	"github.com/AliasgharHeidari/financial-management/internal/config"
)

type AIService struct{ cfg *config.Config }

type AIResponse struct {
	Category    string  `json:"category"`
	Amount      float64 `json:"amount"`
	Description string  `json:"description"`
	Date        string  `json:"date"`
	Type        string  `json:"type"`
}

func NewAIService(cfg *config.Config) *AIService { return &AIService{cfg: cfg} }

func (s *AIService) ProcessTransaction(text string, amount float64) (*AIResponse, error) {
	// اول regex محلی
	result := s.parseLocal(text)
	if result.Amount == 0 && amount > 0 { result.Amount = amount }
	
	// بعد n8n (اگه تنظیم شده)
	if s.cfg.N8NWebhookURL != "" {
		if n8nResult, err := s.callN8N(text); err == nil {
			if n8nResult.Category != "" { result.Category = n8nResult.Category }
			if n8nResult.Amount > 0 { result.Amount = n8nResult.Amount }
		}
	}
	
	if result.Category == "" { result.Category = "سایر" }
	if result.Type == "" { result.Type = "expense" }
	return result, nil
}

func (s *AIService) parseLocal(text string) *AIResponse {
	res := &AIResponse{Description: text, Date: time.Now().Format("2006-01-02"), Type: "expense"}
	
	// استخراج مبلغ
	re := regexp.MustCompile(`(\d{1,3}(?:,\d{3})*|\d+)\s*(?:هزار|تومان|ت)`)
	if m := re.FindStringSubmatch(text); len(m) > 1 {
		if amt, err := strconv.ParseFloat(strings.ReplaceAll(m[1], ",", ""), 64); err == nil {
			if strings.Contains(m[0], "هزار") { res.Amount = amt * 1000 } else { res.Amount = amt }
		}
	}
	
	// دسته‌بندی با کلمات کلیدی
	keywords := map[string][]string{
		"خوراک": {"غذا", "رستوران", "نان", "برنج", "روغن", "گوشت", "مرغ", "میوه"},
		"حمل و نقل": {"بنزین", "تاکسی", "مترو", "بلیط"},
		"قبوض": {"برق", "گاز", "آب", "تلفن", "اینترنت"},
		"تحصیل": {"کتاب", "دفتر", "دانشگاه", "مدرسه"},
		"تفریح": {"سینما", "کنسرت", "بازی"},
		"سلامت": {"دارو", "دکتر", "بیمارستان"},
	}
	for cat, words := range keywords {
		for _, w := range words {
			if strings.Contains(strings.ToLower(text), w) { res.Category = cat; return res }
		}
	}
	return res
}

func (s *AIService) callN8N(text string) (*AIResponse, error) {
	body, _ := json.Marshal(map[string]string{"text": text})
	resp, err := http.Post(s.cfg.N8NWebhookURL, "application/json", bytes.NewBuffer(body))
	if err != nil { return nil, err }
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	var result AIResponse
	json.Unmarshal(data, &result)
	return &result, nil
}
AISVC

# ============================================
# فایل internal/handlers/auth_handler.go
# ============================================
cat > internal/handlers/auth_handler.go << 'AHAND'
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type AuthHandler struct{ svc *services.AuthService }

func NewAuthHandler(svc *services.AuthService) *AuthHandler { return &AuthHandler{svc: svc} }

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req models.RegisterRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	user, err := h.svc.Register(&req)
	if err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.Status(201).JSON(fiber.Map{"user": user})
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req models.LoginRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	resp, err := h.svc.Login(&req)
	if err != nil { return c.Status(401).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(resp)
}
AHAND

# ============================================
# فایل internal/handlers/transaction_handler.go
# ============================================
cat > internal/handlers/transaction_handler.go << 'THAND'
package handlers

import (
	"strconv"
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type TransactionHandler struct{ svc *services.TransactionService }

func NewTransactionHandler(svc *services.TransactionService) *TransactionHandler { return &TransactionHandler{svc: svc} }

func (h *TransactionHandler) Create(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	var req models.CreateTransactionRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	txn, err := h.svc.Create(userID, &req)
	if err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.Status(201).JSON(txn)
}

func (h *TransactionHandler) GetAll(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	offset, _ := strconv.Atoi(c.Query("offset", "0"))
	txns, err := h.svc.GetAll(userID, limit, offset)
	if err != nil { return c.Status(500).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(txns)
}

func (h *TransactionHandler) GetByID(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id, _ := strconv.ParseUint(c.Params("id"), 10, 32)
	txn, err := h.svc.GetByID(uint(id))
	if err != nil || txn.UserID != userID { return c.Status(404).JSON(fiber.Map{"error": "Not found"}) }
	return c.JSON(txn)
}

func (h *TransactionHandler) Update(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id, _ := strconv.ParseUint(c.Params("id"), 10, 32)
	var req models.CreateTransactionRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	txn, err := h.svc.Update(userID, uint(id), &req)
	if err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(txn)
}

func (h *TransactionHandler) Delete(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id, _ := strconv.ParseUint(c.Params("id"), 10, 32)
	if err := h.svc.Delete(userID, uint(id)); err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(fiber.Map{"message": "Deleted"})
}

func (h *TransactionHandler) GetSummary(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"message": "Summary endpoint"})
}
THAND

# ============================================
# فایل internal/handlers/ai_handler.go
# ============================================
cat > internal/handlers/ai_handler.go << 'AIHAND'
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type AIHandler struct{ svc *services.AIService }

func NewAIHandler(svc *services.AIService) *AIHandler { return &AIHandler{svc: svc} }

func (h *AIHandler) ProcessTransaction(c *fiber.Ctx) error {
	var req struct { Text string `json:"text"`; Amount float64 `json:"amount"` }
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	result, err := h.svc.ProcessTransaction(req.Text, req.Amount)
	if err != nil { return c.Status(500).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(result)
}
AIHAND

# ============================================
# فایل .env
# ============================================
cat > .env << 'ENV'
PORT=8080
APP_NAME=Financial API
ENVIRONMENT=development
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=yourpassword
DB_NAME=financial_db
DB_SSL_MODE=disable
JWT_SECRET=super-secret-key-change-me
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=168h
N8N_WEBHOOK_URL=http://localhost:5678/webhook/process
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_DURATION=1m
ENV

echo "✅ همه فایل‌های Backend با موفقیت ساخته شدن!"
echo "🚀 برای اجرا: go mod tidy && go run cmd/api/main.go"
