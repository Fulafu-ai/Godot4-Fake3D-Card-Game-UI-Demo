extends Control

const CARD_SIZE = Vector2(88.0, 124.0)

@onready var label: Label = $Label

@export var position_y_curve: Curve
@export var rotation_z_curve: Curve

@export var width: float
@export var expand_width: float
@export var delta_y_max: float

var expand: bool = false: set = set_expand
##被展示放大的牌的索引，默认从后往前数
var display_index: int = 0: set = set_display_index
##标记：选择牌后点击之后的第一次松开左键不产生效果
var dirty_left_released: bool = false


func set_expand(value: bool) -> void:
	expand = value
	call_deferred("repos_cards")


func set_display_index(value: int) -> void:
	var v: int
	if Event.cards_dragging.size() <= 0: v = 0
	else: v = clampi(value, 0, Event.cards_dragging.size() - 1)
	if display_index != v: call_deferred("repos_cards")
	display_index = v


func _ready() -> void:
	if not Event.is_node_ready():
		await Event.ready
	if not Event.dragging_left_click.is_connected(_on_left_click):
		Event.dragging_left_click.connect(_on_left_click)
	if not Event.dragging_middle_click.is_connected(_on_middle_click):
		Event.dragging_middle_click.connect(_on_middle_click)
	if not Event.dragging_right_click.is_connected(_on_right_click):
		Event.dragging_right_click.connect(_on_right_click)
	if not Event.dragging_wheel_up.is_connected(_on_wheel_up):
		Event.dragging_wheel_up.connect(_on_wheel_up)
	if not Event.dragging_wheel_down.is_connected(_on_wheel_down):
		Event.dragging_wheel_down.connect(_on_wheel_down)


func _process(delta: float) -> void:
	follow_mouse(delta)
	label.text = str(display_index)
	pass


##处理鼠标跟随
func follow_mouse(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	global_position = mouse_pos


func _on_child_entered_tree(node: Node) -> void:
	display_index = display_index
	call_deferred("repos_cards")


func _on_child_exiting_tree(node: Node) -> void:
	display_index = display_index
	call_deferred("repos_cards")
	if Event.cards_dragging.size() <= 0: expand = false


func _on_left_click(event: InputEvent) -> void:
	var cards_dragging = Event.cards_dragging
	
	##处理脏标记
	if event.is_released() and dirty_left_released:
		dirty_left_released = false
		if cards_dragging.size() > 1: return
		else: pass
	
	var i = cards_dragging.size() - 1 - display_index if expand else cards_dragging.size() - 1
	if i < 0: return
	var cur_state = cards_dragging[i].state_machine.current_state
	if cur_state.state == CardState.CardStates.DRAGGING:
		cur_state.left_click(event)


func _on_middle_click(event: InputEvent) -> void:
	if event.is_pressed(): 
		expand = not expand


func _on_wheel_up(event: InputEvent) -> void:
	if Event.cards_dragging.size() <= 0 or not expand: return
	if not event.is_pressed(): return
	display_index += 1


func _on_wheel_down(event: InputEvent) -> void:
	if Event.cards_dragging.size() <= 0 or not expand: return
	if not event.is_pressed(): return
	display_index -= 1


func _on_right_click(event: InputEvent) -> void:
	var cards_dragging = Event.cards_dragging
	Event.dragging_count = cards_dragging.size()
	var overlapping_table = cards_dragging[0].card_table_overlapping()
	var overlapping_destroy = cards_dragging[0].destroy_area_overlapping()
	
	if event.is_released():
		#处理松开右键后进入follow状态的事件
		if overlapping_table:
			var volume = overlapping_table.volume
			var cur_count = overlapping_table.cards_array.size()
			var will_be_full = ((cur_count + Event.dragging_count) > volume) or overlapping_table.is_full
			if not will_be_full:
				var index = _index_of_first_dragging_card(overlapping_table)
				for i in cards_dragging.size():
					cards_dragging[0].follow_requested.emit(overlapping_table.cards, index + i)
				return
		
		if overlapping_destroy:
			var n = cards_dragging.size()
			for i in range(n):
				cards_dragging[0].destroy_requested.emit()
			return
		
		var n = cards_dragging.size()
		for i in range(n):
			var card_UI = cards_dragging[n - i - 1]
			var cur_state = card_UI.state_machine.current_state
			if card_UI.follow_target: 
				cur_state.transition_requested.emit(cur_state, CardState.CardStates.FOLLOWING)
				card_UI.follow_target.get_parent().update_card_UIs()
				continue
			cur_state.transition_requested.emit(cur_state)
		return


func repos_cards() -> void:
	var cards = Event.cards_dragging
	if cards.size() <= 0: return
	if cards.size() == 1: 
		cards[0].dragging_offset = Vector3(0.0, 0.0, 0.0)
		return
	for i in cards.size():
		var card = cards[i]
		var wid = expand_width if expand else width
		var offset_x = (float(i) * 1 / (cards.size() - 1) - 0.5) * wid * CARD_SIZE.x
		var offset_y = position_y_curve.sample(float(i) * 1 / (cards.size() - 1)) * delta_y_max * CARD_SIZE.y if expand else 0.0
		var rot_z = deg_to_rad(rotation_z_curve.sample(float(i) * 1 / (cards.size() - 1))) if expand else 0.0
		
		##使card显示在最上面
		if card.get_parent() == self:
			card.move_to_front()
		
		var stand_out: Vector3 = Vector3.ZERO
		if expand && i == (cards.size() - 1 - display_index):
			stand_out = Vector3(sin(rot_z), - cos(rot_z), 0.0) * 0.24 * CARD_SIZE.y
		card.dragging_offset = Vector3(offset_x, - offset_y, rot_z) + stand_out


#判断cards_dragging的第0张牌根据global_position.x得到的索引
func _index_of_first_dragging_card(card_table: CardTable) -> int:
	if Event.cards_dragging.size() <= 0: return 0
	var _i = 0
	for _x in card_table.cards_array.get_array():
		var _p = _x.global_position.x - Event.cards_dragging[0].global_position.x
		if _p <= 0:
			_i += 1 
		else:
			break
	return _i
