class_name Renderer

var main: Node2D

func setup(m: Node2D):
	main = m

func draw_all():
	main.wall_manager.draw_walls()
	main.object_manager.draw_objects()
	main.force_manager.draw_force_preview()
