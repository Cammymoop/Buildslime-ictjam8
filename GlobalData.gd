extends Node

var max_job_completed : int = 0 setget set_max_job_completed, get_max_job_completed

var current_map = 'home'
var current_job_num = 0

var save_name : String = 'Jel' setget set_save_name, get_save_name

var cur_save_filename = ''

var pause_focus = ''

func new_game():
	current_map = 'home'
	max_job_completed = 0
	current_job_num = 0
	pause_focus = ''
	cur_save_filename = ''
	save_name = 'Jel'

func get_max_job_completed() -> int:
	return max_job_completed
func set_max_job_completed(v : int):
	max_job_completed = v

func has_saved() -> bool:
	return cur_save_filename != ''

func get_current_save_filename() -> String:
	return cur_save_filename
func set_current_save_filename(fname : String) -> void:
	cur_save_filename = fname

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

func get_save_name() -> String:
	return save_name
func set_save_name(v : String):
	save_name = v

func get_pause_focus(name : String) -> bool:
	if pause_focus:
		return false
	pause_focus = name
	return true

func release_pause_focus(name):
	if pause_focus == name:
		pause_focus = ''

func serialize_for_save() -> Dictionary:
	var serialized = {
		"name": get_name(),
		"mode": 'restore',
		
		"max_job_completed": max_job_completed,
		'current_job_num': current_job_num,
		'current_map': current_map,
		
		'save_name': save_name,
	}
	return serialized

func restore_save(serialized, save_version) -> void:
	max_job_completed = serialized['max_job_completed']
	current_job_num = serialized['current_job_num']
	current_map = serialized['current_map']
	
	save_name = serialized['save_name']
