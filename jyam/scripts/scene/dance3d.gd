extends Node3D

var audio_player = null
var game_state: GameState = null
var song_timer: SongTimer = null

var _scene_debug_ref = null
var _last_beat: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Ring._unittest()
	MinHeap._unittest()
	
	GameInputs.init_input_map()
	
	var song_metadata = SongMetadata.new("res://songs/My_Castle_Town.json")
	
	self._scene_debug_ref = get_node("SceneDebug")
	self._scene_debug_ref.set_visible(false)
	
	# TODO: figure out how to dynamically make and attach scripts/properties
	var p1 = get_node("player1")
	var p2 = get_node("player2")
	var platforms = self._setup_platforms()
	
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
	var song = load("res://songs/My_Castle_Town.ogg")
	self.audio_player.stream = song

	self.song_timer = SongTimer.new(
		self.audio_player,
		song_metadata,
		null,
	)

	self.game_state = GameState.new(
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

func _setup_platforms():
	# on screen, row 0 is closest to the camera
	var plat_nums = [
		[0, 1, 2],
		[3, 4, 5],
		[6, 7, 8],
	];
		
	var plats = []	
	for row in plat_nums:
		var plat_row = []
		for num in row:
			var child_name = "platform" + str(num);
			var plat = get_node("platforms/" + child_name)
			
			plat_row.append(plat)
		plats.append(plat_row)

	return GamePlatforms.new(plats)

func _input(event):
	if event.is_action_pressed("ui_text_delete"):
		self._scene_debug_ref.set_visible(!self._scene_debug_ref.visible)
		
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
	
	if self._scene_debug_ref.visible:
		if self._last_beat != self.song_timer.beat:
			self._last_beat = self.song_timer.beat
			
			var beat_value = get_node("SceneDebug/ColorRect/BeatCounter/BeatCounterValue")	
			var beat_total = get_node("SceneDebug/ColorRect/BeatCounter/BeatCounterTotal")
			beat_value.set_value_no_signal(
				float(
					self._last_beat % self.song_timer.beats_per_measure
				)
			)
			beat_total.set_value_no_signal(float(self._last_beat))
			
