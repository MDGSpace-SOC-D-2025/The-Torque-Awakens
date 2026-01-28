extends Node2D

enum WallType { SMOOTH }
enum Mode { WALL, BOX, CIRCLE, OBJECT, FORCE, RULER }

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

var mass_popup: ConfirmationDialog
var mass_input: LineEdit
var pending_object: RigidObject

var force_popup: ConfirmationDialog
var force_input: LineEdit
var pending_force_data: Dictionary = {}

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
	
	_setup_ui()

func _setup_ui():
	mass_popup = ConfirmationDialog.new()
	mass_popup.title = "Set Mass"
	mass_input = LineEdit.new()
	mass_input.placeholder_text = "Mass (kg)"
	mass_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	mass_popup.add_child(mass_input)
	add_child(mass_popup)
	mass_popup.confirmed.connect(_on_mass_confirmed)
	
	force_popup = ConfirmationDialog.new()
	force_popup.title = "Set Force Magnitude"
	force_input = LineEdit.new()
	force_input.placeholder_text = "Magnitude (N)"
	force_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	force_popup.add_child(force_input)
	add_child(force_popup)
	force_popup.confirmed.connect(_on_force_confirmed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W: current_mode = Mode.WALL
		elif event.keycode == KEY_B: current_mode = Mode.BOX
		elif event.keycode == KEY_C: current_mode = Mode.CIRCLE
		elif event.keycode == KEY_O: current_mode = Mode.OBJECT
		elif event.keycode == KEY_F: current_mode = Mode.FORCE
		elif event.keycode == KEY_ENTER:
			contact_detector.detect_all_contacts()
			solver.solve()
		elif event.keycode == KEY_SPACE: clear_everything()
	
	match current_mode:
		Mode.WALL: wall_manager.handle_input(event)
		Mode.BOX: object_manager.handle_box_input(event)
		Mode.CIRCLE: object_manager.handle_circle_input(event)
		Mode.OBJECT: object_manager.handle_object_edit(event)
		Mode.FORCE: force_manager.handle_input(event)
	
	queue_redraw()

func request_mass_input(obj: RigidObject):
	pending_object = obj
	mass_popup.popup_centered(Vector2i(250, 80))
	mass_input.grab_focus()

func _on_mass_confirmed():
	if pending_object:
		var val = mass_input.text.to_float()
		pending_object.mass = val if val > 0 else default_mass
	mass_input.clear()

func request_force_magnitude(obj, direction, magnitude):
	pending_force_data = {"obj": obj, "dir": direction, "mag": magnitude}
	force_input.text = str(snapped(magnitude, 0.1))
	force_popup.popup_centered(Vector2i(250, 80))
	force_input.grab_focus()

func _on_force_confirmed():
	var val = force_input.text.to_float()
	if val > 0:
		var force = ForceData.new()
		force.direction = pending_force_data.dir
		force.magnitude = val
		pending_force_data.obj.forces.append(force)
	force_input.clear()
	queue_redraw()

func clear_everything():
	for obj in objects: if is_instance_valid(obj.body): obj.body.queue_free()
	objects.clear()
	for wall in walls: if is_instance_valid(wall.body): wall.body.queue_free()
	walls.clear()
	queue_redraw()

func _draw():
	renderer.draw_all()
	solver.draw_results(self)
