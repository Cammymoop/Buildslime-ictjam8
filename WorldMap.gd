extends TileMap

var MAP_WIDTH = 41
var MAP_HEIGHT = 41

func serialize_for_save() -> Dictionary:
	var tiles = []
	var tiles_hflip = []
	var tiles_vflip = []
	var tiles_transpose = []
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			tiles.append(get_cell(x, y))
			tiles_hflip.append(is_cell_x_flipped(x, y))
			tiles_vflip.append(is_cell_y_flipped(x, y))
			tiles_transpose.append(is_cell_transposed(x, y))
	
	var serialized = {
		"name": get_name(),
		"mode": 'restore',
		
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		
		"tiles": tiles,
		"tiles_hflip": tiles_hflip,
		"tiles_vflip": tiles_vflip,
		"tiles_transpose": tiles_transpose,
		"visible": visible
	}
	return serialized

func restore_save(serialized, save_version) -> void:
	var i = 0
	var tiles = serialized['tiles']
	var hf = serialized['tiles_hflip']
	var vf = serialized['tiles_vflip']
	var ts = serialized['tiles_transpose']
	
	if save_version > 1:
		MAP_WIDTH = serialized['width']
		MAP_HEIGHT = serialized['height']
	else:
		MAP_WIDTH = 40
		MAP_HEIGHT = 40
		
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			set_cell(x, y, tiles[i], hf[i], vf[i], ts[i])
			i += 1
	
	if save_version == 1:
		MAP_WIDTH = 41
		MAP_HEIGHT = 41
	
	visible = serialized['visible']
	auto_tile_whole_map()

func auto_tile_whole_map() -> void:
	update_bitmask_region(Vector2(-1, -1), Vector2(MAP_WIDTH + 1, MAP_HEIGHT + 1))