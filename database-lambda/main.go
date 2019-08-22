package main

import (
  "context"
  "fmt"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/CodyPerakslis/voy-database/database"
)

func HandleRequest(ctx context.Context, event *database.DatabaseCall) (interface{}, error) {
  fmt.Println("start")
  db, err := database.Open(event.ConnectionInfo)
  fmt.Println("connect")
  if err != nil {
    fmt.Println("err")
    fmt.Println(err)
    return nil, nil
  }
  defer db.Close()
  fmt.Println(event.Request)
  result, err := event.Request.Invoke(db)
  fmt.Println(result, err)
  fmt.Printf("%T\n", result)
  fmt.Println(result)
  fmt.Println("Hello World")
  return nil, nil
}

func main() {lambda.Start(HandleRequest)}
