extends Node

var max_job_completed : int = 0 setget set_max_job_completed, get_max_job_completed

var current_map = 'home'
var current_job_num = 0

func new_game():
	current_map = 'home'
	max_job_completed = 0
	current_job_num = 0

func get_max_job_completed() -> int:
	return max_job_completed
func set_max_job_completed(v : int):
	max_job_completed = v

func is_at_job() -> bool:
	return current_map == 'job'

func set_to_map_home() -> void:
	current_map = 'home'
	current_job_num = 0
func set_to_map_job(job_num : int) -> void:
	current_map = 'job'
	current_job_num = job_num

func get_current_job_num() -> int:
	return current_job_num


func serialize_for_save() -> Dictionary:
	var serialized = {
		"name": get_name(),
		"mode": 'restore',
		
		"max_job_completed": max_job_completed,
		'current_map': current_map,
	}
	return serialized

func restore_save(serialized, save_version) -> void:
	max_job_completed = serialized['max_job_completed']
	current_map = serialized['current_map']