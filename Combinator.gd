extends Node

export var data_filename = "combinator"
export var names_filename = "names"

var rules = []
var names = {}
var inv_names = {}

func _ready():
	names['any'] = -2
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
		var ingredients = rule['ingredients']
		if ingredients[1] != -2 and not ingredients[1] == tile1:
			continue
		if ingredients[2] != -2 and not ingredients[2] == tile2:
			continue
		var results = rule['results']
		return [results[1], results[2]]
	return [tile1, tile2]


func process_line(old_line):
	var line : String = old_line.strip_edges()
	
	var parts: PoolStringArray = line.split(" ", false)
	if line.length() < 1 or parts.size() < 1: #empty line
		return
	
	if parts.size() < 7:
		if parts[2] != ">":
			print("invalid rule: " + old_line)
		if not (names.has(parts[0]) and names.has(parts[1]) and names.has(parts[3]) and names.has(parts[4])):
			print("invalid name in rule: " + old_line)
		var rule = {'ingredients': {1: names[parts[0]], 2: names[parts[1]]}, 'results': {1: names[parts[3]], 2: names[parts[4]]}}
		rules.append(rule)

