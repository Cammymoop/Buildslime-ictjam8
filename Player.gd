extends Node2D

export var enable_debug = true

var tile_position = Vector2(0, 0)
var target_position = Vector2(0, 0)
var facing_angle = 0
var facing = "down"

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

var UP_ANGLE = PI
var DOWN_ANGLE = 0
var LEFT_ANGLE = PI/2
var RIGHT_ANGLE = PI + PI/2

var holding_move = false
var hold_move_ready = false

var MAX_TILE = 40

var TILE = 16

var NON_WALKABLE = [
	'tree', 'wood_wall', 'metal_wall', 'sheep', 'sheered', 'fence', 'tent', 'bed', 'fire', 'anvil', 'bucket_of_rocks',
	'bucket', 'water_bucket', 'puddle', 'pillar', 'birdhouse',
]
var NON_GRABABLE = ['tree', 'gravel', 'metal_wall', 'puddle']
var AUTOTILES : Array = ['puddle', 'wood_wall']

var modification_queue = []

var job_rewards : Array = []

var current_job_num = 0

var make_mp = false

var names
var inv_names

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
	tile_position.x = round(position.x/TILE)
	tile_position.y = round(position.y/TILE)
	target_position = position
	
	#print("spawned at " + str(tile_position))
	
	r_tile_map = get_parent().get_node("HomeMap")
	r_combinator = get_parent().get_node("Combinator")
	
	r_job_manager = get_node("/root/JobManager")
	
	get_node("/root/GlobalData").new_game()
	
	if OS.has_feature('debug') and enable_debug:
		get_node("/root/GlobalData").max_job_completed = r_job_manager.num_jobs()
		NON_GRABABLE = []
	
	#get_parent().find_node("MenuControls").set_next_available_job(min(jobs_finished + 1, r_job_manager.num_jobs()))
	
	call_deferred("post_ready")

func set_my_position(xpos : int, ypos : int) -> void:
	tile_position.x = xpos
	tile_position.y = ypos
	position.x = tile_position.x * TILE
	position.y = tile_position.y * TILE
	target_position = position

func regen_map() -> void:
	if r_tile_map.name == "HomeMap":
		print('dont overwrite home!!!')
		return
	get_parent().get_node("MapGenerator").generate(r_tile_map, spawn_params)
	auto_tile_whole_map()

func set_map_cellv(coord : Vector2, index : int) -> void:
	set_map_cell(int(coord.x), int(coord.y), index)

func set_map_cell(x : int, y : int, index : int) -> void:
	var old = r_tile_map.get_cell(x, y)
	r_tile_map.set_cell(x, y, index)
	if AUTOTILES.has(index) or AUTOTILES.has(old):
		r_tile_map.update_bitmask_area(Vector2(x, y))

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
	#get_parent().find_node("MenuControls").call_deferred('set_job_options')
	get_parent().find_node("ColorRectJob").visible = true
func change_to_home_map() -> void:
	clear_modifications()
	at_home = true
	get_node("/root/GlobalData").set_to_map_home()
	r_tile_map.visible = false
	r_tile_map = get_parent().get_node("HomeMap")
	r_tile_map.visible = true
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

func post_ready() -> void:
	names = r_combinator.names
	inv_names = r_combinator.inv_names
	
	var temp = []
	for name_t in NON_WALKABLE:
		temp.append(names[name_t])
	NON_WALKABLE = temp
	
	temp = []
	for name_t in NON_GRABABLE:
		temp.append(names[name_t])
	NON_GRABABLE = temp
	
	temp = []
	for name_t in AUTOTILES:
		temp.append(names[name_t])
	AUTOTILES = temp
	
	#test_mapgen()
	r_tile_map.set_cellv(tile_position, 0)

func change_facing(direction_h, direction_v = false) -> void:
	var y_tex_offset = 0
	var direction = direction_h
	match direction_h:
		'up':
			facing_angle = UP_ANGLE
			y_tex_offset = 16
		'down':
			facing_angle = DOWN_ANGLE
			y_tex_offset = 0
		'left':
			facing_angle = LEFT_ANGLE
			y_tex_offset = 48
		'right':
			facing_angle = RIGHT_ANGLE
			y_tex_offset = 32
		_:
			direction = direction_v
			match direction_v:
				'up':
					facing_angle = UP_ANGLE
					y_tex_offset = 16
				'down':
					facing_angle = DOWN_ANGLE
					y_tex_offset = 0
				_:
					print('not a vertical direction: ' + direction_v)
					return
	facing = direction
	#$PlayerSprite.rotation = facing_angle
	$PlayerSprite.region_rect.position.y = y_tex_offset

