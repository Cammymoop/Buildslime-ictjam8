extends Control

var paused = false

var r_main_menu : VBoxContainer = null
var r_tutorial : Control = null

var loadable = true

var cur_menu = 'home'

func _ready() -> void:
	r_main_menu = find_node("MainMenu")
	
	r_tutorial = find_parent("Overlay").find_node("Tutorial")

func make_menu_option(value, text : String) -> Dictionary:
	return {'value': value, 'text': text}

func get_home_options() -> Array:
	cur_menu = 'home'
	var options = []
	options.append(make_menu_option("return", "Return"))
	options.append(make_menu_option("get-job", "Get job"))
	options.append(make_menu_option("save-game", "Save"))
	if loadable:
		options.append(make_menu_option("load-game", "Load"))
	options.append(make_menu_option("restart-game", "Reset Game"))
	#options.append(make_menu_option("quit", "Quit"))
	return options

func get_job_options() -> Array:
	cur_menu = 'job'
	var options = []
	options.append(make_menu_option("return", "Return"))
	options.append(make_menu_option("view-job", "Show job"))
	options.append(make_menu_option("eval-job", "Evaluate job"))
	options.append(make_menu_option("leave-job", "Cancel job"))
	options.append(make_menu_option("save-game", "Save"))
	if loadable:
		options.append(make_menu_option("load-game", "Load"))
	options.append(make_menu_option("restart-game", "Reset Game"))
	return options
func get_job_turn_in_options() -> Array:
	var options = []
	options.append(make_menu_option("return", "Return"))
	options.append(make_menu_option("finish-job", "Turn in job"))
	return options

func pause() -> void:
	paused = true
	get_tree().paused = true
	visible = true
	r_tutorial.visible = false
	
	var options = []
	if get_node("/root/GlobalData").is_at_job():
		options = get_job_options()
	else:
		options = get_home_options()
	r_main_menu.show_menu(options)
	r_main_menu.connect("menu_closed", self, "unpause", [], CONNECT_ONESHOT)
	r_main_menu.activate_menu()

func unpause() -> void:
	paused = false
	get_tree().paused = false
	visible = false

func force_unpause() -> void:
	r_main_menu.close_menu()


# warning-ignore:unused_argument
func _process(delta) -> void:
	if Input.is_action_just_pressed("action_menu_open"):
		if paused:
			force_unpause()
		else:
			pause()