extends "res://EntitySprite.gd"

export (Texture) var eye_tex = preload("res://assets/images/buildslime_eyes.png")
export (Texture) var blink_tex = preload("res://assets/images/buildslime_eyes_close.png")

var holding_i = 0

var asleep = false
var blink_times = 0

func fall_asleep():
	asleep = true
	$Eyes.texture = blink_tex

func wake_up():
	asleep = false
	$Eyes.texture = eye_tex

func blink():
	if asleep:
		blink_times = 0
		return
	if blink_times <= 0:
		blink_times = randi() % 5
		if blink_times > 2 or blink_times < 1:
			blink_times = 1
	$Eyes.texture = blink_tex
	$Blink.start()

func _on_unblink():
	blink_times -= 1
	$Eyes.texture = eye_tex
	if blink_times > 0:
		$ReBlink.start()

func _on_reblink():
	blink()

func set_visible(val : bool):
	visible = val
	$Eyes.visible = val

func _set_all_region_pos(pos : Vector2):
	._set_all_region_pos(pos)
	$Eyes.region_rect.position = pos

func set_y_stretch(amount : float):
	.set_y_stretch(amount)
	$Eyes.scale.y = amount
	$Eyes.scale.x = 1/amount

func set_holding_amt(holding):
	holding_i = holding
	set_version(holding)

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
