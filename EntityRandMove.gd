extends Timer

func _ready():
	get_parent().spawn(find_parent("Root").find_node("HomeMap"))

func _on_Timer_timeout():
	var rand = randi() % 4
	var entity = get_parent()
	match rand:
		0:
			entity.standard_move('up')
		1:
			entity.standard_move('down')
		2:
			entity.standard_move('left')
		3:
			entity.standard_move('right')
