extends CardState


func enter() -> void:
	if not card_UI: return
	card_UI.pivot_offset.y = card_UI.size.y * 0.65
	
	card_UI.rad_x_max = deg_to_rad(card_UI.angle_x_max)
	card_UI.rad_y_max = deg_to_rad(card_UI.angle_y_max)
	
	card_UI.to_scale(Vector2(1.0, 1.0), 0.5, false)
	card_UI.to_rot(0.0, 180.0 * card_UI.flip_type, 0.8)
	
	card_UI.call_deferred("move_to_front")
	
	#reparent
	card_UI.follow_target = null
	var main = get_tree().get_first_node_in_group("main")
	card_UI.reparent_requested.emit(main.find_child("TableCards").find_child("DrawnCards"))


func exit() -> void:
	card_UI.z_index = card_UI.target_UI_z_index


func on_gui_input(event: InputEvent) -> void:
	card_UI.card_rotation_display(event, card_UI.flip_type)
	
	if not event is InputEventMouseButton: return
	if not event.is_pressed(): return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			transition_requested.emit(self, CardStates.DRAGGING)
		MOUSE_BUTTON_RIGHT:
			transition_requested.emit(self, CardStates.DISPLAY)


func on_mouse_entered() -> void:
	#print("mouse_enter_idle")
	card_UI.call_deferred("move_to_front")
	card_UI.z_index = card_UI.target_UI_z_index + 2
	
	card_UI.to_scale(Vector2(1.2, 1.2), 0.5)


func on_mouse_exited() -> void:
	card_UI.z_index = card_UI.target_UI_z_index
	
	card_UI.to_scale(Vector2(1.0, 1.0), 0.5, true)
	card_UI.to_rot(0.0, 180.0 * card_UI.flip_type)
