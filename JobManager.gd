extends Node

var jobs = [
	preload("res://Job1.tscn"), preload("res://Job1_2.tscn"), 
	preload("res://Job2.tscn"),
	preload("res://Job3.tscn"), preload("res://Job3_2.tscn"), preload("res://Job3_3.tscn"), 
	preload("res://Job4.tscn")
]

var max_jobs = 7

func get_job(number) -> Node:
	if number > max_jobs or number < 1:
		print('invalid job number')
		return null
	
	var job_instance = jobs[number - 1].instance()
	return job_instance

func num_jobs() -> int:
	return max_jobs

func get_next_job() -> int:
	return int(min(get_node("/root/GlobalData").max_job_completed + 1, max_jobs))

func check_job_completion(job_num : int, map : TileMap) -> bool:
	var JOB_WIDTH = 19
	var MAX_TILE = 40
	
	var first_x = -1
	var first_y = -1
	var first_tile = false
	var last_x = -1
	var last_y = -1
	
	var job_instance = get_job(job_num)
	if not job_instance:
		return false
	
	var goal_map : TileMap = job_instance.get_goal()
	if not goal_map:
		print("failed to get goal map for job " + str(job_num))
		job_instance.print_tree_pretty()
		return false
	
	var max_j = -1
	
	for ty in range(JOB_WIDTH):
		for tx in range(JOB_WIDTH):
			var this_tile = goal_map.get_cell(tx, ty)
			if this_tile > 0:
				if first_x < 0:
					first_x = tx
					first_y = ty
					first_tile = this_tile
				last_x = tx
				last_y = ty
				max_j = max(max_j, tx)
	
	var width = max_j - first_x + 1
	
	var verified = false
	
	
	var search_origin_x = -1
	var search_origin_y = -1
	var searching = false
	var return_coord = false
	
	var tx = 0
	var ty = 0
	
	var safety = 200000
	
	while ty <= MAX_TILE:
		if verified:
			break
		tx = 0
		while tx <= MAX_TILE:
			safety -= 1
			if safety < 0:
				return false
			var this_tile = map.get_cell(tx, ty)
			if searching:
				var x_offset = tx + (first_x - search_origin_x)
				var y_offset = ty + (first_y - search_origin_y)
				var that_tile = goal_map.get_cell(x_offset, y_offset)
				if that_tile < 1 or that_tile == this_tile:
					if x_offset == last_x and y_offset == last_y:
						verified = true
						break
					
					if that_tile < 1 and this_tile == first_tile and not return_coord:
						return_coord = Vector2(tx, ty)
				else:
					searching = false
					if return_coord:
						ty = return_coord.y
						tx = return_coord.x - 1
						continue
			if not searching and this_tile == first_tile and not (tx + width > MAX_TILE):
				search_origin_x = tx
				search_origin_y = ty
				if first_x == last_x and first_y == last_y: # job is only 1 tile
					verified = true
					break
				searching = true
			tx += 1
		ty += 1
	
	return verified
