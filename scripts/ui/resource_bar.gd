extends PanelContainer

@onready var gold_row: HBoxContainer = $VBox/GoldRow
@onready var mana_row: HBoxContainer = $VBox/ManaRow
@onready var gold_label: Label = $VBox/GoldRow/GoldLabel
@onready var gold_orbs: HBoxContainer = $VBox/GoldRow/GoldOrbs
@onready var mana_label: Label = $VBox/ManaRow/ManaLabel
@onready var mana_orbs: HBoxContainer = $VBox/ManaRow/ManaOrbs

var gold_manager := GoldManager.new()
var mana_manager := ManaManager.new()

const GOLD_COLOR := Color(1.0, 0.85, 0.1, 1.0)
const MANA_COLOR := Color(0.3, 0.5, 1.0, 1.0)
const EMPTY_COLOR := Color(0.35, 0.35, 0.35, 1.0)
const ORB_SIZE := 14


func _ready() -> void:
	add_child(gold_manager)
	add_child(mana_manager)
	gold_manager.gold_changed.connect(_on_gold_changed)
	mana_manager.mana_changed.connect(_on_mana_changed)
	_create_orbs(gold_orbs, GoldManager.MAX_GOLD)
	_create_orbs(mana_orbs, ManaManager.MAX_MANA)
	_update_orbs(gold_orbs, 0, GoldManager.MAX_GOLD, GOLD_COLOR)
	_update_orbs(mana_orbs, 0, ManaManager.MAX_MANA, MANA_COLOR)


func _create_orbs(container: HBoxContainer, count: int) -> void:
	for i in range(count):
		var orb := ColorRect.new()
		orb.custom_minimum_size = Vector2(ORB_SIZE, ORB_SIZE)
		orb.color = EMPTY_COLOR
		container.add_child(orb)


func _update_orbs(container: HBoxContainer, current: int, _max_value: int, active_color: Color) -> void:
	var orbs := container.get_children()
	for i in range(orbs.size()):
		orbs[i].color = active_color if i < current else EMPTY_COLOR


func _on_gold_changed(current: int, max_value: int) -> void:
	gold_label.text = "금 %d/%d" % [current, max_value]
	_update_orbs(gold_orbs, current, max_value, GOLD_COLOR)


func _on_mana_changed(current: int, max_value: int) -> void:
	mana_label.text = "마나 %d/%d" % [current, max_value]
	_update_orbs(mana_orbs, current, max_value, MANA_COLOR)
