extends TextureRect

var showing = true

func _ready():
	find_parent("LogoContainer").visible = true
	if OS.has_feature('debug'):
		hide()
		$Timer.stop()

func _on_Timer_timeout():
	hide()

func hide():
	find_parent("LogoContainer").visible = false
	showing = false
	set_process(false)

# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed("action_grab") or Input.is_action_just_pressed("action_menu_open"):
		hide()
		$Timer.stop()
