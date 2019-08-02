extends Node

var TREE = 2
var NO_GENERATE = 65

func generate(map : TileMap, gen_parameters : Dictionary):
	map.clear()
	
	var map_width : int = gen_parameters['map_width']
	var spawns : Array = gen_parameters['spawns']
	var has_forest : bool = gen_parameters['has_forest']
	
	var has_prebuilt : bool = false
	var prebuilt : TileMap = null
	if gen_parameters.has("prebuilt_map"):
		print('has a prebuilt')
		prebuilt = gen_parameters['prebuilt_map']
		has_prebuilt = true
	
	
	for x in range(-1, map_width + 1):
		for y in range(-1, map_width + 1):
			
			# Place any objects from the prebuilt map (dont place no generate tiles)
			if has_prebuilt:
				var pre_tile = prebuilt.get_cell(x, y)
				if pre_tile > 0:
					if pre_tile != NO_GENERATE:
						var xf = prebuilt.is_cell_x_flipped(x, y)
						var yf = prebuilt.is_cell_x_flipped(x, y)
						var tr = prebuilt.is_cell_transposed(x, y)
						map.set_cell(x, y, pre_tile, xf, yf, tr)
					continue
			
			if x < 0 or y < 0 or x > map_width or y > map_width:
				continue
			
			var rv = randi() % 1000
			var this_tile = 0
			var mirrorable = false
			for sp in spawns:
				if rv < sp['frequency']:
					this_tile = sp['object']
					if sp.has('mirrorable') and sp['mirrorable']:
						mirrorable = true
					break
				else:
					rv -= sp['frequency']
			var mirror_me = randi() % 2 == 1
			map.set_cell(x, y, this_tile, mirrorable and mirror_me)
	
	if has_forest:
		#print('making forest')
		var inv_x = false
		var inv_y = false
		
		var corner = randi() % 3
		match corner:
			0:
				inv_x = true
				inv_y = true
			1:
				inv_x = true
			2:
				inv_y = true
		
		var max_x_extent = 9 + (randi() % 9)
		print(max_x_extent)
		var max_y_extent = 9 + (randi() % 9)
		print(max_y_extent)
		
		var cur_x_extent = max_x_extent
		
		for row in range(max_y_extent):
			for n in range(cur_x_extent):
				var tx = n if not inv_x else map_width - n
				var ty = row if not inv_y else map_width - row
				var tree_chance = randi() % 4 != 0
				if tree_chance:
					map.set_cell(tx, ty, TREE)
			cur_x_extent += min(0, 0 - (randi() % 2) - max(0, row - max_y_extent - 9))
			if cur_x_extent < 1:
				cur_x_extent = 3
