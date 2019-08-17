extends Timer

func _ready():
	var p = get_parent()
	p.connect("become_active", self, "start_me")

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

func start_me():
	start()
