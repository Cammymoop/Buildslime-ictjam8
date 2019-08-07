extends Panel


func show_screenshot(name : String):
	get_node("SaveFileScreen/SaveFileScreenVP").show_screenshot(name)