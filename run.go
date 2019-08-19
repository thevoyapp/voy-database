package main

import (
  "fmt"
  "context"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/CodyPerakslis/voy-database/database"
)

func HandleRequest(ctx context.Context, event struct{}) (string, error) {
  output, err := database.Invoke(&database.Request{
    Operation: database.Exec,
    Query: `SELECT * from nodes;`,
  })
  if err != nil {return "", err}
  fmt.Println(output.FunctionError)
  if output.LogResult != nil {return *output.LogResult, nil}
  return "", nil
}

func main() {lambda.Start(HandleRequest)}
