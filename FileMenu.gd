extends PanelContainer

signal file_selected(value, extra)
signal menu_closed

var main_value

var file_count = 0

var current_page = 1
var max_page : int = 0

var all_filenames = []

var left_panel
var right_panel

var one_panel = false

func _ready():
	all_filenames = get_node("/root/SaveManager").get_all_saves()
	file_count = len(all_filenames)
	max_page = (file_count + 1)/2
	
	left_panel = find_node('LeftFile')
	right_panel = find_node('RightFile')
	
	update_display()

func set_main_value(val):
	main_value = val

func focus_left():
	right_panel.unfocus()
	left_panel.focus()
func focus_right():
	right_panel.focus()
	left_panel.unfocus()

func forward_page():
	current_page += 1
	if current_page > max_page:
		current_page = max_page
	focus_left()
	update_display()

func backward_page():
	current_page -= 1
	if current_page < 1:
		current_page = 1
	focus_right()
	update_display()

func update_display():
	var container = find_node('FileContainer')
	
	one_panel = false
	for i in range(2):
		var file_index = ((current_page - 1) * 2) + i
		var file_display = container.get_child(i)
		
		if file_index < file_count:
			file_display.display_file(all_filenames[file_index])
		else:
			one_panel = true
			file_display.hide()
	
	var left_button = find_node('LeftButton')
	if current_page > 1:
		left_button.disabled = false
	else:
		left_button.disabled = true
		
	var right_button = find_node('RightButton')
	if current_page < max_page:
		right_button.disabled = false
	else:
		right_button.disabled = true

func close():
	emit_signal("menu_closed")
	visible = false
	queue_free()

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed("menu_back"):
		close()
		return
	
	if Input.is_action_just_pressed("menu_select"):
		var selected = null
		if left_panel.is_focused():
			selected = left_panel
		elif right_panel.is_focused():
			selected = right_panel
		
		if selected:
			emit_signal("file_selected", main_value, selected.get_save_name())
		close()
		return
	
	if Input.is_action_just_pressed("move_left"):
		if left_panel.is_focused():
			if current_page > 1:
				backward_page()
		else:
			focus_left()
	if Input.is_action_just_pressed("move_right"):
		if right_panel.is_focused() or one_panel:
			if current_page < max_page:
				forward_page()
		else:
			focus_right()

func _on_mouse_entered_panel(panel):
	#print(panel.name)
	left_panel.unfocus()
	right_panel.unfocus()
	panel.focus()

func _on_CancelButton_pressed():
	close()


func _on_selected(save_name):
	emit_signal("file_selected", main_value, save_name)
	close()

func _on_LeftButton_pressed():
	backward_page()
	
func _on_RightButton_pressed():
	forward_page()
