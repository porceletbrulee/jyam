class_name Dancer3D extends Node3D

@export var player: GameLogic.Player = GameLogic.Player.PLAYER_1
@export var CLOSED_POSITION_OFFSET_DISTANCE: float = 2.0

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
	GameDancer.State.CLOSED_BUFFER_INPUTS_LEAD: ["closedpos_idle_lead", ScaleType.PER_MEASURE],
	GameDancer.State.CLOSED_MATCH_INPUTS_FOLLOW: ["closedpos_idle_follow", ScaleType.PER_MEASURE],
	GameDancer.State.CLOSED_AUTO_LEAD: ["closedpos_idle_lead", ScaleType.PER_MEASURE],
	GameDancer.State.CLOSED_AUTO_FOLLOW: ["closedpos_idle_follow", ScaleType.PER_MEASURE],
}

var _song_metadata_ref: SongMetadata = null
var partner_ref = null

var facing: GameLogic.Facing = GameLogic.Facing.PARTNER

var _anim: AnimationPlayer = null
var _facecamui_ref: Control = null

class MoveState extends RefCounted:
	var src: Vector3
	var dst: Vector3
	var duration_sec: float
	var elapsed_sec: float

	func _init(psrc: Vector3, pdst: Vector3, pduration_sec: float):
		self.src = psrc
		self.dst = pdst
		self.duration_sec = pduration_sec
		self.elapsed_sec = 0.0

var _move_state: MoveState

var _action_toggle_facing = ""

func _ready() -> void:
	self._anim = get_node("model/AnimationPlayer")
	self._facecamui_ref = get_node("facecamui")
	self._facecamui_ref.visible = false

# Called by dance3d after the entire scene is ready
func scene_ready(
	song_metadata: SongMetadata,
	initial_plat: GamePlatforms.Platform,
	assigned_player: GameLogic.Player,
	partner: Node3D):
	self._song_metadata_ref = song_metadata
	self.player = assigned_player
	self.partner_ref = partner

	var plat_point = initial_plat.global_origin
	plat_point.y = self.transform.origin.y
	self.transform.origin = plat_point

	if self.player == GameLogic.Player.PLAYER_1:
		self._action_toggle_facing = GameInputs.Action.find_key(GameInputs.Action.P1_TOGGLE_FACING)
	else:
		self._action_toggle_facing = GameInputs.Action.find_key(GameInputs.Action.P2_TOGGLE_FACING)

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

func _physics_process(delta: float) -> void:
	if self._move_state != null:
		self._move_state.elapsed_sec += delta

		var lerp_fraction = clampf(self._move_state.elapsed_sec /
								   	self._move_state.duration_sec,
								   0,
								   1.0)
		var origin_point = self._move_state.src
		var new_point = origin_point.lerp(self._move_state.dst, lerp_fraction)
		self.transform.origin = new_point

	if self.facing == GameLogic.Facing.PARTNER:
		# TODO: maybe slerp facing? currently looks ok
		# XXX: if they get too close, it rotates on x-z axes too. pin y value
		var target = self.partner_ref.transform.origin
		self.look_at(Vector3(
			target.x,
			self.transform.origin.y,
			target.z,
		), Vector3.UP, true)

func _maybe_play_animation(animation: String, duration_sec: float) -> bool:
	if not self._anim.has_animation(animation):
		return false

	self._anim.stop()
	self._anim.play(animation)

	# scale the animation to match 1 measure. 0.5 scale means half speed
	# animation_length * v = total_frames
	# desired_seconds * scale * v = total_frames
	var anim_scale = 1.0
	if duration_sec > 0:
		anim_scale =  self._anim.current_animation_length / duration_sec
	self._anim.set_speed_scale(anim_scale)
	return true

func trigger_animation(duration_sec: float, state: GameDancer.State):
	var info = self.STATE_TO_ANIMATION_INFO.get(state)
	if info != null:
		var animation = info[0]
		self._maybe_play_animation(animation, duration_sec)

# dancers need to be off-center for closed position
# TODO: maybe it's better to have the animations handle this?
# @param offset_dir: GameLogic.UP, .DOWN, .LEFT, .RIGHT. It's applied to the
#                    x-z space.
func _trigger_move_with_offset(
	dst_plat: GamePlatforms.Platform,
	offset_from_center: Vector3,
	move_duration_sec: float,
	state_for_move_animation: GameDancer.State,
):
	assert(self._move_state == null)
	var dst_point = dst_plat.global_origin + offset_from_center
	# FIXME: calculation of height (y-axis) needs some work
	dst_point.y = self.transform.origin.y

	self._move_state = MoveState.new(
		self.transform.origin,
		dst_point,
		move_duration_sec,
	)

	var info = self.STATE_TO_ANIMATION_INFO.get(state_for_move_animation)
	if info != null:
		var animation = info[0]
		self._maybe_play_animation(animation, move_duration_sec)

func trigger_move_in_closed_position(
	dst_plat: GamePlatforms.Platform,
	offset_dir: Vector3,
	move_duration_sec: float,
):
	var offset_from_center = offset_dir * self.CLOSED_POSITION_OFFSET_DISTANCE
	self._trigger_move_with_offset(
		dst_plat,
		offset_from_center,
		move_duration_sec,
		GameDancer.State.SOLO_MOVING,
	)

func trigger_move_to_closed_position(
	dst_plat: GamePlatforms.Platform,
	move_dir: Vector2,
	move_duration_sec: float,
):
	var offset_dir = GamePlatforms.platform_offset_from_move_dir(move_dir)
	var offset_from_center = offset_dir * self.CLOSED_POSITION_OFFSET_DISTANCE
	self._trigger_move_with_offset(
		dst_plat,
		offset_from_center,
		move_duration_sec,
		GameDancer.State.SOLO_MOVING,
	)

func trigger_move(
	_src_plat: GamePlatforms.Platform,
	dst_plat: GamePlatforms.Platform,
	move_duration_sec: float,
	state_for_move_animation: GameDancer.State):
	self._trigger_move_with_offset(
		dst_plat,
		Vector3(0, 0, 0),
		move_duration_sec,
		state_for_move_animation,
	)

func finish_move():
	# finish moving the model even if the interpolation is not done
	assert(self._move_state != null)
	var dst_point = self._move_state.dst
	self._move_state = null
	self.transform.origin = dst_point

func get_facecam_text_label() -> RichTextLabel:
	# TODO: make a facecam class probably to take care of this
	return get_node("facecamui/vbox/text")

func show_facecam():
	var rtl = self.get_facecam_text_label()
	rtl.text = ""
	self._facecamui_ref.visible = true

func hide_facecam():
	self._facecamui_ref.visible = false
