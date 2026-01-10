extends Node
class_name TrussSolver

static func run_calculation(line_data: Array, node_supports: Dictionary, node_loads: Dictionary, nodes: Array):
	var member_count = line_data.size()
	var system_size = nodes.size() * 2
	
	var A = []
	for i in range(system_size):
		var row = []
		row.resize(system_size)
		row.fill(0.0)
		A.append(row)
	
	var B = []
	B.resize(system_size)
	B.fill(0.0)

	for m_idx in range(member_count):
		var member = line_data[m_idx]
		var diff = member.end - member.start
		var length = diff.length()
		var unit = diff/length
		var n1_dx = nodes.find(member.start)
		var n2_dx = nodes.find(member.end)
		
		A[n1_dx * 2][m_idx] = unit.x
		A[n1_dx * 2 + 1][m_idx] = unit.y
		A[n2_dx * 2][m_idx] = -unit.x
		A[n2_dx * 2 + 1][m_idx] = -unit.y
	
	var reaction_col = member_count
	for node_pos in node_supports:
		var n_idx = nodes.find(node_pos)
		var type = node_supports[node_pos]
		match type:
			1, 2, 3, 4: 
				if reaction_col < system_size:
					A[n_idx*2][reaction_col] = 1.0
					reaction_col += 1
				if reaction_col < system_size:
					A[n_idx*2 + 1][reaction_col] = 1.0
					reaction_col += 1
			5, 6: 
				if reaction_col < system_size:
					A[n_idx*2 + 1][reaction_col] = 1.0
					reaction_col += 1
			7, 8: 
				if reaction_col < system_size:
					A[n_idx*2][reaction_col] = 1.0
					reaction_col += 1

	for node_pos in node_loads:
		var n_idx = nodes.find(node_pos)
		if n_idx != -1:
			var force = node_loads[node_pos]
			B[n_idx*2 + 1] = -force.y
			B[n_idx*2] = -force.x

	return TrussMath.solve_system(A, B)
