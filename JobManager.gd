extends Node

var jobs = [preload("res://Job1.tscn"), preload("res://Job2.tscn"), preload("res://Job3.tscn")]

var max_jobs = 3

func get_job(number) -> Node:
	if number > max_jobs:
		print('not that many jobs')
		return null
	
	var job_instance = jobs[number].instance()
	return job_instance