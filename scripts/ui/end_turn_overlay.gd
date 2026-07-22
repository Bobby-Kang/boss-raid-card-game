extends CanvasLayer

signal order_confirmed(ordered_cards: Array[Control])
signal cancelled

const CardScene := preload("res://scenes/cards/card.tscn")
const MAX_PER_ROW := 5   # 한 줄에 놓을 카드 수

@onready var dim_bg: ColorRect = $DimBackground
@onready var card_row: HFlowContainer = $DimBackground/CenterVBox/CardRow
@onready var confirm_button: Button = $DimBackground/CenterVBox/ButtonRow/ConfirmButton
@onready var cancel_button: Button = $DimBackground/CenterVBox/ButtonRow/CancelButton
@onready var info_label: Label = $DimBackground/CenterVBox/InfoLabel

# 원본 카드 참조 배열
var _original_cards: Array[Control] = []
# 미리보기 카드 컨테이너 배열
var _preview_slots: Array[Control] = []
# 선택된 순서 (인덱스 저장)
var _order_sequence: Array[int] = []
var _current_order: int = 0
# 선택 필요 수 (-1이면 전체 선택 필수)
var _required_count: int = -1
# 안내 문구 동사 (버리기 / 소멸 / 제거 등) — "%s 순서를 선택하세요 (n/n)"
var _prompt_verb: String = "버릴"


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)
	confirm_button.disabled = true
	visible = false
	_build_frame()


# 내용을 액자로 감싼다. @onready 참조는 이미 해결된 뒤라 재부모화해도 살아있다.
# 씬 기본은 1360×680 고정이라 버튼이 손패 위까지 내려가 겹쳐 보였다 → 내용에 맞춰 축소.
func _build_frame() -> void:
	var vbox := $DimBackground/CenterVBox as Control
	if vbox == null:
		return
	dim_bg.color = Color(0.02, 0.025, 0.035, 0.86)

	var frame := PanelContainer.new()
	frame.name = "Frame"
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.055, 0.065, 0.085, 0.97)
	box.border_color = Color(0.45, 0.72, 0.95, 0.85)
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(24)
	box.shadow_color = Color(0.2, 0.5, 0.75, 0.28)
	box.shadow_size = 14
	frame.add_theme_stylebox_override("panel", box)

	# CenterContainer로 감싼다 — 내용 크기가 매번 달라지므로 앵커/오프셋으로
	# 중앙을 맞추면 어긋난다(좌상단에 박히는 버그가 있었다).
	var center := CenterContainer.new()
	center.name = "FrameCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_bg.add_child(center)
	center.add_child(frame)

	vbox.reparent(frame, false)
	# 내용 크기에 맞춰 줄어들도록 (고정 오프셋 해제)
	vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	vbox.custom_minimum_size = Vector2.ZERO
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 18)

	# 제목 강조
	info_label.add_theme_font_size_override("font_size", 22)
	info_label.add_theme_color_override("font_color", Color(0.85, 0.94, 1.0))

	# 버튼을 가운데로 + 여유 크기
	var brow := vbox.get_node_or_null("ButtonRow")
	if brow is HBoxContainer:
		(brow as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		(brow as HBoxContainer).add_theme_constant_override("separation", 14)
	for b in [confirm_button, cancel_button]:
		b.custom_minimum_size = Vector2(150, 46)
		b.add_theme_font_size_override("font_size", 18)


## 전체 선택 모드 (턴 종료용)
func show_overlay(hand_cards: Array[Control]) -> void:
	_open(hand_cards, -1, "파이프에 넣을")


## N장만 선택 모드 (밑장 빼기 등). prompt_verb로 안내 문구 동사 지정.
func show_overlay_select(hand_cards: Array[Control], count: int, prompt_verb: String = "버릴") -> void:
	_open(hand_cards, count, prompt_verb)


func _open(hand_cards: Array[Control], required: int, prompt_verb: String = "버릴") -> void:
	_prompt_verb = prompt_verb
	_original_cards.clear()
	_order_sequence.clear()
	_current_order = 0
	_required_count = required

	for slot in _preview_slots:
		slot.queue_free()
	_preview_slots.clear()

	_original_cards.assign(hand_cards)

	# 카드 수에 따라 크기 동적 조정 — 많으면 작게 (HFlowContainer가 자동 줄바꿈)
	var n: int = _original_cards.size()
	var card_scale: float = 1.0
	if n > 16:
		card_scale = 0.62
	elif n > 11:
		card_scale = 0.78
	elif n > 7:
		card_scale = 0.9
	var slot_w: int = int(150 * card_scale)
	var slot_h: int = int(212 * card_scale)
	var order_font: int = maxi(int(44 * card_scale), 22)

	# 한 줄에 최대 5장 — HFlowContainer는 부모 폭에 맞춰 접히므로 폭을 직접 준다.
	# (액자가 내용에 맞춰 줄어들다 보니 2장씩 접혀 세로로 길어졌었다)
	var sep := card_row.get_theme_constant("h_separation")
	card_row.custom_minimum_size.x = slot_w * MAX_PER_ROW + sep * (MAX_PER_ROW - 1)

	for i in range(_original_cards.size()):
		var card: Control = _original_cards[i]

		var slot := Control.new()
		slot.custom_minimum_size = Vector2(slot_w, slot_h)

		var preview: Control = CardScene.instantiate()
		preview.data = card.data
		preview.is_face_up = true
		preview.pivot_offset = Vector2.ZERO   # 좌상단 기준 스케일 → 슬롯에 정렬
		preview.scale = Vector2(card_scale, card_scale)
		preview.position = Vector2.ZERO
		slot.add_child(preview)

		# 순서 뱃지 — 평평한 글자 대신 입체 원형 메달 (그림자 + 금테 + 하이라이트)
		var badge_d: int = maxi(int(order_font * 1.5), 40)
		var badge := Panel.new()
		badge.name = "OrderBadge"
		badge.custom_minimum_size = Vector2(badge_d, badge_d)
		badge.size = Vector2(badge_d, badge_d)
		# 앵커 프리셋 + 수동 position을 섞으면 위치가 어긋난다 → TOP_LEFT 고정 후 직접 배치
		badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		badge.position = ((Vector2(slot_w, slot_h) - Vector2(badge_d, badge_d)) * 0.5).round()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		var bstyle := StyleBoxFlat.new()
		bstyle.bg_color = Color(0.16, 0.12, 0.04, 0.96)
		bstyle.set_corner_radius_all(roundi(badge_d / 2.0))
		bstyle.border_color = Color(1.0, 0.82, 0.32)
		bstyle.set_border_width_all(3)
		bstyle.shadow_color = Color(0, 0, 0, 0.75)     # 아래로 떨어지는 그림자 = 떠 있는 느낌
		bstyle.shadow_size = 8
		bstyle.shadow_offset = Vector2(0, 4)
		badge.add_theme_stylebox_override("panel", bstyle)
		slot.add_child(badge)

		var order_label := Label.new()
		order_label.name = "OrderLabel"
		order_label.text = ""
		order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		order_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		order_label.add_theme_font_size_override("font_size", order_font)
		order_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
		# 검은 외곽선 + 아래 그림자 → 글자가 뱃지 위로 솟아 보인다
		order_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.0))
		order_label.add_theme_constant_override("outline_size", 6)
		order_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		order_label.add_theme_constant_override("shadow_offset_x", 0)
		order_label.add_theme_constant_override("shadow_offset_y", 3)
		order_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(order_label)

		var click_btn := Button.new()
		click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx := i
		click_btn.pressed.connect(func(): _on_slot_clicked(idx))
		slot.add_child(click_btn)

		card_row.add_child(slot)
		_preview_slots.append(slot)

	_update_ui()
	visible = true


