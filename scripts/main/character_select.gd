extends Control

@onready var fight_button: Button = %FightButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	fight_button.pressed.connect(_on_fight_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn")
