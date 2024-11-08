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

static func opposite_facing(f: Facing) -> Facing:
	if f == Facing.CAMERA:
		return Facing.PARTNER
	else:
		return Facing.CAMERA
