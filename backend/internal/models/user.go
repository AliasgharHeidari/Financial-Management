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
