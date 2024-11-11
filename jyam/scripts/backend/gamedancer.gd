class_name GameDancer extends RefCounted

var player: GameLogic.Player
var node3d: Dancer3D
var platform_pos: Vector2 = GamePlatforms.NOWHERE
var moving: bool

func _init(pplayer: GameLogic.Player, pnode3d: Dancer3D, ppos: Vector2):
	self.player = pplayer
	self.node3d = pnode3d
	self.moving = false
	self.platform_pos = ppos

func _to_string() -> String:
	return "GameDancer({0},{1})".format([
		GameLogic.Player.keys()[self.player], self.node3d.name])
