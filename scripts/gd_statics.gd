extends Node2D

enum WallType { SMOOTH }
enum Mode { WALL, BOX, CIRCLE, OBJECT, FORCE }

@export_group("Colors")
@export var color_smooth: Color = Color.GRAY
@export var color_preview_smooth: Color = Color.WHITE
@export var color_box: Color = Color.STEEL_BLUE
@export var color_circle: Color = Color.DARK_GREEN
@export var color_selected: Color = Color.YELLOW
@export var color_force: Color = Color.RED
@export var color_contact_normal: Color = Color.CYAN

@export_group("Wall Style")
@export var wall_thickness: float = 3.0
@export var hatch_step: float = 10.0
@export var hatch_length: float = 5.0
@export var snap_distance: float = 15.0

@export_group("Physics")
@export var default_mass: float = 10.0
@export var gravity: float = 1
@export var contact_threshold: float = 10.0

var current_mode: Mode = Mode.WALL
var wall_container = Node2D.new()
var object_container = Node2D.new()

var wall_manager: WallManager
var object_manager: ObjectManager
var force_manager: ForceManager
var contact_detector: ContactDetector
var solver: StaticsSolver
var renderer: Renderer

var walls: Array[WallData] = []
var objects: Array[RigidObject] = []

func _ready():
	add_child(wall_container)
	add_child(object_container)
	
	wall_manager = WallManager.new()
	wall_manager.setup(self)
	
	object_manager = ObjectManager.new()
	object_manager.setup(self)
	
	force_manager = ForceManager.new()
	force_manager.setup(self)
	
	contact_detector = ContactDetector.new()
	contact_detector.setup(self)
	
	solver = StaticsSolver.new()
	solver.setup(self)
	
	renderer = Renderer.new()
	renderer.setup(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			current_mode = Mode.WALL
			object_manager.clear_selection()
		elif event.keycode == KEY_B:
			current_mode = Mode.BOX
			object_manager.clear_selection()
		elif event.keycode == KEY_C:
			current_mode = Mode.CIRCLE
			object_manager.clear_selection()
		elif event.keycode == KEY_O:
			current_mode = Mode.OBJECT
			object_manager.clear_selection()
		elif event.keycode == KEY_F:
			current_mode = Mode.FORCE
			object_manager.clear_selection()
		elif event.keycode == KEY_ENTER:
			contact_detector.detect_all_contacts()
			solver.solve()
		elif event.keycode == KEY_SPACE:
			clear_everything()
	
	match current_mode:
		Mode.WALL:
			wall_manager.handle_input(event)
		Mode.BOX:
			object_manager.handle_box_input(event)
		Mode.CIRCLE:
			object_manager.handle_circle_input(event)
		Mode.OBJECT:
			object_manager.handle_object_edit(event)
		Mode.FORCE:
			force_manager.handle_input(event)
	
	queue_redraw()

func clear_everything():
	for obj in objects:
		if is_instance_valid(obj.body):
			obj.body.queue_free()
	objects.clear()
	for wall in walls:
		if is_instance_valid(wall.body):
			wall.body.queue_free()
	walls.clear()
	object_manager.clear_selection()
	wall_manager.is_drawing = false
	force_manager.is_drawing = false
	queue_redraw()

func _draw():
	renderer.draw_all()
