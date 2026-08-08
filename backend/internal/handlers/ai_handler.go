package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type AIHandler struct{ svc *services.AIService }

func NewAIHandler(svc *services.AIService) *AIHandler { return &AIHandler{svc: svc} }

func (h *AIHandler) ProcessTransaction(c *fiber.Ctx) error {
	var req struct { Text string `json:"text"`; Amount float64 `json:"amount"` }
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	result, err := h.svc.ProcessTransaction(req.Text, req.Amount)
	if err != nil { return c.Status(500).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(result)
}
