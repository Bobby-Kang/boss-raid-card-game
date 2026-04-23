extends PanelContainer

@onready var gold_row: HBoxContainer = $VBox/GoldRow
@onready var ap_row: HBoxContainer = $VBox/ApRow
@onready var gold_label: Label = $VBox/GoldRow/GoldLabel
@onready var gold_orbs: HBoxContainer = $VBox/GoldRow/GoldOrbs
@onready var ap_label: Label = $VBox/ApRow/ApLabel
@onready var ap_orbs: HBoxContainer = $VBox/ApRow/ApOrbs

var gold_manager := GoldManager.new()
var ap_manager := ApManager.new()

const GOLD_COLOR := Color(1.0, 0.85, 0.1, 1.0)
const AP_COLOR := Color(0.2, 0.8, 0.3, 1.0)
const EMPTY_COLOR := Color(0.35, 0.35, 0.35, 1.0)
const ORB_SIZE := 14


func _ready() -> void:
	add_child(gold_manager)
	add_child(ap_manager)
	gold_manager.gold_changed.connect(_on_gold_changed)
	ap_manager.ap_changed.connect(_on_ap_changed)
	_create_orbs(gold_orbs, GameBalance.GOLD_MAX)
	_create_orbs(ap_orbs, GameBalance.AP_MAX)
	_update_orbs(gold_orbs, 0, GameBalance.GOLD_MAX, GOLD_COLOR)
	_update_orbs(ap_orbs, 0, GameBalance.AP_MAX, AP_COLOR)


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
	gold_label.text = "골드 %d/%d" % [current, max_value]
	_update_orbs(gold_orbs, current, max_value, GOLD_COLOR)


func _on_ap_changed(current: int, max_value: int) -> void:
	ap_label.text = "AP %d/%d" % [current, max_value]
	_update_orbs(ap_orbs, current, max_value, AP_COLOR)
