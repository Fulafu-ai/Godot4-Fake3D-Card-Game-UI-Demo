extends CardState

const DRAGGING_BUFFER_TIME = 0.2
var min_drag_time_elapsed := false


func _on_buffer():
	min_drag_time_elapsed = true


func enter() -> void:
	if not card_UI: return
	Event.cards_dragging.append(card_UI)
	card_UI.selected = false
	card_UI.pivot_offset.y = card_UI.size.y * 0.65
	
	#强制打断当前动画（即使interuptable = false）
	if card_UI.tween_rot and card_UI.tween_rot.is_running():
		card_UI.tween_rot.kill()
	card_UI.to_rot(0.0, 180.0 * card_UI.flip_type)
	card_UI.to_rot_z(0.0, 0.5)
	if card_UI.tween_scale and card_UI.tween_scale.is_running():
		card_UI.tween_scale.kill()
	card_UI.to_scale(Vector2(1.2, 1.2), 0.5)
	
	card_UI.call_deferred("move_to_front")
	card_UI.z_index = card_UI.target_UI_z_index + 2
	
	min_drag_time_elapsed = false
	var buffer_timer = get_tree().create_timer(DRAGGING_BUFFER_TIME, false)
	buffer_timer.timeout.connect(_on_buffer)
	
	#reparent
	var main = get_tree().get_first_node_in_group("main")
	var dragging_cards = main.find_child("TableCards").find_child("DraggingCards")
	card_UI.reparent_requested.emit(dragging_cards)
	card_UI.to_pos(-card_UI.pivot_offset, 0.1, 0, false, false)


func exit() -> void:
	Event.cards_dragging.erase(card_UI)
	
	card_UI.z_index = card_UI.target_UI_z_index
	min_drag_time_elapsed = false


func physics_update(_delta: float) -> void:
	#card_UI.follow_mouse(_delta)
	pass


func on_gui_input(event: InputEvent) -> void:
	#dragging卡牌本身不处理输入事件，只给出实现方案，交由card_event.gd调用
	pass


func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass


func left_click(event: InputEvent) -> void:
	if not min_drag_time_elapsed: return
	
	var follow_table = card_UI.follow_target.get_parent() if card_UI.follow_target else null
	if event.is_released():
		#处理松开左键后进入follow状态的事件
		if card_UI.card_table_overlapping():
			if (not card_UI.card_table_overlapping().is_full) or (card_UI.card_table_overlapping() == follow_table):
				card_UI.follow_requested.emit(card_UI.card_table_overlapping().cards)
				return
		if card_UI.destroy_area_overlapping():
			card_UI.destroy_requested.emit()
			return
		if follow_table: 
			transition_requested.emit(self)
			follow_table.update_card_UIs()
			return
		
		transition_requested.emit(self)
