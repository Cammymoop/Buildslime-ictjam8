extends PanelContainer

signal selected(item, extra)
signal dismissed

var value = ''

var wait_a_bit = false

func show_prompt(prefix : String, menu_value = '', default_text = ''):
	value = menu_value
	get_node("VBoxContainer/Label").text = prefix
	wait_a_bit = true
	
	var line_edit = get_node("VBoxContainer/LineEdit")
	if default_text:
		line_edit.text = default_text
	line_edit.grab_focus()
	line_edit.select_all()

func close() -> void:
	queue_free()

func select():
	emit_signal("dismissed")
	emit_signal("selected", value, get_node("VBoxContainer/LineEdit").text)
	close()

# warning-ignore:unused_argument
func _process(delta):
	if wait_a_bit:
		wait_a_bit = false
		return
	
	var line_edit = get_node("VBoxContainer/LineEdit")
	if Input.is_action_just_pressed("menu_select") and not line_edit.has_focus():
		select()
	if Input.is_action_just_pressed("menu_back") and not line_edit.has_focus():
		emit_signal("dismissed")
		close()
	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_up"):
		line_edit.release_focus()

func _on_OkButton_pressed():
	select()

func _on_CancelButton_pressed():
	emit_signal("dismissed")
	close()
