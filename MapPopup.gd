extends Node2D

var active = false

func show():
	active = true
	visible = true
	find_parent("Root").find_node("PanelBG").visible = true
	get_tree().paused = true

func hide():
	active = false
	visible = false
	find_parent("Root").find_node("PanelBG").visible = false
	get_tree().paused = false
	find_parent("Root").find_node("Player").hide_map_popup()


func _process(delta):
	if not active:
		return
	if Input.is_action_just_pressed("action_dismiss"):
		call_deferred('hide')