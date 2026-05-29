package main

import (
	"context"
	"dummy_api/handler"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/awslabs/aws-lambda-go-api-proxy/httpadapter"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

var adapter *httpadapter.HandlerAdapterV2

func init() {
	log.Println("Cold start: initializing router...")

	chiRouter := chi.NewRouter()
	chiRouter.Use(middleware.Logger)
	chiRouter.Use(middleware.Recoverer)
	chiRouter.Use(middleware.StripSlashes)
	chiRouter.Use(middleware.SetHeader("Content-Type", "application/json"))

	chiRouter.Get("/health", handler.GetHealth)
	chiRouter.Post("/tasks", handler.InsertTask)
	chiRouter.Get("/tasks/{id}", handler.GetTask)

	adapter = httpadapter.NewV2(chiRouter)
}

func Handler(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	return adapter.ProxyWithContext(ctx, req)
}

func main() {
	lambda.Start(Handler)
}
