package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type AuthHandler struct{ svc *services.AuthService }

func NewAuthHandler(svc *services.AuthService) *AuthHandler { return &AuthHandler{svc: svc} }

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req models.RegisterRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	user, err := h.svc.Register(&req)
	if err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.Status(201).JSON(fiber.Map{"user": user})
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req models.LoginRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	resp, err := h.svc.Login(&req)
	if err != nil { return c.Status(401).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(resp)
}
