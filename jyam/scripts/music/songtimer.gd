class_name SongTimer extends RefCounted

const AUDIO_LATENCY_UPDATE_RATE = 60
const DEBUG = true

var _asp_ref = null
var _song_metadata_ref = null

var _output_latency = 0.0
var _process_counter = 0
var _last_sec = -100.0

var _beats: int = -1

var _event_context = null
var _events = null
var _next_event = null

var _latency_warned = false

class SongTimerEvent extends RefCounted:
	var time = 0.0
	var callback = null

	# @param playback_position_time: float time relative to song playback time
	# @param callback: should be func(obj: Object), where obj should be consistent
	func _init(playback_position_time: float, pcallback: Callable):
		self.time = playback_position_time
		self.callback = pcallback

	static func sort_asc(left: SongTimerEvent, right: SongTimerEvent) -> bool:
		return left.time < right.time

	static func sort_desc(left: SongTimerEvent, right: SongTimerEvent) -> bool:
		return left.time > right.time


# @param event_context: Object passed into event calls
func _init(asp: AudioStreamPlayer,
		   song_metadata: SongMetadata,
		   event_context: Object):
	self._asp_ref = asp
	self._song_metadata_ref = song_metadata
	
	self._output_latency = AudioServer.get_output_latency()
	self._process_counter = 1
	self._last_sec = 0.0
	
	var events = song_metadata.events
	# we want the lowest times at the end to pop from the back
	events.sort_custom(SongTimerEvent.sort_desc)
	
	self._event_context = event_context
	self._events = events
	self._next_event = events.pop_back()

func play() -> void:
	self._asp_ref.play()

var beats_per_measure: int:
	get:
		return self._song_metadata_ref.beats_per_measure
	set(_value):
		print_debug("don't set this")

var beats: int:
	get:
		return self._beats
	set(_value):
		print_debug("cannot set beat directly")

func _curr_sec() -> float:
	# https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html
	var pos = self._asp_ref.get_playback_position()
	var last_mix = AudioServer.get_time_since_last_mix()
	var result = pos + last_mix - self._output_latency
	if result < 0:
		if pos > self._output_latency and not self._latency_warned:
			# XXX: broken on web until 4.3.1
			# https://github.com/godotengine/godot/issues/95128
			print_debug("audio potentially unstable! pos {0} last_mix {1} latency {2}".format(
				[pos, last_mix, self._output_latency]
			))
			self._latency_warned = true
	return result

func physics_process(_delta: float) -> void:
	if not self._asp_ref.playing:
		return
	
	if self._process_counter >= AUDIO_LATENCY_UPDATE_RATE:
		# you're not supposed to call this too often; it doesn't change much
		self._output_latency = AudioServer.get_output_latency()
		self._process_counter = 0

	var sec = self._curr_sec()
	if sec > self._last_sec:
		self._last_sec = sec
		# update beat counter
		self._beats = int(self._last_sec / self._song_metadata_ref.sec_per_beat)
		
	if self._next_event != null and self._last_sec > self._next_event.time:
		if DEBUG:
			print_debug("last_pos {0} event {1}".format(
				[self._last_sec, self._next_event.time]))
		self._next_event.callback.call(self._event_context)
		self._next_event = self._events.pop_back()
	
