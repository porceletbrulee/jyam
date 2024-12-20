class_name GamePlatforms extends RefCounted

const NOWHERE: Vector2 = Vector2(-1, -1)

# example: Vector2.x picks row, Vector2.y picks col
# row 0 is closest to camera, last row is furthest
# [
#   [ (0, 0), (0, 1), (0, 2)]
#   [ (1, 0), (1, 1), (1, 2)]
#   [ (2, 0), (2, 1), (2, 2)]
# ]
var _rows_array: Array
var _rows: int
var _cols: int

var _platform3d_ref: Platform3D = null

const ACTION_TO_MOVE_DIR = {
	GameInputs.Action.P1_UP: GameLogic.UP,
	GameInputs.Action.P1_DOWN: GameLogic.DOWN,
	GameInputs.Action.P1_LEFT: GameLogic.LEFT,
	GameInputs.Action.P1_RIGHT: GameLogic.RIGHT,
	GameInputs.Action.P2_UP: GameLogic.UP,
	GameInputs.Action.P2_DOWN: GameLogic.DOWN,
	GameInputs.Action.P2_LEFT: GameLogic.LEFT,
	GameInputs.Action.P2_RIGHT: GameLogic.RIGHT,
}

var rows: int:
	get:
		return self._rows
	set(_value):
		assert(false, "don't set rows")

var cols: int:
	get:
		return self._cols
	set(_value):
		assert(false, "don't set cols")


class Platform extends RefCounted:
	var pos: Vector2
	var dancers: Dictionary
	var global_origin: Vector3

	func _init(ppos: Vector2, pglobal_origin: Vector3):
		self.pos = ppos
		self.global_origin = pglobal_origin
		self.dancers = Dictionary()

	func _to_string() -> String:
		return "GamePlatforms.Platform({0},{1},{2})".format(
			[self.pos, self.dancers, self.global_origin])

func _init(platform3d: Platform3D):
	self._platform3d_ref = platform3d

	var m = self._platform3d_ref.get_platform_map()

	var row_i = 0
	for row in m:
		var curr_row = []
		var col_i = 0
		for exists in row:
			if exists:
				var pos = Vector2(row_i, col_i)
				var global_origin = self._platform3d_ref.platform_global_origin(pos)
				curr_row.append(Platform.new(pos, global_origin))
			else:
				curr_row.append(null)
			col_i += 1
		self._cols = maxi(self._cols, col_i)
		self._rows_array.append(curr_row)
		row_i += 1

	self._rows = row_i

func get_platform(pos: Vector2) -> Platform:
	if pos.x >= 0 and pos.x < self._rows_array.size():
		var row = self._rows_array[pos.x]
		if pos.y >= 0 and pos.y < row.size():
			return row[pos.y]
	return null

func set_dancer(dancer: GameDancer, dst: Vector2):
	var dst_plat = self.get_platform(dst)
	assert(dst_plat != null)
	dst_plat.dancers[dancer.key] = dancer
	dancer.platform_pos = dst_plat.pos

# @returns dst_platform: the destination platform, null if invalid move
func get_dst_platform(dancer: GameDancer, move_dir: Vector2) -> Platform:
	var src_plat = self.get_platform(dancer.platform_pos)
	assert(src_plat != null and src_plat.dancers.has(dancer.key))

	var dst_pos = dancer.platform_pos + move_dir
	var dst_plat = self.get_platform(dst_pos)
	if dst_plat == null:
		return null

	return dst_plat

func finish_move(dancer: GameDancer, dst_plat: Platform):
	var src_plat = self.get_platform(dancer.platform_pos)
	assert(src_plat != null)

	src_plat.dancers.erase(dancer.key)
	dst_plat.dancers[dancer.key] = dancer
	dancer.platform_pos = dst_plat.pos

func _to_string() -> String:
	return str(self._rows_array)

static func platform_offset_from_move_dir(move_dir: Vector2) -> Vector3:
	# if moving down, the dancer should be on the "up" side of the platform,
	# which is negative z
	var offset_dir = Vector3(0, 0, 0)
	match move_dir:
		GameLogic.UP:
			offset_dir = Vector3(0, 0, 1)
		GameLogic.DOWN:
			offset_dir = Vector3(0, 0, -1)
		GameLogic.LEFT:
			offset_dir = Vector3(1, 0, 0)
		GameLogic.RIGHT:
			offset_dir = Vector3(-1, 0, 0)
	return offset_dir
