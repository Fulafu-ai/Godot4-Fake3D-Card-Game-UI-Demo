class_name ObservableArray
extends RefCounted

signal array_changed()

var _array: Array = []


func set_array(array: Array) -> void:
	_array = array.duplicate()
	emit_signal("array_changed")


# 获取数组内容（返回副本以防止外部直接修改）
func get_array() -> Array:
	return _array.duplicate()


# 修改数组的方法
func erase(value) -> void:
	_array.erase(value)
	emit_signal("array_changed")


func append(value) -> void:
	_array.append(value)
	emit_signal("array_changed")


func pop_back():
	var result = _array.pop_back()
	emit_signal("array_changed")
	return result


func pop_front():
	var result = _array.pop_front()
	emit_signal("array_changed")
	return result


func remove_at(position: int) -> void:
	_array.remove_at(position)
	emit_signal("array_changed")


func shuffle() -> void:
	_array.shuffle()
	emit_signal("array_changed")


func sort() -> void:
	_array.sort()
	emit_signal("array_changed")


func sort_custom(func_name: Callable) -> void:
	_array.sort_custom(func_name)
	emit_signal("array_changed")


# 注意：Godot 原生的 Array 没有 filter 方法，需要自己实现
func filter(method: Callable) -> void:
	var new_array = []
	for item in _array:
		if method.call(item):
			new_array.append(item)
	_array = new_array
	emit_signal("array_changed")


# 自定义过滤方法
func filter_custom(obj: Object, func_name: String) -> void:
	var method = Callable(obj, func_name)
	var new_array = []
	for item in _array:
		if method.call(item):
			new_array.append(item)
	_array = new_array
	emit_signal("array_changed")


# 可选：添加其他常用方法
func clear() -> void:
	_array.clear()
	emit_signal("array_changed")


func insert(pos: int, value) -> void:
	_array.insert(pos, value)
	emit_signal("array_changed")


func size() -> int:
	return _array.size()


func is_empty() -> bool:
	return _array.is_empty()


func find(obj: Object) -> int:
	return _array.find(obj) 
