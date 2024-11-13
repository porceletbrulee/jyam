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
var moving: bool

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
	self.moving = false
	self.platform_pos = ppos

	self._state = GameDancer.State.SOLO_IDLE
	self._key = GameLogic.Player.keys()[self.player] + "_" + self.dancer3d.name

func _to_string() -> String:
	return "GameDancer({0})".format([self.key])

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

func trigger_transition(song_timer: SongTimer, new_state: GameDancer.State):
	if DEBUG:
		var state_strings = GameDancer.State.keys()
		print_debug("{0}: transition {1} -> {2}".format([
			self, state_strings[self._state], state_strings[new_state]
		]))
	
	assert(!self._is_move_state(new_state))
	# try to keep GameDancer free of model/animation details
	self._state = new_state
	self.dancer3d.trigger_animation(song_timer, new_state)

func trigger_move(
	song_timer: SongTimer,
	src_plat: GamePlatforms.GamePlatform,
	dst_plat: GamePlatforms.GamePlatform,
	new_state: GameDancer.State):
	if DEBUG:
		var state_strings = GameDancer.State.keys()
		print_debug("{0}: move {1} {2} -> {3} {4}".format([
			self, state_strings[self._state], src_plat,
			state_strings[new_state], dst_plat,
		]))
	assert(self._is_move_state(new_state))
	self.dancer3d.trigger_move(song_timer, src_plat, dst_plat, new_state)

func on_beat(song_timer: SongTimer):
	pass

func on_measure(song_timer: SongTimer):
	# restart idle animation if already idle
	match self._state:
		GameDancer.State.SOLO_IDLE, GameDancer.State.CLOSED_IDLE_LEAD, GameDancer.State.CLOSED_IDLE_FOLLOW:
			self.trigger_transition(song_timer, self._state)
		_:
			pass
