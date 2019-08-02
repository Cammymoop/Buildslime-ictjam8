extends PanelContainer

var prefix = ''

var mode = "numbers"

var submenu_value = 0

var min_number = 1
var max_number = 1

func update_value():
	pass

func set_prefix(text : String):
	prefix = text + '\n'

func set_mode(new_mode : String):
	mode = new_mode

func get_value():
	return submenu_value

func set_numbers_mode(n_start : int, n_max : int, n_min : int = 1) -> void:
	set_mode("numbers")
	min_number = n_min
	max_number = n_max
	submenu_value = n_start

func set_confirm_mode(default : int = 0):
	set_mode("confirm")
	submenu_value = 0 if default == 0 else 1

func open(prefix_text : String):
	set_prefix(prefix_text)
	if mode:
		set_mode(mode)
	visible = true
	update_text()

func close():
	visible = false

func show_value(val):
	$Label.text = prefix + val

func update_text() -> void:
	var val_text = ''
	if mode == "numbers":
		val_text = ("<" if submenu_value > min_number else " ") + " "
		val_text += str(submenu_value) + " "
		val_text += (">" if submenu_value < max_number else " ")
	
	if mode == "confirm":
		val_text = " " + (">" if submenu_value > 0 else " ") + "Yes  "
		val_text += (">" if submenu_value < 1 else " ") + "No"
		
	$Label.text = prefix + val_text

func sub_process() -> void:
	if mode == "numbers":
		if Input.is_action_just_pressed("move_left"):
			if submenu_value > min_number:
				submenu_value -= 1
				update_text()
		if Input.is_action_just_pressed("move_right"):
			if submenu_value < max_number:
				submenu_value += 1
				update_text()
	
	if mode == "confirm":
		if Input.is_action_just_pressed("move_right") and submenu_value > 0:
			submenu_value = 0
			update_text()
		if Input.is_action_just_pressed("move_left") and submenu_value < 1:
			submenu_value = 1
			update_text()