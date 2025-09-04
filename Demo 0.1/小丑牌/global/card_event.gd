class_name CardEvent
extends Node

signal selecting_started
signal selecting_finished

signal dragging_right_click(event: InputEvent)
signal dragging_left_click(event: InputEvent)
signal dragging_middle_click(event: InputEvent)
signal dragging_wheel_up(event: InputEvent)
signal dragging_wheel_down(event: InputEvent)

var dragging_count: int = 0
var cards_on_mouse: int = 0

#卡牌相关事件
var cards_dragging: Array[CardUI]
var cards_displaying: Array[CardUI]


func _input(event: InputEvent) -> void:
	_cards_dragging_input(event)
	_cards_selected_input(event)


func _cards_dragging_input(event: InputEvent) -> void:
	if cards_dragging.size() <= 0: return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT: dragging_right_click.emit(event)
			MOUSE_BUTTON_LEFT: dragging_left_click.emit(event)
			MOUSE_BUTTON_MIDDLE: dragging_middle_click.emit(event)
			MOUSE_BUTTON_WHEEL_UP: dragging_wheel_up.emit(event)
			MOUSE_BUTTON_WHEEL_DOWN: dragging_wheel_down.emit(event)


func _cards_selected_input(event: InputEvent) -> void:
	if get_tree().get_nodes_in_group("selected").size() <= 0: return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: 
				if cards_on_mouse <= 0: return
				get_tree().get_first_node_in_group("dragger").dirty_left_released = true
				for card: CardUI in get_tree().get_nodes_in_group("selected"): 
					card.selected_left_click.emit(event)
