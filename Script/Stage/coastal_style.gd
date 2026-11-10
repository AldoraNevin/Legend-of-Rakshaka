@tool
extends Resource
@export var tileset: TileSet
## Baseline jump reaches about 42 px; keep a margin for discrete physics.
@export_range(32, 40, 1) var climb_rise := 40
@export_range(80, 112, 8) var climb_width := 96
@export_range(16, 32, 8) var climb_offset := 32
@export var background_tint := Color(0.65, 0.78, 0.85)
