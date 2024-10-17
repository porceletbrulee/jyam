extends Object

var node_matrix = null

# node_matrix is Array[Array[Node3D]] but that's not supported sigh
func _init(m):
	self.node_matrix = m
	print_debug(str(m))
	
func get_platform(pos: Vector2) -> Node3D:
	if pos.x >= 0 and pos.x < self.node_matrix.size():
		var col = self.node_matrix[pos.x]
		if pos.y >= 0 and pos.y < col.size():
			return col[pos.y]
	return null
	
