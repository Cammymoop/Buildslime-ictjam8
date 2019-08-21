extends Node

var r_menu

func set_menu(menu) -> void:
	r_menu = menu

func get_options() -> Array:
	return []

# close menu if return true
func handle_item_selected(value, extra) -> bool:
	match value:
		_:
			pass
	
	return false


func make_menu_option(value, text : String) -> Dictionary:
	return {'value': value, 'text': text}