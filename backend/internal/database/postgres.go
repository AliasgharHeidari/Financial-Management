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
