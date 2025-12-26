extends Node2D

class TrussMember extends RefCounted:
	var start: Vector2
	var end: Vector2
	func _init(p1: Vector2, p2: Vector2):
		start = p1
		end = p2
	func has_point(p: Vector2):
		return (start == p) or (end == p)
	func matches(p1: Vector2, p2: Vector2):
		return (start == p1 and end == p2) or (start == p2 and end == p1)
	
var start_point: Vector2
var end_point: Vector2
var grabbed_point: Vector2
var original_point: Vector2
var is_drawing: = false
var is_grabbing: = false
var line_data: Array[TrussMember] = []
@export var line_width: float = 20.0
@export var line_thickness: float = 5.0
@export var line_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var snap_radius: float = 25.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if (is_drawing == false):
				start_point = best_pos(event.position)
				is_drawing = true
			else:
				end_point = best_pos(event.position)
				if event.shift_pressed:
					end_point = apply_shift_lock(start_point, end_point)
					end_point = best_pos(end_point)
				if (end_point != start_point) and not_exists(start_point, end_point):
					line_data.append(TrussMember.new(start_point, end_point))
				is_drawing = false
				is_grabbing = false
				queue_redraw()
				
		if  event.button_index == MOUSE_BUTTON_RIGHT:
			line_data = line_data.filter(func(member):
				if member.has_point(best_pos(event.position)):
					return false
				else:
					return true
				)
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		var mouse_pos = get_viewport().get_mouse_position()
		if mouse_pos.distance_to(best_pos(mouse_pos)) < snap_radius:
			is_drawing = false
			is_grabbing = true
			grabbed_point = best_pos(mouse_pos)
			original_point = best_pos(mouse_pos)
	if is_grabbing:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				update_grabbed_point(best_pos(get_viewport().get_mouse_position()))
				line_data = line_data.filter(func(line):
					return line.start != line.end)
				is_grabbing = false
				is_drawing = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				update_grabbed_point(best_pos(original_point))
				is_drawing = false
				is_grabbing = false
	if is_drawing:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			is_drawing = false
	if is_grabbing and event is InputEventMouseMotion:
		var raw_mouse = event.position
		var snap_pos = raw_mouse
		for member in line_data:
			if member.start != grabbed_point and raw_mouse.distance_to(member.start) < snap_radius:
				snap_pos = member.start
				break
			if member.end != grabbed_point and raw_mouse.distance_to(member.end) < snap_radius:
				snap_pos = member.end
				break
		update_grabbed_point(snap_pos)
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
	draw_circle(p1,4, border_color)
	draw_circle(p2,4, border_color)
	
func apply_shift_lock(origin: Vector2, target: Vector2) -> Vector2:
	var diff_x = abs(target.x - origin.x)
	var diff_y = abs(target.y - origin.y)
	if diff_x > diff_y:
		return Vector2(target.x, origin.y)
	else:
		return Vector2(origin.x, target.y)

func best_pos(p: Vector2) -> Vector2:
	for member in line_data:
		if p.distance_to(member.start) < snap_radius:
			return member.start
		if p.distance_to(member.end) < snap_radius:
			return member.end
	return p

func not_exists(p1: Vector2, p2: Vector2):
	for member in line_data:
		if member.matches(p1  ,p2):
			return false
	return true
	
func update_grabbed_point(new_pos: Vector2):
	for member in  line_data:
		if member.start == grabbed_point:
			member.start = new_pos
		if member.end == grabbed_point:
			member.end = new_pos
	grabbed_point = new_pos

func _draw() -> void:
	for member in line_data:
		draw_truss(member.start,member.end)
	if is_drawing:
		var mouse_pos = best_pos(get_viewport().get_mouse_position())
		if Input.is_key_pressed(KEY_SHIFT):
			mouse_pos = apply_shift_lock(start_point, mouse_pos)
		draw_truss(start_point, mouse_pos)

func _process(_delta: float) -> void:
	queue_redraw()
