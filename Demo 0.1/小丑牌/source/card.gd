class_name CardUI
extends Control

signal reparent_requested(new_parent: Node)
signal destroy_requested
signal follow_requested(target: Control, index: int)
signal selected_left_click(event: InputEvent)

const POKER_TEXTURE_FOLDER = "res://小丑牌/art/Top-Down/Cards/"
const ID_DICT = {"H": "Hearts/", "D": "Diamonds/", "C": "Clubs/", "S": "Spades/"}

enum FlipType {FRONT, BACK}
@export var flip_type: FlipType

@onready var card_texture: TextureRect = %CardTexture
@onready var card_back_texture: TextureRect = %CardBackTexture
@onready var shadow: TextureRect = %Shadow

@onready var area_destroy: Area2D = $AreaDestroy
@onready var collision_shape: CollisionShape2D = $AreaDestroy/CollisionShape2D

@onready var state_machine: CardStateMachine = $StateMachine
@onready var label: Label = $Label

@export_range(0.0, 180.0) var fov: float = 90.0: set = set_fov
@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var shadow_offset_max: float = 50.0

@export_range(0, 12) var index: int: set = set_index

var follow_target: Control: set = set_follow_target
var follow_pos: Vector2 ##follow_pos为相对位置
var dragging_offset: Vector3: set = set_dragging_offset ##dragging时的相对位置

var tween_rot: Tween
var tween_rot_z: Tween
var tween_scale: Tween
var tween_pos: Tween
var tween_dissolve: Tween

var rot_interuptable: bool = true
var rot_z_interuptable: bool = true
var scale_interuptable: bool = true
var pos_interuptable: bool = true
var dissolve_interuptable: bool = true

var selected: bool: set = set_selected

var rad_x_max: float
var rad_y_max: float

var target_UI_z_index: int = 1


func set_index(value: int) -> void:
	index = value
	var suit = Csv2Dict.poker_infos[str(index)]["poker_suit"]
	var number = int(Csv2Dict.poker_infos[str(index)]["poker_number"])
	if not card_texture: await ready
	var file_name = "%02d.png" % (number - 1)
	var texture_path = POKER_TEXTURE_FOLDER + ID_DICT[suit] + file_name
	var texture = load(texture_path)
	if texture:
		card_texture.texture = texture
	else:
		push_error("Failed to load texture: " + texture_path)


func set_rot(rot_x: float, rot_y: float) -> void:
	if not is_node_ready():
		await ready
	card_texture.material.set("shader_parameter/x_rot", rot_x)
	card_texture.material.set("shader_parameter/y_rot", rot_y)
	card_back_texture.material.set("shader_parameter/x_rot", rot_x)
	card_back_texture.material.set("shader_parameter/y_rot", rot_y - 180.0)
	shadow.material.set("shader_parameter/x_rot", rot_x)
	shadow.material.set("shader_parameter/y_rot", rot_y)


func set_fov(value: float) -> void:
	if not is_node_ready():
		await ready
	fov = value
	card_texture.material.set("shader_parameter/fov", fov)
	card_back_texture.material.set("shader_parameter/fov", fov)
	shadow.material.set("shader_parameter/fov", fov)


func set_follow_target(value: Control) -> void:
	if value == null and follow_target: follow_target.get_parent().cards_array.erase(self)
	follow_target = value


func set_dragging_offset(value: Vector3) -> void:
	if tween_pos and tween_pos.is_running():
		tween_pos.kill()
	call_deferred("to_pos", Vector2(value.x, value.y) - pivot_offset, 0.5, 1, true, false)
	call_deferred("to_rot_z", value.z, 0.1)
	dragging_offset = value


func set_selected(value: bool) -> void:
	if not is_node_ready():
		await ready
	if value: 
		shadow.material.set("shader_parameter/selected", true)
		add_to_group("selected")
	else: 
		shadow.material.set("shader_parameter/selected", false)
		if not is_in_group("selected"): return
		remove_from_group("selected")
	selected = value


func _ready() -> void:
	scale = Vector2.ONE
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	_handle_shadow(delta)
	if state_machine.current_state and state_machine.previous_state: 
		label.text = "%s, %s" % [state_machine.previous_state.name, state_machine.current_state.name]
		#label.text = "%s, %s" % [z_index , shadow.get_z_index()]
		#label.text = Csv2Dict.poker_infos[str(index)]["poker_number"]
		#label.text = "%.1f, %.1f" % [position.y, dragging_offset.y]
		#label.text = str(pivot_offset)
		#label.text = str(selected)


