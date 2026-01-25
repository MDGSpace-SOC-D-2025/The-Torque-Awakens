class_name StaticsSolver

var main: Node2D

func setup(m: Node2D):
	main = m

func solve():
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
			var f_vec = force.direction * force.magnitude
			ext_f += f_vec

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
			# Check Stability (Residual Error)
			var res_x = 0.0
			var res_y = 0.0
			var res_m = 0.0
			
			for j in range(num_vars):
				res_x += A[eq_idx][j] * solution[j]
				res_y += A[eq_idx + 1][j] * solution[j]
				res_m += A[eq_idx + 2][j] * solution[j]
			
			var error = Vector3(res_x - b[eq_idx], res_y - b[eq_idx+1], res_m - b[eq_idx+2]).length()
			
			if error > 0.5:
				print("--- SYSTEM UNSTABLE ---")
				print("Residual Error: ", error)
				print("The object would likely fall or rotate.")
			else:
				print("--- SYSTEM STABLE ---")

			for i in range(obj.contacts.size()):
				var mag = solution[var_idx + i]
				if mag < 0: mag = 0.0 # Physics check: Walls can't pull
				print("Wall Contact ", i, " | Magnitude: ", mag)
		
		eq_idx += 3
		var_idx += obj.contacts.size()

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
