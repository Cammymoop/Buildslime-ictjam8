extends Node2D

var active = false

var quick_mode = false

func show():
	active = true
	visible = true
	find_parent("Root").find_node("PanelBG").visible = true
	get_tree().paused = true

func show_quick():
	show()
	quick_mode = true

func hide():
	active = false
	visible = false
	find_parent("Root").find_node("PanelBG").visible = false
	get_tree().paused = false
	find_parent("Root").find_node("Player").hide_map_popup()


# warning-ignore:unused_argument
func _process(delta):
	if not active:
		return
	if quick_mode:
		if not Input.is_action_pressed("action_quick_job_view"):
			call_deferred('hide')
	elif Input.is_action_just_pressed("action_dismiss"):
		call_deferred('hide')