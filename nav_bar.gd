extends PanelContainer

@onready var back_button: Button = $Row/BackButton
@onready var next_button: Button = $Row/NextButton
@onready var stage_label: Label = $Row/StageLabel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	var index: int = Scenario.current_stage
	var last: int = Scenario.STAGES.size() - 1

	stage_label.text = Scenario.STAGES[index]["name"]

	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)

	back_button.disabled = index == 0
	next_button.disabled = index == last

func _on_back_pressed() -> void:
	Scenario.previous_stage()

func _on_next_pressed() -> void:
	Scenario.next_stage()
