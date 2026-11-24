class_name Chunk
extends RefCounted

const SIZE := 64

var ground := PackedByteArray()
var height := PackedInt32Array()
var _filled := 0

func _init() -> void:
	ground.resize(SIZE * SIZE)
	height.resize(SIZE * SIZE)

func _index(lx: int, ly: int) -> int:
	return ly * SIZE + lx

func get_ground(lx: int, ly: int) -> int:
	return ground[_index(lx, ly)]

func get_height(lx: int, ly: int) -> int:
	return height[_index(lx, ly)]

func set_ground(lx: int, ly: int, id: int) -> void:
	var i := _index(lx, ly)
	var was_filled := ground[i] != 0 or height[i] != 0
	ground[i] = id
	_update_count(was_filled, ground[i] != 0 or height[i] != 0)

func set_height(lx: int, ly: int, value: int) -> void:
	var i := _index(lx, ly)
	var was_filled := ground[i] != 0 or height[i] != 0
	height[i] = value
	_update_count(was_filled, ground[i] != 0 or height[i] != 0)

func _update_count(was_filled: bool, is_filled: bool) -> void:
	if is_filled and not was_filled:
		_filled += 1
	elif was_filled and not is_filled:
		_filled -= 1

func is_empty() -> bool:
	return _filled == 0
