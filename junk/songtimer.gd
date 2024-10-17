extends Object

const AUDIO_LATENCY_UPDATE_RATE = 60
const DEBUG = true

var _asp = null
var _output_latency = 0.0
var _process_counter = 0
var _last_pos = 0.0

var _event_context = null
var _events = null
var _next_event = null

var _latency_warned = false

# @param events: Array[AudioTimerEvent], but gdscript breaks...
func _init(asp: AudioStreamPlayer,
		   events: Array,
		   event_context: Object):
	self._asp = asp
	self._output_latency = AudioServer.get_output_latency()
	self._process_counter = 1
	self._last_pos = self._curr_pos()
	
	# we want the lowest times at the end to pop from the back
	events.sort_custom(SongTimerEvent.sort_desc)
	
	self._event_context = event_context
	self._events = events
	self._next_event = events.pop_back()
	
func _curr_pos() -> float:
	# https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html
	var pos = self._asp.get_playback_position()
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
	if self._process_counter >= AUDIO_LATENCY_UPDATE_RATE:
		# you're not supposed to call this too often; it doesn't change much
		self._output_latency = AudioServer.get_output_latency()
		self._process_counter = 0
	
	var pos = self._curr_pos()
	if pos > self._last_pos:
		self._last_pos = pos
	
	if self._next_event != null and self._last_pos > self._next_event.time:
		if DEBUG:
			print_debug("last_pos {0} event {1}".format(
				[self._last_pos, self._next_event.time]))
		self._next_event.callback.call(self._event_context)
		self._next_event = self._events.pop_back()
	
	
