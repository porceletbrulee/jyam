class_name GameInputs

enum Action {
	P1_UP = 0,
	P1_DOWN,
	P1_LEFT,
	P1_RIGHT,
	P1_TOGGLE_FACING,
	P1_INVITE,
	P2_UP,
	P2_DOWN,
	P2_LEFT,
	P2_RIGHT,
	P2_TOGGLE_FACING,
	P2_INVITE,
}

# XXX: this sucks, add test
const P1_UP_STR = "P1_UP"
const P1_DOWN_STR = "P1_DOWN"
const P1_LEFT_STR = "P1_LEFT"
const P1_RIGHT_STR = "P1_RIGHT"
const P1_TOGGLE_FACING_STR = "P1_TOGGLE_FACING"
const P2_UP_STR = "P2_UP"
const P2_DOWN_STR = "P2_DOWN"
const P2_LEFT_STR = "P2_LEFT"
const P2_RIGHT_STR = "P2_RIGHT"
const P2_TOGGLE_FACING_STR = "P2_TOGGLE_FACING"

const ACTION_TO_PLAYER = {
	Action.P1_UP: GameLogic.Player.PLAYER_1,
	Action.P1_DOWN: GameLogic.Player.PLAYER_1,
	Action.P1_LEFT: GameLogic.Player.PLAYER_1,
	Action.P1_RIGHT: GameLogic.Player.PLAYER_1,
	Action.P1_TOGGLE_FACING: GameLogic.Player.PLAYER_1,
	Action.P1_INVITE: GameLogic.Player.PLAYER_1,
	Action.P2_UP: GameLogic.Player.PLAYER_2,
	Action.P2_DOWN: GameLogic.Player.PLAYER_2,
	Action.P2_LEFT: GameLogic.Player.PLAYER_2,
	Action.P2_RIGHT: GameLogic.Player.PLAYER_2,
	Action.P2_TOGGLE_FACING: GameLogic.Player.PLAYER_2,
	Action.P2_INVITE: GameLogic.Player.PLAYER_2,
}

class ActionEvent extends RefCounted:
	# this seconds value is relative to SongTimer
	var sec: float = -1.0
	var player: GameLogic.Player = GameLogic.Player.PLAYER_NONE
	func _init(event_player: GameLogic.Player, song_sec: float):
		self.player = event_player
		self.sec = song_sec

class ActionEventMove extends ActionEvent:
	var dir = Vector2()
	func _init(event_player: GameLogic.Player,
			   song_sec: float,
			   action: GameInputs.Action):
		super(event_player, song_sec)
		self.dir = GamePlatforms.ACTION_TO_MOVE_DIR.get(action)
		assert(self.dir != null)

class ActionEventSetFacing extends ActionEvent:
	var facing: GameLogic.Facing
	func _init(event_player: GameLogic.Player,
			   song_sec: float,
			   new_facing: GameLogic.Facing):
		super(event_player, song_sec)
		self.facing = new_facing


const DEFAULT_KEYS = {
	Action.P1_UP: KEY_W,
	Action.P1_DOWN: KEY_S,
	Action.P1_LEFT: KEY_A,
	Action.P1_RIGHT: KEY_D,
	Action.P1_TOGGLE_FACING: KEY_R,
	Action.P1_INVITE: KEY_E,
	Action.P2_UP: KEY_UP,
	Action.P2_DOWN: KEY_DOWN,
	Action.P2_LEFT: KEY_LEFT,
	Action.P2_RIGHT: KEY_RIGHT,
	Action.P2_TOGGLE_FACING: KEY_SEMICOLON,
	Action.P2_INVITE: KEY_L,
}

# TODO
const DEFAULT_JOYPAD_BUTTONS = {
	Action.P1_TOGGLE_FACING: [0, JOY_BUTTON_Y],
	Action.P1_INVITE: [0, JOY_BUTTON_X],
	Action.P2_TOGGLE_FACING: [1, JOY_BUTTON_Y],
	Action.P2_INVITE: [1, JOY_BUTTON_X],
}

const DEFAULT_JOYPAD_MOTIONS = {
	Action.P1_UP: [0, JOY_AXIS_LEFT_Y, 1.0],
	Action.P1_DOWN: [0, JOY_AXIS_LEFT_Y, -1.0],
	Action.P1_LEFT: [0, JOY_AXIS_LEFT_X, -1.0],
	Action.P1_RIGHT: [0, JOY_AXIS_LEFT_X, 1.0],
	Action.P2_UP: [1, JOY_AXIS_LEFT_Y, 1.0],
	Action.P2_DOWN: [1, JOY_AXIS_LEFT_Y, -1.0],
	Action.P2_LEFT: [1, JOY_AXIS_LEFT_X, -1.0],
	Action.P2_RIGHT: [1, JOY_AXIS_LEFT_X, 1.0],
}

static func action_string_player(action: String) -> GameLogic.Player:
	if action.begins_with("P1_"):
		return GameLogic.Player.PLAYER_1
	elif action.begins_with("P2_"):
		return GameLogic.Player.PLAYER_2
	else:
		return GameLogic.Player.PLAYER_NONE

static func init_input_map() -> void:
	# easier to have this in code than in godot's opaque files
	_set_from_dicts(
		DEFAULT_KEYS,
		DEFAULT_JOYPAD_BUTTONS,
		DEFAULT_JOYPAD_MOTIONS,
	)

static func _set_from_dicts(keys, buttons, motions):
	for action in Action:
		var action_value = Action[action]
		InputMap.add_action(action)
		InputMap.action_erase_events(action)

		var key_to_event = func(k):
			var event = InputEventKey.new()
			# TODO: dual keyboard or other weirdness won't get handled
			event.set_device(0)
			event.set_keycode(k)
			return event

		var button_to_event = func(b):
			var event = InputEventJoypadButton.new()
			event.set_device(b[0])
			event.set_button_index(b[1])
			return event

		var motion_to_event = func(m):
			var event = InputEventJoypadMotion.new()
			event.set_device(m[0])
			event.set_axis(m[1])
			event.set_axis_value(m[2])
			return event

		for t in [
			[keys, key_to_event],
			[buttons, button_to_event],
			[motions, motion_to_event],
		]:
			var value_map = t[0]
			var create_event = t[1]

			var value = value_map.get(action_value)
			if value == null:
				continue

			var event = create_event.call(value)
			print("DEBUG InputMap " + action + " " + str(event))
			InputMap.action_add_event(action, event)
