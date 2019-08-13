extends "res://Entity.gd"

export var enable_debug = true

var r_tile_map : TileMap = null
var r_combinator = null
var r_job_manager = null

var hold_1 : int = 0
var hold_2 : int = 0
var hold_3 : int = 0
var hold_count : int = 0

# rotate/flip by holding down grab
var holding_button : bool = false

var at_home = true

var holding_move = false
var hold_move_ready = false

var debug_mode = false

var modification_queue = []

var job_rewards : Array = []

var current_job_num = 0

var make_mp = false

var spawn_params : Dictionary = {
	'spawns': [
		{'object': 'tree', 'frequency': 16},
		{'object': 'sheep', 'frequency': 4, 'mirrorable': true},
		{'object': 'rock', 'frequency': 8},
		{'object': 'grass', 'frequency': 18, 'mirrorable': true},
		{'object': 'stick', 'frequency': 6, 'mirrorable': true},
		{'object': 'puddle', 'frequency': 3, 'mirrorable': true},
		{'object': 'seed', 'frequency': 1, 'mirrorable': true},
	],
	'has_forest': false,
	'map_width': 40
}

func _ready():
	randomize()
	var tmap = find_parent("Root").find_node("HomeMap")
	spawn(tmap)
	
	#print("spawned at " + str(tile_position))
	
	r_tile_map = get_parent().get_node("HomeMap")
	r_combinator = get_parent().get_node("Combinator")
	
	r_job_manager = get_node("/root/JobManager")
	
	get_node("/root/GlobalData").new_game()
	
	if OS.has_feature('debug') and enable_debug:
		debug_mode = true
		get_node("/root/GlobalData").max_job_completed = r_job_manager.num_jobs()
	
	#get_parent().find_node("MenuControls").set_next_available_job(min(jobs_finished + 1, r_job_manager.num_jobs()))
	
	call_deferred("post_ready")

func post_ready() -> void:
	.post_ready()
	if debug_mode:
		NON_GRABBABLE = []

func regen_map() -> void:
	if r_tile_map.name == "HomeMap":
		print('dont overwrite home!!!')
		return
	get_parent().get_node("MapGenerator").generate(r_tile_map, spawn_params)
	auto_tile_whole_map()

func auto_tile_whole_map() -> void:
	r_tile_map.update_bitmask_region(Vector2(-1, -1), Vector2(41, 41))

func get_a_job(job_num : int) -> void:
	current_job_num = job_num
	var job = r_job_manager.get_job(job_num)
	change_to_job_map()
	set_my_position(4, 4)
	set_spawn_params(job.get_spawn_params())
	regen_map()
	load_job_popup(job_num)
	load_job_rewards(job_num)
	#show_map_popup()
	make_map_popup()

func load_job_rewards(job_num : int) -> void:
	var job = r_job_manager.get_job(job_num)
	job_rewards = job.get_rewards()

func load_job_popup(job_num : int):
	var job = r_job_manager.get_job(job_num)
	clear_popup()
	var popup = find_parent("Root").find_node("MapPopup")
	var goal = job.get_node("JobGoal")
	job.remove_child(goal)
	popup.add_child(goal)
	goal.visible = true

func place_rewards() -> void:
	var home_map = get_parent().find_node("HomeMap")
	for reward in job_rewards:
		var safety = 1000
		while safety >= 0:
			var rx = randi() % 19
			var ry = randi() % 19
			if rx == 4 and ry == 4:
				safety -= 1
				continue
			var existing = home_map.get_cell(rx, ry)
			if existing > 0:
				safety -= 1
				continue
			home_map.set_cell(rx, ry, names[reward])
			break
		if safety < 0:
			print ('couldnt find a spot to spawn reward: ' + reward)
	home_map.update_bitmask_region()

func job_complete() -> void:
	var global = get_node("/root/GlobalData")
	global.max_job_completed = max(global.max_job_completed, current_job_num)

func make_map_popup() -> void:
	make_mp = true

