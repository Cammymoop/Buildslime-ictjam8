tool
extends TileMap

class_name WorldMap

var TILE : = 16

var NOTHING : = 0

export var map_width : int = 41 setget set_map_width, get_map_width
export var map_height : int = 41 setget set_map_height, get_map_height

export var start_x : int = 0 setget set_start_x, get_start_x
export var start_y : int = 0 setget set_start_y, get_start_y

export var is_persistent = false

export var is_modifiable = true

export var bounds_block_move : bool = false
export var bounds_cam_margin : int = 0

export var id : String = ''

var tileset : TileSet = preload("res://assets/tileset/Main.tres")

var AUTOTILES : Array = []
var BIG_TILES : Array = []
var BIG_EXTRAS : Array = []
var BIG_H : int = 0
var BIG_V : int = 0
var BIG_HV : int = 0

var warps : Array = []

func _ready():
	var combinator = get_node("/root/Combinator")
	AUTOTILES = combinator.AUTOTILES
	BIG_TILES = combinator.BIG_TILES
	
	BIG_H = combinator.names['BIG_H']
	BIG_V = combinator.names['BIG_V']
	BIG_HV = combinator.names['BIG_HV']
	BIG_EXTRAS.append(BIG_H)
	BIG_EXTRAS.append(BIG_V)
	BIG_EXTRAS.append(BIG_HV)
	
	centered_textures = true

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

func do_bounds_block_move() -> bool:
	return bounds_block_move

func is_map_modifiable() -> bool:
	return is_modifiable

func update_editor_bounds() -> void:
	if Engine.editor_hint:
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

#########
# Big tile handling is here in these abstraction functions for getting and setting cells
func get_map_cell(x : int, y : int):
	var index = get_cell(x, y)
	while BIG_EXTRAS.has(index):
		var xd : = 0 if index == BIG_V else -1
		var yd : = 0 if index == BIG_H else -1
		x += xd
		y += yd
		index = get_cell(x, y)
	return index

func set_map_cell(x : int, y : int, index : int, flip_x : bool = false, flip_y : bool = false, transpose : bool = false) -> void:
	var old = get_cell(x, y)
	set_cell(x, y, index, flip_x, flip_y, transpose)
	if AUTOTILES.has(index) or AUTOTILES.has(old):
		update_bitmask_area(Vector2(x, y))

func set_map_cellv(coord : Vector2, index : int, flip_x : bool = false, flip_y : bool = false, transpose : bool = false) -> void:
	set_map_cell(int(coord.x), int(coord.y), index, flip_x, flip_y, transpose)

func unset_big_tile_at(x : int, y : int) -> void:
	var index = get_cell(x, y)
	while BIG_EXTRAS.has(index):
		var xd : = 0 if index == BIG_V else -1
		var yd : = 0 if index == BIG_H else -1
		x += xd
		y += yd
		index = get_cell(x, y)
	if BIG_TILES.has(index):
		_remove_big_tile(x, y)

func fix_big_tile(x : int, y : int) -> void:
	var index = get_cell(x, y)
	if BIG_TILES.has(index):
		_place_big_tile(x, y, index)

func fix_all_big_tiles() -> void:
	var x_range : = range(start_x, start_x + map_width)
	var y_range : = range(start_y, start_y + map_height)
	# go through the map in reverse to unset big extras and reset them once the big tile is found
	x_range.invert() 
	y_range.invert()
	for y in y_range:
		for x in x_range:
			var index : = get_cell(x, y)
			if BIG_EXTRAS.has(index):
				set_cell(x, y, NOTHING)
			if BIG_TILES.has(index):
				_place_big_tile(x, y, index)

func _get_big_tile_width(big_tile_index : int) -> int:
	var tile_rect = tileset.tile_get_region(big_tile_index)
	return int(tile_rect.size.x / TILE)
func _get_big_tile_height(big_tile_index : int) -> int:
	var tile_rect = tileset.tile_get_region(big_tile_index)
	return int(tile_rect.size.y / TILE)

func _remove_big_tile(x : int, y : int) -> void:
	var index : = get_cell(x, y)
	var t_width : = _get_big_tile_width(index)
	var t_height : = _get_big_tile_height(index)
	
	for y in range(t_height):
		for x in range(t_width):
			set_cell(x, y, NOTHING)
	
func _place_big_tile(x : int, y : int, big_tile_index : int) -> void:
	var t_width = _get_big_tile_width(big_tile_index)
	var t_height = _get_big_tile_height(big_tile_index)
	
	for vy in range(t_height):
		for vx in range(t_width):
			if vx == 0 and vy == 0:
				set_cell(x + vx, y + vy, big_tile_index)
			elif vy == 0:
				set_cell(x + vx, y + vy, BIG_H)
			elif vx == 0:
				set_cell(x + vx, y + vy, BIG_V)
			else:
				set_cell(x + vx, y + vy, BIG_HV)

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
		
		"save_version": get_node("/root/SaveManager").get_cur_save_version(),
		
		"width": map_width,
		"height": map_height,
		"start_x": start_x,
		"start_y": start_y,
		
		"is_modifiable": is_modifiable,
		
		"tiles": tiles,
		"tiles_hflip": tiles_hflip,
		"tiles_vflip": tiles_vflip,
		"tiles_transpose": tiles_transpose,
	}
	return serialized

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
	
	if save_version >= 4:
		is_modifiable = serialized['is_modifiable']
	auto_tile_whole_map()

func coord_is_in_bounds(coord : Vector2) -> bool:
	if coord.x < start_x or coord.y < start_y:
		return false
	if coord.x >= map_width or coord.y >= map_height:
		return false
	return true

func transform_object_from_to(coord : Vector2, from : String, to : String) -> bool:
	var cur_index = get_cellv(coord)
	var combinator = get_node("/root/Combinator")
	if combinator.inv_names[cur_index] != from:
		return false
	var mirror_x = is_cell_x_flipped(int(coord.x), int(coord.y))
	var mirror_y = is_cell_y_flipped(int(coord.x), int(coord.y))
	var transpose = is_cell_transposed(int(coord.x), int(coord.y))
	set_cell(int(coord.x), int(coord.y), combinator.names[to], mirror_x, mirror_y, transpose)
	return true

func auto_tile_whole_map() -> void:
	update_bitmask_region(Vector2(start_x - 1, start_y - 1), Vector2(map_width + 1, map_height + 1))

func get_entity_at(pos : Vector2) -> Node2D:
	for e in get_entities():
		if e.tile_position == pos:
			return e
	return null

func get_camera_bounds() -> Rect2:
	var rect = Rect2(start_x * TILE, start_y * TILE, map_width * TILE, map_height * TILE)
	var margin = TILE * bounds_cam_margin
	rect.position -= Vector2(margin, margin)
	rect.size += Vector2(2 * margin, 2 * margin)
	
	return rect

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

