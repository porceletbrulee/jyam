extends Camera3D

@export var follow_target: Camera3D = null

func _physics_process(_delta: float):
	self.global_transform = follow_target.global_transform
