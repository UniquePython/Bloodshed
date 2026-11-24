class_name EditorCanvas
extends Control

signal settings_changed
signal history_changed
signal cursor_changed(cell: Vector2i, height: int, inside: bool)

const TOOL_BRUSH := 0
const TOOL_ERASER := 1

const MIN_ZOOM := 2.0
const MAX_ZOOM := 64.0
const ZOOM_FACTOR := 1.25
const PAN_SPEED := 700.0
const GRID_MIN_ZOOM := 6.0

const LAYER_GROUND := 0
const LAYER_ELEVATION := 1
const CONTOUR_COLOR := Color("#2b1a0a")
const CONTOUR_WIDTH := 2.0

var map: MapData
var camera := Vector2.ZERO
var zoom := 6.0
var _textures := {}

var selected_terrain := TerrainTypes.SAND
var brush_radius := 2

var layer := LAYER_GROUND
var current_tool := TOOL_BRUSH
var selected_height := 1
var _paint_layer := LAYER_GROUND
var _contours := {}
var history := EditHistory.new()

var _painting := false
var _paint_id := 0
var _last_cell := Vector2i.ZERO
var _hovering := false

func set_layer(value: int) -> void:
	layer = value
	settings_changed.emit()
	queue_redraw()

func set_tool(value: int) -> void:
	current_tool = value
	settings_changed.emit()

func set_terrain(id: int) -> void:
	selected_terrain = id
	settings_changed.emit()

func set_height(value: int) -> void:
	selected_height = maxi(value, 0)
	settings_changed.emit()

func set_radius(value: int) -> void:
	brush_radius = clampi(value, 0, 50)
	settings_changed.emit()
	queue_redraw()

func _emit_cursor() -> void:
	if not _hovering:
		cursor_changed.emit(Vector2i.ZERO, 0, false)
		return
	var c := _cell_at(get_local_mouse_position())
	if map.in_bounds(c.x, c.y):
		cursor_changed.emit(c, map.get_height(c.x, c.y), true)
	else:
		cursor_changed.emit(c, 0, false)

func _ready() -> void:
	if Scenario.map == null:
		Scenario.reset()

	map = Scenario.map
	camera = Vector2(map.width, map.length) / 2.0
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	resized.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_hovering = true
	queue_redraw()
	_emit_cursor()

func _on_mouse_exited() -> void:
	_hovering = false
	queue_redraw()
	_emit_cursor()

func cell_to_screen(cell: Vector2) -> Vector2:
	return (cell - camera) * zoom + size / 2.0

func screen_to_cell(pos: Vector2) -> Vector2:
	return (pos - size / 2.0) / zoom + camera

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0

	if dir != Vector2.ZERO:
		camera += dir.normalized() * PAN_SPEED / zoom * delta
		queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return

	if key.is_command_or_control_pressed():
		if key.keycode == KEY_Z:
			if key.shift_pressed:
				redo_edit()
			else:
				undo_edit()
		elif key.keycode == KEY_Y:
			redo_edit()
		return

	if key.keycode >= KEY_1 and key.keycode < KEY_1 + TerrainTypes.count():
		set_terrain(key.keycode - KEY_1)
		return

	var step := 1
	if key.shift_pressed:
		step = 5

	match key.keycode:
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			_set_zoom(zoom * ZOOM_FACTOR)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_set_zoom(zoom / ZOOM_FACTOR)
		KEY_BRACKETLEFT:
			set_radius(brush_radius - 1)
		KEY_BRACKETRIGHT:
			set_radius(brush_radius + 1)
		KEY_L:
			if layer == LAYER_GROUND:
				set_layer(LAYER_ELEVATION)
			else:
				set_layer(LAYER_GROUND)
		KEY_E:
			set_height(selected_height + step)
		KEY_Q:
			set_height(selected_height - step)

func _set_zoom(value: float) -> void:
	zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	queue_redraw()

