tool
extends Sprite

var sprite_width = 16
var sprite_height = 16

var facing_i = 0
export var version_i = 0 setget version_setget


func _set_all_region_pos(pos : Vector2):
	region_rect.position = pos

func set_y_stretch(amount : float):
	scale.y = amount
	scale.x = 1/amount

func set_showing_frame(facing : int, version = false):
	facing_i = facing
	if version:
		version_i = version
	_set_all_region_pos(Vector2(version_i * sprite_width, facing * sprite_height))

func set_version(version):
	set_showing_frame(facing_i, version)

func set_facing_frame(facing):
	set_showing_frame(facing)

func set_facing_dir(facing_dir):
	var facing = -1
	match facing_dir:
		'down':
			facing = 0
		'up':
			facing = 1
		'right':
			facing = 2
		'left':
			facing = 3
	set_facing_frame(facing)

func version_setget(new_version):
	version_i = new_version
	set_showing_frame(facing_i)
	return version_i
