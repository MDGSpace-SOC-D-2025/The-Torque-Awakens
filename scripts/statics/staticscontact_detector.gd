class_name ContactDetector

var main: Node2D

func setup(m: Node2D):
	main = m

func detect_all_contacts():
	for obj in main.objects:
		obj.contacts.clear()
		_detect_per_wall(obj)

func _detect_per_wall(obj: RigidObject):
	var space_state = main.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	if obj.is_box:
		var rect = RectangleShape2D.new()
		rect.size = obj.size
		query.shape = rect
	else:
		var circle = CircleShape2D.new()
		circle.radius = obj.size.x
		query.shape = circle
	
	query.transform = Transform2D(obj.rotation, obj.position)
	query.collision_mask = 1 
	query.margin = 1.5

	var intersections = space_state.intersect_shape(query, 32)
	
	for res in intersections:
		var wall_body = res.collider
		var wall_data: WallData = null
		
		for w in main.walls:
			if w.body == wall_body:
				wall_data = w
				break
		
		if wall_data:
			var wall_shape_owner = wall_body.get_shape_owners()[0]
			var wall_shape = wall_body.shape_owner_get_shape(wall_shape_owner, 0)
			
			var collision_points = query.shape.collide_and_get_contacts(
				query.transform, 
				wall_shape, 
				wall_body.global_transform
			)
			
			if collision_points.size() > 0:
				var avg_p := Vector2.ZERO
				for p in collision_points:
					avg_p += p
				avg_p /= collision_points.size()
				
				var contact = ContactData.new()
				contact.point = avg_p
				
				var to_obj = (obj.position - avg_p).normalized()
				if obj.is_box:
					var wall_rot = wall_body.global_rotation
					var wall_normal = Vector2.UP.rotated(wall_rot)
					if wall_normal.dot(to_obj) < 0:
						wall_normal *= -1
					contact.normal = wall_normal
				else:
					contact.normal = to_obj
					
				contact.wall = wall_data
				obj.contacts.append(contact)