func show_map_popup(quick_mode : bool = false) -> void:
	r_tile_map.visible = false
	visible = false
	if quick_mode:
		get_parent().find_node("MapPopup").show_quick()
	else:
		get_parent().find_node("MapPopup").show()

func hide_map_popup() -> void:
	r_tile_map.visible = true
	visible = true

func change_to_job_map() -> void:
	clear_modifications()
	at_home = false
	get_node("/root/GlobalData").set_to_map_job(current_job_num)
	r_tile_map.visible = false
	r_tile_map = get_parent().get_node("JobMap")
	r_tile_map.visible = true
	spawn(r_tile_map)
	#get_parent().find_node("MenuControls").call_deferred('set_job_options')
	get_parent().find_node("ColorRectJob").visible = true
func change_to_home_map() -> void:
	clear_modifications()
	at_home = true
	get_node("/root/GlobalData").set_to_map_home()
	r_tile_map.visible = false
	r_tile_map = get_parent().get_node("HomeMap")
	r_tile_map.visible = true
	spawn(r_tile_map)
	#get_parent().find_node("MenuControls").set_next_available_job(min(jobs_finished + 1, r_job_manager.num_jobs()))
	#get_parent().find_node("MenuControls").call_deferred('set_home_options')
	get_parent().find_node("ColorRectJob").visible = false
	call_deferred('clear_popup')

func clear_popup():
	var popup = get_parent().find_node("MapPopup")
	for child in popup.get_children():
		child.queue_free()

func set_spawn_params(new_params : Dictionary, name_to_id : bool = true) -> void:
	spawn_params = new_params
	#print(spawn_params)
	if name_to_id:
		for sp in spawn_params['spawns']:
			sp['object'] = names[sp['object']]

func rotate_a_thing(tile_coord, counterclockwise = false) -> void:
	var ind = get_map_cellv(tile_coord)
	if not ind:
		return
	var h_flip = r_current_map.is_cell_x_flipped(tile_coord.x, tile_coord.y)
	var v_flip = r_current_map.is_cell_y_flipped(tile_coord.x, tile_coord.y)
	var transposed = r_current_map.is_cell_transposed(tile_coord.x, tile_coord.y)
	
	var determine = 0
	determine += 1 if h_flip else 0
	determine += 1 if v_flip else 0
	determine += 1 if counterclockwise else 0
	determine = determine % 2
	
	transposed = not transposed
	if determine == 0:
		h_flip = not h_flip
	else:
		v_flip = not v_flip
	r_current_map.set_cellv(tile_coord, ind, h_flip, v_flip, transposed)

func flip_a_thing(tile_coord) -> void:
	var ind = get_map_cellv(tile_coord)
	if not ind:
		return
	var h_flip = r_tile_map.is_cell_x_flipped(tile_coord.x, tile_coord.y)
	var v_flip = r_tile_map.is_cell_y_flipped(tile_coord.x, tile_coord.y)
	var transposed = r_tile_map.is_cell_transposed(tile_coord.x, tile_coord.y)
	
	if transposed:
		v_flip = not v_flip
	else:
		h_flip = not h_flip
	r_tile_map.set_cellv(tile_coord, ind, h_flip, v_flip, transposed)

func smack() -> void:
	var facing_t = get_facing_tile_coord()
	var facing_t_2 = get_facing_tile_coord(2)
	
	var first = get_map_cellv(facing_t)
	if first < 0:
		first = 0
	var second = get_map_cellv(facing_t_2)
	if second < 0:
		second = 0
	
	var result = r_combinator.get_combinator_result(first, second)
	if not result:
		return
	
	if typeof(result[0]) == TYPE_STRING and result[0] == "special":
		handle_special_smack(first, second, result)
		return
	
	$SmackSound.play()
	set_map_cellv(facing_t, result[0])
	set_map_cellv(facing_t_2, result[1])
	
	# add old tiles to the undo queue
	add_modification(facing_t, first, facing_t_2, second)

