extends HBoxContainer

signal selected(item, extra)
signal mouse_entered_item(item)

var value = ''

var extra = 1

var is_current = false

var click_focus = false

var r_cursor

var min_extra = 0
var max_extra = 100
var step = 0

var repeat_wait = false

func _ready():
	r_cursor = find_node('Cursor')

func get_value() -> String:
	return value

func set_range(min_v : int, max_v : int) -> void:
	min_extra = min_v
	max_extra = max_v
	$HSlider.set_min(min_v)
	$HSlider.set_max(max_v)

func set_step(new_step : float) -> void:
	step = new_step
	$HSlider.set_step(step)

func set_value(val : String) -> void:
	value = val

func set_extra(new_extra) -> void:
	var old_extra = extra
	
	extra = new_extra
	if extra < min_extra:
		extra = min_extra
	if extra > max_extra:
		extra = max_extra
	
	if old_extra == extra:
		return
	
	$HSlider.value = extra

func get_extra():
	return extra

func set_label(text : String) -> void:
	$Label.text = text

func set_active() -> void:
	is_current = true
	r_cursor.visible = true

func select() -> void:
	emit_signal("selected", value, extra)

func set_inactive() -> void:
	is_current = false
	r_cursor.visible = false

func is_active() -> bool:
	return is_current

func _process(delta) -> void:
	if not is_current:
		return
	
	var amount = step if step > 0 else 0.5 
	if Input.is_action_pressed("move_right"):
		repeat_wait = true
		set_extra(extra + amount)
		select()
	if Input.is_action_pressed("move_left"):
		repeat_wait = true
		extra -= amount
		set_extra(extra - amount)
		select()

func _on_MenuItem_mouse_entered():
	emit_signal("mouse_entered_item", self)


func _on_HSlider_value_changed(value):
	set_extra(value)
	select()


func _on_RepeatTimer_timeout():
	repeat_wait = false
