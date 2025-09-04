class_name CardSelector
extends Control

@onready var label: Label = $Label

@export var color: Color
@export var border_color: Color

var selecting: bool: set = set_selecting
var start_point: Vector2
var select_box: Rect2


func set_selecting(value: bool) -> void:
	if value == true: Event.selecting_started.emit()
	if value == false: Event.selecting_finished.emit()
	selecting = value


func _physics_process(delta: float) -> void:
	if selecting: set_deferred("mouse_filter", Control.MOUSE_FILTER_STOP)
	else: set_deferred("mouse_filter", Control.MOUSE_FILTER_IGNORE)
	
	label.text = "selecting: %s \n stopping: %s" % [selecting, mouse_filter == Control.MOUSE_FILTER_STOP]


func _input(event: InputEvent) -> void:
	#决定选框的顶点位置和大小
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT: return
		if Event.cards_on_mouse != 0: return
		if Event.cards_displaying.size() > 0: return
		if Event.cards_dragging.size() > 0: return
		if event.is_pressed():
			selecting = true
			start_point = event.position
		else:
			selecting = false
			if start_point.is_equal_approx(event.position):
				select_box = Rect2(event.position, Vector2.ZERO)
			update_selected_card()
			queue_redraw()
	elif selecting and event is InputEventMouseMotion:
		var x_min = min(start_point.x, event.position.x)
		var x_l = abs(start_point.x - event.position.x)
		var y_min = min(start_point.y, event.position.y)
		var y_l = abs(start_point.y - event.position.y)
		select_box = Rect2(Vector2(x_min, y_min), Vector2(x_l, y_l))
		update_selected_card()
		queue_redraw()


func _draw() -> void:
	#绘制选框
	if not selecting: return
	draw_rect(select_box, color)
	draw_rect(select_box, border_color, false, 2.0)


func update_selected_card() -> void:
	for unit: CardUI in get_tree().get_nodes_in_group("selectable"):
		if unit.is_in_box(select_box):
			unit.selected = true
		else: 
			unit.selected = false
