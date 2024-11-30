class_name Platform3D extends Node3D

# the local transform.origin for platform at (0, 0)
var zerozero_local_origin: Vector3
var platform_size: Vector3

var _platform_exists: Array

func _ready() -> void:
	var standard: MeshInstance3D = get_node("platform_standard")
	var bm: BoxMesh = standard.mesh

	self.zerozero_local_origin = standard.transform.origin
	# assuming the platform_standard has scale (1, 1, 1)
	self.platform_size = bm.size

	# TODO: make this more flexible
	self._platform_exists = [
		[true, true, true, true, true, true, true],
		[true, true, true, true, true, true, true],
		[true, true, true, true, true, true, true],
	]


func _platform_local_origin(platform_pos: Vector2) -> Vector3:
	var dst = self.zerozero_local_origin
	dst.x += (self.platform_size.x / self.scale.x) * platform_pos.y
	dst.z -= (self.platform_size.z / self.scale.z) * platform_pos.x
	return dst

func platform_global_origin(platform_pos: Vector2) -> Vector3:
	return self.to_global(self._platform_local_origin(platform_pos))

# returns Array[Array[optional Vector3]]
func get_platform_map() -> Array:
	return self._platform_exists
