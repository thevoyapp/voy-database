package main

import (
  "fmt"
  "context"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/CodyPerakslis/voy-database/database"
  "github.com/CodyPerakslis/voy-database/tables"
)

func HandleRequest(ctx context.Context, event struct{}) (string, error) {
  user := tables.PlatformUser{}
  output, err := database.Invoke(user.Select())
  if err != nil {return "", err}
  fmt.Println(output.FunctionError)
  if output.LogResult != nil {return *output.LogResult, nil}
  return "", nil
}

func main() {lambda.Start(HandleRequest)}
