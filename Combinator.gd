extends Node

export var data_filename = "combinator"
export var names_filename = "names"

var rules = []
var names = {}
var inv_names = {}

func _ready():
	names['any'] = -2
	names['special'] = -3
	var nfile = open_text_file(names_filename)
	while not nfile.eof_reached():
		add_name(nfile.get_line())
		
	var dfile = open_text_file(data_filename)
	while not dfile.eof_reached():
		process_line(dfile.get_line())
	
func open_text_file(name) -> File:
	var file = File.new()
	if not file.file_exists("res://assets/text/" + name):
		print("data file not found: " + "res://assets/text/" + name)
		return null
	file.open("res://assets/text/" + name, File.READ)
	return file
	

func add_name(old_line):
	var line : String = old_line.strip_edges()
	
	var parts: PoolStringArray = line.split(" ", false)
	if line.length() < 1 or parts.size() < 2: #empty line
		return
	
	names[parts[1]] = int(parts[0])
	inv_names[int(parts[0])] = parts[1]

func get_combinator_result(tile1, tile2):
	for rule in rules:
		var reversed = false
		var ingredients = rule['ingredients']
		if ingredients[0] != -2 and ingredients[0] != tile1:
			if rule['reversable'] and (ingredients[1] == -2 or ingredients[1] == tile1):
				reversed = true
			else:
				continue
		var ingredient = ingredients[1] if not reversed else ingredients[0]
		if ingredient != -2 and ingredient != tile2:
			continue
		if rule['is_special']:
			return rule['special_results']
		else:
			return rule['results']
# warning-ignore:unreachable_code
	return false

func get_all_recipes_for(tile_index : int) -> Array:
	var recipes = []
	for rule in rules:
		if rule['ingredients'].has(tile_index):
			recipes.append(rule)
	return recipes

func get_all_results_for(tile_index : int) -> Array:
	var recipes = get_all_recipes_for(tile_index)
	var possible_results = []
	for r in recipes:
		if not r['is_special']:
			var i = 0
			for r2 in r['results']:
				if r2 == 0 or r['ingredients'][i] == r2:
					# object didnt change or is nothing so it doesnt count as a result
					pass
				elif not possible_results.has(r2):
					possible_results.append(r2)
				i += 1
	return possible_results

func process_line(old_line):
	var line : String = old_line.strip_edges()
	
	var parts: PoolStringArray = line.split(" ", false)
	if line.length() < 1 or parts.size() < 1: #empty line
		return
	
	var reversable = false
	if parts[0] == 'R':
		reversable = true
		parts.remove(0)
	
	if parts.size() < 7:
		if parts[2] != ">":
			print("invalid rule: " + old_line)
		var is_special = parts[3] == 'special'
		if not (names.has(parts[0]) and names.has(parts[1])): 
			print("invalid name in rule: " + old_line)
		if not is_special and not (names.has(parts[3]) and names.has(parts[4])):
			print("invalid name in rule: " + old_line)
		var rule = {
			'ingredients': [names[parts[0]], names[parts[1]]], 
			'reversable': reversable,
			'is_special': is_special,
		}
		if is_special:
			rule['special_results'] = ['special', parts[4]]
		else:
			rule['results'] = [names[parts[3]], names[parts[4]]]
		rules.append(rule)

