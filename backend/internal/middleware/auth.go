package middleware

import (
	"strings"
	"github.com/gofiber/fiber/v2"
	"github.com/AliasgharHeidari/financial-management/internal/config"
	"github.com/AliasgharHeidari/financial-management/internal/utils"
)

func AuthRequired(cfg *config.Config) fiber.Handler {
	return func(c *fiber.Ctx) error {
		auth := c.Get("Authorization")
		if auth == "" {
			return c.Status(401).JSON(fiber.Map{"error": "Authorization header required"})
		}
		parts := strings.Split(auth, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(401).JSON(fiber.Map{"error": "Invalid token format"})
		}
		claims, err := utils.ValidateToken(parts[1], cfg.JWTSecret)
		if err != nil {
			return c.Status(401).JSON(fiber.Map{"error": "Invalid or expired token"})
		}
		c.Locals("user_id", claims.UserID)
		return c.Next()
	}
}
