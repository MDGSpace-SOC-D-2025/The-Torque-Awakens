extends Node2D

enum WallType { SMOOTH }
enum Mode { WALL, BOX, CIRCLE, OBJECT, FORCE,RULER }

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
	mass_popup = ConfirmationDialog.new()
	mass_popup.title = "Set Mass"
	mass_popup.exclusive = true
	
	mass_input = LineEdit.new()
	mass_input.placeholder_text = "Enter mass (kg)"
	mass_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	mass_input.text_changed.connect(func(new_text):
		var pos = mass_input.caret_column
		var filtered = ""
		for c in new_text:
			if c in "0123456789.":
				filtered += c
		mass_input.text = filtered
		mass_input.caret_column = pos
	)
	
	mass_popup.add_child(mass_input)
	mass_popup.register_text_enter(mass_input)
	mass_popup.confirmed.connect(_on_mass_confirmed)
	mass_popup.canceled.connect(_on_mass_canceled)
	add_child(mass_popup)

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
	
	if _is_interacting():
		get_viewport().set_input_as_handled()
	
	queue_redraw()

func _is_interacting() -> bool:
	return wall_manager.is_drawing or object_manager.is_drawing or \
		   object_manager.is_grabbing or object_manager.is_rotating or \
		   force_manager.is_drawing

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
	solver.clear_results()
	queue_redraw()

func _on_mass_confirmed():
	if pending_object:
		var val = mass_input.text.to_float()
		pending_object.mass = val if val > 0 else default_mass
		pending_object = null
	mass_input.clear()
	


func _on_mass_canceled():
	if pending_object:
		object_manager._remove_object_instance(pending_object)
		pending_object = null
	mass_input.clear()

func request_mass_input(obj: RigidObject):
	pending_object = obj
	mass_popup.popup_centered(Vector2i(250, 80))
	mass_input.grab_focus()

func _draw():
	renderer.draw_all()
	solver.draw_results(self)
