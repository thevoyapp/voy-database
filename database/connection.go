package database

import (
  "fmt"
)

type ConnectionInfo struct {
  Host      string  `json:"host"`
  Port      int     `json:"port"`
  Username  string  `json:"username"`
  Password  string  `json:"password"`
}

func (conn *ConnectionInfo) String() string {
  return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=postgres connect_timeout=1",
    conn.Host, conn.Port, conn.Username, conn.Password)
}