func _draw() -> void:
	if map == null:
		return

	var map_rect := Rect2(cell_to_screen(Vector2.ZERO), Vector2(map.width, map.length) * zoom)
	draw_rect(map_rect, TerrainTypes.get_color_of(TerrainTypes.GRASS))

	var top_left := screen_to_cell(Vector2.ZERO)
	var bottom_right := screen_to_cell(size)
	var first := Vector2i(floori(top_left.x / Chunk.SIZE), floori(top_left.y / Chunk.SIZE))
	var last := Vector2i(floori(bottom_right.x / Chunk.SIZE), floori(bottom_right.y / Chunk.SIZE))

	for cy in range(first.y, last.y + 1):
		for cx in range(first.x, last.x + 1):
			var key := Vector2i(cx, cy)
			if not map.chunks.has(key):
				continue
			var origin := cell_to_screen(Vector2(cx, cy) * Chunk.SIZE)
			var rect := Rect2(origin, Vector2.ONE * Chunk.SIZE * zoom)
			draw_texture_rect(_get_texture(key), rect, false)

	if zoom >= GRID_MIN_ZOOM:
		_draw_grid(top_left, bottom_right)

	draw_set_transform(cell_to_screen(Vector2.ZERO), 0.0, Vector2(zoom, zoom))
	for cy in range(first.y - 1, last.y + 1):
		for cx in range(first.x - 1, last.x + 1):
			var ckey := Vector2i(cx, cy)
			var relevant: bool = map.chunks.has(ckey) \
				or map.chunks.has(ckey + Vector2i.RIGHT) \
				or map.chunks.has(ckey + Vector2i.DOWN)
			if not relevant:
				continue
			var lines := _get_contours(ckey)
			if lines.size() > 0:
				draw_multiline(lines, CONTOUR_COLOR, CONTOUR_WIDTH / zoom)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_rect(map_rect, Color.WHITE, false, 2.0)

	if _hovering:
		var c := _cell_at(get_local_mouse_position())
		var center := cell_to_screen(Vector2(c) + Vector2(0.5, 0.5))
		var outline := Color.WHITE
		if layer == LAYER_ELEVATION:
			outline = Color("#ffb347")
		if current_tool == TOOL_ERASER:
			outline = Color("#ff6b6b")
		draw_arc(center, (brush_radius + 0.5) * zoom, 0.0, TAU, 48, outline, 2.0)

func _draw_grid(top_left: Vector2, bottom_right: Vector2) -> void:
	var x0 := maxi(floori(top_left.x), 0)
	var x1 := mini(ceili(bottom_right.x), map.width)
	var y0 := maxi(floori(top_left.y), 0)
	var y1 := mini(ceili(bottom_right.y), map.length)
	var color := Color(0, 0, 0, 0.25)

	var top := cell_to_screen(Vector2(0, y0)).y
	var bottom := cell_to_screen(Vector2(0, y1)).y
	for x in range(x0, x1 + 1):
		var sx := cell_to_screen(Vector2(x, 0)).x
		draw_line(Vector2(sx, top), Vector2(sx, bottom), color)

	var left := cell_to_screen(Vector2(x0, 0)).x
	var right := cell_to_screen(Vector2(x1, 0)).x
	for y in range(y0, y1 + 1):
		var sy := cell_to_screen(Vector2(0, y)).y
		draw_line(Vector2(left, sy), Vector2(right, sy), color)

func _get_texture(key: Vector2i) -> ImageTexture:
	if _textures.has(key):
		return _textures[key]

	var chunk: Chunk = map.chunks[key]
	var img := Image.create(Chunk.SIZE, Chunk.SIZE, false, Image.FORMAT_RGBA8)
	for ly in Chunk.SIZE:
		for lx in Chunk.SIZE:
			var gx := key.x * Chunk.SIZE + lx
			var gy := key.y * Chunk.SIZE + ly
			if map.in_bounds(gx, gy):
				img.set_pixel(lx, ly, TerrainTypes.get_color_of(chunk.get_ground(lx, ly)))
			else:
				img.set_pixel(lx, ly, Color.TRANSPARENT)

	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex

func _get_contours(key: Vector2i) -> PackedVector2Array:
	if _contours.has(key):
		return _contours[key]

	var lines := PackedVector2Array()
	var exists := map.chunks.has(key)
	var last_index := Chunk.SIZE - 1
	var base_x := key.x * Chunk.SIZE
	var base_y := key.y * Chunk.SIZE

	for ly in Chunk.SIZE:
		for lx in Chunk.SIZE:
			if not exists and lx < last_index and ly < last_index:
				continue
			var gx := base_x + lx
			var gy := base_y + ly
			if not map.in_bounds(gx, gy):
				continue
			var h := map.get_height(gx, gy)
			if map.in_bounds(gx + 1, gy) and map.get_height(gx + 1, gy) != h:
				lines.append(Vector2(gx + 1, gy))
				lines.append(Vector2(gx + 1, gy + 1))
			if map.in_bounds(gx, gy + 1) and map.get_height(gx, gy + 1) != h:
				lines.append(Vector2(gx, gy + 1))
				lines.append(Vector2(gx + 1, gy + 1))

	_contours[key] = lines
	return lines

func invalidate_ground(key: Vector2i) -> void:
	_textures.erase(key)
	queue_redraw()

func invalidate_height(key: Vector2i) -> void:
	_contours.erase(key)
	_contours.erase(key + Vector2i.LEFT)
	_contours.erase(key + Vector2i.UP)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_RIGHT:
			if button.pressed:
				get_viewport().gui_release_focus()
				_painting = true
				_paint_layer = layer
				history.begin(_paint_layer)
				var erasing := button.button_index == MOUSE_BUTTON_RIGHT or current_tool == TOOL_ERASER
				if erasing:
					_paint_id = 0
				elif layer == LAYER_GROUND:
					_paint_id = selected_terrain
				else:
					_paint_id = selected_height
				_last_cell = _cell_at(button.position)
				_stamp_line(_last_cell, _last_cell)
				_emit_cursor()
			else:
				if _painting:
					history.end()
					history_changed.emit()
				_painting = false
		return

	var motion := event as InputEventMouseMotion
	if motion != null:
		if _painting:
			var cell := _cell_at(motion.position)
			_stamp_line(_last_cell, cell)
			_last_cell = cell
		queue_redraw()
		_emit_cursor()

func _cell_at(pos: Vector2) -> Vector2i:
	var c := screen_to_cell(pos)
	return Vector2i(floori(c.x), floori(c.y))

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
		if _paint_layer == LAYER_GROUND:
			invalidate_ground(key)
		else:
			invalidate_height(key)
	queue_redraw()

func _stamp(center: Vector2i, touched: Dictionary) -> void:
	var r := brush_radius
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r + r:
				continue
			var x := center.x + dx
			var y := center.y + dy
			if not map.in_bounds(x, y):
				continue
			var old: int
			if _paint_layer == LAYER_GROUND:
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

func undo_edit() -> void:
	if _painting:
		return
	var stroke = history.undo()
	if stroke != null:
		_apply_stroke(stroke, false)
		history_changed.emit()
		_emit_cursor()

func redo_edit() -> void:
	if _painting:
		return
	var stroke = history.redo()
	if stroke != null:
		_apply_stroke(stroke, true)
		history_changed.emit()
		_emit_cursor()

func _apply_stroke(stroke: Dictionary, use_new: bool) -> void:
	var stroke_layer: int = stroke["layer"]
	var cells: Dictionary = stroke["cells"]
	var touched := {}
	for cell in cells:
		var pair: Vector2i = cells[cell]
		var value: int = pair.y if use_new else pair.x
		if stroke_layer == LAYER_GROUND:
			map.set_ground(cell.x, cell.y, value)
		else:
			map.set_height(cell.x, cell.y, value)
		touched[map.chunk_key(cell.x, cell.y)] = true

	for key in touched:
		if stroke_layer == LAYER_GROUND:
			invalidate_ground(key)
		else:
			invalidate_height(key)
	queue_redraw()
