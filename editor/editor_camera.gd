class_name EditorCamera
extends RefCounted

const MIN_ZOOM := 2.0
const MAX_ZOOM := 64.0
const ZOOM_FACTOR := 1.25
const PAN_SPEED := 700.0

var position := Vector2.ZERO
var zoom := 6.0

func center_on(map_size: Vector2) -> void:
	position = map_size / 2.0

func cell_to_screen(cell: Vector2, viewport_size: Vector2) -> Vector2:
	return (cell - position) * zoom + viewport_size / 2.0

func screen_to_cell(pos: Vector2, viewport_size: Vector2) -> Vector2:
	return (pos - viewport_size / 2.0) / zoom + position

func cell_at(pos: Vector2, viewport_size: Vector2) -> Vector2i:
	var c := screen_to_cell(pos, viewport_size)
	return Vector2i(floori(c.x), floori(c.y))

func set_zoom(value: float) -> void:
	zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)

func zoom_in() -> void:
	set_zoom(zoom * ZOOM_FACTOR)

func zoom_out() -> void:
	set_zoom(zoom / ZOOM_FACTOR)

func pan(dir: Vector2, delta: float) -> bool:
	if dir == Vector2.ZERO:
		return false
	position += dir.normalized() * PAN_SPEED / zoom * delta
	return true
