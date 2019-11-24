extends Node

signal post_load

var CUR_SAVE_VER = 4

func _ready():
	var d :Directory = Directory.new()
	if not d.dir_exists("user://saves"):
		d.make_dir("user://saves")

func get_cur_save_version() -> int:
	return CUR_SAVE_VER

func save_game(save_filename : String, screenshot_name : String = 'none') -> void:
	if len(save_filename) < 1:
		print('no filename')
		return
	if len(save_filename) < 4 or save_filename.substr(len(save_filename) - 3, 3) != '.bs':
		save_filename = save_name_to_filename(save_filename)
	
	#delete old screenshot when overriding save
	var save_file : File = File.new()
	if save_file.file_exists("user://" + save_filename):
		var meta = get_save_meta(save_filename)
		var screenshot = meta['screenshot']
		if save_file.file_exists("user://screenshots/" + screenshot):
			Directory.new().remove("user://screenshots/" + screenshot)
	
	save_file.open("user://" + save_filename, File.WRITE)
	print('saving: ' + save_filename)
	
	save_file.store_line('buildslime_save_version ' + str(CUR_SAVE_VER))
	
	var date = OS.get_date()
	
	var date_str = str(date['year']) + '-' + str(date['month']) + '-' + str(date['day'])
	
	var global = get_node("/root/GlobalData")
	save_file.store_line('name ' + global.save_name)
	save_file.store_line(' job_progress ' + str(global.max_job_completed))
	save_file.store_line('date ' + date_str)
	save_file.store_line('screenshot ' + screenshot_name)
	
	var saveables = get_tree().get_nodes_in_group("saveable")
	
	for node in saveables:
		var serialized = node.call("serialize_for_save")
		save_file.store_line(to_json(serialized))
	save_file.close()

func save_name_to_filename(save_name : String) -> String:
	return 'saves/' + save_name + '.bs'

func load_game(save_filename : String) -> void:
	var save_file_path = "user://" + save_filename
	
	var save_file = File.new()
	if not save_file.file_exists(save_file_path):
		print('save file doesnt exist')
		return
	
	save_file.open(save_file_path, File.READ)
	
	var first_line = save_file.get_line()
	var save_version = int(first_line.split(" ", false)[1])
	if save_version > CUR_SAVE_VER:
		print('unsupported save version!')
		return
	print('loading save version ' + str(save_version))
	
	if save_version > 2:
# warning-ignore:unused_variable
		var second_line = save_file.get_line() # name
# warning-ignore:unused_variable
		var third_line = save_file.get_line() # job progress
# warning-ignore:unused_variable
		var fourth_line = save_file.get_line() # date
# warning-ignore:unused_variable
		var fifth_line = save_file.get_line() # screenshot name
	
	if save_version < 4:
		load_legacy_file_3(save_file, save_version)
	else:
		while not save_file.eof_reached():
			var line = save_file.get_line()
			if not line:
				continue
			var load_node = parse_json(line)
			
			if not load_node:
				print('json parse fail')
				continue
			
			if load_node['mode'] != 'restore':
				#only support restoring object state atm, possible need to create objects at some point
				continue
			
			var existing_node = get_node(load_node['node_path'])
			if existing_node:
				print('calling restore on: ' + existing_node.get_path())
				var post_load_callback = existing_node.call('restore_save', load_node, save_version)
				if post_load_callback:
					connect("post_load", existing_node, post_load_callback, [], CONNECT_ONESHOT)
			else:
				push_error('couldnt find ' + load_node['node_path'])
	
	emit_signal("post_load")
	
func load_legacy_file_3(save_file, save_version) -> void:
	var maps = {}
	var loaded_map = ''
	var root_node = get_node('/root/Root')
	while not save_file.eof_reached():
		var line = save_file.get_line()
		if not line:
			continue
		var load_node = parse_json(line)
		
		if not load_node:
			print('json parse fail')
			continue
		
		if load_node['mode'] != 'restore':
			#only support restoring object state atm, possible need to create objects at some point
			continue
		
		# dont try to load the maps instead well make a worldContrl later
		if load_node['name'] == 'HomeMap' or load_node['name'] == 'JobMap':
			maps[load_node['name']] = load_node
			continue
		
		if load_node['name'] == 'Player':
			loaded_map = 'HomeMap' if load_node['at_home'] else 'JobMap'
		
		var existing_node = get_node("/root/GlobalData")
		if load_node['name'] != 'GlobalData':
			existing_node = root_node.find_node(load_node['name'])
		
		if existing_node:
			print('calling restore on: ' + existing_node.get_path())
			var post_load_callback = existing_node.call('restore_save', load_node, save_version)
			if post_load_callback:
				connect("post_load", existing_node, post_load_callback, [], CONNECT_ONESHOT)
		else:
			push_error('couldnt find ' + load_node['name'])
	
	var world_control = {
		"name": get_name(),
		"node_path": str(get_path()),
		"mode": 'restore',
	}
	
	var cur_map_save = maps[loaded_map]
	cur_map_save['save_version'] = save_version
	world_control['cur_world_map'] = cur_map_save
	
	world_control['unloaded_maps'] = {}
	if loaded_map == "JobMap":
		var home_world = maps['HomeMap']
		home_world['save_version'] = save_version
		world_control['unloaded_maps'] = {'HomeMap': home_world}
	
	var post_load_callback = get_node("/root/WorldControl").restore_save(world_control, save_version)
	if post_load_callback:
		connect("post_load", get_node("/root/WorldControl"), post_load_callback, [], CONNECT_ONESHOT)
	

