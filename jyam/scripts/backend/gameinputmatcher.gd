class_name GameInputMatcher extends RefCounted

var is_accepting_inputs: bool
var is_dequeueing_inputs: bool

var _ui_ref: InputMatcherUI

var _num_inputs: int
var _lead_player: GameLogic.Player
var _follower_input_allowed: bool

var _player_inputs: Dictionary

func _init(ui_ref: InputMatcherUI, num_inputs: int) -> void:
	self._ui_ref = ui_ref
	self._num_inputs = num_inputs

	# breaking abstractions, but UI needs a max input length for sizing
	assert(self._num_inputs <= InputMatcherUI.MAX_INPUTS)

	self._reset()

func _reset() -> void:
	self.is_accepting_inputs = false
	self.is_dequeueing_inputs = false
	self._lead_player = GameLogic.Player.PLAYER_NONE
	self._follower_input_allowed = false

	self._player_inputs = {}
	self._player_inputs[GameLogic.Player.PLAYER_1] = Ring.new(self._num_inputs)
	self._player_inputs[GameLogic.Player.PLAYER_2] = Ring.new(self._num_inputs)

func enqueue_input(player: GameLogic.Player, input: GameInputs.Action) -> bool:
	assert(self._lead_player != GameLogic.Player.PLAYER_NONE)
	var q: Ring = self._player_inputs[player]
	if q.count == self._num_inputs:
		return false

	if player != self._lead_player and not self._follower_input_allowed:
		return false

	var first_lead_input = player == self._lead_player and q.count == 0
	q.enqueue(input)

	self._ui_ref.enqueue_input(player, input)
	if first_lead_input:
		self._follower_input_allowed = true
		self._ui_ref.allow_follower_inputs(GameLogic.opposite_player(player))

	return true

func _is_player_queue_full(player: GameLogic.Player) -> bool:
	var q = self._player_inputs[player]
	return q.count == q.cap	

func is_lead_full() -> bool:
	return self._is_player_queue_full(self._lead_player)

func is_follower_full() -> bool:
	return self._is_player_queue_full(GameLogic.opposite_player(self._lead_player))

func begin_inputmatcher(lead_player: GameLogic.Player) -> void:
	self.is_accepting_inputs = true
	self._lead_player = lead_player
	self._ui_ref.begin_inputmatcher(self._num_inputs, lead_player)

func end_inputmatcher() -> void:
	assert(self._lead_player != GameLogic.Player.PLAYER_NONE)
	self.is_accepting_inputs = false
	self._ui_ref.end_inputmatcher()
	self.is_dequeueing_inputs = true
