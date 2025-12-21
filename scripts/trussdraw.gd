extends Node2D

var start_point: Vector2
var end_point: Vector2
var is_drawing: = false
var line_data = []
@export var line_width: float = 20.0
@export var line_thickness: float = 5.0
@export var line_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_drawing == false:
				start_point = event.position
				is_drawing = true
			else:
				end_point = event.position
				line_data.append([start_point, end_point])
				is_drawing = false
				queue_redraw()

func draw_truss(p1: Vector2, p2: Vector2):
	var total_width = line_thickness + line_width
	var border_radius = total_width/2
	var truss_radius = line_width/2
	draw_line(p1, p2, border_color,total_width)
	draw_circle(p1,border_radius, border_color)
	draw_circle(p2,border_radius, border_color)
	draw_line(p1, p2, line_color,line_width)
	draw_circle(p1,truss_radius, line_color)
	draw_circle(p2,truss_radius, line_color)

func _draw() -> void:
	for i in line_data:
		draw_truss(i[0],i[1])
	if is_drawing == true:
		var mouse_pos = get_global_mouse_position()
		draw_truss(start_point, mouse_pos)
func _process(_delta: float) -> void:
	queue_redraw()
