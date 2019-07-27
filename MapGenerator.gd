extends Node

var TREE = 2

func generate(map : TileMap, map_width : int, spawns : Array, forest : bool = false):
	map.clear()
	
	for x in range(map_width):
		for y in range(map_width):
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
	
	if forest:
		print('making forest')
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
				map.set_cell(tx, ty, TREE)
			cur_x_extent += min(0, 0 - (randi() % 2) - max(0, row - max_y_extent - 9))
			if cur_x_extent < 1:
				cur_x_extent = 3
