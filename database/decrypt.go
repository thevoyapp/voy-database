package database

import (
  "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kms"
  "encoding/base64"
)

func Decrypt(encrypted string) (string, error) {
  kmsClient := kms.New(session.New())
  decodedBytes, err := base64.StdEncoding.DecodeString(encrypted)
  if err != nil {return "", err}
  input := &kms.DecryptInput{CiphertextBlob: decodedBytes}
  response, err := kmsClient.Decrypt(input)
  if err != nil {return "", err}
  return string(response.Plaintext[:]), nil
}
