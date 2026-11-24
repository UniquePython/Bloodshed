class_name BrushPainter
extends RefCounted

signal history_changed

var map: MapData
var settings: EditorProperties
var renderer: ChunkRenderer
var history := EditHistory.new()

var _painting := false
var _paint_layer := EditorProperties.LAYER_GROUND
var _paint_id := 0
var _last_cell := Vector2i.ZERO

func _init(p_map: MapData, p_settings: EditorProperties, p_renderer: ChunkRenderer) -> void:
	map = p_map
	settings = p_settings
	renderer = p_renderer

func is_painting() -> bool:
	return _painting

func begin_stroke(cell: Vector2i, erasing: bool) -> void:
	_painting = true
	_paint_layer = settings.layer
	history.begin(_paint_layer)

	if erasing:
		_paint_id = 0
	elif settings.layer == EditorProperties.LAYER_GROUND:
		_paint_id = settings.selected_terrain
	else:
		_paint_id = settings.selected_height

	_last_cell = cell
	_stamp_line(_last_cell, _last_cell)

func paint_to(cell: Vector2i) -> void:
	if not _painting:
		return
	_stamp_line(_last_cell, cell)
	_last_cell = cell

func end_stroke() -> void:
	if not _painting:
		return
	history.end()
	_painting = false
	history_changed.emit()

func undo() -> bool:
	if _painting:
		return false
	var stroke = history.undo()
	if stroke == null:
		return false
	_apply_stroke(stroke, false)
	history_changed.emit()
	return true

func redo() -> bool:
	if _painting:
		return false
	var stroke = history.redo()
	if stroke == null:
		return false
	_apply_stroke(stroke, true)
	history_changed.emit()
	return true

func _stamp_line(from: Vector2i, to: Vector2i) -> void:
	var touched := {}
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in range(steps + 1):
		var t := 0.0
		if steps > 0:
			t = float(i) / steps
		var center := Vector2i(Vector2(from).lerp(Vector2(to), t).round())
		_stamp(center, touched)

	for key in touched:
		if _paint_layer == EditorProperties.LAYER_GROUND:
			renderer.invalidate_ground(key)
		else:
			renderer.invalidate_height(key)

func _stamp(center: Vector2i, touched: Dictionary) -> void:
	var r := settings.brush_radius
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r + r:
				continue
			var x := center.x + dx
			var y := center.y + dy
			if not map.in_bounds(x, y):
				continue
			var old: int
			if _paint_layer == EditorProperties.LAYER_GROUND:
				old = map.get_ground(x, y)
				if old == _paint_id:
					continue
				map.set_ground(x, y, _paint_id)
			else:
				old = map.get_height(x, y)
				if old == _paint_id:
					continue
				map.set_height(x, y, _paint_id)
			history.record(Vector2i(x, y), old, _paint_id)
			touched[map.chunk_key(x, y)] = true

func _apply_stroke(stroke: Dictionary, use_new: bool) -> void:
	var stroke_layer: int = stroke["layer"]
	var cells: Dictionary = stroke["cells"]
	var touched := {}
	for cell in cells:
		var pair: Vector2i = cells[cell]
		var value: int = pair.y if use_new else pair.x
		if stroke_layer == EditorProperties.LAYER_GROUND:
			map.set_ground(cell.x, cell.y, value)
		else:
			map.set_height(cell.x, cell.y, value)
		touched[map.chunk_key(cell.x, cell.y)] = true

	for key in touched:
		if stroke_layer == EditorProperties.LAYER_GROUND:
			renderer.invalidate_ground(key)
		else:
			renderer.invalidate_height(key)