func _is_alpha_num(c : String) -> bool:
	if len(c) != 1:
		print('not a single char')
		return false
	var alpha_num = "1234567890abcdefghijklmnopqrstuvwxyz"
	if alpha_num.find(c) != -1 or alpha_num.find(c.to_lower()):
		return true
	return false

func get_new_save_name(base_name : String) -> String:
	var f = File.new()
	var number = 1
	
	#dont put weird characters in the filename, nobody even needs to see it really
	var allowed_symbols = "-_"
	var new_name = ''
	for i in base_name.length():
		var c = base_name[i]
		if c == ' ':
			c = '_'
		if _is_alpha_num(c) or allowed_symbols.find(c) != -1:
			new_name += c
	
	while f.file_exists("user://saves/" + new_name + str(number) + '.bs'):
		number += 1
		if number > 10000:
			return 'toomany'
	return new_name + str(number)

func get_all_saves() -> Array:
	var d : Directory = Directory.new()
	if d.open("user://saves/") != OK:
		print('couldnt open save dir')
		return []
	d.list_dir_begin(true, true)
	
	var saves = []
	var filename = d.get_next()
	
	while filename:
		if filename.substr(filename.length() -3, 3) == '.bs':
			saves.append('saves/' + filename)
		filename = d.get_next()
	
	d.list_dir_end()
	
	if d.file_exists('user://savegame.save'):
		saves.append('savegame.save')
	return saves

func get_save_meta(filename) -> Dictionary:
	var save_file_path = "user://" + filename
	
	var save_file = File.new()
	if not save_file.file_exists(save_file_path):
		print('save file doesnt exist')
		return {'success': false}
	
	save_file.open(save_file_path, File.READ)
	
	var save_meta = {'success': true}
	
	var first_line = save_file.get_line()
	var save_version = int(first_line.split(" ", false)[1])
	if save_version > CUR_SAVE_VER:
		print('unsupported save version!')
		return {'success': false}
	#print('getting meta for save version: ' + str(save_version))
	
	if save_version < 3:
		save_meta['date'] = {'year': '*', 'month': '*', 'day': '*'}
		save_meta['name'] = 'Jel'
		save_meta['job_progress'] = '*'
		save_meta['screenshot'] = 'none'
	else:
		var second_line = save_file.get_line()
		save_meta['name'] = second_line.substr(5, second_line.length() - 1)
		var third_line = save_file.get_line().split(" ", false)
		save_meta['job_progress'] = third_line[1]
		var date = save_file.get_line().split(" ", false)[1].split('-', false)
		
		save_meta['date'] = {'year': date[0], 'month': date[1], 'day': date[2]}
		
		save_meta['screenshot'] = save_file.get_line().split(" ", false)[1]
	
	# Can remove this any time, it just counts jobs finished on older saves
	if save_version < 3:
		while not save_file.eof_reached():
			var line = save_file.get_line()
			if not line:
				continue
				
			var data = parse_json(line)
			if not data or data['name'] != "Player":
				continue
			
			save_meta['job_progress'] = str(data['jobs_finished'])
	
	return save_meta

func get_settings_file_json() -> Dictionary:
	var fpath = "user://settings.json"
	
	var f = File.new()
	if not f.file_exists(fpath):
		print('settings file doesnt exist')
		return {}
	
	f.open(fpath, File.READ)
	var res : = JSON.parse(f.get_line())
	if res.error == OK and typeof(res.result) == TYPE_DICTIONARY:
		return res.result
	else:
		print('unable to parse settings file')
		return {}

func save_settings_file(settings_data : Dictionary):
	var fpath = "user://settings.json"
	
	var f = File.new()
	f.open(fpath, File.WRITE)
	f.store_line(to_json(settings_data))
	f.close()
