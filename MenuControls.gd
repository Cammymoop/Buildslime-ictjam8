extends Node

var menu_item_scn : PackedScene = preload("res://MenuItem.tscn")

var paused = false

var pause_screen : Control = null
var pause_menu : VBoxContainer = null
var r_tutorial : Control = null
var r_submenu : Control = null

var menu_item_selected = 0
var menu_item_count = 0

var is_job_validated = false

var allow_job = true
var next_job = 1
var loadable = false

var cur_menu = 'home'

var submenu_open = false
var submenu_val = 1
var submenu_max_val = 1

func _ready() -> void:
	pause_screen = find_parent("Overlay").get_node("PauseMenu")
	pause_menu = pause_screen.find_node("MenuContainer")
	
	r_tutorial = find_parent("Overlay").find_node("Tutorial")
	r_submenu = find_parent("Overlay").find_node("Submenu")
	close_submenu()
	
	set_home_options()

func clear_options() -> void:
	for child in pause_menu.get_children():
		child.queue_free()
	menu_item_count = 0
	menu_item_selected = 0

func set_allow_job(val : bool) -> void:
	allow_job = val

func set_next_available_job(next : int) -> void:
	next_job = next

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
	is_job_validated = true
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

func activate_current() -> bool:
	var current_item = pause_menu.get_child(menu_item_selected)
	if not current_item:
		return true
	if not submenu_open and current_item.get_value() == 'job' and next_job > 1:
		submenu_val = next_job
		submenu_max_val = next_job
		current_item.set_extra(submenu_val)
		open_submenu()
		return false #dont unpause
	else:
		current_item.activate()
		return true

func open_submenu():
	submenu_open = true
	r_submenu.visible = true
	update_submenu_text()

func update_submenu_text() -> void:
	var text = ("<" if submenu_val > 1 else " ") + " "
	text += str(submenu_val) + " "
	text += (">" if submenu_val < submenu_max_val else " ")
	r_submenu.get_node("Label").text = text

func close_submenu():
	submenu_open = false
	r_submenu.visible = false

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
	r_tutorial.visible = false
	#deselect_all()
	select_current()

func unpause() -> void:
	if is_job_validated:
		is_job_validated = false
		set_job_options()
	paused = false
	get_tree().paused = false
	pause_screen.visible = false
	close_submenu()

func submenu_changed() -> void:
	var current_item = pause_menu.get_child(menu_item_selected)
	update_submenu_text()
	current_item.set_extra(submenu_val)

func submenu_process() -> void:
	if Input.is_action_just_pressed("move_left"):
		if submenu_val > 1:
			submenu_val -= 1
			submenu_changed()
	if Input.is_action_just_pressed("move_right"):
		if submenu_val < submenu_max_val:
			submenu_val += 1
			submenu_changed()

# warning-ignore:unused_argument
func _process(delta) -> void:
	if Input.is_action_just_pressed("action_menu_open"):
		if paused:
			unpause()
		else:
			var popup_open = find_parent("Root").find_node("MapPopup").visible
			if not popup_open:
				pause()
	
	if paused:
		if Input.is_action_just_pressed("action_grab"):
			var unpause = activate_current()
			if unpause:
				unpause()
				return
	
	if paused and not submenu_open:
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
		
		var something = false
		for i in range(menu_item_count):
			if pause_menu.get_child(menu_item_selected).is_active():
				something = true
		if not something:
			menu_item_selected = 0
			select_current()
	
	if paused and submenu_open:
		submenu_process()