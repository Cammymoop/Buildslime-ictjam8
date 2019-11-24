extends VBoxContainer

func set_selected(selected : bool) -> void:
	if selected:
		modulate = Color(1, 1, 1, 1)
		$Underline.visible = true
	else:
		modulate = Color(0.45, 0.45, 0.45, 1)
		$Underline.visible = false
