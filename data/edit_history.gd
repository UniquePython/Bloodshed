class_name EditHistory
extends RefCounted

const MAX_STROKES := 200

var _undo_stack: Array = []
var _redo_stack: Array = []
var _current = null

func begin(layer: int) -> void:
	_current = {"layer": layer, "cells": {}}

func record(cell: Vector2i, old_value: int, new_value: int) -> void:
	if _current == null:
		return
	var cells: Dictionary = _current["cells"]
	if cells.has(cell):
		var pair: Vector2i = cells[cell]
		cells[cell] = Vector2i(pair.x, new_value)
	else:
		cells[cell] = Vector2i(old_value, new_value)

func end() -> void:
	if _current == null:
		return
	var cells: Dictionary = _current["cells"]
	if cells.size() > 0:
		_undo_stack.append(_current)
		_redo_stack.clear()
		if _undo_stack.size() > MAX_STROKES:
			_undo_stack.pop_front()
	_current = null

func undo() -> Variant:
	if _undo_stack.is_empty():
		return null
	var stroke = _undo_stack.pop_back()
	_redo_stack.append(stroke)
	return stroke

func redo() -> Variant:
	if _redo_stack.is_empty():
		return null
	var stroke = _redo_stack.pop_back()
	_undo_stack.append(stroke)
	return stroke

func can_undo() -> bool:
	return not _undo_stack.is_empty()

func can_redo() -> bool:
	return not _redo_stack.is_empty()
