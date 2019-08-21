extends Node

var r_menu

func set_menu(menu) -> void:
	r_menu = menu

func get_options() -> Array:
	var options = []
	options.append(make_menu_option("back", "Back"))
	options.append(make_menu_option("get-crafting-book", "Get Crafting Manual"))
	return options

# close menu if return true
func handle_item_selected(value, extra) -> bool:
	match value:
		"back":
			return true
		"get-crafting-book":
			var player = get_tree().get_nodes_in_group("player")
			if len(player) < 1:
				print('couldnt find player to give book')
			player = player[0]
			if player.is_inventory_full():
				r_menu.add_text_popup("You can't carry any more", 'back', 1, true)
				return false
			
			var book_index = get_node("/root/Combinator").names['crafting_manual']
			player.call_deferred('pick_up', book_index)
			get_node("/root/UI").get_pause_screen().force_unpause()
	
	return false



func make_menu_option(value, text : String) -> Dictionary:
	return {'value': value, 'text': text}