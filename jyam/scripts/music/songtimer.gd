class_name SongTimer extends RefCounted

const AUDIO_LATENCY_UPDATE_RATE = 60

var _asp_ref = null
var _song_metadata_ref = null

var _output_latency = 0.0
var _process_counter = 0
var _last_sec = -100.0

var _beats: int = -1
var _measure: int = -1

var _event_context = null
var events: MinHeap

var _latency_warned = false

class BaseEvent extends RefCounted:
	var start_sec: float
	var trigger_sec: float
	var callback: Callable
	
	# @param pstart_sec: when this event was inserted (some events may be
	#					 inserted before song starts)
	# @param ptrigger_sec: when this event will be triggered
	func _init(pstart_sec: float, ptrigger_sec: float, pcallback: Callable):
		self.start_sec = pstart_sec
		self.trigger_sec = ptrigger_sec
		self.callback = pcallback

	# called when event triggers
	func do(context):
		self.callback.call(context)
		
	static func sort_asc(left, right) -> bool:
		# BaseEvent or any of its child classes
		return left.trigger_sec < right.trigger_sec

# should only be instantiated after the song starts
class Event extends SongTimer.BaseEvent:
	func _init(song_timer_ref: SongTimer, pdelay: float, pcallback: Callable):
		var pstart_sec = song_timer_ref.curr_sec
		var ptrigger_sec = pstart_sec + pdelay
		super(pstart_sec, ptrigger_sec, pcallback)
		
	func _to_string() -> String:
		return "SongTimer.Event({0}, {1})".format([
			self.start_sec, self.trigger_sec])

# @param event_context: Object passed into event calls
func _init(asp: AudioStreamPlayer,
		   song_metadata: SongMetadata,
		   event_context: Object):
	self._asp_ref = asp
	self._song_metadata_ref = song_metadata
	
	self._output_latency = AudioServer.get_output_latency()
	self._process_counter = 1
	self._last_sec = 0.0
	
	self.events = MinHeap.new(SongTimer.BaseEvent.sort_asc)
	
	for event in song_metadata.events:
		self.events.push(event)
	
	self._event_context = event_context

func play() -> void:
	self._beats = 0
	self._measure = 0
	self._asp_ref.play()

var beats_per_measure: int:
	get:
		return self._song_metadata_ref.beats_per_measure
	set(_value):
		assert(false, "don't set beats_per_measure")

var sec_per_beat: float:
	get:
		return self._song_metadata_ref.sec_per_beat
	set(_value):
		assert(false, "don't set sec_per_beat")

var beats: int:
	get:
		return self._beats
	set(_value):
		assert(false, "don't set beats")

var measure: int:
	get:
		return self._measure
	set(_value):
		assert(false, "don't set measure")

var curr_sec: float:
	get:
		return self._last_sec
	set(_value):
		assert(false, "cannot set curr_sec")

func _update_curr_sec() -> float:
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

func insert_event(event: SongTimer.Event) -> bool:
	return self.events.push(event)

func physics_process(_delta: float) -> void:
	if not self._asp_ref.playing:
		return
	
	if self._process_counter >= AUDIO_LATENCY_UPDATE_RATE:
		# you're not supposed to call this too often; it doesn't change much
		self._output_latency = AudioServer.get_output_latency()
		self._process_counter = 0

	var sec = self._update_curr_sec()
	if sec > self._last_sec:
		self._last_sec = sec
		# update beat counter
		self._beats = int(self._last_sec / self._song_metadata_ref.sec_per_beat)
		@warning_ignore("integer_division") self._measure = self._beats / self.beats_per_measure
	
	var next_event = self.events.peek_root()
	if next_event != null and next_event.trigger_sec >= self._last_sec:
		next_event = self.events.pop_root()
		next_event.do(self._event_context)
	
