class_name InputMatcherUI extends Control

## HBoxContainer for P1 inputs
@export var p1_hbox: HBoxContainer

## HBoxContainer for P2 inputs
@export var p2_hbox: HBoxContainer

const MAX_INPUTS: int = 8

## Color when input panel is ready to take inputs
@export var INPUT_PANEL_ENABLED_COLOR: Color

## Color when input panel is disabled
@export var INPUT_PANEL_DISABLED_COLOR: Color

# UI elements
var _player_hboxes: Dictionary
var buttonpanel: PanelContainer
var up_button: Panel
var down_button: Panel
var left_button: Panel
var right_button: Panel

# state that's only valid after begin
var _player_to_child_index: Dictionary
var _first_button_index: int
var _num_inputs: int

func _ready() -> void:
	self.visible = false
	self.buttonpanel = get_node("templates/buttonpanel")
	self.up_button = get_node("templates/up")
	self.down_button = get_node("templates/down")
	self.left_button = get_node("templates/left")
	self.right_button = get_node("templates/right")

	self._player_hboxes = {}
	self._player_hboxes[GameLogic.Player.PLAYER_1] = self.p1_hbox
	self._player_hboxes[GameLogic.Player.PLAYER_2] = self.p2_hbox

	self._player_to_child_index = {}

	self.end_inputmatcher()

func end_inputmatcher() -> void:
	for hbox in self._player_hboxes.values():
		var children = hbox.get_children()
		for child in children:
			hbox.remove_child(child)
			child.queue_free()
	self._first_button_index = -1
	self._num_inputs = -1
	self.visible = false

static func _hbox_spacer_control() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = SizeFlags.SIZE_EXPAND_FILL
	spacer.size_flags_vertical = SizeFlags.SIZE_FILL
	spacer.size_flags_stretch_ratio = 1.0
	return spacer

static func _panel_stylebox() -> StyleBoxFlat:
	var flat: StyleBoxFlat = StyleBoxFlat.new()
	flat.bg_color = Color.TRANSPARENT
	flat.border_width_bottom = 2
	flat.border_width_top = 2
	flat.border_width_left = 2
	flat.border_width_right = 2
	return flat

func begin_inputmatcher(num_inputs: int, lead_player: GameLogic.Player) -> void:
	assert(num_inputs <= self.MAX_INPUTS)

	self._num_inputs = num_inputs
	var rem = self.MAX_INPUTS - self._num_inputs
	@warning_ignore("integer_division") var num_before = rem / 2
	@warning_ignore("integer_division") var num_after = (rem / 2) if rem % 2 == 0 else (rem / 2 + 1)

	for p in self._player_hboxes:
		var first_button_index = 0
		var hbox = self._player_hboxes[p]
		for i in range(num_before):
			hbox.add_child(InputMatcherUI._hbox_spacer_control())
			first_button_index += 1

		for i in range(num_inputs):
			var b: PanelContainer = self.buttonpanel.duplicate()
			var flat = InputMatcherUI._panel_stylebox()
			flat.border_color = (self.INPUT_PANEL_ENABLED_COLOR
								 if p == lead_player
								 else self.INPUT_PANEL_DISABLED_COLOR)
			b.add_theme_stylebox_override("panel", flat)

			hbox.add_child(b)

		for i in range(num_after):
			hbox.add_child(InputMatcherUI._hbox_spacer_control())

		for child in hbox.get_children():
			child.visible = true

		self._player_to_child_index[p] = 0
		self._first_button_index = first_button_index
		hbox.visible = true
	self.visible = true

func allow_follower_inputs(follow_player: GameLogic.Player) -> void:
	assert(self._num_inputs > 0)

	var hbox = self._player_hboxes[follow_player]
	assert(self._num_inputs < hbox.get_child_count())
	for i in range(self._num_inputs):
		var button: PanelContainer = hbox.get_child(self._first_button_index + i)
		var flat = InputMatcherUI._panel_stylebox()
		flat.border_color = self.INPUT_PANEL_ENABLED_COLOR
		button.add_theme_stylebox_override("panel", flat)

func add_player_input(player: GameLogic.Player, input: GameInputs.Action) -> void:
	var hbox = self._player_hboxes[player]
	var i = self._player_to_child_index[player]
	assert(i < self._num_inputs)

	var child: PanelContainer = hbox.get_child(self._first_button_index + i)
	var input_panel: Panel = null
	match input:
		GameInputs.Action.P1_UP, GameInputs.Action.P2_UP:
			input_panel = self.up_button.duplicate()
		GameInputs.Action.P1_DOWN, GameInputs.Action.P2_DOWN:
			input_panel = self.down_button.duplicate()
		GameInputs.Action.P1_LEFT, GameInputs.Action.P2_LEFT:
			input_panel = self.left_button.duplicate()
		GameInputs.Action.P1_RIGHT, GameInputs.Action.P2_RIGHT:
			input_panel = self.right_button.duplicate()
		_:
			print_debug("bad input player {0} input {1}".format([player, input]))
			assert(false)
			return
	child.add_child(input_panel)
	input_panel.visible = true
	self._player_to_child_index[player] = i + 1
