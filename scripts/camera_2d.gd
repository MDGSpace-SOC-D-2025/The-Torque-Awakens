extends Camera2D

@export var zoom_sensitivity: float = 1.1
@export var pan_speed: float = 1.0
@export var min_zoom: float = 0.1
@export var max_zoom: float = 10.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative * zoom * pan_speed
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_to_mouse(zoom_sensitivity)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_to_mouse(1.0/zoom_sensitivity)

func zoom_to_mouse(factor: float):
	var old_zoom = zoom
	var new_zoom_val = clamp(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2.ONE * new_zoom_val
	
	var mouse_pos = get_local_mouse_position()
	var zoom_diff = old_zoom - zoom
	position += mouse_pos * zoom_diff
