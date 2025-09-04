extends CardState


func enter() -> void:
	if not card_UI: return
	
	card_UI.selected = false
	if card_UI.is_in_group("selectable"):
		card_UI.remove_from_group("selectable")
	
	if card_UI.follow_target:
		card_UI.follow_target.get_parent().cards_array.erase(card_UI)
	
	#reparent
	card_UI.follow_target = null
	var main = get_tree().get_first_node_in_group("main")
	card_UI.reparent_requested.emit(main.find_child("TableCards").find_child("DrawnCards"))
	
	card_UI.z_index = 99
	
	#强制打断当前动画 (即使interuptable = false)
	if card_UI.tween_rot and card_UI.tween_rot.is_running():
		card_UI.tween_rot.kill()
	card_UI.to_rot(0.0, 180.0 * card_UI.flip_type, 0.1)
	
	if card_UI.tween_scale and card_UI.tween_scale.is_running():
		card_UI.tween_scale.kill()
	card_UI.to_scale(Vector2.ONE)
	card_UI.destroy()


func on_gui_input(event: InputEvent) -> void:
	pass

 
func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass
