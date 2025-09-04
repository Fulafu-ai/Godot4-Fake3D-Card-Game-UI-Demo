class_name CardStateMachine
extends StateMachine

#var transitioning: bool = false
var cards_displaying = Event.cards_displaying
var cards_dragging = Event.cards_dragging


func init(card_UI: Node) -> void:
	for child in get_children():
		if child is CardState:
			states[child.state] = child
			if not child.transition_requested.is_connected(_on_transition_requested):
				child.transition_requested.connect(_on_transition_requested)
			if card_UI is CardUI:
				child.card_UI = card_UI
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state


func _input(event: InputEvent) -> void:
	#if transitioning: return
	if current_state:
		current_state.on_input(event)


func _on_gui_input(event: InputEvent) -> void:
	#if transitioning: return
	if (cards_dragging.size() > 0 and not cards_dragging.has(current_state.card_UI)) or (cards_displaying.size() > 0 and not cards_displaying.has(current_state.card_UI)): return
	if current_state:
		current_state.on_gui_input(event)


func _on_mouse_entered() -> void:
	#if transitioning: return
	if (cards_dragging.size() > 0 and not cards_dragging.has(current_state.card_UI)) or (cards_displaying.size() > 0 and not cards_displaying.has(current_state.card_UI)): return
	if current_state:
		current_state.on_mouse_entered()


func _on_mouse_exited() -> void:
	#if transitioning: return
	if (cards_dragging.size() > 0 and not cards_dragging.has(current_state.card_UI)) or (cards_displaying.size() > 0 and not cards_displaying.has(current_state.card_UI)): return
	if current_state:
		current_state.on_mouse_exited()


func _on_destroy_requested() -> void:
	#if transitioning: return
	if current_state:
		current_state.on_destroy_requested()


func _on_follow_requested(_target: Control, index: int = -1) -> void:
	#if transitioning: return
	if current_state:
		current_state.on_follow_requested(_target, index)


func _on_selected_left_click(event: InputEvent) -> void:
	if not event.is_pressed(): return
	if current_state:
		current_state.transition_requested.emit(current_state, CardState.CardStates.IDLE)
		current_state.transition_requested.emit(current_state, CardState.CardStates.DRAGGING)


func _on_transition_requested(from: State, to: int = previous_state.state) -> void:
	var new_state : State = states[to]
	if from != current_state:
		return
	if not new_state:
		return
	if current_state:
		#transitioning = true
		current_state.exit()
		
	previous_state = current_state
	current_state = new_state
	new_state.enter()
	#transitioning = false


func to_state(state: int) -> void:
	if not current_state: return
	current_state.transition_requested.emit(current_state, state)
