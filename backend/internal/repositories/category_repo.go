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
