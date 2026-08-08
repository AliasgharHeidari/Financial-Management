package handlers

import (
	"strconv"
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/models"
	"github.com/AliasgharHeidari/financial-management/internal/services"
)

type TransactionHandler struct{ svc *services.TransactionService }

func NewTransactionHandler(svc *services.TransactionService) *TransactionHandler { return &TransactionHandler{svc: svc} }

func (h *TransactionHandler) Create(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	var req models.CreateTransactionRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	txn, err := h.svc.Create(userID, &req)
	if err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.Status(201).JSON(txn)
}

func (h *TransactionHandler) GetAll(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	offset, _ := strconv.Atoi(c.Query("offset", "0"))
	txns, err := h.svc.GetAll(userID, limit, offset)
	if err != nil { return c.Status(500).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(txns)
}

func (h *TransactionHandler) GetByID(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id, _ := strconv.ParseUint(c.Params("id"), 10, 32)
	txn, err := h.svc.GetByID(uint(id))
	if err != nil || txn.UserID != userID { return c.Status(404).JSON(fiber.Map{"error": "Not found"}) }
	return c.JSON(txn)
}

func (h *TransactionHandler) Update(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id, _ := strconv.ParseUint(c.Params("id"), 10, 32)
	var req models.CreateTransactionRequest
	if err := c.BodyParser(&req); err != nil { return c.Status(400).JSON(fiber.Map{"error": "Invalid request"}) }
	txn, err := h.svc.Update(userID, uint(id), &req)
	if err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(txn)
}

func (h *TransactionHandler) Delete(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id, _ := strconv.ParseUint(c.Params("id"), 10, 32)
	if err := h.svc.Delete(userID, uint(id)); err != nil { return c.Status(400).JSON(fiber.Map{"error": err.Error()}) }
	return c.JSON(fiber.Map{"message": "Deleted"})
}

func (h *TransactionHandler) GetSummary(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"message": "Summary endpoint"})
}
