extends Node2D

@export var config: TrussConfig
@onready var renderer = $Renderer
@onready var input_manager = TrussInputManager.new()

enum Mode { DRAW_MEMBERS, ADD_SUPPORTS, ADD_FORCES, SOLVED}
var current_mode: = Mode.DRAW_MEMBERS

enum SupportType {NONE, PIN_X, PIN_X_NEG, PIN_Y, PIN_Y_NEG, ROLLER_X, ROLLER_X_NEG, ROLLER_Y, ROLLER_Y_NEG}
var node_supports = {}
var node_loads = {}
var member_forces = {}
var reaction_forces = {}

var force_start_nodes: Vector2
var is_drawing_forces:= false

var start_point: Vector2
var end_point: Vector2
var grabbed_point: Vector2
var original_point: Vector2
var is_drawing: = false
var is_grabbing: = false
var line_data: Array[TrussMember] = []

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M: 
			current_mode = Mode.DRAW_MEMBERS
		if event.keycode == KEY_S: 
			current_mode = Mode.ADD_SUPPORTS
		if event.keycode == KEY_F: 
			current_mode = Mode.ADD_FORCES
		if event.keycode == KEY_ENTER: solve_truss()
	
	match current_mode:
		Mode.DRAW_MEMBERS:
			input_manager.handle_member_drawing(event)
		Mode.ADD_SUPPORTS:
			input_manager.handle_support_logic(event)
		Mode.ADD_FORCES:
			input_manager.handle_force_logic(event)
		Mode.SOLVED:
			if event is InputEventMouseButton and event.pressed:
				current_mode = Mode.DRAW_MEMBERS
				member_forces.clear()
				renderer.queue_redraw()

func draw_truss(p1: Vector2, p2: Vector2, truss_color: Color):
	var total_width = config.line_thickness + config.line_width
	var border_radius = total_width/2
	var truss_radius = config.line_width/2
	draw_line(p1, p2, config.border_color,total_width)
	draw_circle(p1,border_radius, config.border_color)
	draw_circle(p2,border_radius, config.border_color)
	draw_line(p1, p2, truss_color,config.line_width)
	draw_circle(p1,truss_radius, truss_color)
	draw_circle(p2,truss_radius, truss_color)
	draw_circle(p1,4, config.border_color)
	draw_circle(p2,4, config.border_color)

func draw_force(from: Vector2, to: Vector2, force_color: Color):
	if from.distance_to(to) < 5:
		return
	var dir = (to-from).normalized()
	var side = dir.rotated(PI/2)*10
	var b_side = dir.rotated(PI/2)*15
	draw_line(from,to,config.border_color,3.0+config.line_thickness)
	draw_circle(from,(3.0+config.line_thickness)/2,config.border_color,true)
	draw_primitive([to, to -dir*15 + b_side, to -dir*15-b_side],[config.border_color],[])
	draw_line(from,to,force_color,3.0)
	draw_circle(from,3.0/2,force_color,true)
	draw_primitive([to, to -dir*15 + side, to -dir*15-side],[force_color],[])

func apply_shift_lock(origin: Vector2, target: Vector2) -> Vector2:
	var diff_x = abs(target.x - origin.x)
	var diff_y = abs(target.y - origin.y)
	if diff_x > diff_y:
		return Vector2(target.x, origin.y)
	else:
		return Vector2(origin.x, target.y)

func best_pos(p: Vector2) -> Vector2:
	for member in line_data:
		if p.distance_to(member.start) < config.snap_radius:
			return member.start
		if p.distance_to(member.end) < config.snap_radius:
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

func get_unique_nodes():
	var points = []
	for m in line_data:
		if not points.has(m.start):
			points.append(m.start)
		if not points.has(m.end):
			points.append(m.end)
	return points

func solve_truss():
	var nodes = get_unique_nodes()
	var results = TrussSolver.run_calculation(line_data, node_supports, node_loads, nodes)
	
	if results:
		print("Truss System is solved!")
		member_forces.clear()
		
		for i in range(line_data.size()):
			var force_val = results[i]
			member_forces[line_data[i]] = force_val
			var type_label: String
			if force_val > 0.01:
				type_label = "T"
			else:
				type_label = "C"
			if abs(force_val) < 0.01:
				type_label = "Zero"
			print("  Member %d: %0.2f [%s]" % [i, force_val, type_label])

		var reaction_idx = line_data.size()
		for node_pos in node_supports:
			var type = node_supports[node_pos]
			match type:
				SupportType.PIN_X, SupportType.PIN_X_NEG, SupportType.PIN_Y, SupportType.PIN_Y_NEG:
					var rx = results[reaction_idx]
					var ry = results[reaction_idx+1]
					print("  Node %s: Rx = %0.2f, Ry = %0.2f" % [node_pos, rx, ry])
					reaction_idx += 2
				SupportType.ROLLER_X, SupportType.ROLLER_X_NEG:
					var ry = results[reaction_idx]
					print("  Node %s: Ry = %0.2f" % [node_pos, ry])
					reaction_idx += 1
				SupportType.ROLLER_Y, SupportType.ROLLER_Y_NEG:
					var rx = results[reaction_idx]
					print("  Node %s: Rx = %0.2f" % [node_pos, rx])
					reaction_idx += 1
		current_mode = Mode.SOLVED
	else:
		print("Some Error Occured")
	renderer.queue_redraw()


func draw_support_icon(pos: Vector2, type: SupportType):
	var size = 15.0
	var color = Color.GREEN
	match type:
		SupportType.PIN_X:
			draw_support_triangle(pos, Vector2(0, size*1.5),color)
		SupportType.PIN_X_NEG:
			draw_support_triangle(pos,Vector2(0,-size*1.5), color)
		SupportType.PIN_Y:
			draw_support_triangle(pos, Vector2(size*1.5,0), color)
		SupportType.PIN_Y_NEG:
			draw_support_triangle(pos, Vector2(-size*1.5,0), color)
		SupportType.ROLLER_X:
			draw_support_triangle(pos, Vector2(0,size), color)
			draw_circle(pos + Vector2(-size/2 ,size +5),4, color)
			draw_circle(pos + Vector2(size/2 ,size +5),4, color)
		SupportType.ROLLER_X_NEG:
			draw_support_triangle(pos, Vector2(0,-size), color)
			draw_circle(pos + Vector2(-size/2 ,-size -5),4, color)
			draw_circle(pos + Vector2(size/2 ,-size -5),4, color)
		SupportType.ROLLER_Y:
			draw_support_triangle(pos, Vector2(size,0), color)
			draw_circle(pos + Vector2(size +5, -size/2),4, color)
			draw_circle(pos + Vector2(size +5, size/2),4, color)
		SupportType.ROLLER_Y_NEG:
			draw_support_triangle(pos, Vector2(-size,0), color)
			draw_circle(pos + Vector2(-size -5, -size/2),4, color)
			draw_circle(pos + Vector2(-size -5, size/2),4, color)

func draw_support_triangle(center: Vector2, offset: Vector2, color: Color):
	var side = offset.rotated(PI/2).normalized() * 15.0
	var p1 = center
	var p2 = center + offset - side
	var p3 = center + offset + side
	draw_colored_polygon([p1,p2,p3], color)

func _process(_delta: float) -> void:
	renderer.queue_redraw()
