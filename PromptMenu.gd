extends PanelContainer

signal item_selected(item, extra)
signal menu_closed

var prefix = ''

var mode = "numbers"

var main_value = ''
var prompt_value = 0

var min_number = 1
var max_number = 1

func update_value():
	pass

func set_prefix(text : String):
	prefix = text
	find_node('Prefix').text = text

func set_mode(new_mode : String):
	mode = new_mode

func set_main_value(value : String):
	main_value = value

func get_prompt_value():
	return prompt_value

func set_numbers_mode(main_value : String, n_start : int, n_max : int, n_min : int = 1) -> void:
	set_main_value(main_value)
	set_mode("numbers")
	min_number = n_min
	max_number = n_max
	prompt_value = n_start
	find_node('ConfirmButtons').visible = false
	find_node('Numbers').visible = true
	update_prompt()

func set_confirm_mode(main_value : String, default : int = 0):
	set_main_value(main_value)
	set_mode("confirm")
	prompt_value = 0 if default == 0 else 1
	var buttons = find_node('ConfirmButtons')
	buttons.visible = true
	find_node('Numbers').visible = false
	
	var yes = buttons.get_node('YesOption')
	yes.set_value(main_value)
	yes.set_extra(1)
	var no = buttons.get_node('NoOption')
	no.set_value(main_value)
	no.set_extra(0)
	if default == 0:
		no.set_active()
	else:
		yes.set_active()

func close():
	emit_signal("menu_closed")
	visible = false
	queue_free()

func update_prompt() -> void:
	if mode == "numbers":
		var left_button = find_node("LeftButton")
		if prompt_value > min_number:
			left_button.disabled = false
		else:
			left_button.disabled = true
		var right_button = find_node("RightButton")
		if prompt_value < max_number:
			right_button.disabled = false
		else:
			right_button.disabled = true
#		val_text = ("<" if prompt_value > min_number else " ") + " "
#		val_text += str(prompt_value) + " "
#		val_text += (">" if prompt_value < max_number else " ")
#
#		find_node('Prefix').text = prefix + '\n' + val_text
		find_node('NumberLabel').text = str(prompt_value)

	if mode == "confirm":
		var active = 'YesOption' if prompt_value > 0 else 'NoOption'
		var inactive = 'NoOption' if prompt_value > 0 else 'YesOption'
		find_node(active).set_active()
		find_node(inactive).set_inactive()

func number_decrease():
	if prompt_value > min_number:
		prompt_value -= 1
		update_prompt()

func number_increase():
	if prompt_value < max_number:
		prompt_value += 1
		update_prompt()


# warning-ignore:unused_argument
func _process(delta) -> void:
	if Input.is_action_just_pressed("menu_back"):
		close()
		return
	
	if Input.is_action_just_pressed("menu_select"):
		if mode == "confirm":
			find_node('YesOption' if prompt_value > 0 else 'NoOption').select()
		elif mode == "numbers":
			emit_signal("item_selected", main_value, prompt_value)
		close()
		return
	
	if mode == "numbers":
		if Input.is_action_just_pressed("move_left"):
			number_decrease()
		if Input.is_action_just_pressed("move_right"):
			number_increase()

	if mode == "confirm":
		if Input.is_action_just_pressed("move_right") and prompt_value > 0:
			prompt_value = 0
			update_prompt()
		if Input.is_action_just_pressed("move_left") and prompt_value < 1:
			prompt_value = 1
			update_prompt()

func _on_option_selected(value, extra):
	emit_signal("item_selected", value, extra)
	close()

func _on_mouse_entered_item(item):
	if not mode == "confirm":
		return
	find_node('YesOption').set_inactive()
	find_node('NoOption').set_inactive()
	item.set_active()
	prompt_value = item.get_extra()


func _on_LeftButton_pressed():
	number_decrease()

func _on_RightButton_pressed():
	number_increase()

func _on_OkButton_pressed():
	emit_signal("item_selected", main_value, prompt_value)
	close()
