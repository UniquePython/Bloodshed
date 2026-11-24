class_name EditorToolbar
extends PanelContainer

@onready var row: HBoxContainer = $Row
@onready var ground_button: Button = $Row/GroundButton
@onready var elevation_button: Button = $Row/ElevationButton
@onready var brush_button: Button = $Row/BrushButton
@onready var eraser_button: Button = $Row/EraserButton
@onready var size_label: Label = $Row/SizeLabel
@onready var size_slider: HSlider = $Row/SizeSlider
@onready var palette: HBoxContainer = $Row/Palette
@onready var height_box: HBoxContainer = $Row/HeightBox
@onready var height_spin: SpinBox = $Row/HeightBox/HeightSpin
@onready var undo_button: Button = $Row/UndoButton
@onready var redo_button: Button = $Row/RedoButton
@onready var status_label: Label = $Row/StatusLabel

var canvas: EditorCanvas
var _swatches: Array[Button] = []

func setup(c: EditorCanvas) -> void:
	canvas = c

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#26262b")
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	row.add_theme_constant_override("separation", 12)

	var layer_group := ButtonGroup.new()
	for b in [ground_button, elevation_button]:
		b.toggle_mode = true
		b.button_group = layer_group
	var tool_group := ButtonGroup.new()
	for b in [brush_button, eraser_button]:
		b.toggle_mode = true
		b.button_group = tool_group

	size_slider.min_value = 0
	size_slider.max_value = 50
	size_slider.step = 1
	size_slider.custom_minimum_size.x = 140
	size_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	height_spin.min_value = 0
	height_spin.max_value = 1000
	height_spin.step = 1
	height_spin.allow_greater = true

	status_label.custom_minimum_size.x = 230
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	palette.add_theme_constant_override("separation", 6)
	_build_palette()

	for label in find_children("*", "Label", true, false):
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for button in find_children("*", "Button", true, false):
		button.focus_mode = Control.FOCUS_NONE

	ground_button.pressed.connect(canvas.set_layer.bind(EditorCanvas.LAYER_GROUND))
	elevation_button.pressed.connect(canvas.set_layer.bind(EditorCanvas.LAYER_ELEVATION))
	brush_button.pressed.connect(canvas.set_tool.bind(EditorCanvas.TOOL_BRUSH))
	eraser_button.pressed.connect(canvas.set_tool.bind(EditorCanvas.TOOL_ERASER))
	size_slider.value_changed.connect(_on_size_changed)
	height_spin.value_changed.connect(_on_height_changed)
	undo_button.pressed.connect(canvas.undo_edit)
	redo_button.pressed.connect(canvas.redo_edit)

	canvas.settings_changed.connect(_sync)
	canvas.cursor_changed.connect(_on_cursor_changed)
	canvas.history_changed.connect(_update_history_buttons)

	_sync()
	_update_history_buttons()

func _build_palette() -> void:
	var group := ButtonGroup.new()
	for id in TerrainTypes.count():
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(36, 36)
		swatch.toggle_mode = true
		swatch.button_group = group
		swatch.tooltip_text = "%d: %s" % [id + 1, TerrainTypes.get_name_of(id)]

		var color := TerrainTypes.get_color_of(id)
		swatch.add_theme_stylebox_override("normal", _swatch_style(color, Color(0, 0, 0, 0.5), 2))
		swatch.add_theme_stylebox_override("hover", _swatch_style(color.lightened(0.15), Color(1, 1, 1, 0.5), 2))
		swatch.add_theme_stylebox_override("pressed", _swatch_style(color, Color.WHITE, 4))
		swatch.add_theme_stylebox_override("hover_pressed", _swatch_style(color, Color.WHITE, 4))
		swatch.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		swatch.pressed.connect(canvas.set_terrain.bind(id))
		palette.add_child(swatch)
		_swatches.append(swatch)

func _swatch_style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(6)
	return s

func _sync() -> void:
	ground_button.set_pressed_no_signal(canvas.layer == EditorCanvas.LAYER_GROUND)
	elevation_button.set_pressed_no_signal(canvas.layer == EditorCanvas.LAYER_ELEVATION)
	brush_button.set_pressed_no_signal(canvas.current_tool == EditorCanvas.TOOL_BRUSH)
	eraser_button.set_pressed_no_signal(canvas.current_tool == EditorCanvas.TOOL_ERASER)
	size_slider.set_value_no_signal(canvas.brush_radius)
	size_label.text = "Size: %d" % canvas.brush_radius
	height_spin.set_value_no_signal(canvas.selected_height)
	for i in _swatches.size():
		_swatches[i].set_pressed_no_signal(i == canvas.selected_terrain)

	var on_ground := canvas.layer == EditorCanvas.LAYER_GROUND
	palette.visible = on_ground
	height_box.visible = not on_ground

func _on_size_changed(value: float) -> void:
	canvas.set_radius(int(value))

func _on_height_changed(value: float) -> void:
	canvas.set_height(int(value))

func _on_cursor_changed(cell: Vector2i, height: int, inside: bool) -> void:
	if inside:
		status_label.text = "Cell %d, %d    Height %d" % [cell.x, cell.y, height]
	else:
		status_label.text = "Cell -    Height -"

func _update_history_buttons() -> void:
	undo_button.disabled = not canvas.history.can_undo()
	redo_button.disabled = not canvas.history.can_redo()
