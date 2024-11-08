extends Node3D

var audio_player = null
var song_timer = null

var _scene_debug_ref = null
var _last_beats: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameInputs.init_input_map()
	
	var song_metadata = SongMetadata.new("res://songs/My_Castle_Town.json")
	
	self._scene_debug_ref = get_node("SceneDebug")
	self._scene_debug_ref.set_visible(false)
	
	# TODO: figure out how to dynamically make and attach scripts/properties
	var p1 = get_node("puppymaid2")
	var p2 = get_node("player2")
	var platform_layout = self._setup_platforms(Vector2(1,0), Vector2(2,2))
	
	p1.scene_ready(
		song_metadata,
		platform_layout,
		Vector2(1,0),
		GameLogic.Player.PLAYER_1,
		p2)
	p2.scene_ready(
		song_metadata,
		platform_layout,
		Vector2(2,2),
		GameLogic.Player.PLAYER_2,
		p1)
	
	self.audio_player = get_node("AudioStreamPlayer")
	var song = load("res://songs/My_Castle_Town.ogg")
	self.audio_player.stream = song
	
	self.song_timer = SongTimer.new(
		self.audio_player,
		song_metadata,
		null,
	)
	self.song_timer.play()

func _setup_platforms(p1_loc: Vector2, p2_loc: Vector2):
	var plats = [
		[null, null, null],	
		[null, null, null],	
		[null, null, null],
	];
	var rows = plats.size()
	var cols = plats[0].size()
	for i in range(0, rows * cols):
		var child_name = "platform" + str(i);
		var n = get_node("")
		var plat = get_node("platforms/" + child_name)
		var row = i % 3
		@warning_ignore("integer_division") var col = i / 3
		plats[row][col] = plat

	return GamePlatforms.new(plats, p1_loc, p2_loc)

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
	
func _physics_process(delta: float) -> void:
	self.song_timer.physics_process(delta)
	if self._scene_debug_ref.visible:
		if self._last_beats != self.song_timer.beats:
			self._last_beats = self.song_timer.beats
			
			var beat_value = get_node("SceneDebug/ColorRect/BeatCounter/BeatCounterValue")	
			var beat_total = get_node("SceneDebug/ColorRect/BeatCounter/BeatCounterTotal")
			beat_value.set_value_no_signal(
				float(
					self._last_beats % self.song_timer.beats_per_measure
				)
			)
			beat_total.set_value_no_signal(float(self._last_beats))
			
