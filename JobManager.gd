extends Node

var jobs = [
	preload("res://Job1.tscn"), preload("res://Job1_2.tscn"), 
	preload("res://Job2.tscn"), 
	preload("res://Job3.tscn"), preload("res://Job3_2.tscn"), 
	preload("res://Job4.tscn")
]

var max_jobs = 6

func get_job(number) -> Node:
	if number > max_jobs or number < 1:
		print('invalid job number')
		return null
	
	var job_instance = jobs[number - 1].instance()
	return job_instance

func num_jobs() -> int:
	return max_jobs