func rotate_a_thing(tile_coord, counterclockwise = false) -> void:
	var ind = r_tile_map.get_cellv(tile_coord)
	if not ind:
		return
	var h_flip = r_tile_map.is_cell_x_flipped(tile_coord.x, tile_coord.y)
	var v_flip = r_tile_map.is_cell_y_flipped(tile_coord.x, tile_coord.y)
	var transposed = r_tile_map.is_cell_transposed(tile_coord.x, tile_coord.y)
	
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
	r_tile_map.set_cellv(tile_coord, ind, h_flip, v_flip, transposed)

func flip_a_thing(tile_coord) -> void:
	var ind = r_tile_map.get_cellv(tile_coord)
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

func _get_facing_xdelta() -> int:
	if facing == 'up' or facing == 'down':
		return 0
	return 1 if facing == 'right' else -1
func _get_facing_ydelta() -> int:
	if facing == 'left' or facing == 'right':
		return 0
	return 1 if facing == 'down' else -1

func get_facing_tile_coord(amount : int = 1) -> Vector2:
	var facing_c = Vector2(tile_position.x, tile_position.y)
	facing_c.x += _get_facing_xdelta() * amount
	facing_c.y += _get_facing_ydelta() * amount
	return facing_c

#returns facing direction
func move_tile(direction_h, direction_v = false) -> String:
	var xd = 0
	var yd = 0
	match direction_h:
		'up':
			yd = -1
		'down':
			yd = 1
		'left':
			xd = -1
		'right':
			xd = 1
		false:
			pass
		_:
			print('not a h direction: ' + direction_h)
			return 'up'
	match direction_v:
		'up':
			yd = -1
		'down':
			yd = 1
		false:
			pass
		_:
			print('not a vertical direction: ' + direction_v)
			return 'up'
	return _move(xd, yd)

func tile_blocks_move(tile):
	return NON_WALKABLE.find(tile) != -1

func delta_to_direction(xdelta, ydelta):
	var direction = ''
	match xdelta:
		1:
			direction = 'right'
		-1:
			direction = 'left'
		0:
			match ydelta:
				1:
					direction = 'down'
				-1:
					direction = 'up'
	return direction

func _move(xdelta, ydelta) -> String:
	var facing_dir = delta_to_direction(xdelta, ydelta)
	if tile_position.x + xdelta > MAX_TILE or tile_position.x + xdelta < 0:
		xdelta = 0
	if tile_position.y + ydelta > MAX_TILE or tile_position.y + ydelta < 0:
		ydelta = 0
	
	if xdelta == 0 and ydelta == 0: # hit map edge, no diagonal
		return facing_dir
	
	facing_dir = delta_to_direction(xdelta, ydelta) #update facing if diagonally along map edge
	
	tile_position.x += xdelta
	tile_position.y += ydelta
	
	#can I step here?
	if xdelta != 0 and ydelta != 0:
		var object_dest = r_tile_map.get_cellv(tile_position)
		var object_vert = r_tile_map.get_cell(tile_position.x - xdelta, tile_position.y)
		var object_horiz = r_tile_map.get_cell(tile_position.x, tile_position.y - ydelta)
		if tile_blocks_move(object_horiz) and tile_blocks_move(object_vert):
			tile_position.x -= xdelta
			tile_position.y -= ydelta
			return facing_dir
		if tile_blocks_move(object_dest):
			if tile_blocks_move(object_vert):
				facing_dir = delta_to_direction(xdelta, 0)
				tile_position.y -= ydelta
			else: # move horizontally by default
				facing_dir = delta_to_direction(0, ydelta)
				tile_position.x -= xdelta
	else:
		var object_here = r_tile_map.get_cellv(tile_position)
		if NON_WALKABLE.find(object_here) != -1:
			tile_position.x -= xdelta
			tile_position.y -= ydelta
			return facing_dir
	
	target_position.x = tile_position.x * TILE
	target_position.y = tile_position.y * TILE
	#position.x += xdelta * TILE
	#position.y += ydelta * TILE
	return facing_dir

