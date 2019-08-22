package tables

type Point struct {
  Lat     *float64  `json:"lat,omitempty"`
  Lng   *float64    `json:"lng,omitempty"`
}

type BoundingBox struct {
  MaxLat    *float64   `json:"max_lat,omitempty"`
  MinLat    *float64   `json:"min_lat,omitempty"`
  MaxLng    *float64   `json:"max_lng,omitempty"`
  MinLng    *float64   `json:"min_lng,omitempty"`
}

type Region struct {
  Points   []Point  `json:"points"`
  Box   *BoundingBox  `json:"box,omitempty"`
}
