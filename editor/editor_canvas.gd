class_name EditorCanvas
extends Control

signal cursor_changed(cell: Vector2i, height: int, inside: bool)

var map: MapData
var camera := EditorCamera.new()
var settings := EditorProperties.new()
var renderer: ChunkRenderer
var painter: BrushPainter

var _hovering := false

func _ready() -> void:
	if Scenario.map == null:
		Scenario.reset()

	map = Scenario.map
	camera.center_on(Vector2(map.width, map.length))
	renderer = ChunkRenderer.new(map)
	painter = BrushPainter.new(map, settings, renderer)

	settings.changed.connect(queue_redraw)
	painter.history_changed.connect(_emit_cursor)

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

func _emit_cursor() -> void:
	if not _hovering:
		cursor_changed.emit(Vector2i.ZERO, 0, false)
		return
	var c := camera.cell_at(get_local_mouse_position(), size)
	if map.in_bounds(c.x, c.y):
		cursor_changed.emit(c, map.get_height(c.x, c.y), true)
	else:
		cursor_changed.emit(c, 0, false)

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

	if camera.pan(dir, delta):
		queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return

	if key.is_command_or_control_pressed():
		if key.keycode == KEY_Z:
			if key.shift_pressed:
				painter.redo()
			else:
				painter.undo()
		elif key.keycode == KEY_Y:
			painter.redo()
		queue_redraw()
		return

	if key.keycode >= KEY_1 and key.keycode < KEY_1 + TerrainTypes.count():
		settings.set_terrain(key.keycode - KEY_1)
		return

	var step := 1
	if key.shift_pressed:
		step = 5

	match key.keycode:
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			camera.zoom_in()
			queue_redraw()
		KEY_MINUS, KEY_KP_SUBTRACT:
			camera.zoom_out()
			queue_redraw()
		KEY_BRACKETLEFT:
			settings.set_radius(settings.brush_radius - 1)
		KEY_BRACKETRIGHT:
			settings.set_radius(settings.brush_radius + 1)
		KEY_L:
			settings.toggle_layer()
		KEY_E:
			settings.set_height(settings.selected_height + step)
		KEY_Q:
			settings.set_height(settings.selected_height - step)

func _draw() -> void:
	if map == null:
		return

	renderer.draw(self, camera, size)

	if _hovering:
		var c := camera.cell_at(get_local_mouse_position(), size)
		var center := camera.cell_to_screen(Vector2(c) + Vector2(0.5, 0.5), size)
		var outline := Color.WHITE
		if settings.layer == EditorProperties.LAYER_ELEVATION:
			outline = Color("#ffb347")
		if settings.current_tool == EditorProperties.TOOL_ERASER:
			outline = Color("#ff6b6b")
		draw_arc(center, (settings.brush_radius + 0.5) * camera.zoom, 0.0, TAU, 48, outline, 2.0)

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_RIGHT:
			if button.pressed:
				get_viewport().gui_release_focus()
				var erasing := button.button_index == MOUSE_BUTTON_RIGHT or settings.current_tool == EditorProperties.TOOL_ERASER
				painter.begin_stroke(camera.cell_at(button.position, size), erasing)
				queue_redraw()
				_emit_cursor()
			else:
				painter.end_stroke()
		return

	var motion := event as InputEventMouseMotion
	if motion != null:
		painter.paint_to(camera.cell_at(motion.position, size))
		queue_redraw()
		_emit_cursor()
