class_name StaticsSolver

var main: Node2D
var contact_results = {}
var stability_info = {}
var is_solved: = false

func setup(m: Node2D):
	main = m

func solve():
	contact_results.clear()
	stability_info.clear()
	
	var num_objects = main.objects.size()
	if num_objects == 0: return
	
	var total_contacts = 0
	for obj in main.objects:
		total_contacts += obj.contacts.size()
	
	if total_contacts == 0: return

	var num_eq = num_objects * 3
	var num_vars = total_contacts
	
	var A = []
	for _i in range(num_eq):
		var row = []
		row.resize(num_vars)
		row.fill(0.0)
		A.append(row)
	
	var b = []
	b.resize(num_eq)
	b.fill(0.0)
	
	var var_idx = 0
	var eq_idx = 0
	
	for obj in main.objects:
		var ext_f = Vector2(0, obj.mass * main.gravity)
		var ext_m = 0.0
		
		for force in obj.forces:
			ext_f += force.direction * force.magnitude
		
		for i in range(obj.contacts.size()):
			var c = obj.contacts[i]
			var r = c.point - obj.position
			
			A[eq_idx][var_idx + i] = c.normal.x
			A[eq_idx + 1][var_idx + i] = c.normal.y
			A[eq_idx + 2][var_idx + i] = r.cross(c.normal)
		
		b[eq_idx] = -ext_f.x
		b[eq_idx + 1] = -ext_f.y
		b[eq_idx + 2] = -ext_m
		
		var solution = _solve_least_squares(A, b)
		
		if solution:
			var res_x = 0.0
			var res_y = 0.0
			var res_m = 0.0
			
			for j in range(num_vars):
				res_x += A[eq_idx][j] * solution[j]
				res_y += A[eq_idx + 1][j] * solution[j]
				res_m += A[eq_idx + 2][j] * solution[j]
			
			var error = Vector3(res_x - b[eq_idx], res_y - b[eq_idx+1], res_m - b[eq_idx+2]).length()
			stability_info[obj] = error

			for i in range(obj.contacts.size()):
				var mag = solution[var_idx + i]
				if mag < 0: mag = 0.0
				contact_results[obj.contacts[i]] = mag
		
		eq_idx += 3
		var_idx += obj.contacts.size()
	
	is_solved = true
	if main.has_method("queue_redraw"):
		main.queue_redraw()

func draw_results(canvas: Node2D):
	if not is_solved: return

	var font = preload("res://assets/JosefinSans-Bold.ttf")
	var font_size = 14
	var golden = Color.GOLD
	
	for contact in contact_results:
		var mag = contact_results[contact]
		var label = "Fn: %.1f" % mag
		var offset_pos = contact.point + (contact.normal * 25.0)
		canvas.draw_string(font, offset_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, golden)

	for obj in stability_info:
		var err = stability_info[obj]
		var status = "STABLE" if err <= 0.5 else "UNSTABLE (Err: %.2f)" % err
		
		var v_offset = 40.0
		if obj.is_box == true: 
			v_offset = (obj.size.y / 2.0) + 25.0
		else: 
			v_offset = obj.size.x + 25.0
			
		canvas.draw_string(font, obj.position + Vector2(0, v_offset), status, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, golden)

func clear_results():
	contact_results.clear()
	stability_info.clear()
	is_solved = false
	if main.has_method("queue_redraw"):
		main.queue_redraw()

func _solve_least_squares(A: Array, b: Array) -> Array:
	var AT = _transpose(A)
	var ATA = _multiply_matrices(AT, A)
	var ATb = _multiply_matrix_vector(AT, b)
	var lambda = 0.0001
	for i in range(ATA.size()):
		ATA[i][i] += lambda
	return TrussMath.solve_system(ATA, ATb)

func _transpose(m: Array) -> Array:
	var res = []
	for j in range(m[0].size()):
		var row = []
		for i in range(m.size()):
			row.append(m[i][j])
		res.append(row)
	return res

func _multiply_matrices(m1: Array, m2: Array) -> Array:
	var res = []
	for i in range(m1.size()):
		var row = []
		for j in range(m2[0].size()):
			var s = 0.0
			for k in range(m1[0].size()):
				s += m1[i][k] * m2[k][j]
			row.append(s)
		res.append(row)
	return res

func _multiply_matrix_vector(m: Array, v: Array) -> Array:
	var res = []
	for i in range(m.size()):
		var s = 0.0
		for j in range(v.size()):
			s += m[i][j] * v[j]
		res.append(s)
	return res
