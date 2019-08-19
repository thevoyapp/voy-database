package database

import (
  "os"
  "encoding/json"
  "github.com/aws/aws-sdk-go/aws"
  "github.com/aws/aws-sdk-go/aws/session"
  "github.com/aws/aws-sdk-go/service/lambda"
  "strconv"
)

func NewConnectionFromLambda() (*ConnectionInfo, error) {
  password, err := Decrypt(os.Getenv("PASSWORD"))
  if err != nil {return nil, err}
  port, err := strconv.Atoi(os.Getenv("PORT"))
  if err != nil {return nil, err}
  return &ConnectionInfo{
    Host: os.Getenv("HOST"),
    Port: port,
    Username: os.Getenv("USERNAME"),
    Password: password,
  }, nil
}

func NewDatabaseCallFromLambda(req *Request) (*DatabaseCall, error){
  conn, err := NewConnectionFromLambda()
  if err != nil {return nil, err}
  return &DatabaseCall{
    ConnectionInfo: conn,
    Request: req,
  }, nil
}

func (dc *DatabaseCall) Invoke() (*lambda.InvokeOutput, error) {
  data, err := json.Marshal(dc)
  if err != nil {return nil, err}
  return lambda.New(session.New()).Invoke(&lambda.InvokeInput{
    FunctionName: aws.String("database-interaction"),
    InvocationType: aws.String("RequestResponse"),
    LogType: aws.String("Tail"),
    Payload: data,
  })
}

func Invoke(req *Request) (*lambda.InvokeOutput, error) {
  dc, err := NewDatabaseCallFromLambda(req)
  if err != nil {return nil, err}
  return dc.Invoke()
}
