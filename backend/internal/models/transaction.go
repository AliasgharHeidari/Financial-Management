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
