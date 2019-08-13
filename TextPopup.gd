extends PanelContainer

export (Theme) var default_theme = preload("res://assets/ui/UITheme.tres")
export (Theme) var error_theme = preload("res://assets/ui/UITheme_Red.tres")

signal selected(item, extra)
signal dismissed

var value = ''
var extra = -1

var wait_a_bit = false

func show_text(text : String, v = '', e = -1, error : bool = false):
	value = v
	extra = e
	$Label.text = text
	theme = error_theme if error else default_theme
	wait_a_bit = true

func close() -> void:
	queue_free()

# warning-ignore:unused_argument
func _process(delta):
	if wait_a_bit:
		wait_a_bit = false
		return
	if Input.is_action_just_pressed("action_dismiss"):
		emit_signal("dismissed")
		emit_signal("selected", value, extra)
		close()