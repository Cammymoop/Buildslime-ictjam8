extends PanelContainer

signal item_selected(item, extra)
signal menu_closed

export (Script) var item_script = null

var menu_item_scn : PackedScene = preload("res://MenuItem.tscn")
var menu_option_scn : PackedScene = preload("res://MenuItemToggle.tscn")
var menu_slider_scn : PackedScene = preload("res://MenuItemSlider.tscn")

var prompt_menu_scn : PackedScene = preload("res://PromptMenu.tscn")
var text_prompt_scn : PackedScene = preload("res://TextPrompt.tscn")
var file_menu_scn : PackedScene = preload("res://FileMenu.tscn")
var text_popup_scn : PackedScene = preload("res://TextPopup.tscn")
var job_menu_scn : PackedScene = preload("res://JobMenu.tscn")
var list_menu_scn_path = "res://ListMenu.tscn"

var menu_item_count = 0

var menu_open = false
var menu_active = false

var has_script = false

func _ready():
	if item_script:
		_set_menu_script(item_script)
#		var script_obj = item_script.new()
#		script_obj.name = "Script"
#		script_obj.set_menu(self)
#		add_child(script_obj)
#		has_script = true

func set_menu_script(script_name : String) -> void:
	var scr : = load("res://menu_scripts/" + script_name) as Script
	if not scr:
		push_error('couldn\'t load menu script: ' + script_name)
		return
	_set_menu_script(scr)

func _set_menu_script(menu_script : Script) -> void:
	var script_obj = menu_script.new()
	script_obj.name = "MenuScript"
	script_obj.set_menu(self)
	add_child(script_obj)
	has_script = true

func show_menu(options : Array):
	clear_options()
	
	if len(options) < 1 and has_script:
		if $MenuScript.has_method('get_options'):
			options = $MenuScript.get_options()
	
	var first = true
	for o in options:
		var option : = o as Dictionary
		if not option:
			print('menu option must be a Dictionary')
			continue
		if not (option.has('value') and option.has('text')):
			print('menu option must have a value and text')
			continue
		
		var item
		if option.has('toggle'):
			item = add_menu_option(option['value'], option['text'], option['starting_extra'])
		elif option.has('slider'):
			item = add_menu_slider(option['value'], option['text'], option['min_extra'], option['max_extra'], option['starting_extra'])
		else:
			item = add_menu_item(option['value'], option['text'])
		if first:
			item.set_active()
			first = false
	visible = true

func open_menu():
	menu_open = true
	activate_menu()

func close_menu():
	menu_open = false
	deactivate_menu()
	hide_menu()
	emit_signal("menu_closed")

func remove_menu():
	close_menu()
	queue_free()

func is_open() -> bool:
	return menu_open

func add_child_list_menu(script_name : String = '', options : Array = []) -> void:
	var lm = load(list_menu_scn_path).instance()
	get_parent().add_child(lm)
	if script_name:
		lm.set_menu_script(script_name)
	else:
		lm.connect("item_selected", self, "on_item_selected")
	lm.show_menu(options)
	lm.open_menu()
	lm.connect("menu_closed", self, "activate_menu", [], CONNECT_ONESHOT)
	connect("menu_closed", lm, "remove_menu")
	deactivate_menu()
	

func add_child_text_prompt(prompt_value, prompt_text, starting_input) -> void:
	var prompt = text_prompt_scn.instance()
	get_parent().add_child(prompt)
	prompt.show_prompt(prompt_text, prompt_value, starting_input)
	prompt.connect("selected", self, "on_item_selected")
	prompt.connect("dismissed", self, "activate_menu")
	connect("menu_closed", prompt, "close")
	deactivate_menu()

func _add_child_prompt(prompt_text) -> Node:
	var prompt = prompt_menu_scn.instance()
	get_parent().add_child(prompt)
	prompt.set_prefix(prompt_text)
	return prompt

func add_child_confirm_prompt(prompt_value : String, prompt_text : String) -> void:
	var prompt = _add_child_prompt(prompt_text)
	prompt.set_confirm_mode(prompt_value)
	show_child_prompt(prompt)

func add_child_numbers_prompt(prompt_value : String, prompt_text : String, start_number : int, min_num : int, max_num : int) -> void:
	var prompt = _add_child_prompt(prompt_text)
	prompt.set_numbers_mode(prompt_value, start_number, max_num, min_num)
	show_child_prompt(prompt)

func add_child_job_menu(name: String, levels: Array) -> void:
	var jmenu = job_menu_scn.instance()
	get_parent().add_child(jmenu)
	jmenu.set_title(name)
	show_child_prompt(jmenu)

