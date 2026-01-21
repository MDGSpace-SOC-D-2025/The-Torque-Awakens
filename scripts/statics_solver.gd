class_name StaticsSolver

var main: Node2D

func setup(m: Node2D):
	main = m

func solve():
	
	var num_objects = main.objects.size()
	if num_objects == 0:
		print("No objects")
		return
	
	var total_contacts = 0
	for obj in main.objects:
		total_contacts += obj.contacts.size()
	
	var num_equations = num_objects * 2
	var num_unknowns = total_contacts
	
	print("Objects: ", num_objects)
	print("Contacts: ", total_contacts)
	print("Equations: ", num_equations, " Unknowns: ", num_unknowns)
	
	if num_equations != num_unknowns:
		print("ERROR: System cannot be solved")
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
	
	for obj in main.objects:
		var total_force = Vector2(0, obj.mass * main.gravity)
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
	for i in range(main.objects.size()):
		var obj = main.objects[i]
		print("\nObject ", i)
		print("  Mass: ", obj.mass)
		for j in range(obj.contacts.size()):
			var force_mag = solution[contact_idx]
			print("  Contact ", j, ": ", force_mag)
			contact_idx += 1
