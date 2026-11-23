extends Control

@onready var new_button: Button = $Layout/ButtonArea/Buttons/NewButton
@onready var quit_button: Button = $Layout/ButtonArea/Buttons/QuitButton

func _ready() -> void:
	new_button.pressed.connect(_on_new_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_new_pressed() -> void:
	print("New!")

func _on_quit_pressed() -> void:
	get_tree().quit()
