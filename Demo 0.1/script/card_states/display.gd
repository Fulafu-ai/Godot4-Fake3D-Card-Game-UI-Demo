extends CardState

const DRAGGING_BUFFER_TIME = 0.2
var min_drag_time_elapsed := false


func _on_buffer():
	min_drag_time_elapsed = true


func enter() -> void:
	if not card_UI: return
	Event.cards_displaying.append(card_UI)
	
	card_UI.rad_x_max = deg_to_rad(2.0 * card_UI.angle_x_max)
	card_UI.rad_y_max = deg_to_rad(2.0 * card_UI.angle_y_max)
	card_UI.to_rot(0.0, 0.0)
	card_UI.to_scale(Vector2(1.2, 1.2), 0.5)
	
	card_UI.call_deferred("move_to_front")
	card_UI.z_index = card_UI.target_UI_z_index + 2
	
	min_drag_time_elapsed = false
	var buffer_timer = get_tree().create_timer(DRAGGING_BUFFER_TIME, false)
	buffer_timer.timeout.connect(_on_buffer)


func exit() -> void:
	min_drag_time_elapsed = false
	Event.cards_displaying.erase(card_UI)
	card_UI.z_index = card_UI.target_UI_z_index


func on_input(event: InputEvent) -> void:
	card_UI.card_rotation_display(event, card_UI.flip_type, true)
	if not event is InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_RIGHT: return
	if not min_drag_time_elapsed: return
	if event.is_pressed() or event.is_released():
		transition_requested.emit(self)
	else:
		return
