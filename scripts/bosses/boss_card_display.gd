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
	# 보스 카드 = 붉은 Kenney 프레임 (위협/위험 신호)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", DarkFantasyTheme.kenney_panel(true, 4, DarkFantasyTheme.CARD_FRAMES[0]))
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

	# ─── 위협 비네트 (아트 위 붉은 어둠 — 보스 위압감) ───
	var menace := TextureRect.new()
	menace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menace.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menace.stretch_mode = TextureRect.STRETCH_SCALE
	var mg := GradientTexture2D.new()
	mg.fill = GradientTexture2D.FILL_RADIAL
	mg.fill_from = Vector2(0.5, 0.42)
	mg.fill_to = Vector2(1.05, 1.05)
	var mgrad := Gradient.new()
	mgrad.set_color(0, Color(0.45, 0.03, 0.03, 0.0))
	mgrad.set_color(1, Color(0.13, 0.0, 0.0, 0.74))
	mg.gradient = mgrad
	menace.texture = mg
	panel.add_child(menace)

	# ─── 아트 매트 (안쪽 크림슨 테두리 — 액자 속 그림) ───
	var matte := Panel.new()
	matte.set_anchors_preset(Control.PRESET_FULL_RECT)
	matte.offset_left = 3
	matte.offset_top = 3
	matte.offset_right = -3
	matte.offset_bottom = -3
	matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var matte_style := StyleBoxFlat.new()
	matte_style.bg_color = Color(0, 0, 0, 0)
	matte_style.set_border_width_all(1)
	matte_style.border_color = Color(0.72, 0.20, 0.16, 0.6)
	matte_style.set_corner_radius_all(4)
	matte.add_theme_stylebox_override("panel", matte_style)
	panel.add_child(matte)

	# ─── 상단 이름 스트립 (반투명) ───
	var top_strip := PanelContainer.new()
	top_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.19, 0.02, 0.02, 0.86)   # 크림슨 이름판
	top_style.border_width_bottom = 2
	top_style.border_color = Color(0.92, 0.40, 0.28, 0.9)   # 밝은 크림슨 액센트 라인
	# 좌측 페이즈 스트립(최대 10px)에 이름이 안 걸리도록 좌우 여백 확보
	top_style.content_margin_left = 13
	top_style.content_margin_right = 8
	top_style.content_margin_top = 2
	top_style.content_margin_bottom = 2
	top_strip.add_theme_stylebox_override("panel", top_style)
	add_child(top_strip)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.85))
	_name_label.add_theme_color_override("font_outline_color", Color(0.15, 0, 0, 1))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.clip_text = false
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
	bot_style.bg_color = Color(0.10, 0.02, 0.02, 0.82)   # 크림슨 설명판
	bot_style.border_width_top = 1
	bot_style.border_color = Color(0.60, 0.14, 0.12, 0.7)
	# 좌측 페이즈 스트립(최대 10px)에 설명이 안 걸리도록 좌우 여백 확보
	bot_style.content_margin_left = 13
	bot_style.content_margin_right = 8
	bot_style.content_margin_top = 2
	bot_style.content_margin_bottom = 2
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
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	badge_style.bg_color = Color(0.74, 0.10, 0.07)      # 크림슨
	badge_style.set_border_width_all(2)
	badge_style.border_color = Color(1.0, 0.62, 0.45)   # 발광 링
	badge_style.set_corner_radius_all(13)               # 원형
	badge_style.shadow_color = Color(0.9, 0.2, 0.1, 0.55)
	badge_style.shadow_size = 5
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

	# 카드 크기 비례 폰트·뱃지 스케일링
	# 기준: CARD_H = 145 (파워존 카드 기본). 더 큰 카드(다음 예고 230, 행동 연출 294)는 확대.
	_apply_size_scaling()

	if card.artwork != null:
		_artwork_rect.texture = card.artwork
		_artwork_rect.visible = true
		_icon_label.visible = false   # 아트워크 있으면 중앙 아이콘 숨김
	else:
		_artwork_rect.visible = false
		_icon_label.visible = true

	if card.card_type == BossCardData.BossCardType.POWER:
		_type_label.text = "☄ 파워"
		_type_label.add_theme_color_override("font_color", Color(1.0, 0.66, 0.2))
		_countdown_badge.visible = true
		_countdown_label.text = str(current_tokens)
	else:
		_type_label.text = "⚔ 공격"
		_type_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
		_countdown_badge.visible = false

	# 페이즈 시각화 — 좌측 스트립 + 좌상단 뱃지
	if phase >= 1 and phase <= 3 and PHASE_COLORS.has(phase):
		var pc: Color = PHASE_COLORS[phase]
		_phase_stripe.color = Color(pc.r, pc.g, pc.b, 0.85)
		_phase_stripe.visible = true
		_phase_badge_label.text = "P%d" % phase
		# 뱃지 = 어두운 젬 바탕 + 페이즈색 발광 테두리 + 페이즈색 글자
		var pb_style := _phase_badge.get_theme_stylebox("panel") as StyleBoxFlat
		if pb_style:
			pb_style.bg_color = Color(0.06, 0.05, 0.04, 0.94)
			pb_style.set_border_width_all(2)
			pb_style.border_color = pc
			pb_style.set_corner_radius_all(9)
			pb_style.shadow_color = Color(pc.r, pc.g, pc.b, 0.4)
			pb_style.shadow_size = 3
		_phase_badge_label.add_theme_color_override("font_color", pc.lightened(0.2))
		_phase_badge.visible = true
	else:
		_phase_stripe.visible = false
		_phase_badge.visible = false


# 카드 크기에 비례해 폰트와 코너 뱃지(페이즈/카운트다운)를 스케일.
# 기준: CARD_H = 145. 예) 230 → 1.58×, 294 → 2.03×.
# 작은 카드(파워존 기본)는 1.0× 유지.
func _apply_size_scaling() -> void:
	var s: float = float(_card_h) / float(CARD_H)
	if s < 1.0:
		s = 1.0   # 기본 미만 카드는 그대로 (축소 방지)

	# 폰트 스케일
	_name_label.add_theme_font_size_override("font_size", int(round(13 * s)))
	_desc_label.add_theme_font_size_override("font_size", int(round(10 * s)))
	_type_label.add_theme_font_size_override("font_size", int(round(9 * s)))
	_icon_label.add_theme_font_size_override("font_size", int(round(38 * s)))

	# 페이즈 뱃지 — 이름 스트립 아래(아트워크 영역 좌상단)로 배치해 이름과 겹치지 않게
	# 이름 스트립 높이 ≈ font_size + padding(약 7) → 13+7=20 기준, 거기서 4px 띄움
	_phase_badge.offset_left = 6 * s
	_phase_badge.offset_top = 26 * s
	_phase_badge.offset_right = 32 * s
	_phase_badge.offset_bottom = 46 * s
	_phase_badge_label.add_theme_font_size_override("font_size", int(round(11 * s)))

	# 카운트다운 뱃지 — 우상단, 비례 확대
	_countdown_badge.offset_left = -28 * s
	_countdown_badge.offset_top = 2 * s
	_countdown_badge.offset_right = -2 * s
	_countdown_badge.offset_bottom = 28 * s
	_countdown_label.add_theme_font_size_override("font_size", int(round(14 * s)))

	# 좌측 페이즈 스트립 — 두께도 약간 비례 (6 → 최대 10)
	_phase_stripe.offset_right = mini(int(round(6 * s)), 10)
