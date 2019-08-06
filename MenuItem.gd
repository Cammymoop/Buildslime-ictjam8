extends HBoxContainer

signal focused

var value = ''

var extra = 0

var r_menu

func set_menu(menu):
	r_menu = menu

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


func _on_MenuItem_gui_input(event : InputEvent):
	var click_event : = event as InputEventMouseButton
	if not click_event:
		return
	
	if click_event.button_index == BUTTON_LEFT and not click_event.pressed:
		r_menu.item_clicked(self)
		#print($Label.text + " was clicked")
