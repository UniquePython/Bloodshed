class_name ChunkRenderer
extends RefCounted

const CONTOUR_COLOR := Color("#2b1a0a")
const CONTOUR_WIDTH := 2.0
const GRID_MIN_ZOOM := 6.0

var map: MapData
var _textures := {}
var _contours := {}

func _init(p_map: MapData) -> void:
	map = p_map

func invalidate_ground(key: Vector2i) -> void:
	_textures.erase(key)

func invalidate_height(key: Vector2i) -> void:
	_contours.erase(key)
	_contours.erase(key + Vector2i.LEFT)
	_contours.erase(key + Vector2i.UP)

func draw(canvas: CanvasItem, camera: EditorCamera, viewport_size: Vector2) -> void:
	var map_rect := Rect2(
		camera.cell_to_screen(Vector2.ZERO, viewport_size),
		Vector2(map.width, map.length) * camera.zoom
	)
	canvas.draw_rect(map_rect, TerrainTypes.get_color_of(TerrainTypes.GRASS))

	var top_left := camera.screen_to_cell(Vector2.ZERO, viewport_size)
	var bottom_right := camera.screen_to_cell(viewport_size, viewport_size)
	var first := Vector2i(floori(top_left.x / Chunk.SIZE), floori(top_left.y / Chunk.SIZE))
	var last := Vector2i(floori(bottom_right.x / Chunk.SIZE), floori(bottom_right.y / Chunk.SIZE))

	for cy in range(first.y, last.y + 1):
		for cx in range(first.x, last.x + 1):
			var key := Vector2i(cx, cy)
			if not map.chunks.has(key):
				continue
			var origin := camera.cell_to_screen(Vector2(cx, cy) * Chunk.SIZE, viewport_size)
			var rect := Rect2(origin, Vector2.ONE * Chunk.SIZE * camera.zoom)
			canvas.draw_texture_rect(_get_texture(key), rect, false)

	if camera.zoom >= GRID_MIN_ZOOM:
		_draw_grid(canvas, camera, viewport_size, top_left, bottom_right)

	canvas.draw_set_transform(camera.cell_to_screen(Vector2.ZERO, viewport_size), 0.0, Vector2(camera.zoom, camera.zoom))
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
				canvas.draw_multiline(lines, CONTOUR_COLOR, CONTOUR_WIDTH / camera.zoom)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	canvas.draw_rect(map_rect, Color.WHITE, false, 2.0)

func _draw_grid(canvas: CanvasItem, camera: EditorCamera, viewport_size: Vector2, top_left: Vector2, bottom_right: Vector2) -> void:
	var x0 := maxi(floori(top_left.x), 0)
	var x1 := mini(ceili(bottom_right.x), map.width)
	var y0 := maxi(floori(top_left.y), 0)
	var y1 := mini(ceili(bottom_right.y), map.length)
	var color := Color(0, 0, 0, 0.25)

	var top := camera.cell_to_screen(Vector2(0, y0), viewport_size).y
	var bottom := camera.cell_to_screen(Vector2(0, y1), viewport_size).y
	for x in range(x0, x1 + 1):
		var sx := camera.cell_to_screen(Vector2(x, 0), viewport_size).x
		canvas.draw_line(Vector2(sx, top), Vector2(sx, bottom), color)

	var left := camera.cell_to_screen(Vector2(x0, 0), viewport_size).x
	var right := camera.cell_to_screen(Vector2(x1, 0), viewport_size).x
	for y in range(y0, y1 + 1):
		var sy := camera.cell_to_screen(Vector2(0, y), viewport_size).y
		canvas.draw_line(Vector2(left, sy), Vector2(right, sy), color)

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
