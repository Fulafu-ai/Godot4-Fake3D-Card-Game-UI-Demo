class_name CardState
extends State

enum CardStates {IDLE, DISPLAY, DRAGGING, DESTROY, FOLLOWING, NO_INTERACT}

@export var card_state: CardStates: set = set_card_state

var card_UI: CardUI


func _ready() -> void:
	if not Event.is_node_ready():
		await Event.ready
	if not Event.selecting_started.is_connected(_on_selecting_started):
		Event.selecting_started.connect(_on_selecting_started)
	if not Event.selecting_finished.is_connected(_on_selecting_finished):
		Event.selecting_finished.connect(_on_selecting_finished)


func set_card_state(value: CardStates) -> void:
	card_state = value
	state = card_state


func on_gui_input(event: InputEvent) -> void:
	pass


func on_input(event: InputEvent) -> void:
	pass


func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass


func on_destroy_requested() -> void:
	transition_requested.emit(self, CardStates.DESTROY)


func on_follow_requested(_target: Control, index: int = -1) -> void:
	#index表示需要插入的位置，当index为-1时自动排序
	if not _target: return
	if card_UI.follow_target == _target:
		transition_requested.emit(self, CardStates.FOLLOWING)
		if index == -1: card_UI.follow_target.get_parent().cards_array.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		else: card_UI.follow_target.get_parent().update_card_UIs()
		return
	if not _target.get_parent().is_full:
		#原数组中擦除
		if card_UI.follow_target: card_UI.follow_target.get_parent().cards_array.erase(card_UI)
		#赋值
		card_UI.follow_target = _target
		#新数组中添加
		if index == -1: 
			var _i = 0
			for _x in card_UI.follow_target.get_parent().cards_array.get_array():
				var _p = _x.global_position.x - card_UI.global_position.x
				if _p <= 0:
					_i += 1 
				else:
					break
			index = _i
		card_UI.follow_target.get_parent().cards_array.insert(index, card_UI)
		transition_requested.emit(self, CardStates.FOLLOWING)


func _on_selecting_started() -> void:
	pass


func _on_selecting_finished() -> void:
	pass
