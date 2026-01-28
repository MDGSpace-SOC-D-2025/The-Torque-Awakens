extends Control




func _on_statics_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gd_statics.tscn")


func _on_truss_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/trussdraw.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
