extends Node

var max_job_completed : int = 0 setget set_max_job_completed, get_max_job_completed

var current_map = '' setget set_current_map, get_current_map
var current_job_num = 0

var save_name : String = 'Jel' setget set_save_name, get_save_name

var cur_save_filename = ''

var pause_focus = ''

func new_game():
	current_map = ''
	max_job_completed = 0
	current_job_num = 0
	pause_focus = ''
	cur_save_filename = ''
	save_name = 'Jel'
	get_node("/root/WorldControl").clear_map()
	get_node("/root/WorldControl").call_deferred('load_home')

func get_max_job_completed() -> int:
	return max_job_completed
func set_max_job_completed(v : int):
	max_job_completed = v

func complete_current_job() -> void:
	if current_job_num > max_job_completed:
		set_max_job_completed(current_job_num)

func get_current_map() -> String:
	return current_map
func set_current_map(v : String):
	print(v)
	current_map = v

func has_saved() -> bool:
	return cur_save_filename != ''

func get_current_save_filename() -> String:
	return cur_save_filename
func set_current_save_filename(fname : String) -> void:
	cur_save_filename = fname

func is_at_job() -> bool:
	return current_map == 'JobMap'

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
		"node_path": str(get_path()),
		"mode": 'restore',
		
		"max_job_completed": max_job_completed,
		'current_job_num': current_job_num,
		
		'save_name': save_name,
	}
	return serialized

func restore_save(serialized, save_version) -> String:
	max_job_completed = serialized['max_job_completed']
	current_job_num = serialized['current_job_num']
	
	save_name = serialized['save_name']
	
	return "post_load"

func post_load() -> void:
	if current_map == "JobMap":
		var job = get_node("/root/JobManager").get_job(current_job_num)
		get_node("/root/UI").set_popup_goal(job.get_job_goal())