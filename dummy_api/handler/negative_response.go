package handler

import (
	"encoding/json"
	"net/http"
)

func badRequest(w http.ResponseWriter, errMessage string) {
	w.WriteHeader(http.StatusBadRequest)
	json.NewEncoder(w).Encode(map[string]any{"message": errMessage})
}

func notFound(w http.ResponseWriter, errMessage string) {
	w.WriteHeader(http.StatusNotFound)
	json.NewEncoder(w).Encode(map[string]any{"message": errMessage})
}
