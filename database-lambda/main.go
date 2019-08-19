package main

import (
  "context"
  "fmt"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/CodyPerakslis/voy-database/database"
)

func HandleRequest(ctx context.Context, event *database.DatabaseCall) (interface{}, error) {
  db, err := database.Open(event.ConnectionInfo)
  fmt.Println("connect")
  if err != nil {
    fmt.Println("err")
    fmt.Println(err)
    return nil, nil
  }
  db.Close()
  fmt.Println("close")
  return nil, nil
}

func main() {lambda.Start(HandleRequest)}
