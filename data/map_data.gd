class_name MapData
extends RefCounted

var map_name := "Untitled"
var width: int
var length: int
var chunks: Dictionary = {}

func _init(w: int = 256, l: int = 256) -> void:
	width = w
	length = l

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < length

func chunk_key(x: int, y: int) -> Vector2i:
	return Vector2i(floori(float(x) / Chunk.SIZE), floori(float(y) / Chunk.SIZE))

func get_ground(x: int, y: int) -> int:
	var chunk: Chunk = chunks.get(chunk_key(x, y))
	if chunk == null:
		return TerrainTypes.GRASS

	return chunk.get_ground(posmod(x, Chunk.SIZE), posmod(y, Chunk.SIZE))

func get_height(x: int, y: int) -> int:
	var chunk: Chunk = chunks.get(chunk_key(x, y))
	if chunk == null:
		return 0

	return chunk.get_height(posmod(x, Chunk.SIZE), posmod(y, Chunk.SIZE))

func set_ground(x: int, y: int, id: int) -> void:
	if not in_bounds(x, y):
		return

	var key := chunk_key(x, y)
	var chunk: Chunk = chunks.get(key)

	if chunk == null:
		if id == TerrainTypes.GRASS:
			return

		chunk = Chunk.new()
		chunks[key] = chunk

	chunk.set_ground(posmod(x, Chunk.SIZE), posmod(y, Chunk.SIZE), id)
	if chunk.is_empty():
		chunks.erase(key)

func set_height(x: int, y: int, value: int) -> void:
	if not in_bounds(x, y):
		return

	value = maxi(value, 0)
	var key := chunk_key(x, y)
	var chunk: Chunk = chunks.get(key)

	if chunk == null:
		if value == 0:
			return

		chunk = Chunk.new()
		chunks[key] = chunk

	chunk.set_height(posmod(x, Chunk.SIZE), posmod(y, Chunk.SIZE), value)
	if chunk.is_empty():
		chunks.erase(key)
