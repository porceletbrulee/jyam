extends Object

class_name SongTimerEvent

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

		
