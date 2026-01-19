extends Node2D

enum WallType { SMOOTH }
enum Mode { WALL, BOX, CIRCLE, OBJECT, FORCE }

@export var color_smooth: Color = Color.GRAY
@export var color_preview_smooth: Color = Color.WHITE
@export var color_box: Color = Color.STEEL_BLUE
@export var color_circle: Color = Color.DARK_GREEN
@export var color_selected: Color = Color.YELLOW
@export var color_force: Color = Color.RED
@export var color_contact_normal: Color = Color.CYAN

@export var wall_thickness: float = 3.0
@export var hatch_step: float = 10.0
@export var hatch_length: float = 5.0
@export var snap_distance: float = 15.0

@export var default_mass: float = 100.0
@export var gravity: float = 1.0
@export var contact_threshold: float = 10.0

@onready var wall_container = Node2D.new()
@onready var object_container = Node2D.new()

var current_mode: Mode = Mode.WALL
var is_drawing_wall := false
var is_grabbing := false
var is_rotating := false
var is_drawing_force := false

var wall_start := Vector2.ZERO
var wall_end := Vector2.ZERO
var grabbed_joint := Vector2.ZERO
var original_joint_pos := Vector2.ZERO
var current_wall_type := WallType.SMOOTH

var box_start := Vector2.ZERO
var circle_center := Vector2.ZERO
var selected_object = null
var force_start := Vector2.ZERO
var rotation_start_angle := 0.0

class WallData:
	var start: Vector2
	var end: Vector2
	var type: WallType
	var body: StaticBody2D

class RigidObject:
	var position: Vector2
	var rotation: float = 0.0
	var mass: float
	var is_box: bool
	var size: Vector2
	var body: Node2D
	var forces: Array[ForceData] = []
	var contacts: Array[ContactData] = []

class ForceData:
	var direction: Vector2
	var magnitude: float

class ContactData:
	var point: Vector2
	var normal: Vector2
	var wall: WallData

var walls: Array[WallData] = []
var objects: Array[RigidObject] = []

func _ready():
	add_child(wall_container)
	add_child(object_container)

