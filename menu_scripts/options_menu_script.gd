extends Node

var r_menu

func set_menu(menu):
	r_menu = menu

func get_options() -> Array:
	var options = []
	var settings = get_node("/root/GlobalData").get_settings()
	options.append(make_menu_option("back", "Back"))
	options.append(make_menu_option("color", "Color"))
	options.append(make_menu_toggle("movement_smoothing", "Movement Smoothing", settings))
	options.append(make_menu_toggle("camera_smoothing", "Camera Smoothing", settings))
	options.append(make_menu_toggle("squishing", "Squishing", settings))
	return options

# close menu if return true
func handle_item_selected(value, extra) -> bool:
	match value:
		"back":
			return true
		'ignore':
			pass
		_:
			var settings : Dictionary = get_node("/root/GlobalData").get_settings()
			if extra == -1:
				pass
			else:
				if settings.has(value):
					get_node("/root/GlobalData").change_setting(value, extra)
	
	# dont close menu
	return false

func make_menu_option(value, text : String) -> Dictionary:
	return {'value': value, 'text': text}

func make_menu_toggle(value, text : String, starting_vals : Dictionary) -> Dictionary:
	var starting = 1
	if starting_vals.has(value):
		starting = starting_vals[value]
	return {'value': value, 'text': text, 'toggle': true, 'starting_extra': starting}