func _on_slot_clicked(index: int) -> void:
	if index in _order_sequence:
		# 이미 선택됨 → 해당 순서 이후 전부 취소
		var pos := _order_sequence.find(index)
		var removed := _order_sequence.slice(pos)
		_order_sequence.resize(pos)
		_current_order = _order_sequence.size()
		for r_idx in removed:
			_set_order_badge(r_idx, 0)
	else:
		# N장 모드에서 이미 필요한 만큼 선택했으면 무시
		if _required_count > 0 and _order_sequence.size() >= _required_count:
			return
		_order_sequence.append(index)
		_current_order += 1
		_set_order_badge(index, _current_order)

	_update_ui()


# 순서 뱃지 갱신 — n이 0이면 숨긴다
func _set_order_badge(slot_index: int, n: int) -> void:
	var badge := _preview_slots[slot_index].get_node_or_null("OrderBadge")
	if badge == null:
		return
	badge.visible = n > 0
	var label := badge.get_node_or_null("OrderLabel")
	if label is Label:
		(label as Label).text = str(n) if n > 0 else ""


func _update_ui() -> void:
	for i in range(_order_sequence.size()):
		_set_order_badge(_order_sequence[i], i + 1)

	var total: int = _original_cards.size() if _required_count < 0 else _required_count
	var selected := _order_sequence.size()
	info_label.text = "%s 순서를 선택하세요 (%d/%d)" % [_prompt_verb, selected, total]
	confirm_button.disabled = (selected != total)


func _on_confirm() -> void:
	var ordered: Array[Control] = []
	for idx in _order_sequence:
		ordered.append(_original_cards[idx])
	visible = false
	order_confirmed.emit(ordered)
	_cleanup()


func _on_cancel() -> void:
	visible = false
	cancelled.emit()
	_cleanup()


func _cleanup() -> void:
	for slot in _preview_slots:
		slot.queue_free()
	_preview_slots.clear()
	_original_cards.clear()
	_order_sequence.clear()
	_current_order = 0
