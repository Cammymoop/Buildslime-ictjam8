extends Node

var world_map : WorldMap  = null

var unloaded_maps = {}

func load_home() -> void:
	load_map("HomeMap")

func load_test_map() -> void:
	load_map("TestMap")

func load_map(target_map_name : String, spawn_entities : bool = true) -> void:
	if not ResourceLoader.exists("res://assets/maps/" + target_map_name + '.tscn'):
		print('Could not find map scene: ' + target_map_name)
		return
	
	var map_instance = load("res://assets/maps/" + target_map_name + ".tscn").instance()
	if map_instance.id != target_map_name:
		print('map name id mismatch. name: ' + target_map_name + ' id: ' + map_instance.id)
	_load_map(map_instance)
	
	if spawn_entities:
		spawn_entities()
	
	if unloaded_maps.has(world_map.id):
		var save = unloaded_maps[world_map.id]
		world_map.restore_save(save, save['save_version'])
	
	world_map.fix_all_big_tiles()
	world_map.update_bitmask_region()
	
	var player = get_player()
	if player:
		player.set_camera_bounds(world_map.get_camera_bounds())
	get_node("/root/GlobalData").current_map = target_map_name

func spawn_entities() -> void:
	var entities = world_map.get_entities()
	
	for ent in entities:
		ent.spawn(world_map)

func load_job(job_num : int) -> void:
	var player = get_player()
	if not player:
		return
	
	if player.is_holding_stuff():
		var text = "You can't go to the job\nholding all that stuff!"
		get_node("/root/UI").get_pause_screen().call_deferred('show_quick_text', text, true)
		return
	
	get_node("/root/GlobalData").current_job_num = job_num
	var job_manager = get_node("/root/JobManager")
	var job = job_manager.get_job(job_num)
	
	get_node("/root/UI").set_popup_goal(job.get_job_goal())
	load_map("JobMap")
	
	get_node("/root/MapGenerator").generate(world_map, job.get_spawn_params())
	
	world_map.update_bitmask_region()
	
	player.set_my_position(4, 4)

func _load_map(new_world_map : TileMap) -> void:
	if world_map:
		unload_map()
	world_map = new_world_map
	if not world_map.is_inside_tree():
		get_node("/root/Root").add_child(world_map)
		#print('adding ' + world_map.name + ' to the tree')
	
	world_map.visible = true

func leave_job(success : bool) -> void:
	var player = get_player()
	if not player:
		print('error no player')
		return
	
	load_map("HomeMap")
	player.set_my_position(9, 0)
	
	if success:
		get_node("/root/GlobalData").complete_current_job()
		place_job_rewards()
	else:
		player.clear_inventory()

func place_job_rewards() -> void:
	var names = get_node("/root/Combinator").names
	var job_num = get_node("/root/GlobalData").current_job_num
	var job = get_node("/root/JobManager").get_job(job_num)
	var rewards = job.get_rewards()
	
	var text = "Here's you rewards for a job well done:\n"
	
	for reward in rewards:
		text += ":tile." + str(names[reward]) + ":"
		var safety = 1000
		while safety >= 0:
			var rx = randi() % 19
			var ry = randi() % 19
			if rx == 4 and ry == 4:
				safety -= 1
				continue
			var existing = world_map.get_cell(rx, ry)
			if existing > 0:
				safety -= 1
				continue
			world_map.set_cell(rx, ry, names[reward])
			break
		if safety < 0:
			print ('couldnt find a spot to spawn reward: ' + reward)
	
	get_node("/root/UI").get_pause_screen().call_deferred('show_quick_text', text)
	world_map.auto_tile_whole_map()

func is_job_completed() -> bool:
	var global = get_node("/root/GlobalData")
	if not global.is_at_job():
		return false
	return get_node("/root/JobManager").check_job_completion(global.current_job_num, world_map)

func get_player() -> Node:
	var p = get_tree().get_nodes_in_group("player")
	if len(p) < 1:
		return null
	return p[0]

func clear_map() -> void:
	world_map = null

func unload_map() -> void:
	if world_map.is_persistent:
		var serialized = world_map.serialize_for_save()
		unloaded_maps[world_map.id] = serialized
	world_map.queue_free()

func serialize_for_save() -> Dictionary:
	var cur_map_serialized = world_map.serialize_for_save()
	var serialized = {
		"name": get_name(),
		"node_path": str(get_path()),
		"mode": 'restore',
		
		"unloaded_maps": unloaded_maps,
		"cur_world_map": cur_map_serialized,
	}
	return serialized

func restore_save(serialized, save_version) -> String:
	unloaded_maps = {}
	
	var cur_map = serialized['cur_world_map']
	if save_version < 4:
		cur_map['id'] = cur_map['name']
	load_map(cur_map['id'])
	
	world_map.restore_save(cur_map, cur_map['save_version'])
	
	unloaded_maps = serialized['unloaded_maps']
	
	return "world_post_load"

func world_post_load() -> void:
	spawn_entities()
