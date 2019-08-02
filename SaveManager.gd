extends Node

func save_game() -> void:
	var save_file = File.new()
	save_file.open("user://savegame.save", File.WRITE)
	
	save_file.store_line('buildslime_save_version 2')
	
	var saveables = get_tree().get_nodes_in_group("saveable")
	
	for node in saveables:
		var serialized = node.call("serialize_for_save")
		save_file.store_line(to_json(serialized))
	save_file.close()

func load_game() -> void:
	var save_file = File.new()
	if not save_file.file_exists("user://savegame.save"):
		print('save file doesnt exist')
		return
	
	save_file.open("user://savegame.save", File.READ)
	
	var first_line = save_file.get_line()
	var save_version = int(first_line.split(" ", false)[1])
	if save_version > 2:
		print('unsupported save version!')
		return
	print('loading save version ' + str(save_version))
	
	var root_node = find_parent("Root")
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
		
		var existing_node = root_node.find_node(load_node['name'])
		print('calling restore on: ' + existing_node.get_path())
		existing_node.call('restore_save', load_node, save_version)