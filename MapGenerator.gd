extends Node

func generate(map : TileMap, map_width : int, spawns : Array):
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
