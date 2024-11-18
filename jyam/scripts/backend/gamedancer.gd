class_name GameDancer extends RefCounted

enum State {
	SOLO_IDLE = 1,
	SOLO_MOVING,
	INVITING,
	ENTERING_CLOSED_POSITION_LEAD,
	ENTERING_CLOSED_POSITION_FOLLOW,
	CLOSED_BUFFER_INPUTS_LEAD,
	CLOSED_MATCH_INPUTS_FOLLOW,
	CLOSED_AUTO_LEAD,
	CLOSED_AUTO_FOLLOW,
	CLOSED_FINISH_LEAD,
	CLOSED_FINISH_FOLLOW,
}

var player: GameLogic.Player
var dancer3d: Dancer3D
var platform_pos: Vector2 = GamePlatforms.NOWHERE

const DEBUG = true

var _state: GameDancer.State = GameDancer.State.SOLO_IDLE

var _event_seq: int
var _cancelled_seqs: Dictionary

# TODO: this might make more sense as "state related to self._state" that gets
# reset to empty on every state transition
var _pending_invite_seq: int = -1

var _key: String

var key: String:
	get:
		return self._key
	set(_value):
		assert(false, "cannot set key")

var dancers_position: GameLogic.DancersPosition:
	get:
		match self._state:
			GameDancer.State.CLOSED_BUFFER_INPUTS_LEAD, \
			GameDancer.State.CLOSED_MATCH_INPUTS_FOLLOW, \
			GameDancer.State.CLOSED_AUTO_LEAD, \
			GameDancer.State.CLOSED_AUTO_FOLLOW, \
			GameDancer.State.CLOSED_FINISH_LEAD, \
			GameDancer.State.CLOSED_FINISH_FOLLOW:
				return GameLogic.DancersPosition.CLOSED
			_:
				return GameLogic.DancersPosition.SOLO
	set(_value):
		assert(false, "cannot set dancers_position")

func _init(pplayer: GameLogic.Player, pdancer3d: Dancer3D, ppos: Vector2):
	self.player = pplayer
	self.dancer3d = pdancer3d
	self.platform_pos = ppos

	self._state = GameDancer.State.SOLO_IDLE

	self._event_seq = 1
	self._cancelled_seqs = Dictionary()

	self._key = GameLogic.Player.keys()[self.player] + "_" + self.dancer3d.name

func _to_string() -> String:
	var state_strings = GameDancer.State.keys()
	return "GameDancer({0}, {1})".format([self.key, state_strings[self._state]])

static func _is_move_state(state: GameDancer.State) -> bool:
	match state:
		GameDancer.State.SOLO_MOVING:
			return true
		_:
			return false

func _transition_move_state() -> GameDancer.State:
	match self._state:
		GameDancer.State.SOLO_IDLE, GameDancer.State.SOLO_MOVING:
			return GameDancer.State.SOLO_MOVING
		_:
			assert(false, "can't move in state {0}".format([self._state]))
			return GameDancer.State.SOLO_IDLE

# opposite of _transition_move_state
func _transition_idle_state() -> GameDancer.State:
	match self._state:
		GameDancer.State.SOLO_IDLE, GameDancer.State.SOLO_MOVING:
			return GameDancer.State.SOLO_IDLE
		_:
			assert(false, "could not choose idle state {0}".format([self._state]))
			return GameDancer.State.SOLO_IDLE

func can_move() -> bool:
	return (not self.is_inviting() and
			not GameDancer._is_move_state(self._state))

func can_invite() -> bool:
	return self._state == GameDancer.State.SOLO_IDLE

func is_inviting() -> bool:
	return self._state == GameDancer.State.INVITING

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

func _new_cancellable_seq() -> int:
	var seq = self._event_seq
	self._cancelled_seqs[seq] = false
	self._event_seq = seq + 1
	return seq

# @returns: Callable, caller should check is_null
func trigger_invite(song_timer: SongTimer) -> Callable:
	if not self.can_invite():
		return Callable()

	self.trigger_stationary_transition(song_timer,
									   GameDancer.State.INVITING)
	var seq = self._new_cancellable_seq()
	self._pending_invite_seq = seq

	var _invite_expired = func(_context):
		if self._cancelled_seqs.get(seq, true):
			if DEBUG:
				print_debug("{0}: skipping invite_expired for seq {1}".format([
					self, seq
				]))
			self._cancelled_seqs.erase(seq)
			return

		assert(seq == self._pending_invite_seq)
		self.invite_expired(song_timer)
		# TODO: may race with accepting invite
		self._cancelled_seqs.erase(seq)
		self._pending_invite_seq = -1

	return _invite_expired

func invite_accepted(song_timer: SongTimer, partner: GameDancer) -> bool:
	# TODO: may race with invite_expired...
	if self._state != GameDancer.State.INVITING:
		return false

	self._cancelled_seqs[self._pending_invite_seq] = true
	self._pending_invite_seq = -1

	# the inviter always becomes the lead for now
	self.trigger_stationary_transition(song_timer, GameDancer.State.ENTERING_CLOSED_POSITION_LEAD)
	partner.trigger_stationary_transition(song_timer, GameDancer.State.ENTERING_CLOSED_POSITION_FOLLOW)
	return true

func invite_expired(song_timer: SongTimer):
	assert(self._state == GameDancer.State.INVITING)
	self.trigger_stationary_transition(song_timer, GameDancer.State.SOLO_IDLE)

func on_beat(_song_timer: SongTimer):
	pass

func on_measure(song_timer: SongTimer):
	# restart idle animation if already idle
	match self._state:
		GameDancer.State.SOLO_IDLE, \
		GameDancer.State.CLOSED_BUFFER_INPUTS_LEAD, \
		GameDancer.State.CLOSED_MATCH_INPUTS_FOLLOW:
			self._trigger_stationary_animation(song_timer, self._state)
		_:
			pass
