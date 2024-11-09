class_name GamePlatforms extends RefCounted

# example: Vector2.x picks array, Vector2.y picks element in array
# [
#   [ p0, p3, p6]
#   [ p1, p4, p7]
#   [ p2, p5, p8]
# ]
var _cols: Array

class GamePlatform extends RefCounted:
	var loc: Vector2
	var player: GameLogic.Player = GameLogic.Player.PLAYER_NONE
	var node3d: Node3D = null
	func  _init(ploc: Vector2, pplayer: GameLogic.Player, pnode3d: Node3D):
		self.player = pplayer
		self.node3d = pnode3d
		self.loc = ploc
		
	func _to_string() -> String:
		return "GamePlatform({0},{1},{2})".format(
			[self.loc, self.player, self.platform.name])

# m is Array[Array[Node3D]] but that's not supported :(
func _init(m: Array, p1_loc: Vector2, p2_loc: Vector2):
	for col in m.size():
		var platform_col: Array
		var mcol = m[col]
		for row in mcol.size():
			var loc = Vector2(col, row)
			var player: GameLogic.Player
			match loc:
				p1_loc:
					player = GameLogic.Player.PLAYER_1
				p2_loc:
					player = GameLogic.Player.PLAYER_2
				_:
					player = GameLogic.Player.PLAYER_NONE
			var gp = GamePlatform.new(loc, player, mcol[row])
			platform_col.push_back(gp)
		self._cols.push_back(platform_col)
	
func get_platform(pos: Vector2) -> GamePlatform:
	if pos.x >= 0 and pos.x < self._cols.size():
		var col = self._cols[pos.x]
		if pos.y >= 0 and pos.y < col.size():
			return col[pos.y]
	return null
	
func _to_string() -> String:
	return str(self._cols)
