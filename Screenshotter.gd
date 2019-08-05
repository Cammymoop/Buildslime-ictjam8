extends Node

var vp_size

func _ready():
	var d :Directory = Directory.new()
	if not d.dir_exists("user://screenshots"):
		d.make_dir("user://screenshots")

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed("temp_screenshot"):
		take_shot()

func get_screenshot_name() -> String:
	var f = File.new()
	var try_name = "screenshot"
	var number = 1
	
	while f.file_exists("user://screenshots/" + try_name + str(number) + '.png'):
		number += 1
		if number > 10000:
			return 'toomany'
	return try_name + str(number)
	

func take_shot(name : String = ''):
	var vp = get_viewport()
	var shot = vp.get_texture().get_data()
	shot.flip_y()
	shot.resize(300, 300, Image.INTERPOLATE_NEAREST)
	if len(name) < 1:
		name = get_screenshot_name()
	shot.save_png("user://screenshots/" + name + ".png")