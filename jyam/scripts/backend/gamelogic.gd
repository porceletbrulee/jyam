class_name GameLogic

enum Player {
	PLAYER_NONE = 0,
	PLAYER_1,
	PLAYER_2,
}

enum Facing {
	CAMERA = 0,
	PARTNER,
}

enum DancersPosition {
	SOLO = 1,
	CLOSED,
}

const ANTICIPATION_METER_MAX = 100
const ANTICIPATION_GROWTH_PER_MEASURE = 10

static func opposite_facing(f: Facing) -> Facing:
	if f == Facing.CAMERA:
		return Facing.PARTNER
	else:
		return Facing.CAMERA
