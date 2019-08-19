package database

import (
  "database/sql"
  "errors"
)

type Operation int

const (
  Exec Operation = iota + 1
  Query
  QueryRow
)

var (
  NoSuchOperationError = errors.New("No such operation")
)

type Request struct {
  Operation   Operation     `json:"operation"`
  Query       string        `json:"query"`
  Args        []interface{} `json:"args"`
}

type ExecResponse struct {
  RowsAffected    int64     `json:"rows_affected"`
}

func (op Operation) Invoke(db *sql.DB, query string, args ...interface{}) (interface{}, error) {
  switch op {
  case Exec:
    return db.Exec(query, args...)
  default:
    return nil, NoSuchOperationError
  }
}

func Convert(data interface{}, err error) (interface{}, error) {
  if err != nil {return nil, err}
  switch v := data.(type) {
  case sql.Result:
    rowsAffected, err := v.RowsAffected()
    return &ExecResponse{RowsAffected: rowsAffected}, err
  default:
    return nil, NoSuchOperationError
  }
}

func (req *Request) Invoke(db *sql.DB) (interface{}, error) {
  return req.Operation.Invoke(db, req.Query, req.Args...)
}
