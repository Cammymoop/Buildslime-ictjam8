extends Control

signal took_screenshot
signal force_unpause
signal unpaused

var btext_scn = preload("res://BetterTextPopup.tscn")

var paused = false

var just_paused = false

var r_main_menu : VBoxContainer = null
var r_tutorial : Control = null

var cur_menu = 'home'

var take_screenshot_name = ''
var take_screenshot = false

func _ready() -> void:
	r_main_menu = find_node("MainMenu")
	
	r_tutorial = find_parent("UI").find_node("Tutorial")

func make_menu_option(value, text : String) -> Dictionary:
	return {'value': value, 'text': text}

func can_load() -> bool:
	return len(get_node("/root/SaveManager").get_all_saves()) > 0

func get_home_options() -> Array:
	cur_menu = 'home'
	var options = []
	options.append(make_menu_option("return", "Return"))
	options.append(make_menu_option("get-job", "Get job"))
	options.append(make_menu_option("save-load-menu", "Save/Load"))
	options.append(make_menu_option("set-name", "Change Name"))
	options.append(make_menu_option("help-menu", "Help"))
	#options.append(make_menu_option("quit", "Quit"))
	return options

func get_job_options() -> Array:
	cur_menu = 'job'
	var options = []
	options.append(make_menu_option("return", "Return"))
	options.append(make_menu_option("view-job", "Show job"))
	options.append(make_menu_option("eval-job", "Evaluate job"))
	options.append(make_menu_option("leave-job", "Cancel job"))
	options.append(make_menu_option("save-load-menu", "Save/Load"))
	options.append(make_menu_option("set-name", "Change Name"))
	options.append(make_menu_option("help-menu", "Help"))
	return options

func pause() -> bool:
	if paused:
		just_paused = true
		return true
	var can_pause = get_node("/root/GlobalData").get_pause_focus('pause-screen')
	if not can_pause:
		return false
	paused = true
	just_paused = true
	get_tree().paused = true
	visible = true
	r_tutorial.visible = false
	return true

func show_pause_menu():
	var options = []
	if get_node("/root/GlobalData").is_at_job():
		options = get_job_options()
	else:
		options = get_home_options()
	r_main_menu.show_menu(options)
	r_main_menu.connect("menu_closed", self, "defer_unpause", [], CONNECT_ONESHOT)
	r_main_menu.open_menu()

func defer_unpause() -> void:
	call_deferred('unpause')

func unpause() -> void:
	if just_paused:
		return
	paused = false
	get_tree().paused = false
	visible = false
	get_node("/root/GlobalData").release_pause_focus('pause-screen')
	emit_signal("unpaused")

func force_unpause() -> void:
	if r_main_menu.is_open():
		r_main_menu.close_menu()
	emit_signal("force_unpause")

func show_quick_text(text : String, error : bool = false):
	print('show text')
	if pause():
		var text_popup = btext_scn.instance()
		text_popup.show_text(text, error)
		$CenterContainer.add_child(text_popup)
		text_popup.connect("dismissed", self, "unpause", [], CONNECT_ONESHOT)
		connect("force_unpause", text_popup, "close", [], CONNECT_ONESHOT)

# warning-ignore:unused_argument
func _process(delta) -> void:
	if take_screenshot:
		return
	if just_paused:
		just_paused = false
	if Input.is_action_just_pressed("action_menu_open"):
		if paused:
			force_unpause()
		else:
			if pause():
				show_pause_menu()

func queue_screenshot(name : String) -> void:
	take_screenshot_name = name
	take_screenshot = true
	visible = false
	$ScreenshotTimer.start()

func _on_ScreenshotTimer_timeout():
	take_screenshot = false
	get_node("/root/Screenshotter").take_shot(take_screenshot_name)
	visible = true
	emit_signal('took_screenshot')
