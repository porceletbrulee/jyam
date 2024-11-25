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

const UP = Vector2(1, 0)
const DOWN = Vector2(-1, 0)
const RIGHT = Vector2(0, 1)
const LEFT = Vector2(0, -1)

const ANTICIPATION_METER_MAX = 100
const ANTICIPATION_GROWTH_PER_MEASURE = 10

static func opposite_facing(f: Facing) -> Facing:
	if f == Facing.CAMERA:
		return Facing.PARTNER
	else:
		return Facing.CAMERA

static func opposite_dir(d: Vector2) -> Vector2:
	match d:
		GameLogic.UP:
			return GameLogic.DOWN
		GameLogic.DOWN:
			return GameLogic.UP
		GameLogic.RIGHT:
			return GameLogic.LEFT
		GameLogic.LEFT:
			return GameLogic.RIGHT
		_:
			assert(false, "oops {0}".format([d]))
			return Vector2(0, 0)
