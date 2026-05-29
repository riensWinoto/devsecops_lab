package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type newTaskStruct struct {
	Name     string `json:"name"`
	Priority string `json:"priority"`
}

type taskStruct struct {
	Id        string    `json:"uuid"`
	Name      string    `json:"name"`
	Priority  string    `json:"priority"`
	CreatedAt time.Time `json:"created_at"`
}

var taskMap = make(map[string]taskStruct)
var mu sync.RWMutex

func InsertTask(w http.ResponseWriter, r *http.Request) {
	var newTask newTaskStruct
	defer r.Body.Close()
	if err := json.NewDecoder(r.Body).Decode(&newTask); err != nil {
		badRequest(w, "invalid request body")
		return
	}

	if newTask.Name == "" || newTask.Priority == "" {
		badRequest(w, "name and priority are required")
		return
	}

	uuidStr := uuid.NewString()
	mu.Lock()
	taskMap[uuidStr] = taskStruct{
		Id:        uuidStr,
		Name:      newTask.Name,
		Priority:  newTask.Priority,
		CreatedAt: time.Now(),
	}
	mu.Unlock()

	responseStruct := struct {
		Id     string `json:"uuid"`
		Status string `json:"status"`
	}{
		Id:     uuidStr,
		Status: "created",
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(responseStruct)
}

func GetTask(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	mu.RLock()
	val, ok := taskMap[id]
	mu.RUnlock()

	if ok {
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(val)
		return
	}
	notFound(w, fmt.Sprintf("%s not found", id))
}