func handle_special_smack(first_t : int, second_t : int, special : Array):
	match special[1]:
		'craft_help':
			# lookup all recipe results for the object that isnt the crafting manual
			var lookup_tile = second_t if inv_names[first_t] == 'crafting_manual' else first_t
			var possible_results = r_combinator.get_all_results_for(lookup_tile)
			var text = ''
			if len(possible_results) > 0:
				text = 'With :tile.' + str(lookup_tile) + ': I can make these:\n'
				
				var n = 0
				var per_line = 6
				for res in possible_results:
					if n > 0 and n % per_line == 0:
						text += '\n'
					text += ':tile.' + str(res) + ':'
					n += 1
			else:
				text = 'I can\'t seem to make anything with :tile.' + str(lookup_tile) + ':.'
			
			var pause_screen = find_parent('Root').find_node('PauseScreen')
			pause_screen.show_quick_text(text)

# check if you're holding too many first
func pick_up(index) -> void:
	hold_3 = hold_2
	hold_2 = hold_1
	hold_1 = index
	hold_count += 1
	$EntitySprite.set_holding_amt(hold_count)
	$PickupSound.play()

#check if you're holding something first
func drop() -> int:
	var drop_me = hold_1
	hold_1 = hold_2
	hold_2 = hold_3
	hold_3 = 0
	hold_count -= 1
	$EntitySprite.set_holding_amt(hold_count)
	$PutdownSound.play()
	return drop_me

func restore_inv(inv) -> void:
	var count = 0
	for a in inv:
		if a > 0:
			count += 1
	hold_count = count
	hold_1 = inv[0]
	hold_2 = inv[1]
	hold_3 = inv[2]
	$EntitySprite.set_holding_amt(hold_count)
	

func restore_pos_facing(pos, res_facing) -> void:
	change_facing(res_facing)
	set_my_position(pos.x, pos.y)

func restore_tile_mod(mod) -> void:
	set_map_cellv(mod['position'], mod['index'])

func pop_modification() -> void:
	if modification_queue.size() < 1:
		return
	var mod = modification_queue.pop_back()
	restore_inv(mod['inventory'])
	restore_pos_facing(mod['pos'], mod['facing'])
	
	restore_tile_mod(mod['tile1'])
	if mod['tile2']:
		restore_tile_mod(mod['tile2'])
	

func add_modification(tile_was_pos : Vector2, tile_was : int, tile_was_2_pos = false, tile_was_2 : int = -1) -> void:
	var modification = {'inventory': [hold_1, hold_2, hold_3], 'pos': tile_position, 'facing': facing}
	
	modification['tile1'] = {'index': tile_was, 'position': tile_was_pos}
	if tile_was_2 > -1:
		modification['tile2'] = {'index': tile_was_2, 'position': tile_was_2_pos}
	else:
		modification['tile2'] = false
	
	modification_queue.append(modification)

func clear_modifications() -> void:
	modification_queue = []

func set_y_stretch(amount: float) -> void:
	$EntitySprite.set_y_stretch(amount)

