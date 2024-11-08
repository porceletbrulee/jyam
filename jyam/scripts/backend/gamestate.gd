class_name GameState extends RefCounted
		
var _song_timer_ref: SongTimer = null
var _platforms_ref: GamePlatforms = null
var _p1_ref = null
var _p2_ref = null

var _paused: bool = false

func _init(song_timer: SongTimer,
		   platforms,
		   player1,
		   player2):
	self._song_timer_ref = song_timer
	self._platforms_ref = platforms
	self._p1_ref = player1
	self._p2_ref = player2

func _is_action_valid(action: GameInputs.GameAction):
	var dir = GameInputs.GAME_ACTION_TO_DIR.get(action)
	# TODO: check move against platforms

func input(event: InputEvent) -> void:
	for action_str in GameInputs.GameAction:
		if event.is_action_pressed(action_str):
			var action = GameInputs.GameAction[action_str]
			if not self._is_action_valid(action):
				continue
				
