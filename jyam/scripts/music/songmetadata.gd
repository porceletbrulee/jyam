class_name SongMetadata extends RefCounted

# don't change these after _init
var sec_per_beat: float = 0.0
var beats_per_measure: int = 0
var sec_per_measure: float = 0.0

var events: Array = []

func _init(path: String) -> void:
	# FIXME: load from file
	self.sec_per_beat = 60.0 / 137.0
	self.beats_per_measure = 3
	self.sec_per_measure = self.sec_per_beat * self.beats_per_measure
	self.events = [
		SongTimer.SongTimerEvent.new(20.0, func(_obj): print_debug("yay 20")),
		SongTimer.SongTimerEvent.new(4.0, func(_obj): print_debug("yay 4")),
		SongTimer.SongTimerEvent.new(15.0, func(_obj): print_debug("yay 15"))
	]
