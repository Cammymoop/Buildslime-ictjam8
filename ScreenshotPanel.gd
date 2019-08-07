extends Panel

func reset():
	get_node("SaveFileScreen/SaveFileScreenVP").reset()

func show_screenshot(name : String):
	get_node("SaveFileScreen/SaveFileScreenVP").show_screenshot(name)