class_name BossCardDisplay
extends Control

# 보스 카드 시각 위젯 (읽기 전용, 드래그 없음).
# 아트워크가 있으면 카드 전체 배경으로 깔고 이름·설명을 반투명 오버레이로 표시 (플레이어 카드 스타일).
# 아트워크가 없으면 아이콘 기반 폴백 레이아웃.
# POWER 카드에는 우상단 카운트다운 뱃지.

const CARD_W := 100
const CARD_H := 145

# 페이즈 색 팔레트 (main_scene.PHASE_COLORS와 동일 톤)
const PHASE_COLORS := {
	1: Color(0.95, 0.92, 0.85, 1),  # 양피지 흰 (추적 페이즈)
	2: Color(0.50, 0.72, 1.00, 1),  # 청 (광폭화)
	3: Color(1.00, 0.40, 0.40, 1),  # 적 (광기)
}

var _artwork_rect: TextureRect
var _icon_label: Label
var _name_label: Label
var _desc_label: Label
var _type_label: Label
var _countdown_badge: PanelContainer
var _countdown_label: Label
var _phase_stripe: ColorRect            # 좌측 세로 컬러 스트립
var _phase_badge: PanelContainer        # 좌상단 P1/P2/P3 뱃지
var _phase_badge_label: Label
var _card_w: int = CARD_W
var _card_h: int = CARD_H


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(_card_w, _card_h)

	# ─── 배경 패널 ───
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = true
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.09, 0.08)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.62, 0.16, 0.12)
	bg.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)

	# ─── 아트워크 (풀커버, 기본 숨김) ───
	_artwork_rect = TextureRect.new()
	_artwork_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_artwork_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_artwork_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_artwork_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_artwork_rect.visible = false
	panel.add_child(_artwork_rect)

	# ─── 상단 이름 스트립 (반투명) ───
	var top_strip := PanelContainer.new()
	top_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.05, 0.03, 0.03, 0.72)
	top_strip.add_theme_stylebox_override("panel", top_style)
	add_child(top_strip)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.add_theme_color_override("font_color", Color(0.97, 0.92, 0.80))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_strip.add_child(_name_label)

	# ─── 중앙 아이콘 (아트워크 없을 때만) ───
	_icon_label = Label.new()
	_icon_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 38)
	_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon_label)

	# ─── 하단 설명 스트립 (반투명) ───
	var bottom_strip := PanelContainer.new()
	bottom_strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_strip.offset_top = -46
	bottom_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bot_style := StyleBoxFlat.new()
	bot_style.bg_color = Color(0.05, 0.03, 0.03, 0.78)
	bottom_strip.add_theme_stylebox_override("panel", bot_style)
	add_child(bottom_strip)

	var bot_vbox := VBoxContainer.new()
	bot_vbox.add_theme_constant_override("separation", 1)
	bot_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_strip.add_child(bot_vbox)

	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 10)
	_desc_label.add_theme_color_override("font_color", Color(0.88, 0.80, 0.70))
	_desc_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_desc_label.add_theme_constant_override("outline_size", 2)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_vbox.add_child(_desc_label)

	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_type_label.add_theme_font_size_override("font_size", 9)
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_vbox.add_child(_type_label)

	# ─── 카운트다운 뱃지 (POWER 전용, 우상단) ───
	_countdown_badge = PanelContainer.new()
	_countdown_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_countdown_badge.offset_left = -28
	_countdown_badge.offset_top = 2
	_countdown_badge.offset_right = -2
	_countdown_badge.offset_bottom = 28
	_countdown_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.85, 0.44, 0.0)
	badge_style.set_corner_radius_all(5)
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

	# ─── 페이즈 좌측 컬러 스트립 (전체 높이) ───
	_phase_stripe = ColorRect.new()
	_phase_stripe.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_phase_stripe.offset_left = 0
	_phase_stripe.offset_top = 0
	_phase_stripe.offset_right = 6
	_phase_stripe.offset_bottom = 0
	_phase_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_stripe.visible = false
	add_child(_phase_stripe)

	# ─── 페이즈 뱃지 (좌상단 "P1"/"P2"/"P3") ───
	_phase_badge = PanelContainer.new()
	_phase_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_phase_badge.offset_left = 8
	_phase_badge.offset_top = 2
	_phase_badge.offset_right = 34
	_phase_badge.offset_bottom = 22
	_phase_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pb_style := StyleBoxFlat.new()
	pb_style.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	pb_style.set_border_width_all(1)
	pb_style.border_color = Color.WHITE
	pb_style.set_corner_radius_all(4)
	_phase_badge.add_theme_stylebox_override("panel", pb_style)
	_phase_badge.visible = false
	add_child(_phase_badge)

	_phase_badge_label = Label.new()
	_phase_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phase_badge_label.add_theme_font_size_override("font_size", 11)
	_phase_badge_label.add_theme_color_override("font_color", Color.WHITE)
	_phase_badge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_phase_badge_label.add_theme_constant_override("outline_size", 2)
	_phase_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_badge.add_child(_phase_badge_label)

	if _pending_card != null:
		_apply(_pending_card, _pending_tokens, _pending_phase)


var _pending_card: BossCardData = null
var _pending_tokens: int = 0
var _pending_phase: int = 0


# card: BossCardData / current_tokens: 파워 카운트다운 / card_size: 0,0이면 기본 크기
# phase: 1/2/3 (0이면 페이즈 뱃지 숨김 — 하위 호환)
func setup(card: BossCardData, current_tokens: int = 0, card_size: Vector2 = Vector2.ZERO, phase: int = 0) -> void:
	if card_size != Vector2.ZERO:
		_card_w = int(card_size.x)
		_card_h = int(card_size.y)
		custom_minimum_size = card_size
	# _ready 전에 호출될 수 있으므로 보류했다 적용
	if _name_label == null:
		_pending_card = card
		_pending_tokens = current_tokens
		_pending_phase = phase
		return
	_apply(card, current_tokens, phase)


func _apply(card: BossCardData, current_tokens: int, phase: int = 0) -> void:
	_name_label.text = card.card_name
	_desc_label.text = card.description
	_icon_label.text = card.intent_icon

	if card.artwork != null:
		_artwork_rect.texture = card.artwork
		_artwork_rect.visible = true
		_icon_label.visible = false   # 아트워크 있으면 중앙 아이콘 숨김
	else:
		_artwork_rect.visible = false
		_icon_label.visible = true

	if card.card_type == BossCardData.BossCardType.POWER:
		_type_label.text = "파워"
		_type_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
		_countdown_badge.visible = true
		_countdown_label.text = str(current_tokens)
	else:
		_type_label.text = "공격"
		_type_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		_countdown_badge.visible = false

	# 페이즈 시각화 — 좌측 스트립 + 좌상단 뱃지
	if phase >= 1 and phase <= 3 and PHASE_COLORS.has(phase):
		var pc: Color = PHASE_COLORS[phase]
		_phase_stripe.color = Color(pc.r, pc.g, pc.b, 0.85)
		_phase_stripe.visible = true
		_phase_badge_label.text = "P%d" % phase
		# 뱃지 배경을 페이즈 색의 어두운 톤으로
		var pb_style := _phase_badge.get_theme_stylebox("panel") as StyleBoxFlat
		if pb_style:
			pb_style.bg_color = Color(pc.r * 0.5, pc.g * 0.5, pc.b * 0.5, 0.95)
			pb_style.border_color = pc
		_phase_badge.visible = true
	else:
		_phase_stripe.visible = false
		_phase_badge.visible = false
