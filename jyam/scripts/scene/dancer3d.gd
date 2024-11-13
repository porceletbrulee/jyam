class_name Dancer3D extends Node3D

@export var player: GameLogic.Player = GameLogic.Player.PLAYER_1

enum ScaleType {
	NONE = 0,
	PER_BEAT,
	PER_MEASURE,
}

# depends on what is in the Blender file. periods in blender become underscores
# in godot. the format is like so:
# [blender_animation_name, ScaleType]
const STATE_TO_ANIMATION_INFO = {
	GameDancer.State.SOLO_IDLE: ["idle", ScaleType.PER_MEASURE],
	GameDancer.State.SOLO_MOVING: ["solo_moveforward", ScaleType.PER_BEAT],
	GameDancer.State.INVITING: ["invite", ScaleType.PER_MEASURE],
	GameDancer.State.CLOSED_IDLE_LEAD: ["closedpos_idle_lead", ScaleType.PER_MEASURE],
	GameDancer.State.CLOSED_MOVING_LEAD: ["closedpos_idle_lead", ScaleType.PER_BEAT],
	GameDancer.State.CLOSED_IDLE_FOLLOW: ["closedpos_idle_follow", ScaleType.PER_MEASURE],
	GameDancer.State.CLOSED_MOVING_FOLLOW: ["closedpos_idle_follow", ScaleType.PER_BEAT],
}

var _platform_layout_ref = null
var _song_metadata_ref: SongMetadata = null
var platform_loc = Vector2()
var partner_ref = null

var facing: GameLogic.Facing = GameLogic.Facing.PARTNER

var _anim: AnimationPlayer = null

var _move_target_loc = Vector2()
var _move_origin_point = Vector3()
var _move_target_point = Vector3()
var _move_t = 0.0
var _is_moving = false

var _action_movements = null
var _action_toggle_facing = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self._anim = get_node("AnimationPlayer")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _platform_pos(plat_transform: Transform3D) -> Vector3:
	# y-axis is up-and-down
	return Vector3(
		plat_transform.origin.x,
		self.transform.origin.y,
		plat_transform.origin.z)

func scene_ready(
	song_metadata: SongMetadata,
	platform_layout,
	initial_pos: Vector2,
	assigned_player: GameLogic.Player,
	partner: Node3D):
	self._platform_layout_ref = platform_layout
	self._song_metadata_ref = song_metadata
	self.platform_loc = initial_pos
	self.player = assigned_player
	self.partner_ref = partner

	var plat = platform_layout.get_platform(initial_pos)
	self.transform.origin = self._platform_pos(plat.node3d.transform)

	var action_to_event_str = GameInputs.GameAction.keys()
	self._action_movements = []
	for action in GamePlatforms.GAME_ACTION_TO_MOVE_DIR:
		if self.player != GameInputs.GAME_ACTION_TO_PLAYER[action]:
			continue

		var dir = GamePlatforms.GAME_ACTION_TO_MOVE_DIR[action]
		self._action_movements.append([dir, action_to_event_str[action]])

	if self.player == GameLogic.Player.PLAYER_1:
		self._action_toggle_facing = GameInputs.P1_TOGGLE_FACING_STR
	else:
		self._action_toggle_facing = GameInputs.P2_TOGGLE_FACING_STR

func _toggle_facing():
	var new_facing = GameLogic.opposite_facing(self.facing)

	if new_facing == GameLogic.Facing.CAMERA:
		# positive z goes into the camera
		var target = Vector3(
			self.transform.origin.x,
			self.transform.origin.y,
			self.transform.origin.z + 3.0,
		)
		self.look_at(target, Vector3.UP, true)

	# since partner moves, the _physics_process will update facing
	self.facing = new_facing


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(self._action_toggle_facing):
		self._toggle_facing()

	for i in self._action_movements:
		var dir = i[0]
		var act = i[1]
		if event.is_action_pressed(act):
			self._move(dir)

func _move(dir):
	if self._is_moving:
		# skip moves for now (think about buffering moves later)
		return

	var new_loc = self.platform_loc + dir
	var plat = self._platform_layout_ref.get_platform(new_loc)
	if plat == null:
		print_debug("out of bounds move! " + str(new_loc))
		return

	self._anim.play("solo_moveforward")
	# XXX: remove when p2 animation is sorted out
	if self.player == GameLogic.Player.PLAYER_1:
		# scale the animation to match 1 measure. 0.5 scale means half speed
		# animation_length * v = total_frames
		# desired_seconds * scale * v = total_frames
		var animation_length = self._anim.current_animation_length
		var anim_scale = animation_length / self._song_metadata_ref.sec_per_beat
		self._anim.set_speed_scale(anim_scale)
	self._move_target_loc = new_loc
	self._move_origin_point = self.transform.origin
	self._move_target_point = self._platform_pos(plat.node3d.transform)
	self._move_t = 0.0
	self._is_moving = true

func _physics_process(delta: float) -> void:
	if self._is_moving:
		# finish the move when _move_t / sec_per_beat ~= 1
		# clamp to 1.0 to prevent overshooting
		self._move_t += delta
		var lerp_fraction = clamp(self._move_t /
							 	  self._song_metadata_ref.sec_per_beat,
								  0,
								  1.0)

		var origin_point = self._move_origin_point
		var new_point = origin_point.lerp(self._move_target_point, lerp_fraction)
		self.transform.origin = new_point

		if new_point.is_equal_approx(self._move_target_point):
			print_debug(self.get_name() + " move done {0} {1}".format(
				[new_point, self._move_target_loc]))
			self.platform_loc = self._move_target_loc
			self._is_moving = false

	if self.facing == GameLogic.Facing.PARTNER:
		# TODO: maybe slerp facing? currently looks ok
		# XXX: if they get too close, it rotates on x-z axes too. pin y value
		var target = self.partner_ref.transform.origin
		self.look_at(Vector3(
			target.x,
			self.transform.origin.y,
			target.z,
		), Vector3.UP, true)

func trigger_animation(song_timer: SongTimer, state: GameDancer.State):
	var info = self.STATE_TO_ANIMATION_INFO.get(state)
	if info == null:
		return

	var animation = info[0]
	var scale_type = info[1]

	self._anim.stop()
	self._anim.play(animation)
	if self._anim.current_animation != "":
		# helpful to skip this when animation hasn't been made yet

		# scale the animation to match 1 measure. 0.5 scale means half speed
		# animation_length * v = total_frames
		# desired_seconds * scale * v = total_frames
		var anim_scale = self._anim.current_animation_length
		match scale_type:
			ScaleType.PER_BEAT:
				anim_scale = anim_scale / song_timer.sec_per_beat
			ScaleType.PER_MEASURE:
				anim_scale = anim_scale / song_timer.sec_per_measure
			_:
				anim_scale = 1.0
		self._anim.set_speed_scale(anim_scale)

func trigger_move(
	song_timer: SongTimer,
	src_plat: GamePlatforms.Platform,
	dst_plat: GamePlatforms.Platform,
	new_state: GameDancer.State):
		pass
