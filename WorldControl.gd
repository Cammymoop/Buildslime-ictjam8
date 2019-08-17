extends Node

var world_map : TileMap = null

var unloaded_maps = []

func _ready():
	var home = load("res://assets/maps/HomeMap.tscn").instance()
	load_map(home)

func load_test_map() -> void:
	var test_map = load("res://assets/maps/TestMap.tscn").instance()
	print(test_map.name)
	load_map(test_map)
	get_node("/root/GlobalData").current_map = 'test'

func load_map(new_world_map : TileMap) -> void:
	if world_map:
		unload_map()
	world_map = new_world_map
	if not world_map.is_inside_tree():
		get_node("/root/Root").add_child(world_map)
		print('adding ' + world_map.name + ' to the tree')
	
	var entities = world_map.get_entities()
	
	for ent in entities:
		ent.spawn(world_map)
	
	world_map.visible = true

func unload_map() -> void:
	if not world_map.is_persistent:
		world_map.queue_free()
	else:
		world_map.visible = false