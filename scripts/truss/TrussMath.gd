class_name TrussMath

static func solve_system(A: Array, B: Array):
	var n = A.size()
	var M = []
	
	for i in range(n):
		var row = A[i].duplicate()
		row.append(B[i])
		M.append(row)
	
	for i in range(n):
		var max_row = i
		for k in range(i + 1, n):
			if abs(M[k][i]) > abs(M[max_row][i]):
				max_row = k
		var temp = M[i]
		M[i] = M[max_row]
		M[max_row] = temp
		
		if abs(M[i][i]) < 1e-10:
			return null
			
		for k in range(i + 1, n):
			var factor = float(M[k][i]) / float(M[i][i])
			for j in range(i, n + 1):
				M[k][j] -= factor * M[i][j]
	
	var x = []
	x.resize(n)
	for i in range(n - 1, -1, -1):
		var sum = 0.0
		for j in range(i + 1, n):
			sum += M[i][j] * x[j]
		x[i] = (M[i][n] - sum) / M[i][i]
	return x
