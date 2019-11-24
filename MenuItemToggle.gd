extends HBoxContainer

signal selected(item, extra)
signal mouse_entered_item(item)

var value = ''

var extra = 1

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
	
	var one_selected : = false
	if new_extra == 1:
		one_selected = true
	$Option1.set_selected(one_selected)
	$Option2.set_selected(not one_selected)

func get_extra():
	return extra

func set_label(text : String) -> void:
	$Label.text = text

func set_active() -> void:
	is_current = true
	r_cursor.visible = true

func select() -> void:
	emit_signal("selected", value, extra)

func set_inactive() -> void:
	is_current = false
	r_cursor.visible = false

func is_active() -> bool:
	return is_current


func _process(delta) -> void:
	if not is_current:
		return
	
	if Input.is_action_just_pressed("move_right"):
		if extra < 2:
			set_extra(2)
			select()
	if Input.is_action_just_pressed("move_left"):
		if extra > 1:
			set_extra(1)
			select()

func _on_MenuItem_mouse_entered():
	emit_signal("mouse_entered_item", self)

func _on_Option_gui_input(event : InputEvent, option_clicked : int):
	print('event: ' + str(option_clicked))
	var click_event : = event as InputEventMouseButton
	if not click_event:
		return
	
	if click_event.button_index == BUTTON_LEFT and click_event.pressed: # on press
		set_extra(option_clicked)
		select()
