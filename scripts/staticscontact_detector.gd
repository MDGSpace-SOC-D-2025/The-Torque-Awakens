class_name ContactDetector

var main: Node2D

func setup(m: Node2D):
	main = m

func detect_all_contacts():
	for obj in main.objects:
		obj.contacts.clear()
		
		if obj.is_box:
			_detect_box_contacts(obj)
		else:
			_detect_circle_contacts(obj)

func _detect_box_contacts(obj: RigidObject):
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
	
	for wall in main.walls:
		var min_dist = INF
		var best_contact_point = Vector2.ZERO
		
		for i in range(4):
			var edge_start = world_corners[i]
			var edge_end = world_corners[(i + 1) % 4]
			
			for j in range(5):
				var t = j / 4.0
				var point_on_edge = edge_start.lerp(edge_end, t)
				var point_on_wall = _closest_point_on_segment(point_on_edge, wall.start, wall.end)
				var dist = point_on_edge.distance_to(point_on_wall)
				
				if dist < min_dist:
					min_dist = dist
					best_contact_point = point_on_wall
		
		if min_dist < main.contact_threshold:
			var contact = ContactData.new()
			contact.point = best_contact_point
			contact.normal = (obj.position - best_contact_point).normalized()
			contact.wall = wall
			obj.contacts.append(contact)

func _detect_circle_contacts(obj: RigidObject):
	var radius = obj.size.x
	
	for wall in main.walls:
		var point_on_wall = _closest_point_on_segment(obj.position, wall.start, wall.end)
		var dist = obj.position.distance_to(point_on_wall)
		
		if abs(dist - radius) < main.contact_threshold:
			var contact = ContactData.new()
			contact.point = point_on_wall
			contact.normal = (obj.position - point_on_wall).normalized()
			contact.wall = wall
			obj.contacts.append(contact)

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ap = p - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0:
		return a
	var t = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	return a + t * ab
