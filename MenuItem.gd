extends HBoxContainer

signal focused

var value = ''

var extra = 0

func get_value() -> String:
	return value

func set_value(val : String) -> void:
	value = val

func set_extra(new_extra) -> void:
	extra = new_extra

func select() -> void:
	find_node("Cursor").visible = true

func activate() -> void:
	find_parent("Root").find_node("Player").menu_selection(value, extra)

func deselect() -> void:
	find_node("Cursor").visible = false

func is_active() -> bool:
	return find_node("Cursor").visible
