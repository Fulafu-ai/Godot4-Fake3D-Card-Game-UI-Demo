class_name CardTable
extends Control

const VISUAL_CARD = preload("res://小丑牌/source/visual_card.tscn")
const CARD_SIZE = Vector2(88.0, 124.0)

@onready var area_2d: Area2D = %Area2D
@onready var cards: Control = %Cards
@onready var background: Panel = %Background
@onready var pos_settler: ScrollContainer = %PosSettler
@onready var cards_container: HBoxContainer = %VisualCardsContainer
@onready var button_box: VBoxContainer = $ButtonBox

@export var position_y_curve: Curve
@export var rotation_z_curve: Curve

@export var volume: int = 4
@export var shrink_rate: float = 0.3

@export var sort_by_suit: bool = false

var cards_array: ObservableArray: set = set_cards_array
var is_full: bool = false
var curve_on: bool = true


func _ready() -> void:
	cards_array = ObservableArray.new()
	area_2d.get_children()[0].shape = area_2d.get_children()[0].shape.duplicate()
	resize_table()


func set_cards_array(value: ObservableArray) -> void:
	cards_array = value
	if not cards_array.array_changed.is_connected(_on_cards_array_changed):
		cards_array.array_changed.connect(_on_cards_array_changed)
	_on_cards_array_changed()


func _process(delta: float) -> void:
	if cards_array.size() >= volume:
		is_full = true
	else:
		is_full = false


func _physics_process(delta: float) -> void:
	#var areas = area_2d.get_overlapping_areas()
	#if areas.size() <= 0: return
	#for area in areas:
		#var area_state = area.get_parent().state_machine.current_state.state
		
		#if area_state == CardState.CardStates.IDLE:
			#if is_full: return
			#area.get_parent().follow_requested.emit(cards)
	pass


func reindex_cards() -> void:
	if cards_array.size() <= 0: return
	var i := 0
	for card_UI: CardUI in cards_array.get_array():
		if i >= volume: break
		var visual_card = cards_container.get_children()[i]
		card_UI.call_deferred("move_to_front")


func repos_cards() -> void:
	if cards_array.size() <= 0: return
	var i := 0
	for card_UI: CardUI in cards_array.get_array():
		if i >= volume: break
		var visual_card = cards_container.get_children()[i]
		var pos0 = visual_card.global_position + (visual_card.size.x / 2 - card_UI.size.x / 2) * Vector2.RIGHT
		var center_x = visual_card.global_position.x + visual_card.size.x / 2
		var center_x_percent = (center_x - cards_container.global_position.x) / cards_container.size.x
		var offset_y = - position_y_curve.sample(center_x_percent) * CARD_SIZE.y if curve_on else 0.0
		var rot_z = deg_to_rad(rotation_z_curve.sample(center_x_percent)) if curve_on else 0.0
		
		card_UI.follow_pos = pos0 + offset_y * Vector2(0.0, 1.0) - card_UI.follow_target.global_position
		i += 1
		
		if card_UI.state_machine.current_state.state == CardState.CardStates.DRAGGING: continue
		card_UI.to_pos(card_UI.follow_pos + card_UI.follow_target.global_position, 0.5 , 1)
		card_UI.to_rot_z(rot_z, 0.2)


func update_visual_cards() -> void:
	# 确保cards_container已就绪
	if not is_instance_valid(cards_container):
		return
	
	var target_count = cards_array.size()
	var current_count = cards_container.get_child_count()
	#print("%s/%s" % [current_count, target_count])
	
	# 如果数量没有变化，不需要做任何事
	if target_count == current_count:
		return
	
	# 如果需要减少卡片数量
	if target_count < current_count:
		for i in range(current_count - 1, target_count - 1, -1):
			cards_container.get_children()[i].queue_free()
		return
	
	# 如果需要增加卡片数量
	if target_count > current_count:
		for i in range(current_count, target_count, 1):
			var visual_card = VISUAL_CARD.instantiate()
			cards_container.add_child(visual_card)
		return


func _on_cards_array_changed() -> void:
	#清除无效元素
	for card_UI: CardUI in cards_array.get_array():
		if not is_instance_valid(card_UI): 
			cards_array.erase(card_UI)
			return
	update_card_UIs()


func update_card_UIs() -> void:
	update_visual_cards()
	await get_tree().create_timer(0.01667).timeout
	call_deferred("reindex_cards")
	call_deferred("repos_cards")


func _on_sort_button_pressed() -> void:
	sort_cards()


func sort_cards() -> void:
	if sort_by_suit:
		cards_array.sort_custom(
			func(a, b): 
			if int(Csv2Dict.poker_infos[str(a.index)]["suit_value"]) == int(Csv2Dict.poker_infos[str(b.index)]["suit_value"]):
				return int(Csv2Dict.poker_infos[str(a.index)]["poker_number"]) < int(Csv2Dict.poker_infos[str(b.index)]["poker_number"])
			return int(Csv2Dict.poker_infos[str(a.index)]["suit_value"]) < int(Csv2Dict.poker_infos[str(b.index)]["suit_value"])
			)
		return
	cards_array.sort_custom(
		func(a, b): 
		if int(Csv2Dict.poker_infos[str(a.index)]["poker_number"]) == int(Csv2Dict.poker_infos[str(b.index)]["poker_number"]):
			return int(Csv2Dict.poker_infos[str(a.index)]["suit_value"]) < int(Csv2Dict.poker_infos[str(b.index)]["suit_value"])
		return int(Csv2Dict.poker_infos[str(a.index)]["poker_number"]) < int(Csv2Dict.poker_infos[str(b.index)]["poker_number"])
		)


func _on_shrink_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		curve_on = false
		resize_table(shrink_rate, 1.0)
	else:
		curve_on = true
		resize_table(1 / shrink_rate)


func resize_table(x_rate: float = 1.0, y_rate: float = 1.0) -> void:
	background.size *= Vector2(x_rate, y_rate)
	
	pos_settler.size.y *= y_rate
	pos_settler.size.x = background.size.x - CARD_SIZE.x
	pos_settler.position.x = CARD_SIZE.x / 2
	
	area_2d.get_children()[0].shape.size = background.size
	area_2d.get_children()[0].position = background.size / 2
	#button_box.size.y *= y_rate
	#button_box.position.x = background.position.x + background.size.x + 10
	
	update_card_UIs()


func _on_delete_button_pressed() -> void:
	delete_cards()


func delete_cards() -> void:
	if cards_array.size() <= 0: return
	for card_UI: CardUI in cards_array.get_array():
		if not is_instance_valid(card_UI): continue
		card_UI.destroy_requested.emit()


func _on_check_all_button_pressed() -> void:
	check_all_cards()


func check_all_cards() -> void:
	if cards_array.size() <= 0: return
	for card_UI: CardUI in cards_array.get_array():
		if not is_instance_valid(card_UI): continue
		var cur_state = card_UI.state_machine.current_state
		cur_state.transition_requested.emit(cur_state, CardState.CardStates.DRAGGING)
