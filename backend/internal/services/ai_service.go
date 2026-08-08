package services

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"
	"github.com/AliasgharHeidari/financial-management/internal/config"
)

type AIService struct{ cfg *config.Config }

type AIResponse struct {
	Category    string  `json:"category"`
	Amount      float64 `json:"amount"`
	Description string  `json:"description"`
	Date        string  `json:"date"`
	Type        string  `json:"type"`
}

func NewAIService(cfg *config.Config) *AIService { return &AIService{cfg: cfg} }

func (s *AIService) ProcessTransaction(text string, amount float64) (*AIResponse, error) {
	// اول regex محلی
	result := s.parseLocal(text)
	if result.Amount == 0 && amount > 0 { result.Amount = amount }
	
	// بعد n8n (اگه تنظیم شده)
	if s.cfg.N8NWebhookURL != "" {
		if n8nResult, err := s.callN8N(text); err == nil {
			if n8nResult.Category != "" { result.Category = n8nResult.Category }
			if n8nResult.Amount > 0 { result.Amount = n8nResult.Amount }
		}
	}
	
	if result.Category == "" { result.Category = "سایر" }
	if result.Type == "" { result.Type = "expense" }
	return result, nil
}

func (s *AIService) parseLocal(text string) *AIResponse {
	res := &AIResponse{Description: text, Date: time.Now().Format("2006-01-02"), Type: "expense"}
	
	// استخراج مبلغ
	re := regexp.MustCompile(`(\d{1,3}(?:,\d{3})*|\d+)\s*(?:هزار|تومان|ت)`)
	if m := re.FindStringSubmatch(text); len(m) > 1 {
		if amt, err := strconv.ParseFloat(strings.ReplaceAll(m[1], ",", ""), 64); err == nil {
			if strings.Contains(m[0], "هزار") { res.Amount = amt * 1000 } else { res.Amount = amt }
		}
	}
	
	// دسته‌بندی با کلمات کلیدی
	keywords := map[string][]string{
		"خوراک": {"غذا", "رستوران", "نان", "برنج", "روغن", "گوشت", "مرغ", "میوه"},
		"حمل و نقل": {"بنزین", "تاکسی", "مترو", "بلیط"},
		"قبوض": {"برق", "گاز", "آب", "تلفن", "اینترنت"},
		"تحصیل": {"کتاب", "دفتر", "دانشگاه", "مدرسه"},
		"تفریح": {"سینما", "کنسرت", "بازی"},
		"سلامت": {"دارو", "دکتر", "بیمارستان"},
	}
	for cat, words := range keywords {
		for _, w := range words {
			if strings.Contains(strings.ToLower(text), w) { res.Category = cat; return res }
		}
	}
	return res
}

func (s *AIService) callN8N(text string) (*AIResponse, error) {
	body, _ := json.Marshal(map[string]string{"text": text})
	resp, err := http.Post(s.cfg.N8NWebhookURL, "application/json", bytes.NewBuffer(body))
	if err != nil { return nil, err }
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	var result AIResponse
	json.Unmarshal(data, &result)
	return &result, nil
}
