extends PanelContainer

signal item_selected(item, extra)
signal menu_closed

var menu_title = ''

var mode = "numbers"

var main_value = ''
var prompt_value = 0

var min_number = 1
var max_number = 1

func update_value():
	pass

func set_title(text : String):
	menu_title = text
	find_node('Title').text = text


func set_main_value(value : String):
	main_value = value

func get_prompt_value():
	return prompt_value

func set_numbers_mode(main_value : String, n_start : int, n_max : int, n_min : int = 1) -> void:
	set_main_value(main_value)
	#set_mode("numbers")
	min_number = n_min
	max_number = n_max
	prompt_value = n_start
	find_node('ConfirmButtons').visible = false
	find_node('Numbers').visible = true
	update_prompt()

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
		find_node('Job Name').text = str(prompt_value)

func next_job():
	if prompt_value > min_number:
		prompt_value -= 1
		update_prompt()

func prev_job():
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
			prev_job()
		if Input.is_action_just_pressed("move_right"):
			next_job()

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


func _on_LeftButton_pressed():
	prev_job()

func _on_RightButton_pressed():
	next_job()

func _on_OkButton_pressed():
	emit_signal("item_selected", main_value, prompt_value)
	close()
