extends MarginContainer

var focus_color = '485454'
var unfocus_color = '000000'

var r_menu

func set_menu(menu):
	r_menu = menu

func focus():
	$BGColor.color = Color(focus_color)

func unfocus():
	$BGColor.color = Color(unfocus_color)

func _on_LeftFile_mouse_entered():
	r_menu.focus_me(self)
