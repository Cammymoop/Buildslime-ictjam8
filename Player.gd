extends "res://Entity.gd"

export var enable_debug = true

var hold_1 : int = 0
var hold_2 : int = 0
var hold_3 : int = 0
var hold_count : int = 0

# rotate/flip by holding down grab
var holding_button : bool = false

var holding_move = false
var hold_move_ready = false

var debug_mode = false

var modification_queue = []

var in_tent = false

func _ready():
	randomize()
	
	#print("spawned at " + str(tile_position))
	get_node("/root/GlobalData").new_game()
	
	if OS.has_feature('debug') and enable_debug:
		debug_mode = true
		get_node("/root/GlobalData").max_job_completed = get_node("/root/JobManager").num_jobs()
	
	call_deferred("post_ready")

func post_ready() -> void:
	.post_ready()
	if debug_mode:
		NON_GRABBABLE = []

func spawn(new_tilemap, new_tile_position = false) -> void:
	.spawn(new_tilemap, new_tile_position)
	clear_modifications()

func focus_camera() -> void:
	$Camera2D.reset_smoothing()

func rotate_a_thing(tile_coord, counterclockwise = false) -> void:
	var ind = get_map_cellv(tile_coord)
	if not ind:
		return
	if not get_node("/root/Combinator").can_rotate(ind):
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
	var h_flip = r_current_map.is_cell_x_flipped(tile_coord.x, tile_coord.y)
	var v_flip = r_current_map.is_cell_y_flipped(tile_coord.x, tile_coord.y)
	var transposed = r_current_map.is_cell_transposed(tile_coord.x, tile_coord.y)
	
	if transposed:
		v_flip = not v_flip
	else:
		h_flip = not h_flip
	r_current_map.set_cellv(tile_coord, ind, h_flip, v_flip, transposed)

func smack() -> void:
	var facing_t = get_facing_tile_coord()
	var facing_t_2 = get_facing_tile_coord(2)
	if not r_current_map.coord_is_in_bounds(facing_t) or not r_current_map.coord_is_in_bounds(facing_t_2):
		return
	
	var first = get_map_cellv(facing_t)
	if first < 0:
		first = 0
	var second = get_map_cellv(facing_t_2)
	if second < 0:
		second = 0
	
	var r_combinator = get_node("/root/Combinator")
	var result = r_combinator.get_combinator_result(first, second)
	if not result:
		return
	
	if typeof(result[0]) == TYPE_STRING and result[0] == "special":
		handle_special_smack(first, second, result)
		return
	
	if not r_current_map.is_map_modifiable():
		cant_build_here()
		return
	
	$SmackSound.play()
	set_map_cellv(facing_t, result[0])
	set_map_cellv(facing_t_2, result[1])
	
	# add old tiles to the undo queue
	add_modification(facing_t, first, facing_t_2, second)

func handle_special_smack(first_t : int, second_t : int, special : Array):
	var r_combinator = get_node("/root/Combinator")
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
			
			var pause_screen = get_node("/root/UI").get_pause_screen()
			pause_screen.show_quick_text(text)

func is_holding_stuff() -> bool:
	return hold_count > 0

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
	stop_being_invisible()
	
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
	
	._process(delta)
	
	if holding_button and not Input.is_action_pressed("action_grab"):
		holding_button = false
	
	#movement and flip/rotate
	var move_h = false
	var move_v = false
	if not in_tent:
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
	else:
		if Input.is_action_just_pressed("move_down"):
			move_v = "down"
	
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
			stop_holding_move()
		elif hold_move_ready:
			move_h = hold_dir_h
			move_v = hold_dir_v
			hold_move_ready = false
	elif move_h or move_v:
		holding_move = true
		$InitialMoveTimer.start()
	
	if move_h or move_v:
		if in_tent:
			get_out_of_tent()
			make_sleep_tent(tile_position)
		var new_facing = move_tile(move_h, move_v)
		if not Input.is_action_pressed("hold_strafe"):
			change_facing(new_facing)
		
		var cur_map = get_node("/root/GlobalData").current_map
		if cur_map == 'HomeMap' and tile_position.y < -1:
			get_node("/root/WorldControl").load_map("Village")
			set_my_position(tile_position.x, 39)
		if cur_map == 'Village' and tile_position.y > 42:
			get_node("/root/WorldControl").load_map("HomeMap")
			set_my_position(9, 0)
	else:
		if Input.is_action_just_pressed("action_grab"):
			holding_button = true
			if not r_current_map.is_map_modifiable():
				cant_build_here()
			else:
				var facing_t = get_facing_tile_coord()
				if r_current_map.coord_is_in_bounds(facing_t):
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

