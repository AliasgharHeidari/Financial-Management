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
