class_name GameState extends RefCounted
		
var _song_timer_ref: SongTimer = null
var _platforms_ref: GamePlatforms = null
var _player_to_dancer: Dictionary
var _player_to_anticipation_meter: Dictionary

var _paused: bool = false

var _last_beat: int
var _last_measure: int

func _init(song_timer: SongTimer,
		   platforms,
		   dancers):
	self._song_timer_ref = song_timer
	self._platforms_ref = platforms
	self._player_to_dancer = {}
	for d in dancers:
		self._player_to_dancer[d.player] = d
		self._player_to_anticipation_meter[d.player] = 0
		self._platforms_ref.set_dancer(d, d.platform_pos)

	self._paused = false

	self._last_measure = 0

func anticipation_meter(player: GameLogic.Player) -> int:
	var val = self._player_to_anticipation_meter.get(player)
	assert(val != null)
	return val

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

func _on_measure():
	for p in self._player_to_anticipation_meter:
		var old_meter = self._player_to_anticipation_meter[p]
		var meter = old_meter + GameLogic.ANTICIPATION_GROWTH_PER_MEASURE
		meter = mini(meter, GameLogic.ANTICIPATION_METER_MAX)
		if old_meter != meter:
			self._player_to_anticipation_meter[p] = meter

	for dancer in self._player_to_dancer.values():
		# run the idle animation every measure
		dancer.on_measure(self._song_timer_ref)

func _on_beat():
	for dancer in self._player_to_dancer.values():
		# run the idle animation every measure
		dancer.on_beat(self._song_timer_ref)

func play_song():
	for dancer in self._player_to_dancer.values():
		dancer.trigger_transition(self._song_timer_ref, GameDancer.State.SOLO_IDLE)
	self._song_timer_ref.play()

func physics_process(delta: float) -> void:
	# update SongTimer first so time is up-to-date
	self._song_timer_ref.physics_process(delta)
	
	var beat = self._song_timer_ref.beat
	if self._last_beat != beat:
		if self._last_beat + 1 != beat:
			print_debug("jumped {0} beats, dropping frames?".format([
				beat - self._last_beat
			]))
		self._on_beat()
		self._last_beat = beat
	
	var measure = self._song_timer_ref.measure
	if measure != self._last_measure:
		if self._last_measure + 1 != measure:
			print_debug("jumped {0} measures, dropping frames?".format([
				measure - self._last_measure
			]))
		self._on_measure()
		self._last_measure = measure
