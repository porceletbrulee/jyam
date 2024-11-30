class_name Dance3D extends Node3D

var audio_player = null
var game_state: GameState = null
var song_timer: SongTimer = null

var _platforms3d_ref: Platform3D = null

var _ui_scene_debug_ref: Control = null
var _ui_player_to_meter: Dictionary
var _last_beat: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Ring._unittest()
	MinHeap._unittest()

	GameInputs.init_input_map()

	var song_metadata = SongMetadata.new("res://songs/midwaltz.json")

	self._ui_scene_debug_ref = get_node("ui/SceneDebug")
	self._ui_scene_debug_ref.set_visible(false)

	self._ui_player_to_meter = Dictionary()
	self._ui_player_to_meter[GameLogic.Player.PLAYER_1] = get_node("ui/hud/TopMargin/TopHbox/Player1Meter")
	self._ui_player_to_meter[GameLogic.Player.PLAYER_2] = get_node("ui/hud/TopMargin/TopHbox/Player2Meter")

	# TODO: figure out how to dynamically make and attach scripts/properties
	var p1 = get_node("player1")
	var p2 = get_node("player2")
	self._platforms3d_ref = get_node("platforms")

	var platforms = GamePlatforms.new(self._platforms3d_ref)

	var dancer1 = GameDancer.new(
		GameLogic.Player.PLAYER_1,
		p1,
		Vector2(0, 1),
	)
	var dancer2 = GameDancer.new(
		GameLogic.Player.PLAYER_2,
		p2,
		Vector2(2, 2),
	)

	self.audio_player = get_node("AudioStreamPlayer")
	var song = load("res://songs/midwaltz.ogg")
	self.audio_player.stream = song

	self.song_timer = SongTimer.new(
		self.audio_player,
		song_metadata,
		null,
	)

	# FIXME: this will be a circular reference and godot will not clean it up
	# Dance3D should be a child of GameState and there should be a new root
	# for GameState to do _physics_process and _input
	self.game_state = GameState.new(
		self,
		song_timer,
		platforms,
		[dancer1, dancer2],
	)

	p1.scene_ready(
		song_metadata,
		platforms.get_platform(dancer1.platform_pos),
		GameLogic.Player.PLAYER_1,
		p2)
	p2.scene_ready(
		song_metadata,
		platforms.get_platform(dancer2.platform_pos),
		GameLogic.Player.PLAYER_2,
		p1)

	self.game_state.play_song()

func update_player_meter(player: GameLogic.Player, meter: int):
	var bar = self._ui_player_to_meter[player]
	bar.value = meter

func spotlight_platform(platform_pos: Vector2):
	self._platforms3d_ref.spotlight_platform(platform_pos)

func unspotlight():
	self._platforms3d_ref.unspotlight()

func _input(event):
	if event.is_action_pressed("ui_text_delete"):
		self._ui_scene_debug_ref.set_visible(!self._ui_scene_debug_ref.visible)

		# in browser get stuff like this:
		# rate 48000 last 0.010101 next -0.00743433333333 latency 0.09266667068005
		# rate 48000 last 0.008901 next -0.00623433333333 latency 0.09266667068005
		# rate 48000 last 0.0024 next 0.00026666666667 latency 0.09266667068005
		# rate 48000 last 0.01 next -0.00733333333333 latency 0.09266667068005
		# rate 48000 last 0.010399 next -0.00773233333333 latency 0.09266667068005
		var rate = AudioServer.get_mix_rate()
		var last_mix_time = AudioServer.get_time_since_last_mix()
		var next_mix_time = AudioServer.get_time_to_next_mix()
		var latency = AudioServer.get_output_latency()
		print_debug("rate {0} last {1} next {2} latency {3} timer {4}".format(
			[rate, last_mix_time, next_mix_time, latency, self.song_timer._last_sec]))

	self.game_state.input(event)

func _physics_process(delta: float) -> void:
	self.game_state.physics_process(delta)

	if self._ui_scene_debug_ref.visible:
		if self._last_beat != self.song_timer.beat:
			self._last_beat = self.song_timer.beat

			var beat_value = get_node("ui/SceneDebug/ColorRect/BeatCounter/BeatCounterValue")
			var beat_total = get_node("ui/SceneDebug/ColorRect/BeatCounter/BeatCounterTotal")
			beat_value.set_value_no_signal(
				float(
					self._last_beat % self.song_timer.beats_per_measure
				)
			)
			beat_total.set_value_no_signal(float(self._last_beat))
