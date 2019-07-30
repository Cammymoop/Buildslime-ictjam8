extends Node

var menu_item_scn : PackedScene = preload("res://MenuItem.tscn")

var paused = false

var pause_screen : Control = null
var pause_menu : VBoxContainer = null
var tutorial : Control = null

var menu_item_selected = 0
var menu_item_count = 0

var job_validated = false

var allow_job = true
var loadable = false

var cur_menu = 'home'

func _ready() -> void:
	pause_screen = find_parent("Overlay").get_node("PauseMenu")
	pause_menu = pause_screen.find_node("MenuContainer")
	
	tutorial = find_parent("Overlay").find_node("Tutorial")
	
	set_home_options()

func clear_options() -> void:
	for child in pause_menu.get_children():
		child.queue_free()
	menu_item_count = 0
	menu_item_selected = 0

func set_allow_job(val : bool) -> void:
	allow_job = val

func set_home_options() -> void:
	cur_menu = 'home'
	clear_options()
	add_menu_item("return", "Return")
	if allow_job:
		add_menu_item("job", "Get job")
	#add_menu_item("quit", "Quit")
	add_menu_item("save-game", "Save")
	if loadable:
		add_menu_item("load-game", "Load")
	add_menu_item("restart-game", "Reset Game")
	#print('set home options')

func set_job_options() -> void:
	cur_menu = 'job'
	clear_options()
	add_menu_item("return", "Return")
	add_menu_item("view-job", "Show job")
	add_menu_item("eval-job", "Evaluate job")
	add_menu_item("leave-job", "Cancel job")
	add_menu_item("save-game", "Save")
	if loadable:
		add_menu_item("load-game", "Load")
	add_menu_item("restart-game", "Reset Game")
	#print('set job options')
func set_job_options2() -> void:
	clear_options()
	add_menu_item("return", "Return")
	add_menu_item("finish-job", "Turn in job")
	#print('set job options 2')

func job_validated() -> void:
	job_validated = true
	set_job_options2()
	call_deferred('pause')
	
func add_menu_item(val : String, text : String) -> void:
	var item = menu_item_scn.instance()
	item.find_node("Label").text = text
	item.set_value(val)
	pause_menu.add_child(item)
	menu_item_count += 1

func select_current() -> void:
	var current_item = pause_menu.get_child(menu_item_selected)
	if not current_item:
		return
	current_item.select()

func deselect_current() -> void:
	var current_item = pause_menu.get_child(menu_item_selected)
	if not current_item:
		return
	#print('deactivating : ' + str(menu_item_selected))
	current_item.deselect()
	
func deselect_all() -> void:
	for child in pause_menu.get_children():
		child.deselect()
	#print('deactivating all')
	menu_item_selected = 0

func activate_current() -> void:
	var current_item = pause_menu.get_child(menu_item_selected)
	if not current_item:
		return
	find_parent("Root").find_node("Player").menu_selection(current_item.get_value())

func pause() -> void:
	if not loadable:
		var f = File.new()
		if f.file_exists("user://savegame.save"):
			loadable = true
			if cur_menu == 'home':
				set_home_options()
			elif cur_menu == 'job':
				set_job_options()
	paused = true
	get_tree().paused = true
	pause_screen.visible = true
	tutorial.visible = false
	#deselect_all()
	select_current()

func unpause() -> void:
	if job_validated:
		job_validated = false
		set_job_options()
	paused = false
	get_tree().paused = false
	pause_screen.visible = false

func _process(delta) -> void:
	if Input.is_action_just_pressed("action_menu_open"):
		if paused:
			unpause()
		else:
			var popup_open = find_parent("Root").find_node("MapPopup").visible
			if not popup_open:
				pause()
	
	if paused:
		if Input.is_action_just_pressed("move_down"):
			deselect_current()
			menu_item_selected += 1
			if menu_item_selected >= menu_item_count:
				menu_item_selected = 0
			select_current()
		elif Input.is_action_just_pressed("move_up"):
			deselect_current()
			menu_item_selected -= 1
			if menu_item_selected < 0:
				menu_item_selected = menu_item_count - 1
			select_current()
		elif Input.is_action_just_pressed("action_grab"):
			activate_current()
			unpause()
		
		var something = false
		for i in range(menu_item_count):
			if pause_menu.get_child(menu_item_selected).is_active():
				something = true
		if not something:
			menu_item_selected = 0
			select_current()