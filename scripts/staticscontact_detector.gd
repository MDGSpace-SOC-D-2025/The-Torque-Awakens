class_name ContactDetector

var main: Node2D

func setup(m: Node2D):
	main = m

func detect_all_contacts():
	for obj in main.objects:
		obj.contacts.clear()
		_detect_with_shapecast(obj)

func _detect_with_shapecast(obj: RigidObject):
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
	query.margin = 1.0 

	var intersections = space_state.intersect_shape(query, 32)
	
	for res in intersections:
		var wall_body = res.collider
		var wall_data: WallData = null
		
		for w in main.walls:
			if w.body == wall_body:
				wall_data = w
				break
		
		if wall_data:
			var rest_info = wall_body.get_shape_owners()[0] # Get wall shape
			var wall_shape = wall_body.shape_owner_get_shape(rest_info, 0)
			
			var collision_points = query.shape.collide_and_get_contacts(
				query.transform, 
				wall_shape, 
				wall_body.global_transform
			)
			
			if collision_points.size() > 0:
				var avg_p := Vector2.ZERO
				var avg_n := Vector2.ZERO
				
				for p in collision_points:
					avg_p += p
				
				avg_p /= collision_points.size()
				avg_n = (obj.position - avg_p).normalized()
				
				var contact = ContactData.new()
				contact.point = avg_p
				contact.normal = avg_n
				contact.wall = wall_data
				obj.contacts.append(contact)
