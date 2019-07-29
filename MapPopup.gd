extends Node2D

func show():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = true
	find_parent("Root").find_node("PanelBG").visible = true
	get_tree().paused = true

func _process(delta):
	if Input.is_action_just_pressed("action_grab"):
		pause_mode = Node.PAUSE_MODE_STOP
		visible = false
		find_parent("Root").find_node("PanelBG").visible = false
		get_tree().paused = false
		find_parent("Root").find_node("Player").hide_map_popup()