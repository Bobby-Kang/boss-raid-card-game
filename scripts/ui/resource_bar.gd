class_name ResourceBar
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
const AP_COLOR := Color(0.35, 0.85, 1.0, 1.0)
const EMPTY_COLOR := Color(0.22, 0.24, 0.28, 1.0)
# 골드·AP·투기 오브는 크기가 같아야 한다 (제각각이면 UI가 들쭉날쭉해 보임)
const ORB_SIZE := 16


func _ready() -> void:
	add_child(gold_manager)
	add_child(ap_manager)
	gold_manager.gold_changed.connect(_on_gold_changed)
	ap_manager.ap_changed.connect(_on_ap_changed)
	_create_orbs(gold_orbs, GameBalance.GOLD_MAX)
	_create_orbs(ap_orbs, GameBalance.AP_MAX)
	_update_orbs(gold_orbs, 0, GameBalance.GOLD_MAX, GOLD_COLOR)
	_update_orbs(ap_orbs, 0, GameBalance.AP_MAX, AP_COLOR)


# 오브 = 납작한 네모가 아니라 둥근 알 (테두리 + 채움색). 공용 헬퍼로 투기 오브와 톤을 맞춘다.
static func orb_style(fill: Color, lit: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(int(ORB_SIZE / 2.0))
	s.border_color = Color(0, 0, 0, 0.55) if lit else Color(0, 0, 0, 0.35)
	s.set_border_width_all(1)
	if lit:   # 켜진 알은 살짝 발광
		s.shadow_color = Color(fill.r, fill.g, fill.b, 0.45)
		s.shadow_size = 4
	return s


func _create_orbs(container: HBoxContainer, count: int) -> void:
	container.add_theme_constant_override("separation", 4)
	for i in range(count):
		var orb := Panel.new()
		orb.custom_minimum_size = Vector2(ORB_SIZE, ORB_SIZE)
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orb.add_theme_stylebox_override("panel", orb_style(EMPTY_COLOR, false))
		container.add_child(orb)


func _update_orbs(container: HBoxContainer, current: int, _max_value: int, active_color: Color) -> void:
	var orbs := container.get_children()
	for i in range(orbs.size()):
		var lit := i < current
		orbs[i].add_theme_stylebox_override("panel",
			orb_style(active_color if lit else EMPTY_COLOR, lit))


func _on_gold_changed(current: int, max_value: int) -> void:
	gold_label.text = "💰 %d/%d" % [current, max_value]
	_update_orbs(gold_orbs, current, max_value, GOLD_COLOR)


func _on_ap_changed(current: int, max_value: int) -> void:
	ap_label.text = "⚡ %d/%d" % [current, max_value]
	_update_orbs(ap_orbs, current, max_value, AP_COLOR)
