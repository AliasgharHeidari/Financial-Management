package services

import (
	"errors"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/repositories"
	"github.com/AliasgharHeidari/financial-management/internal/utils"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	repo *repositories.UserRepository
	cfg  *config.Config
}

func NewAuthService(repo *repositories.UserRepository, cfg *config.Config) *AuthService {
	return &AuthService{repo: repo, cfg: cfg}
}

func (s *AuthService) Register(req *models.RegisterRequest) (*models.User, error) {
	if exists, _ := s.repo.ExistsByEmail(req.Email); exists {
		return nil, errors.New("email already exists")
	}
	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	user := &models.User{Username: req.Username, Email: req.Email, Password: string(hash), FullName: req.FullName, IsActive: true}
	return user, s.repo.Create(user)
}

func (s *AuthService) Login(req *models.LoginRequest) (*models.LoginResponse, error) {
	user, err := s.repo.FindByEmail(req.Email)
	if err != nil || bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)) != nil {
		return nil, errors.New("invalid credentials")
	}
	token, _ := utils.GenerateToken(user.ID, s.cfg.JWTSecret, s.cfg.JWTExpiresIn)
	refresh, _ := utils.GenerateRefreshToken(user.ID, s.cfg.JWTSecret, s.cfg.JWTRefreshExpiresIn)
	return &models.LoginResponse{Token: token, RefreshToken: refresh, User: *user}, nil
}
