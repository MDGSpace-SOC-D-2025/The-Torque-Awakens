class_name Renderer

var main: Node2D

func setup(m: Node2D):
	main = m

func draw_all():
	var cam = main.get_viewport().get_camera_2d()
	var t_scale = 1.0 / cam.zoom.x if (cam and cam.zoom.x != 0) else 1.0
	
	main.wall_manager.draw_walls(t_scale)
	main.object_manager.draw_objects(t_scale)
	main.force_manager.draw_force_preview(t_scale)