func _on_reparent_requested(new_parent: Node) -> void:
	if get_parent() != new_parent:
		if not new_parent: return
		if tween_pos and tween_pos.is_running():
			tween_pos.kill()
		reparent(new_parent)


func card_rotation_display(event: InputEvent, flip_type: int = 0, no_limit: bool = false) -> void:
	#flip_type = 0代表正面， =1代表背面； no_limit = true表明当鼠标在牌外仍然会旋转卡牌
	if not event is InputEventMouseMotion: return
	if not no_limit: if not get_global_rect().has_point(event.global_position): return
	var mouse_pos: Vector2 = get_local_mouse_position()
	var lerp_val_y: float = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_val_x: float = remap(mouse_pos.y, 0.0, size.y, 1.0, 0.0)
	
	var rot_x := rad_to_deg(lerp_angle(-rad_x_max, rad_x_max, lerp_val_x)) 
	var rot_y := rad_to_deg(lerp_angle(-rad_y_max, rad_y_max, lerp_val_y)) 
	
	to_rot(rot_x, rot_y + 180.0 * float(flip_type))


func to_rot(rot_x: float, rot_y: float, _time: float = 0.5, interuptable: bool = true) -> void:
	#将Y轴旋转角度：卡面的(-180, 180)对应卡背的(0, 360)映射到(-180, 180)的定义域中:
	var _rot_y: float = rot_y - 180.0
	
	if tween_rot and tween_rot.is_running():
		if not rot_interuptable:
			return
		tween_rot.kill()
	tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	rot_interuptable = interuptable
	tween_rot.tween_property(card_texture.material, "shader_parameter/x_rot", rot_x, _time)
	tween_rot.tween_property(card_texture.material, "shader_parameter/y_rot", rot_y, _time)
	tween_rot.tween_property(card_back_texture.material, "shader_parameter/x_rot", rot_x, _time)
	tween_rot.tween_property(card_back_texture.material, "shader_parameter/y_rot", _rot_y, _time)
	tween_rot.tween_property(shadow.material, "shader_parameter/x_rot", rot_x, _time)
	tween_rot.tween_property(shadow.material, "shader_parameter/y_rot", rot_y, _time)


func to_rot_z(rot_z: float = 0.0, _time: float = 0.5, interuptable: bool = true) -> void:
	if tween_rot_z and tween_rot_z.is_running():
		if not rot_z_interuptable:
			return
		tween_rot_z.kill()
	tween_rot_z = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	rot_z_interuptable = interuptable
	tween_rot_z.tween_property(self, "rotation", rot_z, _time)


func to_scale(_scale: Vector2, _time: float = 0.5, interuptable: bool = true) -> void:
	card_texture.pivot_offset = pivot_offset
	card_back_texture.pivot_offset = pivot_offset
	shadow.pivot_offset = pivot_offset
	
	if tween_scale and tween_scale.is_running():
		if not scale_interuptable:
			return
		tween_scale.kill()
	tween_scale = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	scale_interuptable = interuptable
	tween_scale.tween_property(card_texture, "scale", _scale, _time)
	tween_scale.tween_property(card_back_texture, "scale", _scale, _time)
	tween_scale.tween_property(shadow, "scale", _scale, _time)


func to_dissolve(_dissolve_value: float, _time: float = 2.0, interuptable: bool = true) -> void:
	card_texture.use_parent_material = true
	card_back_texture.use_parent_material = true
	
	var noise: NoiseTexture2D = material.get("shader_parameter/dissolve_texture")
	noise.noise.seed = int((randf() - 0.5) * 400)
	
	if tween_dissolve and tween_dissolve.is_running():
		if not dissolve_interuptable:
			return
		tween_dissolve.kill()
	tween_dissolve = create_tween().set_trans(Tween.TRANS_CUBIC)
	dissolve_interuptable = interuptable
	tween_dissolve.tween_property(material, "shader_parameter/dissolve_value", _dissolve_value, _time).from(1.0)
	tween_dissolve.parallel().tween_property(shadow.material, "shader_parameter/alpha", 0.0, _time * 0.7)
	tween_dissolve.tween_callback(queue_free)


