class_name GameDancer extends RefCounted

enum State {
	SOLO_IDLE = 0,
	SOLO_MOVING,
	INVITING,
	CLOSED_IDLE_LEAD,
	CLOSED_MOVING_LEAD,
	CLOSED_IDLE_FOLLOW,
	CLOSED_MOVING_FOLLOW,
}

var player: GameLogic.Player
var dancer3d: Dancer3D
var platform_pos: Vector2 = GamePlatforms.NOWHERE

const DEBUG = true

var _state: GameDancer.State

var _key: String

var key: String:
	get:
		return self._key
	set(_value):
		assert(false, "cannot set key")

func _init(pplayer: GameLogic.Player, pdancer3d: Dancer3D, ppos: Vector2):
	self.player = pplayer
	self.dancer3d = pdancer3d
	self.platform_pos = ppos

	self._state = GameDancer.State.SOLO_IDLE
	self._key = GameLogic.Player.keys()[self.player] + "_" + self.dancer3d.name

func _to_string() -> String:
	var state_strings = GameDancer.State.keys()
	return "GameDancer({0}, {1})".format([self.key, state_strings[self._state]])

static func _is_move_state(state: GameDancer.State) -> bool:
	match state:
		GameDancer.State.SOLO_MOVING:
			return true
		GameDancer.State.CLOSED_MOVING_LEAD:
			return true
		GameDancer.State.CLOSED_MOVING_FOLLOW:
			return true
		_:
			return false

func _transition_move_state() -> GameDancer.State:
	match self._state:
		GameDancer.State.SOLO_IDLE, GameDancer.State.SOLO_MOVING:
			return GameDancer.State.SOLO_MOVING
		GameDancer.State.CLOSED_IDLE_LEAD, GameDancer.State.CLOSED_MOVING_LEAD:
			return GameDancer.State.CLOSED_MOVING_LEAD
		GameDancer.State.CLOSED_IDLE_FOLLOW, GameDancer.State.CLOSED_MOVING_FOLLOW:
			return GameDancer.State.CLOSED_MOVING_FOLLOW
		_:
			assert(false, "can't move in state {0}".format([self._state]))
			return GameDancer.State.SOLO_IDLE

# opposite of _transition_move_state
func _transition_idle_state() -> GameDancer.State:
	match self._state:
		GameDancer.State.SOLO_IDLE, GameDancer.State.SOLO_MOVING:
			return GameDancer.State.SOLO_IDLE
		GameDancer.State.CLOSED_IDLE_LEAD, GameDancer.State.CLOSED_MOVING_LEAD:
			return GameDancer.State.CLOSED_IDLE_LEAD
		GameDancer.State.CLOSED_IDLE_FOLLOW, GameDancer.State.CLOSED_MOVING_FOLLOW:
			return GameDancer.State.CLOSED_IDLE_FOLLOW
		_:
			assert(false, "could not choose idle state {0}".format([self._state]))
			return GameDancer.State.SOLO_IDLE

func can_move() -> bool:
	return (self._state != GameDancer.State.INVITING and
			not GameDancer._is_move_state(self._state))

func _trigger_stationary_animation(song_timer: SongTimer, state: GameDancer.State):
	var info = Dancer3D.STATE_TO_ANIMATION_INFO.get(state)
	if info != null:
		var scale_type = info[1]
		var duration_sec = 0
		match scale_type:
			Dancer3D.ScaleType.PER_BEAT:
				duration_sec = song_timer.sec_per_beat
			Dancer3D.ScaleType.PER_MEASURE:
				duration_sec = song_timer.sec_per_measure
		self.dancer3d.trigger_animation(duration_sec, state)

func trigger_stationary_transition(
	song_timer: SongTimer,
	new_state: GameDancer.State) -> bool:
	if DEBUG:
		var state_strings = GameDancer.State.keys()
		print_debug("{0}: transition {1} -> {2}".format([
			self, state_strings[self._state], state_strings[new_state]
		]))

	assert(!GameDancer._is_move_state(new_state))
	self._state = new_state

	# TODO: try to keep GameDancer free of model/animation details
	self._trigger_stationary_animation(song_timer, new_state)
	return true

func trigger_move(
	src_plat: GamePlatforms.Platform,
	dst_plat: GamePlatforms.Platform,
	move_duration_sec: float):
	var new_state = self._transition_move_state()
	if DEBUG:
		var state_strings = GameDancer.State.keys()
		print_debug("{0}: move {1} {2} -> {3} {4}".format([
			self, state_strings[self._state], src_plat,
			state_strings[new_state], dst_plat,
		]))
	self._state = new_state

	self.dancer3d.trigger_move(src_plat, dst_plat, move_duration_sec, new_state)

func finish_move(song_timer: SongTimer):
	if DEBUG:
		print_debug("{0} {1}: finish_move".format([self, song_timer.curr_sec]))

	self.dancer3d.finish_move()
	var new_state = self._transition_idle_state()
	self.trigger_stationary_transition(song_timer, new_state)

func on_beat(_song_timer: SongTimer):
	pass

func on_measure(song_timer: SongTimer):
	# restart idle animation if already idle
	match self._state:
		GameDancer.State.SOLO_IDLE, GameDancer.State.CLOSED_IDLE_LEAD, GameDancer.State.CLOSED_IDLE_FOLLOW:
			self._trigger_stationary_animation(song_timer, self._state)
		_:
			pass
