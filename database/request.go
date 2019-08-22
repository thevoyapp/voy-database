package database

import (
  "database/sql"
  "errors"
  "fmt"
  "encoding/json"
)

type Operation int

const (
  Exec Operation = iota + 1
  Query
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

type RowResponse struct {
  Row    []byte   `json:"row"`
}

func (e *ExecResponse) String() string {
  data, err := json.Marshal(e)
  if err != nil {
    return err.Error()
  }
  return string(data)
}

func (r *RowResponse) String() string {
  return string(r.Row)
}

func (op Operation) Invoke(db *sql.DB, query string, args ...interface{}) (interface{}, error) {
  switch op {
  case Exec:
    return db.Exec(query, args...)
  case Query:
    return db.QueryRow(query, args...), nil
  default:
    return nil, NoSuchOperationError
  }
}

func Convert(data interface{}, err error) (interface{}, error) {
  if err != nil {return nil, err}
  fmt.Printf("%T\n", data)
  switch v := data.(type) {
  case sql.Result:
    rowsAffected, err := v.RowsAffected()
    return &ExecResponse{RowsAffected: rowsAffected}, err
  case *sql.Row:
    var row RowResponse
    err := v.Scan(&row.Row)
    return &row, err
  default:
    return nil, NoSuchOperationError
  }
}

func (req *Request) Invoke(db *sql.DB) (interface{}, error) {
  return Convert(req.Operation.Invoke(db, req.Query, req.Args...))
}
