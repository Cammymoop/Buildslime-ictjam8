extends Node2D

var tile_position = Vector2(0, 0)
var facing_angle = 0
var facing = "down"

var r_tile_map : TileMap = null
var r_combinator = null

var holding_tile_ind : int = 0
var hold_2 : int = 0
var hold_3 : int = 0
var hold_count : int = 0

# rotate/flip by holding down grab
var holding_button : bool = false

var UP_ANGLE = PI
var DOWN_ANGLE = 0
var LEFT_ANGLE = PI/2
var RIGHT_ANGLE = PI + PI/2

var MAX_TILE = 40

var TILE = 16

var NON_WALKABLE = ['tree', 'wood_wall', 'sheep', 'sheered', 'fence', 'tent']
var NON_GRABABLE = ['tree']

var action_queue = []

var names

var sample_spawns = [
	{'object': 'tree', 'frequency': 16},
	{'object': 'sheep', 'frequency': 4, 'mirrorable': true},
	{'object': 'rock', 'frequency': 8},
	{'object': 'stick', 'frequency': 6, 'mirrorable': true},
	{'object': 'puddle', 'frequency': 3, 'mirrorable': true},
	{'object': 'seed', 'frequency': 3, 'mirrorable': true},
]

func _ready():
	randomize()
	tile_position.x = round(position.x/TILE)
	tile_position.y = round(position.y/TILE)
	
	print("spawned at " + str(tile_position))
	
	r_tile_map = get_parent().get_node("TileMap")
	r_combinator = get_parent().get_node("Combinator")
	
	call_deferred("post_ready")

func test_mapgen() -> void:
	get_parent().get_node("MapGenerator").generate(r_tile_map, MAX_TILE, sample_spawns)

func post_ready() -> void:
	names = r_combinator.names
	
	var temp = []
	for name_t in NON_WALKABLE:
		temp.append(names[name_t])
	NON_WALKABLE = temp
	
	temp = []
	for name_t in NON_GRABABLE:
		temp.append(names[name_t])
	NON_GRABABLE = temp
	
	for sp in sample_spawns:
		sp['object'] = names[sp['object']]
	
	test_mapgen()
	r_tile_map.set_cellv(tile_position, 0)

func change_facing(direction) -> void:
	match direction:
		'up':
			facing_angle = UP_ANGLE
		'down':
			facing_angle = DOWN_ANGLE
		'left':
			facing_angle = LEFT_ANGLE
		'right':
			facing_angle = RIGHT_ANGLE
		_:
			print('not a direction: ' + direction)
			return
	facing = direction
	$PlayerSprite.rotation = facing_angle

func rotate_a_thing(tile_coord, counterclockwise = false) -> void:
	var ind = r_tile_map.get_cellv(tile_coord)
	if not ind:
		return
	var h_flip = r_tile_map.is_cell_x_flipped(tile_coord.x, tile_coord.y)
	var v_flip = r_tile_map.is_cell_y_flipped(tile_coord.x, tile_coord.y)
	var transposed = r_tile_map.is_cell_transposed(tile_coord.x, tile_coord.y)
	
	var determine = 0
	determine += 1 if h_flip else 0
	determine += 1 if v_flip else 0
	determine += 1 if counterclockwise else 0
	determine = determine % 2
	
	transposed = not transposed
	if determine == 0:
		h_flip = not h_flip
	else:
		v_flip = not v_flip
	r_tile_map.set_cellv(tile_coord, ind, h_flip, v_flip, transposed)

func flip_a_thing(tile_coord) -> void:
	var ind = r_tile_map.get_cellv(tile_coord)
	if not ind:
		return
	var h_flip = r_tile_map.is_cell_x_flipped(tile_coord.x, tile_coord.y)
	var v_flip = r_tile_map.is_cell_y_flipped(tile_coord.x, tile_coord.y)
	var transposed = r_tile_map.is_cell_transposed(tile_coord.x, tile_coord.y)
	
	if transposed:
		v_flip = not v_flip
	else:
		h_flip = not h_flip
	r_tile_map.set_cellv(tile_coord, ind, h_flip, v_flip, transposed)

