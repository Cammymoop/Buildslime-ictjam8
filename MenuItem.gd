extends HBoxContainer

var value = ''

func get_value() -> String:
	return value

func set_value(val : String) -> void:
	value = val

func select() -> void:
	find_node("Cursor").visible = true

func deselect() -> void:
	find_node("Cursor").visible = false

func is_active() -> bool:
	return find_node("Cursor").visible