func smack() -> void:
	var facing_t = get_facing_tile_coord()
	var facing_t_2 = get_facing_tile_coord(2)
	
	var first = r_tile_map.get_cellv(facing_t)
	if first < 0:
		first = 0
	var second = r_tile_map.get_cellv(facing_t_2)
	if second < 0:
		second = 0
	
	var result = r_combinator.get_combinator_result(first, second)
	if not result:
		return
	
	if typeof(result[0]) == TYPE_STRING and result[0] == "special":
		handle_special_smack(first, second, result)
	
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

# check if you're holding too many first
func pick_up(index) -> void:
	hold_3 = hold_2
	hold_2 = hold_1
	hold_1 = index
	hold_count += 1
	$PlayerSprite.region_rect.position.x += 16
	$PickupSound.play()

#check if you're holding something first
func drop() -> int:
	var drop_me = hold_1
	hold_1 = hold_2
	hold_2 = hold_3
	hold_3 = 0
	hold_count -= 1
	$PlayerSprite.region_rect.position.x -= 16
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
	$PlayerSprite.region_rect.position.x = (count*16)
	

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

# warning-ignore:unused_argument
func _process(delta) -> void:
	if make_mp:
		make_mp = false
		print('showing mp')
		show_map_popup()
		return
	
	position.x = lerp(position.x, target_position.x, 0.4)
	position.y = lerp(position.y, target_position.y, 0.4)
	
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
		var tile = r_tile_map.get_cellv(get_facing_tile_coord())
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
			var ind = r_tile_map.get_cellv(facing_t)
			if ind > 0:
				if NON_GRABABLE.find(ind) == -1 and hold_count < 3:
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
		elif Input.is_action_just_pressed("action_d_regen"):
			regen_map()
		elif Input.is_action_just_pressed("action_rewind"):
			pop_modification()
		elif Input.is_action_just_pressed("action_quick_job_view"):
			if not at_home:
				show_map_popup(true)

func evaluate_job() -> void:
	var JOB_WIDTH = 19
	
	var first_x = -1
	var first_y = -1
	var first_tile = false
	var last_x = -1
	var last_y = -1
	
	var r_job_map : TileMap = get_parent().find_node("MapPopup").find_node("JobGoal", true, false)
	if not r_job_map:
		print("no job to check")
		get_parent().find_node("MapPopup").print_tree_pretty()
		return
	
	var max_j = -1
	
	for ty in range(JOB_WIDTH):
		for tx in range(JOB_WIDTH):
			var this_tile = r_job_map.get_cell(tx, ty)
			if this_tile > 0:
				if first_x < 0:
					first_x = tx
					first_y = ty
					first_tile = this_tile
				last_x = tx
				last_y = ty
				max_j = max(max_j, tx)
	
	var width = max_j - first_x + 1
	
	var verified = false
	
	
	var search_origin_x = -1
	var search_origin_y = -1
	var searching = false
	var return_coord = false
	
	var tx = 0
	var ty = 0
	
	var safety = 200000
	
	while ty <= MAX_TILE:
		if verified:
			break
		tx = 0
		while tx <= MAX_TILE:
			safety -= 1
			if safety < 0:
				return
			var this_tile = r_tile_map.get_cell(tx, ty)
			if searching:
				var x_offset = tx + (first_x - search_origin_x)
				var y_offset = ty + (first_y - search_origin_y)
				var that_tile = r_job_map.get_cell(x_offset, y_offset)
				if that_tile < 1 or that_tile == this_tile:
					if x_offset == last_x and y_offset == last_y:
						verified = true
						break
					
					if that_tile < 1 and this_tile == first_tile and not return_coord:
						return_coord = Vector2(tx, ty)
				else:
					searching = false
					if return_coord:
						ty = return_coord.y
						tx = return_coord.x - 1
						continue
			if not searching and this_tile == first_tile and not (tx + width > MAX_TILE):
				search_origin_x = tx
				search_origin_y = ty
				if first_x == last_x and first_y == last_y: # job is only 1 tile
					verified = true
					break
				searching = true
			tx += 1
		ty += 1
	
#	if verified:
#		call_deferred("verified_menu")

#func verified_menu() -> void:
#	get_parent().find_node("MenuControls").job_validated()

func clear_inventory() -> void:
	hold_1 = 0
	hold_2 = 0
	hold_3 = 0
	hold_count = 0
	$PlayerSprite.region_rect.position.x = 0

func menu_selection(value : String, extra) -> void:
	match value:
		"return":
			pass
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
		"eval-job":
			evaluate_job()
		"restart-game":
			if extra == 1:
				get_tree().reload_current_scene()
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