func _get_facing_xdelta() -> int:
	if facing == 'up' or facing == 'down':
		return 0
	return 1 if facing == 'right' else -1
func _get_facing_ydelta() -> int:
	if facing == 'left' or facing == 'right':
		return 0
	return 1 if facing == 'down' else -1

func get_facing_tile_coord(amount : int = 1) -> Vector2:
	var facing_c = Vector2(tile_position.x, tile_position.y)
	facing_c.x += _get_facing_xdelta() * amount
	facing_c.y += _get_facing_ydelta() * amount
	return facing_c

func move_tile(direction) -> void:
	var xd = 0
	var yd = 0
	match direction:
		'up':
			yd = -1
		'down':
			yd = 1
		'left':
			xd = -1
		'right':
			xd = 1
		_:
			print('not a direction: ' + direction)
			return
	_move(xd, yd)

func _move(xdelta, ydelta) -> void:
	if tile_position.x + xdelta > MAX_TILE or tile_position.x + xdelta < 0:
		return
	if tile_position.y + ydelta > MAX_TILE or tile_position.y + ydelta < 0:
		return
	tile_position.x += xdelta
	tile_position.y += ydelta
	
	#can I step here?
	var object_here = r_tile_map.get_cellv(tile_position)
	if NON_WALKABLE.find(object_here) != -1:
		tile_position.x -= xdelta
		tile_position.y -= ydelta
		return
		
	position.x += xdelta * TILE
	position.y += ydelta * TILE

func smack() -> void:
	var facing_t = get_facing_tile_coord()
	var facing_t_2 = get_facing_tile_coord(2)
	
	var first = r_tile_map.get_cellv(facing_t)
	var second = r_tile_map.get_cellv(facing_t_2)
	
	var result = r_combinator.get_combinator_result(first, second)
	print(str(result))
	r_tile_map.set_cellv(facing_t, result[0])
	r_tile_map.set_cellv(facing_t_2, result[1])

# check if you're holding too many first
func pick_up(index) -> void:
	hold_3 = hold_2
	hold_2 = holding_tile_ind
	holding_tile_ind = index
	hold_count += 1
	$PlayerSprite.region_rect.position.x += 16

#check if you're holding something first
func drop() -> int:
	var drop_me = holding_tile_ind
	holding_tile_ind = hold_2
	hold_2 = hold_3
	hold_3 = 0
	hold_count -= 1
	$PlayerSprite.region_rect.position.x -= 16
	return drop_me


func _process(delta) -> void:
	if holding_button and not Input.is_action_pressed("action_grab"):
		holding_button = false
	
	#movement and flip/rotate
	var move = false
	if not holding_button:
		if Input.is_action_just_pressed("move_up"):
			move = "up"
		elif Input.is_action_just_pressed("move_down"):
			move = "down"
		elif Input.is_action_just_pressed("move_left"):
			move = "left"
		elif Input.is_action_just_pressed("move_right"):
			move = "right"
	else:
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
			flip_a_thing(get_facing_tile_coord())
		if Input.is_action_just_pressed("move_right"):
			rotate_a_thing(get_facing_tile_coord())
		if Input.is_action_just_pressed("move_left"):
			rotate_a_thing(get_facing_tile_coord(), true)
	
	if move:
		move_tile(move)
		if not Input.is_action_pressed("hold_strafe"):
			change_facing(move)
	else:
		if Input.is_action_just_pressed("action_grab"):
			holding_button = true
			var facing_t = get_facing_tile_coord()
			var ind = r_tile_map.get_cellv(facing_t)
			if ind > 0:
				if NON_GRABABLE.find(ind) == -1 and hold_count < 3:
					pick_up(ind)
					#print("got object " + str(ind))
					r_tile_map.set_cellv(facing_t, 0)
				else:
					print("cant pick up")
			else:
				if hold_count > 0:
					ind = drop()
					#print("placed object " + str(ind))
					r_tile_map.set_cellv(facing_t, ind)
		elif Input.is_action_just_pressed("action_smack"):
			smack()
		elif Input.is_action_just_pressed("action_d_regen"):
			test_mapgen()
