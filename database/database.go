package database

import (
  _ "github.com/lib/pq"
  "database/sql"
  "fmt"
)

type DatabaseCall struct {
  ConnectionInfo    *ConnectionInfo   `json:"connection"`
  Request           *Request          `json:"request"`
}

func Open(conn *ConnectionInfo) (*sql.DB, error) {
  c := conn.String()
  fmt.Println(c)
  db, err := sql.Open("postgres", c)
  if err != nil {return nil, err}
  fmt.Println("Connected")
  err = db.Ping()
  if err != nil {return nil, err}
  return db, nil
}

func RunDatabase(dcall *DatabaseCall) (interface{}, error) {
  db, err := Open(dcall.ConnectionInfo)
  if err != nil {return nil, err}
  return dcall.Request.Invoke(db)
}