func _input(event: InputEvent) -> void:
	var mouse_pos = get_global_mouse_position()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			current_mode = Mode.WALL
			clear_temp_state()
		elif event.keycode == KEY_B:
			current_mode = Mode.BOX
			clear_temp_state()
		elif event.keycode == KEY_C:
			current_mode = Mode.CIRCLE
			clear_temp_state()
		elif event.keycode == KEY_O:
			current_mode = Mode.OBJECT
			clear_temp_state()
		elif event.keycode == KEY_F:
			current_mode = Mode.FORCE
			clear_temp_state()
		
		if current_mode == Mode.OBJECT and selected_object:
			if event.keycode == KEY_M:
				prompt_mass_input()
			elif event.keycode == KEY_G:
				is_grabbing = true
				grabbed_joint = selected_object.position
				original_joint_pos = selected_object.position
			elif event.keycode == KEY_R:
				is_rotating = true
				rotation_start_angle = selected_object.rotation
				original_joint_pos = selected_object.position
		
		if event.keycode == KEY_ENTER:
			solve_system()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_left_click(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click(mouse_pos)

	if event is InputEventMouseMotion:
		handle_mouse_motion(mouse_pos)

func clear_temp_state():
	is_drawing_wall = false
	is_grabbing = false
	is_rotating = false
	is_drawing_force = false
	selected_object = null
	queue_redraw()

func handle_left_click(mouse_pos: Vector2):
	match current_mode:
		Mode.WALL:
			if not is_drawing_wall:
				is_drawing_wall = true
				wall_start = snap_to_joints(mouse_pos)
				wall_end = wall_start
			else:
				if wall_start.distance_to(wall_end) > 5:
					create_wall_object(wall_start, wall_end, current_wall_type)
				is_drawing_wall = false
		
		Mode.BOX:
			if not is_drawing_wall:
				is_drawing_wall = true
				box_start = mouse_pos
			else:
				var size = (mouse_pos - box_start).abs()
				if size.length() > 5:
					create_box(box_start, size)
				is_drawing_wall = false
		
		Mode.CIRCLE:
			if not is_drawing_wall:
				is_drawing_wall = true
				circle_center = mouse_pos
			else:
				var radius = circle_center.distance_to(mouse_pos)
				if radius > 5:
					create_circle(circle_center, radius)
				is_drawing_wall = false
		
		Mode.OBJECT:
			if is_grabbing:
				is_grabbing = false
			elif is_rotating:
				is_rotating = false
			else:
				selected_object = get_object_at(mouse_pos)
		
		Mode.FORCE:
			if not is_drawing_force:
				var obj = get_object_at(mouse_pos)
				if obj:
					selected_object = obj
					is_drawing_force = true
					force_start = obj.position
			else:
				var force_vec = mouse_pos - force_start
				if Input.is_key_pressed(KEY_ALT):
					force_vec = -force_vec
				if force_vec.length() > 5:
					var force = ForceData.new()
					force.direction = force_vec.normalized()
					force.magnitude = force_vec.length()
					selected_object.forces.append(force)
				is_drawing_force = false
				selected_object = null
	
	queue_redraw()

func handle_right_click(mouse_pos: Vector2):
	match current_mode:
		Mode.WALL:
			if is_drawing_wall:
				is_drawing_wall = false
			elif is_grabbing:
				update_grabbed_wall_joint(original_joint_pos)
				is_grabbing = false
			else:
				remove_wall_at(mouse_pos)
		
		Mode.BOX, Mode.CIRCLE:
			if is_drawing_wall:
				is_drawing_wall = false
		
		Mode.OBJECT:
			if is_grabbing:
				selected_object.position = original_joint_pos
				is_grabbing = false
			elif is_rotating:
				selected_object.rotation = rotation_start_angle
				is_rotating = false
			else:
				remove_object_at(mouse_pos)
		
		Mode.FORCE:
			if is_drawing_force:
				is_drawing_force = false
				selected_object = null
			else:
				remove_force_at(mouse_pos)
	
	queue_redraw()

func handle_mouse_motion(mouse_pos: Vector2):
	match current_mode:
		Mode.WALL:
			if is_drawing_wall:
				wall_end = snap_to_joints(mouse_pos)
				if Input.is_key_pressed(KEY_SHIFT):
					var diff = wall_end - wall_start
					if abs(diff.x) > abs(diff.y):
						wall_end.y = wall_start.y
					else:
						wall_end.x = wall_start.x
			elif is_grabbing:
				update_grabbed_wall_joint(mouse_pos)
		
		Mode.OBJECT:
			if is_grabbing and selected_object:
				selected_object.position = mouse_pos
				if not is_rotating:
					auto_snap_rotation(selected_object)
			elif is_rotating and selected_object:
				var current_angle = (mouse_pos - selected_object.position).angle()
				selected_object.rotation = current_angle
	
	queue_redraw()

func get_joint_at(pos: Vector2) -> Vector2:
	for w in walls:
		if pos.distance_to(w.start) < snap_distance:
			return w.start
		if pos.distance_to(w.end) < snap_distance:
			return w.end
	return Vector2.INF

func snap_to_joints(pos: Vector2) -> Vector2:
	var joint = get_joint_at(pos)
	if joint != Vector2.INF:
		return joint
	return pos

func update_grabbed_wall_joint(new_pos: Vector2):
	var target_pos = new_pos
	
	if Input.is_key_pressed(KEY_SHIFT):
		var reference_point = Vector2.INF
		for w in walls:
			if w.start == grabbed_joint: 
				reference_point = w.end
				break
			elif w.end == grabbed_joint: 
				reference_point = w.start
				break
		
		if reference_point != Vector2.INF:
			var diff = target_pos - reference_point
			if abs(diff.x) > abs(diff.y):
				target_pos.y = reference_point.y
			else:
				target_pos.x = reference_point.x

	for w in walls:
		if w.start == grabbed_joint:
			w.start = target_pos
		if w.end == grabbed_joint:
			w.end = target_pos
			
	grabbed_joint = target_pos

func remove_wall_at(pos: Vector2):
	var to_remove = -1
	for i in range(walls.size()):
		var w = walls[i]
		var dist = dist_to_segment(pos, w.start, w.end)
		if dist < 10.0:
			to_remove = i
			break
			
	if to_remove != -1:
		walls[to_remove].body.queue_free()
		walls.remove_at(to_remove)

func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = a.distance_to(b)
	if ab == 0: return p.distance_to(a)
	var t = max(0, min(1, (p - a).dot(b - a) / (ab * ab)))
	var projection = a + t * (b - a)
	return p.distance_to(projection)

func create_wall_object(p1: Vector2, p2: Vector2, type: WallType):
	var new_wall = WallData.new()
	new_wall.start = p1
	new_wall.end = p2
	new_wall.type = type
	
	var body = StaticBody2D.new()
	var col = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	
	shape.a = p1
	shape.b = p2
	col.shape = shape
	
	body.add_child(col)
	
	wall_container.add_child(body)
	new_wall.body = body
	walls.append(new_wall)

func create_box(corner: Vector2, size: Vector2):
	var obj = RigidObject.new()
	obj.is_box = true
	obj.position = corner + size / 2
	obj.size = size
	obj.mass = default_mass
	obj.rotation = 0.0
	
	var body = Node2D.new()
	body.position = obj.position
	body.rotation = obj.rotation
	object_container.add_child(body)
	obj.body = body
	
	objects.append(obj)

func create_circle(center: Vector2, radius: float):
	var obj = RigidObject.new()
	obj.is_box = false
	obj.position = center
	obj.size = Vector2(radius, radius)
	obj.mass = default_mass
	obj.rotation = 0.0
	
	var body = Node2D.new()
	body.position = obj.position
	object_container.add_child(body)
	obj.body = body
	
	objects.append(obj)

func auto_snap_rotation(obj: RigidObject):
	if not obj.is_box:
		return
	
	var closest_wall = null
	var min_dist = INF
	
	for wall in walls:
		var dist = dist_to_segment(obj.position, wall.start, wall.end)
		if dist < min_dist:
			min_dist = dist
			closest_wall = wall
	
	if closest_wall and min_dist < snap_distance:
		var wall_angle = (closest_wall.end - closest_wall.start).angle()
		obj.rotation = wall_angle

func get_object_at(pos: Vector2) -> RigidObject:
	for obj in objects:
		var check_dist = obj.size.x if not obj.is_box else obj.size.length() / 2
		if obj.position.distance_to(pos) < check_dist:
			return obj
	return null

func remove_object_at(pos: Vector2):
	var to_remove = -1
	for i in range(objects.size()):
		var obj = objects[i]
		var check_dist = obj.size.x if not obj.is_box else obj.size.length() / 2
		if obj.position.distance_to(pos) < check_dist:
			to_remove = i
			break
	
	if to_remove != -1:
		objects[to_remove].body.queue_free()
		objects.remove_at(to_remove)

func remove_force_at(pos: Vector2):
	for obj in objects:
		for i in range(obj.forces.size() - 1, -1, -1):
			var force = obj.forces[i]
			var force_end = obj.position + force.direction * force.magnitude
			var dist = dist_to_segment(pos, obj.position, force_end)
			if dist < 10.0:
				obj.forces.remove_at(i)
				return

func prompt_mass_input():
	if selected_object:
		print("Current mass: ", selected_object.mass, " kg")

func closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ap = p - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0:
		return a
	var t = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	return a + t * ab

func detect_contacts():
	for obj in objects:
		obj.contacts.clear()
		
		if obj.is_box:
			detect_box_contacts(obj)
		else:
			detect_circle_contacts(obj)

func detect_box_contacts(obj: RigidObject):
	var half = obj.size / 2
	var corners = [
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	]
	
	var world_corners = []
	for corner in corners:
		world_corners.append(obj.position + corner.rotated(obj.rotation))
	
	for wall in walls:
		var min_dist = INF
		var best_contact_point = Vector2.ZERO
		
		for i in range(4):
			var edge_start = world_corners[i]
			var edge_end = world_corners[(i + 1) % 4]
			
			for j in range(5):
				var t = j / 4.0
				var point_on_edge = edge_start.lerp(edge_end, t)
				var point_on_wall = closest_point_on_segment(point_on_edge, wall.start, wall.end)
				var dist = point_on_edge.distance_to(point_on_wall)
				
				if dist < min_dist:
					min_dist = dist
					best_contact_point = point_on_wall
		
		if min_dist < contact_threshold:
			var contact = ContactData.new()
			contact.point = best_contact_point
			contact.normal = (obj.position - best_contact_point).normalized()
			contact.wall = wall
			obj.contacts.append(contact)

func detect_circle_contacts(obj: RigidObject):
	var radius = obj.size.x
	
	for wall in walls:
		var point_on_wall = closest_point_on_segment(obj.position, wall.start, wall.end)
		var dist = obj.position.distance_to(point_on_wall)
		
		if abs(dist - radius) < contact_threshold:
			var contact = ContactData.new()
			contact.point = point_on_wall
			contact.normal = (obj.position - point_on_wall).normalized()
			contact.wall = wall
			obj.contacts.append(contact)

func solve_system():
	
	detect_contacts()
	
	var num_objects = objects.size()
	if num_objects == 0:
		print("No objects")
		return
	
	var total_contacts = 0
	for obj in objects:
		total_contacts += obj.contacts.size()
	
	var num_equations = num_objects * 2
	var num_unknowns = total_contacts
	
	print("Objects: ", num_objects)
	print("Contacts: ", total_contacts)
	print("Equations: ", num_equations, " Unknowns: ", num_unknowns)
	
	if num_equations != num_unknowns:
		print("ERROR: System cannot be solved (needs rotational equilibrium)")
		return
	
	if num_unknowns == 0:
		print("ERROR: No contacts detected")
		return
	
	var A = []
	for _i in range(num_equations):
		var row = []
		row.resize(num_unknowns)
		row.fill(0.0)
		A.append(row)
	
	var b = []
	b.resize(num_equations)
	b.fill(0.0)
	
	var contact_idx = 0
	var eq_idx = 0
	
	for obj in objects:
		var total_force = Vector2(0, obj.mass * gravity)
		for force in obj.forces:
			total_force += force.direction * force.magnitude
		
		for i in range(obj.contacts.size()):
			A[eq_idx][contact_idx + i] = obj.contacts[i].normal.x
		b[eq_idx] = -total_force.x
		eq_idx += 1
		
		for i in range(obj.contacts.size()):
			A[eq_idx][contact_idx + i] = obj.contacts[i].normal.y
		b[eq_idx] = -total_force.y
		eq_idx += 1
		
		contact_idx += obj.contacts.size()
	
	var solution = TrussMath.solve_system(A, b)
	
	if solution == null:
		print("ERROR: Failed to solve")
		return
	contact_idx = 0
	for i in range(objects.size()):
		var obj = objects[i]
		print("\nObject ", i)
		print("  Mass: ", obj.mass)
		for j in range(obj.contacts.size()):
			var force_mag = solution[contact_idx]
			print("  Contact ", j, ": ", force_mag)
			contact_idx += 1

func _draw():
	for w in walls:
		draw_wall_style(w.start, w.end, color_smooth, w.type)
	
	if current_mode == Mode.WALL and is_drawing_wall:
		draw_wall_style(wall_start, wall_end, color_preview_smooth, current_wall_type)
	
	for obj in objects:
		var color = color_box if obj.is_box else color_circle
		if obj == selected_object:
			color = color_selected
		
		if obj.is_box:
			var half = obj.size / 2
			var corners = [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y)
			]
			var rotated = []
			for c in corners:
				rotated.append(obj.position + c.rotated(obj.rotation))
			
			for i in range(4):
				draw_line(rotated[i], rotated[(i + 1) % 4], color, 2.0)
			draw_circle(obj.position, 3, color)
		else:
			draw_arc(obj.position, obj.size.x, 0, TAU, 32, color, 2.0)
			draw_circle(obj.position, 3, color)
		
		for force in obj.forces:
			var force_end = obj.position + force.direction * force.magnitude
			draw_line(obj.position, force_end, color_force, 2.0)
			draw_arrow_head(force_end, force.direction, color_force)
		
		for contact in obj.contacts:
			draw_line(contact.point, obj.position, color_contact_normal, 1.5)
			draw_circle(contact.point, 3, color_contact_normal)
	
	if current_mode == Mode.BOX and is_drawing_wall:
		var size = (get_global_mouse_position() - box_start).abs()
		var corners = [
			box_start,
			box_start + Vector2(size.x, 0),
			box_start + size,
			box_start + Vector2(0, size.y)
		]
		for i in range(4):
			draw_line(corners[i], corners[(i + 1) % 4], color_preview_smooth, 2.0)
	
	if current_mode == Mode.CIRCLE and is_drawing_wall:
		var radius = circle_center.distance_to(get_global_mouse_position())
		draw_arc(circle_center, radius, 0, TAU, 32, color_preview_smooth, 2.0)
	
	if current_mode == Mode.FORCE and is_drawing_force and selected_object:
		var mouse_pos = get_global_mouse_position()
		var force_vec = mouse_pos - force_start
		if Input.is_key_pressed(KEY_ALT):
			force_vec = -force_vec
		var force_end = force_start + force_vec
		draw_line(force_start, force_end, color_preview_smooth, 2.0)
		draw_arrow_head(force_end, force_vec.normalized(), color_preview_smooth)

func draw_wall_style(p1: Vector2, p2: Vector2, color: Color, _type: WallType):
	draw_line(p1, p2, color, wall_thickness)
	
	var dir = (p2 - p1).normalized()
	var normal = Vector2(-dir.y, dir.x)
	var length = p1.distance_to(p2)
	
	for i in range(0, int(length), int(hatch_step)):
		var s = p1 + dir * i
		var hatch_end = s + (normal + dir) * hatch_length
		draw_line(s, hatch_end, color, 1.0)

func draw_arrow_head(tip: Vector2, direction: Vector2, color: Color):
	var size = 8.0
	var angle = 0.5
	var left = tip - direction.rotated(angle) * size
	var right = tip - direction.rotated(-angle) * size
	draw_line(tip, left, color, 2.0)
	draw_line(tip, right, color, 2.0)
