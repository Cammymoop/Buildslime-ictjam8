extends Node

export var data_filename = "combinator"
export var names_filename = "names"

var rules = []
var names = {}
var inv_names = {}

var ING_ANY = -2
var RES_SPECIAL = -3
var RES_SAME = -4

var NON_WALKABLE : Array = []
var NON_GRABBABLE : Array = []
var AUTOTILES : Array = []

func _ready():
	names['any'] = ING_ANY
	names['special'] = RES_SPECIAL
	names['same'] = RES_SAME

	var nfile = open_text_file(names_filename)
	while not nfile.eof_reached():
		process_name(nfile.get_line())
		
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
	

func process_name(old_line):
	var line : String = old_line.strip_edges()
	
	var parts: PoolStringArray = line.split(" ", false)
	if line.length() < 1 or parts.size() < 2: #empty line
		return
	
	names[parts[1]] = int(parts[0])
	inv_names[int(parts[0])] = parts[1]
	if len(parts) > 2:
		for i in range(2, len(parts)):
			match parts[i]:
				'NO_WALK':
					NON_WALKABLE.append(int(parts[0]))
				'NO_GRAB':
					NON_GRABBABLE.append(int(parts[0]))
				'AUTO_TILE':
					AUTOTILES.append(int(parts[0]))

# rule matching
func _ingredients_match_rule_exact(rule : Dictionary, ing1 : int, ing2 : int) -> bool:
	var ru_i = rule['ingredients']
	var real_i = [ing1, ing2]
	if ru_i == real_i:
		return true
	if (ru_i[0] == ING_ANY and ru_i[1] == real_i[1]): # handle "any" in ingredients
		return true
	if (ru_i[1] == ING_ANY and ru_i[0] == real_i[0]): # handle "any" in ingredients
		return true
	return false

func reverse_output_match(rule : Dictionary, ing1 : int, ing2 : int) -> bool:
	return rule['reverse_out'] and _ingredients_match_rule_exact(rule, ing2, ing1)

func regular_output_match(rule : Dictionary, ing1 : int, ing2 : int) -> bool:
	var reverse_valid = rule['reversable'] and _ingredients_match_rule_exact(rule, ing2, ing1)
	return reverse_valid or _ingredients_match_rule_exact(rule, ing1, ing2)

func _reverse_output(results : Array) -> Array:
	return [results[1], results[0]]

func get_results_for(rule, tile1, tile2):
	if rule['is_special']:
		return rule['special_results']
	var ingredients = [tile1, tile2]
	var out = []
	for i in range(2):
		out.append(ingredients[i] if rule['results'][i] == RES_SAME else rule['results'][i])
	return out

func get_combinator_result(tile1, tile2):
	for rule in rules:
		var results = get_results_for(rule, tile1, tile2)
		if reverse_output_match(rule, tile1, tile2):
			return _reverse_output(results)
		elif regular_output_match(rule, tile1, tile2):
			return results
	return false

func get_all_recipes_for(tile_index : int) -> Array:
	var recipes = []
	for rule in rules:
		if rule['ingredients'].has(tile_index) and not rule['result_ignore']:
			recipes.append(rule)
	return recipes

func get_all_results_for(tile_index : int) -> Array:
	var recipes = get_all_recipes_for(tile_index)
	var possible_results = []
	for r in recipes:
		if not r['is_special']:
			var i = 0
			for r2 in r['results']:
				if r2 < 1 or r['ingredients'][i] == r2:
					# object didnt change or is nothing/a special thing so it doesnt count as a result
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
	if parts[0][0] == '#': #comment
		return
	
	var rule = {'reversable': false, 'reverse_out': false, 'result_ignore': false}
	#tags
	if parts[0][0] == '.':
		var tags = parts[0]
		parts.remove(0)
		if tags.find('R') != -1:
			rule['reversable'] = true
			if tags.find('O') != -1:
				rule['reverse_out'] = true
		if tags.find('I') != -1:
			rule['result_ignore'] = true
	
	if parts.size() < 7:
		if parts[2] != ">":
			print("invalid rule: " + old_line)
		var is_special = parts[3] == 'special'
		
		if not (names.has(parts[0]) and names.has(parts[1])): 
			print("invalid name in rule: " + old_line)
		
		if not is_special and not (names.has(parts[3]) and names.has(parts[4])):
			print("invalid name in rule: " + old_line)
		
		rule['ingredients'] = [names[parts[0]], names[parts[1]]]
		rule['is_special'] = is_special
		if is_special:
			rule['special_results'] = ['special', parts[4]]
		else:
			rule['results'] = [names[parts[3]], names[parts[4]]]
		rules.append(rule)

