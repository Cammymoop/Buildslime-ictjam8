extends Node

func _ready():
	var d :Directory = Directory.new()
	if not d.dir_exists("user://saves"):
		d.make_dir("user://saves")

func save_game(save_filename : String, screenshot_name : String = 'none') -> void:
	print('save in: ' + save_filename)
	if len(save_filename) < 1:
		print('no filename')
		return
	if len(save_filename) < 4 or save_filename.substr(len(save_filename) - 3, 3) != '.bs':
		save_filename = save_name_to_filename(save_filename)
	
	var save_file = File.new()
	save_file.open("user://" + save_filename, File.WRITE)
	print('saving: ' + save_filename)
	
	save_file.store_line('buildslime_save_version 3')
	
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
	if save_version > 3:
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
	
	var root_node = get_node('/root/Root') # this only works in gamescene anyway
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
		
		var existing_node = null
		if load_node['name'] == "GlobalData":
			existing_node = get_node("/root/GlobalData")
		else:
			existing_node = root_node.find_node(load_node['name'])
		
		if existing_node:
			print('calling restore on: ' + existing_node.get_path())
			existing_node.call('restore_save', load_node, save_version)
		else:
			print('couldnt find ' + load_node['name'])
			root_node.print_tree_pretty()
			existing_node.get_path() # error out

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
	var i = 0
	var new_name = ''
	for i in base_name.length():
		var c = base_name[i]
		if c == ' ':
			c = '_'
		if _is_alpha_num(c) or allowed_symbols.find(c) != -1:
			print('allowed: ' + c)
			new_name += c
		else:
			print('not allowed: ' + c)
	
	while f.file_exists("user://saves/" + new_name + str(number) + '.bs'):
		number += 1
		if number > 10000:
			return 'toomany'
	return new_name + str(number)

func get_all_saves() -> Array:
	var d : Directory = Directory.new()
	var res = d.open("user://saves/")
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
	if save_version > 3:
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
		save_meta['job_progress'] = second_line[1]
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