# warning-ignore:unused_argument
func _process(delta) -> void:
	if not active:
		return
	
	if make_mp:
		make_mp = false
		show_map_popup()
		return
	
	._process(delta)
	
	if holding_button and not Input.is_action_pressed("action_grab"):
		holding_button = false
	
	#movement and flip/rotate
	var move_h = false
	var move_v = false
	if not holding_button:
		if Input.is_action_just_pressed("move_up"):
			move_v = "up"
		elif Input.is_action_just_pressed("move_down"):
			move_v = "down"
		
		if Input.is_action_just_pressed("move_left"):
			move_h = "left"
		elif Input.is_action_just_pressed("move_right"):
			move_h = "right"
	else:
		var tile = get_map_cellv(get_facing_tile_coord())
		if not AUTOTILES.has(tile):
			if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
				flip_a_thing(get_facing_tile_coord())
			if Input.is_action_just_pressed("move_right"):
				rotate_a_thing(get_facing_tile_coord())
			if Input.is_action_just_pressed("move_left"):
				rotate_a_thing(get_facing_tile_coord(), true)
	
	if holding_move:
		var hold_dir_h = false
		var hold_dir_v = false
		if Input.is_action_pressed("move_up"):
			hold_dir_v = "up"
		elif Input.is_action_pressed("move_down"):
			hold_dir_v = "down"
		
		if Input.is_action_pressed("move_left"):
			hold_dir_h = "left"
		elif Input.is_action_pressed("move_right"):
			hold_dir_h = "right"

		if not (hold_dir_h or hold_dir_v):
			holding_move = false
			hold_move_ready = false
			$InitialMoveTimer.stop()
			$MoveTimer.stop()
		elif hold_move_ready:
			move_h = hold_dir_h
			move_v = hold_dir_v
			hold_move_ready = false
	elif move_h or move_v:
		holding_move = true
		$InitialMoveTimer.start()
	
	if move_h or move_v:
		var new_facing = move_tile(move_h, move_v)
		if not Input.is_action_pressed("hold_strafe"):
			change_facing(new_facing)
	else:
		if Input.is_action_just_pressed("action_grab"):
			holding_button = true
			var facing_t = get_facing_tile_coord()
			var ind = get_map_cellv(facing_t)
			if ind > 0:
				if NON_GRABBABLE.find(ind) == -1 and hold_count < 3:
					#print("got object " + str(ind))
					set_map_cellv(facing_t, 0)
					add_modification(facing_t, ind)
					pick_up(ind)
				else:
					print("cant pick up")
			else:
				if hold_count > 0:
					add_modification(facing_t, 0)
					ind = drop()
					#print("placed object " + str(ind))
					set_map_cellv(facing_t, ind)
		elif Input.is_action_just_pressed("action_smack"):
			smack()
		elif Input.is_action_just_pressed("action_rewind"):
			pop_modification()
		elif Input.is_action_just_pressed("action_quick_job_view"):
			if not at_home:
				show_map_popup(true)

func clear_inventory() -> void:
	hold_1 = 0
	hold_2 = 0
	hold_3 = 0
	hold_count = 0
	$EntitySprite.set_showing_frame(0, 0)

func menu_selection(value : String, extra) -> void:
	match value:
		"job":
			if not extra:
				get_a_job(get_node("/root/GlobalData").max_job_completed + 1)
			else:
				get_a_job(extra)
		"view-job":
			make_map_popup()
		"leave-job":
			if extra == 1:
				clear_inventory()
				change_to_home_map()
				set_my_position(4, 4)
		"finish-job":
			place_rewards()
			job_complete()
			change_to_home_map()
			set_my_position(4, 4)
		_:
			print("Unkown menu option: " + value)

func serialize_for_save() -> Dictionary:
	var serialized = {
		"name": get_name(),
		"mode": 'restore',
		
		"tile_pos_x": tile_position.x,
		"tile_pos_y": tile_position.y,
		"pos_x": position.x,
		"pos_y": position.y,
		"facing": facing,
		
		"at_home": at_home,
		
		"hold_count": hold_count,
		"hold_1": hold_1,
		"hold_2": hold_2,
		"hold_3": hold_3,
		
		"current_job_num": current_job_num,
	}
	return serialized

func restore_save(serialized, save_version) -> void:
	clear_modifications()
	if save_version < 3:
		get_node("/root/GlobalData").max_job_completed = serialized['jobs_finished']
	
	if serialized['at_home']:
		change_to_home_map()
		clear_popup()
	else:
		current_job_num = serialized['current_job_num']
		change_to_job_map()
		load_job_popup(current_job_num)
		load_job_rewards(current_job_num)
	
	clear_inventory()
	restore_inv([serialized['hold_1'], serialized['hold_2'], serialized['hold_3']])
	
	change_facing(serialized['facing'])
	set_my_position(serialized['tile_pos_x'], serialized['tile_pos_y'])

func _on_MoveTimer_timeout():
	if not holding_move:
		$MoveTimer.stop()
		return
	
	hold_move_ready = true


func _on_InitialMoveTimer_timeout():
	if not holding_move:
		return
	
	hold_move_ready = true
	$MoveTimer.start()
