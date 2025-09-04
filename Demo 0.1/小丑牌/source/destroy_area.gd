class_name DestroyArea
extends MarginContainer
@onready var area_2d: Area2D = $Area2D


func _physics_process(delta: float) -> void:
	var areas = area_2d.get_overlapping_areas()
	if areas.size() <= 0: return
	for area in areas:
		#area.get_parent().destroy_requested.emit()
		pass
