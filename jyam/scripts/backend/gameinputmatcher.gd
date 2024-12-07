class_name GameInputMatcher extends RefCounted

var is_accepting_inputs: bool
var is_dequeueing_inputs: bool
var lead_player: GameLogic.Player

var _ui_ref: InputMatcherUI

var _num_inputs: int


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
	self.lead_player = GameLogic.Player.PLAYER_NONE

	self._player_inputs = {}
	self._player_inputs[GameLogic.Player.PLAYER_1] = Ring.new(self._num_inputs)
	self._player_inputs[GameLogic.Player.PLAYER_2] = Ring.new(self._num_inputs)

func enqueue_input(player: GameLogic.Player, input: GameInputs.Action) -> bool:
	assert(self.lead_player != GameLogic.Player.PLAYER_NONE)
	var q: Ring = self._player_inputs[player]
	if q.count == self._num_inputs:
		return false

	if player != self.lead_player:
		if q.count >= self._player_inputs[self.lead_player].count:
			return false

	q.enqueue(input)
	self._ui_ref.enqueue_input(player, input)
	if player == self.lead_player:
		self._ui_ref.allow_nth_follower_input(
			GameLogic.opposite_player(player), q.count - 1
		)

	return true

func _is_player_queue_full(player: GameLogic.Player) -> bool:
	var q = self._player_inputs[player]
	return q.count == q.cap	

func is_lead_full() -> bool:
	return self._is_player_queue_full(self.lead_player)

func is_follower_full() -> bool:
	return self._is_player_queue_full(GameLogic.opposite_player(self.lead_player))

func begin_inputmatcher(lead_player: GameLogic.Player) -> void:
	self.is_accepting_inputs = true
	self.lead_player = lead_player
	self._ui_ref.begin_inputmatcher(self._num_inputs, lead_player)

func end_inputmatcher() -> void:
	assert(self.lead_player != GameLogic.Player.PLAYER_NONE)
	self.is_accepting_inputs = false
	self._ui_ref.end_inputmatcher()
	self.is_dequeueing_inputs = true

func dequeue_all() -> Array[Dictionary]:
	var p1 = self._player_inputs[GameLogic.Player.PLAYER_1]
	var p2 = self._player_inputs[GameLogic.Player.PLAYER_2]

	var all_inputs: Array[Dictionary] = []
	while p1.count > 0 or p2.count > 0:
		var d = {
			GameLogic.Player.PLAYER_1: p1.dequeue(),
			GameLogic.Player.PLAYER_2: p2.dequeue(),
		}
		all_inputs.append(d)
	return all_inputs
