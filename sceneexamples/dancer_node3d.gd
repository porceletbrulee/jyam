extends Node3D

var loc = Vector2(1, 0)
var cached_platform_layout = null

var _anim = null

var _move_target_loc = Vector2()
var _move_target_point = Vector3()
var _move_t = 0.0
var _is_moving = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self._anim = get_node("AnimationPlayer")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _print_event(event):
	print_debug("pressed " + event.as_text())

func _platform_pos(plat_transform: Transform3D) -> Vector3:
	# z-axis is up-and-down
	return Vector3(
		plat_transform.origin.x,
		self.transform.origin.y,
		plat_transform.origin.z)

func scene_ready(platform_layout, initial_pos: Vector2):
	self.cached_platform_layout = platform_layout
	
	var plat = platform_layout.get_platform(initial_pos)
	self.transform.origin = self._platform_pos(plat.transform)
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		self._print_event(event)
		var player = get_node("AnimationPlayer")
		player.play("idle")
		
	for i in [
		[Vector2(-1, 0), "ui_left"],
		[Vector2(1, 0), "ui_right"],
		[Vector2(0, 1), "ui_up"],
		[Vector2(0, -1), "ui_down"],
	]:
		var dir = i[0]
		var act = i[1]
		if event.is_action_pressed(act):
			self._print_event(event)
			self._move(dir)
			
func _move(dir):
	if self._is_moving:
		# skip moves for now (think about buffering moves later)
		return
	
	var new_loc = self.loc + dir
	var plat = self.cached_platform_layout.get_platform(new_loc)
	if plat == null:
		print_debug("out of bounds move! " + str(new_loc))
		return
	print_debug(plat.name + " @ " + str(self.loc) + str(plat.transform))
	
	self._anim.play("waltz forward")
	self._move_target_loc = new_loc
	self._move_target_point = self._platform_pos(plat.transform)
	self._move_t = 0.0
	self._is_moving = true
	
func _physics_process(delta: float) -> void:
	if self._is_moving:
		self._move_t += delta * 0.4
		var point = self.transform.origin
		var new_point = point.lerp(self._move_target_point, self._move_t)
		self.transform.origin = new_point
		if new_point.is_equal_approx(self._move_target_point):
			print_debug("move done {0} -> {1}".format([point, new_point]))
			self.loc = self._move_target_loc
			self._is_moving = false
