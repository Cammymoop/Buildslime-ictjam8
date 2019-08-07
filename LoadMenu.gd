extends Control

var file_dialog_option_scene : PackedScene = preload('res://FileDialogOption.tscn')

func _ready():
	var file_container = find_node('FileContainer')
	
	for file_option in file_container.get_children():
		file_option.queue_free()
	
	var lf = file_dialog_option_scene.instance()
	lf.set_menu(self)
	lf.name = 'LeftFile'
	file_container.add_child(lf)
	
	var rf = file_dialog_option_scene.instance()
	rf.set_menu(self)
	rf.name = 'RightFile'
	file_container.add_child(rf)
	
	#lf.focus()

func scroll_left():
	print('scroll left')

func scroll_right():
	print('scroll right')
