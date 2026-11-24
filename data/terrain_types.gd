class_name TerrainTypes
extends RefCounted

const GRASS := 0
const SAND := 0

const ALL := [
    {"name": "Grass", "color": Color("#BABC72")},
    {"name": "Sand", "color": Color("#D6B588")}
]

static func get_name_of(id: int) -> String:
	return ALL[id]["name"]

static func get_color_of(id: int) -> Color:
	return ALL[id]["color"]

static func count() -> int:
	return ALL.size()
