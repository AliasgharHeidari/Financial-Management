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