func to_pos(_pos: Vector2, _time: float = 0.5, _type: int = 0, interuptable: bool = true, _global: bool = true) -> void:
	if tween_pos and tween_pos.is_running():
		if not pos_interuptable:
			return
		tween_pos.kill()
	tween_pos = create_tween()
	pos_interuptable = interuptable
	
	var final_pos = _pos - get_parent().global_position if _global else _pos
	match _type:
		0: 
			tween_pos.tween_property(self, "position", final_pos, _time).set_trans(Tween.TRANS_LINEAR)
		_: 
			# 先使用一个快速的线性动画
			var mid_pos = global_position if _global else position
			tween_pos.tween_property(self, "position", final_pos + 0.2 * (mid_pos - _pos), 0.07 * _time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			# 然后添加一个较小的弹性效果
			tween_pos.tween_property(self, "position", final_pos, 0.93 * _time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func to_global_pos() -> void:
	pass


func destroy() -> void:
	to_dissolve(0.0)


##处理选框判定
func is_in_box(box: Rect2) -> bool:
	# 获取 RectangleShape2D 和 CollisionShape2D 的全局变换
	var shape: RectangleShape2D = collision_shape.shape
	var transform: Transform2D = collision_shape.global_transform
	
	# 计算旋转矩形的本地顶点（基于 extents）
	var extents = shape.size / 2.0
	var local_vertices = [
		Vector2(-extents.x, -extents.y),
		Vector2(extents.x, -extents.y),
		Vector2(extents.x, extents.y),
		Vector2(-extents.x, extents.y)
	]
	
	# 变换到全局空间
	var global_vertices: Array[Vector2] = []
	for vertex in local_vertices:
		global_vertices.append(transform * vertex)
	
	# 定义投影轴：Rect2 的 X/Y 轴 + 旋转矩形的两条边法线
	var axes = [
		Vector2.RIGHT,   # Rect2 的 X 轴
		Vector2.UP,      # Rect2 的 Y 轴
		(global_vertices[1] - global_vertices[0]).normalized().orthogonal(),  # 旋转矩形边0的法线
		(global_vertices[2] - global_vertices[1]).normalized().orthogonal()   # 旋转矩形边1的法线
		]
	
	# 检查所有轴上的投影是否重叠
	for axis in axes:
		# 投影旋转矩形
		var proj_min = INF
		var proj_max = -INF
		for vertex in global_vertices:
			var proj = vertex.dot(axis)
			proj_min = min(proj_min, proj)
			proj_max = max(proj_max, proj)
		
		# 投影 Rect2
		var box_vertices = [
			box.position,
			box.position + Vector2(box.size.x, 0),
			box.position + box.size,
			box.position + Vector2(0, box.size.y)
		]
		var box_proj_min = INF
		var box_proj_max = -INF
		for vertex in box_vertices:
			var proj = vertex.dot(axis)
			box_proj_min = min(box_proj_min, proj)
			box_proj_max = max(box_proj_max, proj)
		
		# 检查投影是否不重叠
		if proj_max < box_proj_min or box_proj_max < proj_min:
			return false
		
	return true


##处理鼠标跟随
func follow_mouse(_delta: float) -> void:
	if tween_pos and tween_pos.is_running():
		await tween_pos.finished
	var mouse_pos: Vector2 = get_global_mouse_position()
	var target_pos = mouse_pos - pivot_offset
	global_position = target_pos


##处理阴影效果
func _handle_shadow(_delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x + size.x * scale.x / 2 - center.x
	
	shadow.position.x = lerp(0.0, shadow_offset_max * sign(distance), abs(distance / center.x))


##判断重叠区域
func card_table_overlapping() -> CardTable:
	var areas = area_destroy.get_overlapping_areas()
	if areas.size() <= 0: return
	for area in areas:
		if not area.get_parent() is CardTable: continue
		return area.get_parent()
	return null


func destroy_area_overlapping() -> DestroyArea:
	var areas = area_destroy.get_overlapping_areas()
	if areas.size() <= 0: return
	for area in areas:
		if not area.get_parent() is DestroyArea: continue
		return area.get_parent()
	return null


func _on_mouse_entered() -> void:
	Event.cards_on_mouse += 1


func _on_mouse_exited() -> void:
	Event.cards_on_mouse -= 1
