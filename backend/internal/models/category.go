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
