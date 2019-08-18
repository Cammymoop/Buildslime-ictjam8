extends Camera2D

func set_world_cam_bounds(bounds : Rect2) -> void:
	limit_left = int(bounds.position.x + 2)
	limit_top = int(bounds.position.y + 2)
	limit_right = int(bounds.position.x + bounds.size.x - 2)
	limit_bottom = int(bounds.position.y + bounds.size.y - 2)