func stop_holding_move() -> void:
	holding_move = false
	hold_move_ready = false
	$InitialMoveTimer.stop()
	$MoveTimer.stop()

func cant_build_here() -> void:
	var pause_screen = get_node("/root/UI").get_pause_screen()
	pause_screen.show_quick_text("Hey you can't build here!", true)

#returns facing direction
func move_tile(direction_h, direction_v = false) -> String:
	if (typeof(direction_h) == TYPE_STRING and direction_h == 'up') or (typeof(direction_v) == TYPE_STRING and direction_v == 'up'):
		var deltas = get_move_deltas(direction_h, direction_v)
		var dest_tile = get_map_cellv(tile_position + deltas)
		if dest_tile == names['tent']:
			go_in_tent()
			make_tent_sleep(tile_position + deltas)
			_force_move(deltas.x, deltas.y)
			return 'down'
	return .move_tile(direction_h, direction_v)

func clear_inventory() -> void:
	hold_1 = 0
	hold_2 = 0
	hold_3 = 0
	hold_count = 0
	$EntitySprite.set_showing_frame(0, 0)

func become_invisible() -> void:
	$EntitySprite.set_visible(false)
func stop_being_invisible() -> void:
	$EntitySprite.set_visible(true)

func go_in_tent() -> void:
	in_tent = true
	change_facing('down')
	stop_holding_move()
	become_invisible()
func get_out_of_tent() -> void:
	in_tent = false
	stop_being_invisible()

func make_tent_sleep(coord : Vector2) -> bool:
	return r_current_map.transform_object_from_to(coord, 'tent', 'sleep_in_tent')
func make_sleep_tent(coord: Vector2) -> bool:
	return r_current_map.transform_object_from_to(coord, 'sleep_in_tent', 'tent')

func serialize_for_save() -> Dictionary:
	var serialized = {
		"name": get_name(),
		"node_path": str(get_path()),
		"mode": 'restore',
		
		"tile_pos_x": tile_position.x,
		"tile_pos_y": tile_position.y,
		"pos_x": position.x,
		"pos_y": position.y,
		"facing": facing,
		
		"hold_count": hold_count,
		"hold_1": hold_1,
		"hold_2": hold_2,
		"hold_3": hold_3,
		
		"in_tent": in_tent,
	}
	return serialized

func restore_save(serialized, save_version) -> void:
	clear_modifications()
	stop_being_invisible()
	if save_version < 3:
		get_node("/root/GlobalData").max_job_completed = serialized['jobs_finished']
	
	clear_inventory()
	restore_inv([serialized['hold_1'], serialized['hold_2'], serialized['hold_3']])
	
	change_facing(serialized['facing'])
	set_my_position(serialized['tile_pos_x'], serialized['tile_pos_y'])
	
	if save_version > 3 and serialized['in_tent']:
		go_in_tent()
	else:
		get_out_of_tent()

func set_camera_bounds(bounds : Rect2) -> void:
	$Camera2D.set_world_cam_bounds(bounds)

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

func _on_Blinker_timeout():
	$EntitySprite.blink()
	$Blinker.wait_time = rand_range(10.8, 50)
	$Blinker.start()
