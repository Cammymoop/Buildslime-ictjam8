extends CanvasLayer

func get_pause_screen() -> Node:
	return get_node("ThemeMaster/PauseScreen")

func set_popup_goal(tilemap : TileMap) -> void:
	get_node("ThemeMaster/MapPopup").set_job_goal(tilemap)

func show_popup_goal() -> void:
	get_node("ThemeMaster/MapPopup").show_me()