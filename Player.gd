extends Node2D

var tile_position = Vector2(0, 0)
var facing_angle = 0
var facing = "down"

var r_tile_map : TileMap = null
var r_combinator = null

var holding_tile_ind = 0

var UP_ANGLE = PI
var DOWN_ANGLE = 0
var LEFT_ANGLE = PI/2
var RIGHT_ANGLE = PI + PI/2

var MAX_TILE = 40

var TILE = 16

func _ready():
	tile_position.x = round(position.x/TILE)
	tile_position.y = round(position.y/TILE)
	
	print("spawned at " + str(tile_position))
	
	r_tile_map = get_parent().get_node("TileMap")
	r_combinator = get_parent().get_node("Combinator")

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


func _process(delta) -> void:
	var move = false
	if Input.is_action_just_pressed("move_up"):
		move = "up"
	elif Input.is_action_just_pressed("move_down"):
		move = "down"
	elif Input.is_action_just_pressed("move_left"):
		move = "left"
	elif Input.is_action_just_pressed("move_right"):
		move = "right"
	
	if move:
		move_tile(move)
		change_facing(move)
	else:
		if Input.is_action_just_pressed("action_grab"):
			var facing_t = get_facing_tile_coord()
			var ind = r_tile_map.get_cellv(facing_t)
			if ind > 0:
				if holding_tile_ind == 0:
					holding_tile_ind = ind
					print("got object " + str(ind))
					r_tile_map.set_cellv(facing_t, 0)
				else:
					print("cant pick up")
			else:
				ind = holding_tile_ind
				holding_tile_ind = 0
				print("placed object " + str(ind))
				r_tile_map.set_cellv(facing_t, ind)
		elif Input.is_action_just_pressed("action_smack"):
			smack()