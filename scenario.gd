extends Node

var map = null

const STAGES := [
	{"name": "Main Menu", "scene": "res://main_menu.tscn"},
	{"name": "Terrain Editor", "scene": "res://terrain_editor.tscn"}
]

var current_stage := 1

func reset() -> void:
	map = null
	current_stage = 1

func go_to_stage(index: int) -> void:
	if index < 0 or index >= STAGES.size():
		return

	current_stage = index
	get_tree().change_scene_to_file(STAGES[index]["scene"])

func next_stage() -> void:
	go_to_stage(current_stage + 1)

func previous_stage() -> void:
	go_to_stage(current_stage - 1)
