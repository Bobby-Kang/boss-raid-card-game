extends Control

signal hover_changed(card: Control, entered: bool)

@onready var card_back: TextureRect = $CardBack
@onready var card_front: Control = $CardFront

@onready var artwork_area: TextureRect = %ArtworkArea
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var type_label: Label = %TypeLabel
@onready var cost_label: Label = %CostLabel
@onready var name_bg: PanelContainer = %NameBg
@onready var type_bg: PanelContainer = %TypeBg
@onready var art_matte: Panel = %ArtMatte

var is_face_up: bool = false
var is_active: bool = true
var data: CardData
var temper: int = 0      # 단련 횟수 — 파이프를 한 바퀴 돌 때마다 +1 (TemperedDamageEffect 등이 참조)
var vanguard: bool = false   # 선봉 🚩 — 이번 손패의 첫 장(파이프 맨 앞)으로 드로우됐는지 (Vanguard 효과가 참조)


func _ready() -> void:
	# 모든 자식의 mouse_filter를 IGNORE로 설정하여
	# 드래그 이벤트가 Card 루트까지 도달하도록 함
	_set_children_mouse_ignore(self)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if data != null:
		_apply_data()

	if is_face_up:
		_show_front()
	else:
		_show_back()


func _on_mouse_entered() -> void:
	if is_face_up and is_active:
		hover_changed.emit(self, true)


func _on_mouse_exited() -> void:
	hover_changed.emit(self, false)


func _set_children_mouse_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_ignore(child)


func _apply_data() -> void:
	cost_label.text = str(data.cost)
	name_label.text = data.card_name
	desc_label.text = data.get_description_text()

	if data.artwork != null:
		artwork_area.texture = data.artwork

	# 카드 프레임을 타입별 색으로 (공격=붉은구리 / 스킬=블루스틸 / 파워=바이올렛 / 모듈=골드)
	var accent := _card_accent(data.card_type)
	if card_front is PanelContainer:
		card_front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # 프레임 선명
		card_front.add_theme_stylebox_override("panel", DarkFantasyTheme.card_frame(data.card_type))
	_style_card_chrome(accent)

	match data.card_type:
		CardData.CardType.ATTACK:
			type_label.text = "⚔ 공격"
		CardData.CardType.SKILL:
			type_label.text = "✦ 스킬"
		CardData.CardType.POWER:
			type_label.text = "☄ 파워"
		CardData.CardType.MODULE:
			type_label.text = "◈ 모듈"
		_:
			type_label.text = "알 수 없음"


# 카드 타입 색 (프레임·타임라인과 동일 체계)
func _card_accent(t: int) -> Color:
	match t:
		CardData.CardType.ATTACK: return Color(0.86, 0.42, 0.31)
		CardData.CardType.SKILL:  return Color(0.44, 0.63, 0.90)
		CardData.CardType.POWER:  return Color(0.66, 0.51, 0.83)
		CardData.CardType.MODULE: return Color(0.85, 0.68, 0.40)
	return Color(0.70, 0.60, 0.40)


# 카드 크롬(이름 배너·타입 배너·아트 매트)을 타입색으로 정돈
func _style_card_chrome(accent: Color) -> void:
	# ① 이름 배너 — 어두운 타입색 + 하단 타입색 라인
	if name_bg:
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(accent.r * 0.26, accent.g * 0.26, accent.b * 0.26, 0.9)
		ns.border_width_bottom = 2
		ns.border_color = accent
		ns.set_corner_radius_all(5)
		name_bg.add_theme_stylebox_override("panel", ns)
	if name_label:
		name_label.add_theme_color_override("font_color", accent.lightened(0.6))
	# ③ 타입 배너 — 타입색 채움
	if type_bg:
		var ts := StyleBoxFlat.new()
		ts.bg_color = Color(accent.r * 0.75, accent.g * 0.75, accent.b * 0.75, 0.92)
		ts.set_corner_radius_all(4)
		type_bg.add_theme_stylebox_override("panel", ts)
	if type_label:
		type_label.add_theme_color_override("font_color", accent.lightened(0.75))
	# ④ 아트 매트 — 안쪽 테두리를 타입색으로
	if art_matte:
		var ms := StyleBoxFlat.new()
		ms.bg_color = Color(0, 0, 0, 0)
		ms.set_border_width_all(2)
		ms.border_color = Color(accent.r, accent.g, accent.b, 0.55)
		ms.set_corner_radius_all(6)
		art_matte.add_theme_stylebox_override("panel", ms)


func set_active(active: bool) -> void:
	is_active = active
	modulate.a = 1.0 if active else 0.5
	mouse_filter = MOUSE_FILTER_STOP if active else MOUSE_FILTER_IGNORE
	_set_children_mouse_ignore(self)


# --- 실시간 예상 수치 뱃지 (손패 전용) ---
# 현재 상황(보스 방어·투기·단련·인접 등)에서 이 카드가 실제로 낼 피해/방어를 좌하단에 표시.
var _live_label: Label = null

func set_live_preview(damage: int, block: int) -> void:
	if damage <= 0 and block <= 0:
		if _live_label:
			_live_label.visible = false
		return
	if _live_label == null:
		_live_label = Label.new()
		_live_label.add_theme_font_size_override("font_size", 17)
		_live_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		_live_label.add_theme_constant_override("outline_size", 5)
		_live_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_live_label.z_index = 5
		add_child(_live_label)
		_live_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_live_label.offset_left = 6
		_live_label.offset_top = -28
		_live_label.offset_bottom = -6
	var parts: PackedStringArray = []
	if damage > 0:
		parts.append("⚔%d" % damage)
	if block > 0:
		parts.append("🛡%d" % block)
	_live_label.text = " ".join(parts)
	if damage > 0 and block > 0:
		_live_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1))
	elif damage > 0:
		_live_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4, 1))
	else:
		_live_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 1))
	_live_label.visible = true


# --- 드래그 앤 드롭 ---

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not is_face_up or not is_active:
		return null
	# 프리뷰 생성
	set_drag_preview(_create_drag_preview())
	modulate.a = 0.4
	return self


func _create_drag_preview() -> Control:
	# 커서가 프리뷰 중앙에 오도록 offset 컨테이너 사용
	var offset_container := Control.new()

	# 드래그 프리뷰는 카드 원본의 55% 크기 (마우스 따라다닐 때 화면 가림 최소화)
	var preview_size: Vector2 = custom_minimum_size * 0.55
	var preview := PanelContainer.new()
	preview.custom_minimum_size = preview_size
	preview.size = preview_size
	preview.position = -preview_size / 2.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.85, 0.9)
	style.border_color = Color(0.3, 0.25, 0.2, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	preview.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = data.card_name if data else "카드"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	preview.add_child(label)
	offset_container.add_child(preview)
	return offset_container


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0


# --- 앞/뒷면 표시 ---

func _show_front() -> void:
	if card_back: card_back.visible = false
	if card_front: card_front.visible = true


func _show_back() -> void:
	if card_back: card_back.visible = true
	if card_front: card_front.visible = false
