extends HBoxContainer

signal selected(item, extra)
signal mouse_entered_item(item)

var value = ''

var extra = -1

var is_current = false

var click_focus = false

var r_cursor

func _ready():
	r_cursor = find_node('Cursor')

func get_value() -> String:
	return value

func set_value(val : String) -> void:
	value = val

func set_extra(new_extra) -> void:
	extra = new_extra
func get_extra():
	return extra

func set_label(text : String) -> void:
	$Label.text = text

func set_active() -> void:
	is_current = true
	r_cursor.visible = true

func select() -> void:
	emit_signal("selected", value, extra)
	#find_parent("Root").find_node("Player").menu_selection(value, extra)

func set_inactive() -> void:
	is_current = false
	r_cursor.visible = false

func is_active() -> bool:
	return is_current


func _on_MenuItem_mouse_entered():
	emit_signal("mouse_entered_item", self)

func _on_MenuItem_gui_input(event : InputEvent):
	var click_event : = event as InputEventMouseButton
	if not click_event:
		return
	
	if click_event.button_index == BUTTON_LEFT and click_event.pressed: # on press
		#print('clicked ' + value)
		select()
	# This is how to do it on release to make sure mouse is still inside
#	if click_event.button_index == BUTTON_LEFT and not click_event.pressed: # on release
#		var my_rect = Rect2(Vector2(0, 0), rect_size)
#		if my_rect.has_point(click_event.position):
#			print('clicked ' + value)
#			select()
#			#r_menu.item_clicked(self)
#			#print($Label.text + " was clicked")
