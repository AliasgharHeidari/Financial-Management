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
