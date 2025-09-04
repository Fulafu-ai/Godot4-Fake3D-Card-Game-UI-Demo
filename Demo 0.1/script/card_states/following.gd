extends CardState


func enter() -> void:
	if not card_UI: return
	card_UI.pivot_offset.y = card_UI.size.y * 0.9
	
	card_UI.rad_x_max = deg_to_rad(card_UI.angle_x_max)
	card_UI.rad_y_max = deg_to_rad(card_UI.angle_y_max)
	
	card_UI.to_scale(Vector2(1.0, 1.0), 0.5, false)
	card_UI.to_rot(0.0, 180.0 * card_UI.flip_type, 0.5, false)
	
	card_UI.z_index = card_UI.target_UI_z_index
	
	#reparent
	if not card_UI.follow_target.get_children().has(card_UI):
		card_UI.reparent_requested.emit(card_UI.follow_target)
	
	if not card_UI.follow_target: return
	card_UI.follow_target.get_parent().call_deferred("reindex_cards")
	
	await get_tree().create_timer(0.0333).timeout
	card_UI.call_deferred("to_pos", card_UI.follow_pos + card_UI.follow_target.global_position, 0.5, 1)


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
	card_UI.z_index = card_UI.target_UI_z_index + 3
	
	card_UI.to_scale(Vector2(1.2, 1.2), 0.5)


func on_mouse_exited() -> void:
	card_UI.z_index = card_UI.target_UI_z_index
	
	card_UI.to_scale(Vector2(1.0, 1.0), 0.5)
	card_UI.to_rot(0.0, 180.0 * card_UI.flip_type)
