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

const GAME_ACTION_TO_MOVE_DIR = {
	GameInputs.GameAction.P1_UP: Vector2(1, 0),
	GameInputs.GameAction.P1_DOWN: Vector2(-1, 0),
	GameInputs.GameAction.P1_LEFT: Vector2(0, -1),
	GameInputs.GameAction.P1_RIGHT: Vector2(0, 1),
	GameInputs.GameAction.P2_UP: Vector2(1, 0),
	GameInputs.GameAction.P2_DOWN: Vector2(-1, 0),
	GameInputs.GameAction.P2_LEFT: Vector2(0, -1),
	GameInputs.GameAction.P2_RIGHT: Vector2(0, 1),
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


class GamePlatform extends RefCounted:
	var pos: Vector2
	var dancer: GameDancer = null
	var node3d: Node3D = null
	
	func _init(ppos: Vector2, pnode3d: Node3D):
		self.pos = ppos
		self.node3d = pnode3d
		self.dancer = null
		
	func _to_string() -> String:
		return "GamePlatform({0},{1},{2})".format(
			[self.pos, self.dancer, self.node3d.name])

# m is Array[Array[Node3D]] but that's not supported :(
func _init(m: Array):
	var row_i = 0
	for row in m:
		var curr_row = []
		var col_i = 0
		for node in row:
			var pos = Vector2(row_i, col_i)
			curr_row.append(GamePlatform.new(pos, node))
			col_i += 1
		self._cols = maxi(self._cols, col_i)
		self._rows_array.append(curr_row)
		row_i += 1
	
	self._rows = row_i

func get_platform(pos: Vector2) -> GamePlatform:
	if pos.x >= 0 and pos.x < self._rows_array.size():
		var row = self._rows_array[pos.x]
		if pos.y >= 0 and pos.y < row.size():
			return row[pos.y]
	return null
	
func set_dancer(dancer: GameDancer, dst: Vector2):
	var dst_plat = self.get_platform(dst)
	assert(dst_plat != null && dst_plat.dancer == null)
	dst_plat.dancer = dancer

# @returns dst_platform: the destination platform, null if invalid move
func attempt_begin_move(dancer: GameDancer, move_dir: Vector2) -> GamePlatform:
	var src_plat = self.get_platform(dancer.platform_pos)
	assert(src_plat != null and src_plat.dancer == dancer)

	var dst_pos = dancer.platform_pos + move_dir
	var dst_plat = self.get_platform(dst_pos)
	if dst_plat == null:
		return null
	
	if dst_plat.dancer != null:
		return null

	return dst_plat
	
func finish_move(dancer: GameDancer, dst_plat: GamePlatform):
	var src_plat = self.get_platform(dancer.platform_pos)
	assert(src_plat != null)
	
	src_plat.dancer = null
	dst_plat.dancer = dancer
	dancer.platform_pos = dst_plat.pos
	
func _to_string() -> String:
	return str(self._rows_array)
