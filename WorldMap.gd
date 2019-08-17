tool
extends TileMap

var TILE = 16

export var map_width : int = 41 setget set_map_width, get_map_width
export var map_height : int = 41 setget set_map_height, get_map_height

export var start_x : int = 0 setget set_start_x, get_start_x
export var start_y : int = 0 setget set_start_y, get_start_y

export var is_persistent = false

export var bounds_block_move : bool = false
export var bounds_move_margin : int = 0

export var id : String = ''

func set_map_width(val) -> void:
	map_width = val
	update_editor_bounds()
func get_map_width() -> int:
	return map_width
func set_map_height(val) -> void:
	map_height = val
	update_editor_bounds()
func get_map_height() -> int:
	return map_height

func set_start_x(val) -> void:
	start_x = val
	update_editor_bounds()
func get_start_x() -> int:
	return start_x
func set_start_y(val) -> void:
	start_y = val
	update_editor_bounds()
func get_start_y() -> int:
	return start_y

func update_editor_bounds() -> void:
	if Engine.editor_hint:
		print('redraw map')
		update()

func _draw():
	if Engine.editor_hint:
		var points = PoolVector2Array([
			Vector2(start_x * TILE, start_y * TILE),
			Vector2(start_x * TILE + (map_width * TILE), start_y * TILE),
			Vector2(start_x * TILE + (map_width * TILE), start_y * TILE + (map_height * TILE)),
			Vector2(start_x * TILE, start_y * TILE + (map_height * TILE)),
			Vector2(start_x * TILE, start_y * TILE),
		])
		
#		var rect = Rect2(start_x * TILE, start_y * TILE, map_width * TILE, map_height * TILE)
#		draw_rect(rect, Color('#eeaaaa'), false)
		draw_polyline(points, Color('#fe9999'), 3, false)

func serialize_for_save() -> Dictionary:
	var tiles = []
	var tiles_hflip = []
	var tiles_vflip = []
	var tiles_transpose = []
	for y in range(start_y, map_height):
		for x in range(start_x, map_width):
			tiles.append(get_cell(x, y))
			tiles_hflip.append(is_cell_x_flipped(x, y))
			tiles_vflip.append(is_cell_y_flipped(x, y))
			tiles_transpose.append(is_cell_transposed(x, y))
	
#	for ent in get_entities():
#		var s = ent.serialize_for_save()
	
	var serialized = {
		"name": get_name(),
		"id": id,
		"mode": 'restore',
		
		"width": map_width,
		"height": map_height,
		"start_x": start_x,
		"start_y": start_y,
		
		"tiles": tiles,
		"tiles_hflip": tiles_hflip,
		"tiles_vflip": tiles_vflip,
		"tiles_transpose": tiles_transpose,
		"visible": visible
	}
	return serialized

func coord_is_in_bounds(coord : Vector2) -> bool:
	if coord.x < start_x or coord.y < start_y:
		return false
	if coord.x >= map_width or coord.y >= map_height:
		return false
	return true

func restore_save(serialized, save_version) -> void:
	var i = 0
	var tiles = serialized['tiles']
	var hf = serialized['tiles_hflip']
	var vf = serialized['tiles_vflip']
	var ts = serialized['tiles_transpose']
	
	if save_version > 1:
		map_width = serialized['width']
		map_height = serialized['height']
	else:
		map_width = 40
		map_height = 40
	
	if save_version >= 4:
		start_x = serialized['start_x']
		start_y = serialized['start_y']
	else:
		start_x = 0
		start_y = 0
		
	for y in range(start_y, map_height):
		for x in range(start_x, map_width):
			set_cell(x, y, tiles[i], hf[i], vf[i], ts[i])
			i += 1
	
	# original save accidentally saved 41x41 maps as 40x40
	if save_version == 1:
		map_width = 41
		map_height = 41
	
	visible = serialized['visible']
	auto_tile_whole_map()

func auto_tile_whole_map() -> void:
	update_bitmask_region(Vector2(start_x - 1, start_y - 1), Vector2(map_width + 1, map_height + 1))

func get_entity_at(pos : Vector2) -> Node2D:
	for e in get_entities():
		if e.tile_position == pos:
			return e
	return null

func get_entities() -> Array:
	var entities : = []
	if has_node("Entities"):
		var all_ent = get_node("Entities").get_children()
		for e in all_ent:
			var ent : = e as Entity
			if ent:
				entities.append(ent)
	
	#TODO better handling of keeping track of which entities are currently in the map
	var player = get_tree().get_nodes_in_group("player")
	for p in player:
		entities.append(p)
	
	return entities