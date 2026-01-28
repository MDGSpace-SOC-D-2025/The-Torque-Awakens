extends RefCounted
class_name TrussMember

var start: Vector2
var end: Vector2

func _init(p1: Vector2, p2: Vector2):
	start = p1
	end = p2

func has_point(p: Vector2) -> bool:
	return (start == p) or (end == p)

func matches(p1: Vector2, p2: Vector2) -> bool:
	return (start == p1 and end == p2) or (start == p2 and end == p1)
