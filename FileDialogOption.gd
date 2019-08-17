extends MarginContainer

signal selected(save_name)
signal mouse_entered_panel(panel)

export var is_new_file : bool = false

var focus_color = '485454'
var unfocus_color = '000000'

var save_name : String

var focused = false

func focus():
	focused = true
	$BGColor.color = Color(focus_color)

func unfocus():
	focused = false
	$BGColor.color = Color(unfocus_color)

func is_focused():
	return focused

func get_save_name() -> String:
	if is_new_file:
		return '__new_file__'
	return save_name

func hide():
	visible = false

func display_file(save_filename: String, label_prefix):
	if is_new_file:
		return
	visible = true
	save_name = save_filename
	var meta_data = get_node("/root/SaveManager").get_save_meta(save_filename)
	if not meta_data['success']:
		fail_display()
		return
	
	var text = ''
	text += meta_data['name'] + '\n'
	text += meta_data['date']['month'] + '/' + meta_data['date']['day'] + '/' + meta_data['date']['year'] + '\n'
	text += 'Jobs Completed: ' + meta_data['job_progress']
	
	find_node('FileInfoLabel').text = label_prefix + text
	
	if meta_data['screenshot'] != 'none':
		display_screenshot(meta_data['screenshot'])
	else:
		reset_screenshot()

func display_screenshot(screenshot_name : String) -> void:
	var screenshot_panel = find_node('ScreenshotPanel')
	screenshot_panel.show_screenshot(screenshot_name)

func reset_screenshot():
	var screenshot_panel = find_node('ScreenshotPanel')
	screenshot_panel.reset()

func fail_display():
	$Label.text = 'Err\n\nx.x'

func select():
	#print('sn: ' + save_name)
	if is_new_file:
		emit_signal("selected", '__new_file__')
	else:
		emit_signal("selected", save_name)

func _on_LeftFile_mouse_entered():
	emit_signal("mouse_entered_panel", self)


func _on_LeftFile_gui_input(event : InputEvent):
	var click_event : = event as InputEventMouseButton
	if not click_event:
		return
	
	if click_event.button_index == BUTTON_LEFT and click_event.pressed: # on press
		select()
