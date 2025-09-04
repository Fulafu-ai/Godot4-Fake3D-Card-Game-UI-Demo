class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var previous_state: State
var states: Dictionary = {}

func init(node: Node) -> void:
	for child in get_children():
		if child is State:
			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state


func _ready() -> void:
	init(null)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_transition_requested(from: State, to: int = previous_state.state) -> void:
	var new_state : State = states[to]
	if from != current_state:
		return
	if not new_state:
		return
	if current_state:
		current_state.exit()
		
	previous_state = current_state
	current_state = new_state
	new_state.enter()
