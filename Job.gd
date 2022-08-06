extends Node2D

export var spawn_objects : Array
# warning-ignore:unused_class_variable
export var spawn_frequencies : Array
# warning-ignore:unused_class_variable
export var spawn_mirrorable : Array

export var rewards : Array

export var forest : bool

func has_forest() -> bool:
	return forest

func get_rewards() -> Array:
	return rewards

func get_spawn_params() -> Array:
	var spawn_params = {'map_width': 40, 'spawns': [], 'has_forest': has_forest()}
	
	for i in range(spawn_objects.size()):
		var p = {
			'object': spawn_objects[i],
			'frequency': spawn_frequencies[i],
			'mirrorable': spawn_mirrorable[i]
		}
		spawn_params['spawns'].append(p)
	
	var prebuilt_tilemap = get_node("Prebuilt")
	if prebuilt_tilemap:
		spawn_params['prebuilt_map'] = prebuilt_tilemap
	
	return spawn_params

func get_goal() -> TileMap:
	var goal : TileMap = get_node("JobGoal")
	return goal
