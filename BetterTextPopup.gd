extends PanelContainer

export (Theme) var error_theme = preload("res://assets/ui/UITheme_Red.tres")

signal selected(item, extra)
signal dismissed

var tile_control_scn : PackedScene = preload("res://TileControl.tscn")

# for menu selcting
var value = ''
var extra = -1

var wait_a_bit = false

func clear_text():
	for child in $Lines.get_children():
		child.queue_free()

func set_menu_val(v, e) -> void:
	value = v
	extra = e

func show_text(text : String, error : bool = false) -> void:
	clear_text()
	if error:
		theme = error_theme
	
	var lines = text.split('\n')
	
	for l in lines:
		var line : = l as String
		var container = HBoxContainer.new()
		var string_pos = 0
		
		var found_pos = line.find(':tile.', string_pos)
		while found_pos != -1:
			# text before the next tile control
			if string_pos < found_pos:
				var label = Label.new()
				label.text = line.substr(string_pos, found_pos - string_pos)
				container.add_child(label)
			
			# ignore 6 characters before (":tile.") to get the tile number which goes until the next ":"
			string_pos = found_pos + 6
			var tile_index_length = line.find(':', string_pos) - string_pos
			var tile_index = int(line.substr(string_pos, tile_index_length))
			var tile_control = tile_control_scn.instance()
			tile_control.set_tile(tile_index)
			container.add_child(tile_control)
			string_pos += tile_index_length + 1
			
			#loop again
			found_pos = line.find(':tile.', string_pos)
		
		# text after the last tile control
		if string_pos < len(line) - 1:
			var label = Label.new()
			label.text = line.substr(string_pos, len(line) - string_pos)
			container.add_child(label)
		$Lines.add_child(container)
		
func close() -> void:
	queue_free()

func dismiss() -> void:
		emit_signal("dismissed")
		emit_signal("selected", value, extra)
		close()

# warning-ignore:unused_argument
func _process(delta):
	if wait_a_bit:
		wait_a_bit = false
		return
	if Input.is_action_just_pressed("action_dismiss"):
		call_deferred('dismiss')