extends Node2D

var active = false

var quick_mode = false

var wait_a_bit = false

func show():
	var can_pause = get_node("/root/GlobalData").get_pause_focus('goal-popup')
	if not can_pause:
		return
	active = true
	visible = true
	find_parent("Root").find_node("PanelBG").visible = true
	get_tree().paused = true
	wait_a_bit = true

func show_quick():
	show()
	quick_mode = true

func hide():
	active = false
	visible = false
	find_parent("Root").find_node("PanelBG").visible = false
	get_tree().paused = false
	find_parent("Root").find_node("Player").hide_map_popup()
	get_node("/root/GlobalData").release_pause_focus('goal-popup')


# warning-ignore:unused_argument
func _process(delta):
	if not active:
		return
	if quick_mode:
		if not Input.is_action_pressed("action_quick_job_view"):
			call_deferred('hide')
	if wait_a_bit:
		wait_a_bit = false
	elif Input.is_action_just_pressed("action_dismiss"):
		call_deferred('hide')