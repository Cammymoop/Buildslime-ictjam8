extends Sprite

var tile_position = Vector2(0, 0)
var TILE = 16

func _ready():
	tile_position.x = round(position.x/TILE)
	tile_position.y = round(position.y/TILE)

func _process(delta) -> void:
	if Input.is_action_just_pressed("move_right"):
		tile_position.x += 1
		position.x += TILE
