class_name GameState extends RefCounted
		
var _song_timer_ref: SongTimer = null
var _platforms_ref: GamePlatforms = null
var _player_to_dancer: Dictionary

var _paused: bool = false

func _init(song_timer: SongTimer,
		   platforms,
		   dancers):
	self._song_timer_ref = song_timer
	self._platforms_ref = platforms
	self._player_to_dancer = {}
	for d in dancers:
		self._player_to_dancer[d.player] = d
		self._platforms_ref.set_dancer(d, d.platform_pos)
	self._paused = false

func _perform_action(action: GameInputs.GameAction) -> bool:
	var player = GameInputs.GAME_ACTION_TO_PLAYER.get(action)
	var move_dir = GamePlatforms.GAME_ACTION_TO_MOVE_DIR.get(action)
	if move_dir != null:
		var dancer = self._player_to_dancer[player]
		assert(dancer != null)
		
		if dancer.moving:
			# TODO: allow some input buffering
			return false
		
		var dst_plat = self._platforms_ref.attempt_begin_move(dancer, move_dir)
		
		if dst_plat == null:
			return false

		dancer.moving = true
		# FIXME: trigger dancer move animation

		# closures might be inefficient and/or hard to debug
		var finish_move = func(_context):
			self._platforms_ref.finish_move(dancer, dst_plat)

			dancer.moving = false
			# FIXME: trigger dancer idle animation
			
			print_debug(self._platforms_ref)  # FIXME: remove
			
		var ev = SongTimer.Event.new(
			self._song_timer_ref,
			self._song_timer_ref.sec_per_beat,
			finish_move,
		)
		self._song_timer_ref.insert_event(ev)
		
		return true
		
	return false
		
func input(event: InputEvent) -> void:
	# TODO: does _input race with _physics_process??
	for action_str in GameInputs.GameAction:
		if event.is_action_pressed(action_str):
			var action = GameInputs.GameAction[action_str]
			self._perform_action(action)

func physics_process(delta: float) -> void:
	# update SongTimer first so time is up-to-date
	self._song_timer_ref.physics_process(delta)
	
