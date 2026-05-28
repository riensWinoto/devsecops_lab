package handler

import (
	"encoding/json"
	"net/http"
)

func GetHealth(w http.ResponseWriter, r *http.Request) {
	jsonMap := make(map[string]any)
	jsonMap["message"] = "I am ok 200"
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(jsonMap)
}
