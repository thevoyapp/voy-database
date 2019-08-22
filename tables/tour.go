package tables

import (
  "github.com/google/uuid"
)

type Tour struct {
  Id    *uuid.UUID  `json:"id,omitempty"`
  Owner *uuid.UUID  `json:"owner,omitempty"`
  Title *string `json:"title,omitempty"`
  Description *string `json:"description,omitempty"`
  PhotoUrl  *string `json:"photo_url,omitempty"`
  AudioUrl  *string `json:"audio_url,omitempty"`
  VideoUrl  *string `json:"video_url,omitempty"`
  Data    *string   `json:"data,omitempty"`
  Updated *time.Time  `json:"updated,omitempty"`
  Private *boolean  `json:"private,omitemtpy"`
  AccessCode  *string `json:"access_code,omitempty"`
}
