extends Control

var active = false

var quick_mode = false

var wait_a_bit = false

func show_me() -> bool:
	var can_pause = get_node("/root/GlobalData").get_pause_focus('goal-popup')
	if not can_pause:
		return false
	active = true
	visible = true
	get_tree().paused = true
	wait_a_bit = true
	return true

func set_job_goal(new_tilemap : TileMap) -> void:
	for c in get_children():
		if c is TileMap:
			c.queue_free()
	new_tilemap.get_parent().remove_child(new_tilemap)
	add_child(new_tilemap)
	new_tilemap.set_owner(self)
	new_tilemap.visible = true

func show_quick():
	if show_me():
		quick_mode = true

func hide():
	active = false
	visible = false
	get_tree().paused = false
	#find_parent("Root").find_node("Player").hide_map_popup()
	get_node("/root/GlobalData").release_pause_focus('goal-popup')


# warning-ignore:unused_argument
func _process(delta):
	if not active:
		if Input.is_action_pressed("action_quick_job_view"):
			if get_node("/root/GlobalData").is_at_job():
				show_quick()
		return
	if quick_mode:
		if not Input.is_action_pressed("action_quick_job_view"):
			call_deferred('hide')
	if wait_a_bit:
		wait_a_bit = false
	elif Input.is_action_just_pressed("action_dismiss"):
		call_deferred('hide')