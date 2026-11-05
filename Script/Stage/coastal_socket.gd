@tool
extends Resource
## Position is room-local. Vertical openings are 192px; horizontal openings 128px.
@export_enum("left", "right", "up", "down") var side := "left"
@export var position := Vector2.ZERO
@export var opening := 128
