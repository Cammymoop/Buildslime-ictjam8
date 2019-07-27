extends Node2D

export var spawn_objects : Array
export var spawn_frequencies : Array
export var spawn_mirrorable : Array

export var rewards : Array

export var forest : bool

func has_forest() -> bool:
	return forest

func get_rewards() -> Array:
	return rewards

func get_spawn_params() -> Array:
	var spawn_params = []
	
	for i in range(spawn_objects.size()):
		var p = {
			'object': spawn_objects[i],
			'frequency': spawn_frequencies[i],
			'mirrorable': spawn_mirrorable[i]
		}
		spawn_params.append(p)
	
	return spawn_params