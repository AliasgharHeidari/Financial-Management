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
