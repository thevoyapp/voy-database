package tables

import (
  "github.com/google/uuid"
)

type Checkpoint struct {
  Id  *uuid.UUID  `json:"id,omitempty"`
  Subid   *uuid.UUID  `json:"subid,omitempty"`
  StartRel  *float64  `json:"start_rel,omitempty"`
  PhotoUrl  *string   `json:"photo_url,omitempty"`
  Region    *Region   `json:"region,omitempty"`
  
}
