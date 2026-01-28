extends Resource
class_name TrussConfig

@export var snap_radius: float = 25.0
@export var line_width: float = 20.0
@export var line_thickness: float = 5.0
@export var line_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK

@export var pin_texture: Texture2D
@export var roller_texture: Texture2D
@export var icon_size: Vector2 = Vector2(64, 64)

@export var pin_hole_offset: Vector2 = Vector2.ZERO
@export var roller_hole_offset: Vector2 = Vector2.ZERO
