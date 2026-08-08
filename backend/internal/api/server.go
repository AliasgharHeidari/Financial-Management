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
	return &Server{
		app: fiber.New(fiber.Config{AppName: cfg.AppName}),
		cfg: cfg,
		db:  db,
	}
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
		Max:        s.cfg.RateLimitRequests,
		Expiration: s.cfg.RateLimitDuration,
	}))
}

func (s *Server) SetupRoutes() {
	s.app.Get("/api/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
			"time":   time.Now().Format(time.RFC3339),
		})
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

func (s *Server) Shutdown() error {
	return s.app.Shutdown()
}