func show_child_prompt(prompt):
	prompt.connect("item_selected", self, "on_item_selected")
	prompt.connect("menu_closed", self, "activate_menu")
	connect("menu_closed", prompt, "close")
	deactivate_menu()

func add_child_file_menu(main_value : String, just_these = false, new_mode : bool = false) -> void:
	var fm : = file_menu_scn.instance()
	get_parent().add_child(fm)
	fm.set_main_value(main_value)
	if new_mode:
		fm.set_new_file_mode(true)
	if typeof(just_these) == TYPE_ARRAY:
		fm.set_files(just_these)
	fm.connect("file_selected", self, "on_item_selected")
	fm.connect("menu_closed", self, "activate_menu")
	connect("menu_closed", fm, "close")
	deactivate_menu()
	

func add_text_popup(text, item_value, item_extra, error : bool):
	var popup = text_popup_scn.instance()
	get_parent().add_child(popup)
	popup.show_text(text, item_value, item_extra, error)
	popup.connect("selected", self, "on_item_selected")
	popup.connect("dismissed", self, "activate_menu")
	connect("menu_closed", popup, "close")
	deactivate_menu()

func mouse_deactivate() -> void:
	for item in $MenuContainer.get_children():
		item.mouse_filter = MOUSE_FILTER_IGNORE
func mouse_activate() -> void:
	for item in $MenuContainer.get_children():
		item.mouse_filter = MOUSE_FILTER_STOP

func activate_menu() -> void:
	if not menu_open:
		return
	menu_active = true
	mouse_activate()
func deactivate_menu() -> void:
	menu_active = false
	mouse_deactivate()

func hide_menu():
	visible = false


func clear_options() -> void:
	for item in $MenuContainer.get_children():
		item.queue_free()
	menu_item_count = 0

func add_menu_item(val : String, text : String) -> Node:
	var item = menu_item_scn.instance()
	item.set_label(text)
	item.set_value(val)
	$MenuContainer.add_child(item)
	menu_item_count += 1
	item.connect("selected", self, "on_item_selected")
	item.connect("mouse_entered_item", self, "on_mouseover_item")
	return item

func add_menu_option(val : String, text : String, starting_extra) -> Node:
	var item = menu_option_scn.instance()
	item.set_label(text)
	item.set_value(val)
	item.set_extra(starting_extra)
	$MenuContainer.add_child(item)
	menu_item_count += 1
	item.connect("selected", self, "on_item_selected")
	item.connect("mouse_entered_item", self, "on_mouseover_item")
	return item

func add_menu_slider(val : String, text : String, min_e : float, max_e : float, starting_extra : float) -> Node:
	var item = menu_slider_scn.instance()
	item.set_label(text)
	item.set_value(val)
	item.set_range(min_e, max_e)
	item.set_extra(starting_extra)
	$MenuContainer.add_child(item)
	menu_item_count += 1
	item.connect("selected", self, "on_item_selected")
	item.connect("mouse_entered_item", self, "on_mouseover_item")
	return item

func on_item_selected(item, extra):
	if not has_script:
		emit_signal("item_selected", item, extra)
		close_menu()
	else:
		var close : bool = $MenuScript.handle_item_selected(item, extra)
		if close:
			call_deferred('close_menu')

func on_mouseover_item(m_item):
	for item in $MenuContainer.get_children():
		if item == m_item:
			item.set_active()
		else:
			item.set_inactive()

func find_active_item() -> Control:
	if $MenuContainer.get_child_count() < 1:
		return null
	for child in $MenuContainer.get_children():
		var item : = child as Control
		if item.is_active():
			return item
	var first_item : = $MenuContainer.get_child(0) as Control
	return first_item

func set_all_inactive() -> void:
	for item in $MenuContainer.get_children():
		item.set_inactive()

func set_item_active(index : int) -> void:
	set_all_inactive()
	$MenuContainer.get_child(index).set_active()

# warning-ignore:unused_argument
func _process(delta):
	if not menu_active:
		return
	
	if Input.is_action_just_pressed("menu_back"):
		close_menu()
		return
	
	if menu_item_count > 0:
		var active_index : int = find_active_item().get_index()
		if active_index >= menu_item_count:
			return
		
		if Input.is_action_just_pressed("menu_select"):
			$MenuContainer.get_child(active_index).select()
		elif Input.is_action_just_pressed("move_down"):
			active_index += 1
			if active_index >= menu_item_count:
				active_index = 0
			set_item_active(active_index)
		elif Input.is_action_just_pressed("move_up"):
			active_index -= 1
			if active_index < 0:
				active_index = menu_item_count - 1
			set_item_active(active_index)
