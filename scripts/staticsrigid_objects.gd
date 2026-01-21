class_name RigidObject

var position: Vector2
var rotation: float = 0.0
var mass: float
var is_box: bool
var size: Vector2
var body: Node2D
var forces: Array[ForceData] = []
var contacts: Array[ContactData] = []
