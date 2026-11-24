extends Control

@onready var canvas: EditorCanvas = $Layout/EditorCanvas
@onready var toolbar: EditorToolbar = $Layout/Toolbar

func _ready() -> void:
	toolbar.setup(canvas)
