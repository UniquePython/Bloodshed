class_name EditorProperties
extends RefCounted

signal changed

const TOOL_BRUSH := 0
const TOOL_ERASER := 1

const LAYER_GROUND := 0
const LAYER_ELEVATION := 1

var selected_terrain := TerrainTypes.SAND
var brush_radius := 2
var layer := LAYER_GROUND
var current_tool := TOOL_BRUSH
var selected_height := 1

func set_layer(value: int) -> void:
	layer = value
	changed.emit()

func set_tool(value: int) -> void:
	current_tool = value
	changed.emit()

func set_terrain(id: int) -> void:
	selected_terrain = id
	changed.emit()

func set_height(value: int) -> void:
	selected_height = maxi(value, 0)
	changed.emit()

func set_radius(value: int) -> void:
	brush_radius = clampi(value, 0, 50)
	changed.emit()

func toggle_layer() -> void:
	if layer == LAYER_GROUND:
		set_layer(LAYER_ELEVATION)
	else:
		set_layer(LAYER_GROUND)
