extends Control

const CARD = preload("res://小丑牌/source/card.tscn")

@export var from: Control
@export var card_offset_x: float
@export var z_rot_max: float = 15.0

var is_drawn: bool = false
var rad_z_rot_max: float


func _ready() -> void:
	rad_z_rot_max = deg_to_rad(z_rot_max)


#发牌
func draw_cards(pos: Vector2, num: int) -> void:
	for i in num:
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		var instance = CARD.instantiate()
		add_child(instance)
		instance.global_position = pos
		instance.index = randi_range(0, 51)
		instance.state_machine.current_state.transition_requested.emit(instance.state_machine.current_state, CardState.CardStates.NO_INTERACT)
		
		var final_pos: Vector2 = - (instance.size / 2) - Vector2(card_offset_x * (num - 1 - i), 100.0)
		var z_rot: float = lerp(-rad_z_rot_max, rad_z_rot_max, float(i)/float(num - 1))
		final_pos.x += card_offset_x * (num - 1.0) / 2.0
		final_pos.y -= card_offset_x * (num - 1.0) * (0.5 / sin(rad_z_rot_max)) * (cos(z_rot) - cos(rad_z_rot_max))
		
		instance.set_rot(0.0, 180.0)
		instance.to_rot(0.0, 180.0 * instance.flip_type, 0.3)
		tween.parallel().tween_property(instance, "position", final_pos, 0.3)
		tween.parallel().tween_property(instance, "rotation", z_rot, 0.3)
		await get_tree().create_timer(0.075).timeout
		tween.finished.connect(_on_card_drawn.bind(tween).bind(instance))


#取消发牌
func undraw_cards(pos: Vector2) -> void:
	pass


func _on_draw_button_pressed() -> void:
	if is_drawn:
		undraw_cards(from.global_position)
	else:
		draw_cards(from.global_position, 10)
	is_drawn = !is_drawn


func _on_card_drawn(card_UI: CardUI, drawn_tween: Tween) -> void:
	drawn_tween.kill()
	var current_state := card_UI.state_machine.current_state
	current_state.transition_requested.emit(current_state, CardState.CardStates.IDLE)
	
