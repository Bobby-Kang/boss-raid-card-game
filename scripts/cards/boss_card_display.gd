class_name BossCardDisplay
extends Control

# 보스 카드를 시각적으로 표시하는 읽기 전용 카드 위젯
# 플레이어 카드(card.tscn)와 유사한 외형이지만 드래그 없이 표시 전용
# POWER 카드에는 카운트다운 토큰 뱃지(우상단 오렌지 원)를 표시

const CARD_W := 118
const CARD_H := 168

var _icon_label: Label
var _name_label: Label
var _desc_label: Label
var _type_label: Label
var _countdown_badge: PanelContainer
var _countdown_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ─── 배경 패널 (어두운 보스 톤) ───
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.09, 0.08)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.62, 0.16, 0.12)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	# ─── 내용 마진 ───
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# 아이콘 (이모지)
	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 32)
	_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_icon_label)

	# 카드명
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)

	# 구분선
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	# 설명
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 10)
	_desc_label.add_theme_color_override("font_color", Color(0.78, 0.68, 0.56))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_desc_label)

	# 타입 라벨 (우측 정렬)
	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_type_label.add_theme_font_size_override("font_size", 10)
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_type_label)

	# ─── 카운트다운 뱃지 (POWER 카드 전용, 우상단) ───
	_countdown_badge = PanelContainer.new()
	_countdown_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_countdown_badge.offset_left = -28
	_countdown_badge.offset_top = 2
	_countdown_badge.offset_right = -2
	_countdown_badge.offset_bottom = 28
	_countdown_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.85, 0.44, 0.0)
	badge_style.corner_radius_top_left = 5
	badge_style.corner_radius_top_right = 5
	badge_style.corner_radius_bottom_left = 5
	badge_style.corner_radius_bottom_right = 5
	_countdown_badge.add_theme_stylebox_override("panel", badge_style)
	add_child(_countdown_badge)

	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 14)
	_countdown_label.add_theme_color_override("font_color", Color.WHITE)
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_badge.add_child(_countdown_label)

	_countdown_badge.visible = false


# card: BossCardData, current_tokens: 파워 카드의 현재 카운트다운 값
func setup(card: BossCardData, current_tokens: int = 0) -> void:
	_icon_label.text = card.intent_icon
	_name_label.text = card.card_name
	_desc_label.text = card.description

	if card.card_type == BossCardData.BossCardType.POWER:
		_type_label.text = "파워"
		_type_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
		_countdown_badge.visible = true
		_countdown_label.text = str(current_tokens)
	else:
		_type_label.text = "공격"
		_type_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		_countdown_badge.visible = false
