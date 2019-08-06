extends Control

func _ready():
	var lf = find_node('LeftFile')
	
	lf.find_node('BGColor').color = Color('485454')

func scroll_left():
	print('scroll left')

func scroll_right():
	print('scroll right')
