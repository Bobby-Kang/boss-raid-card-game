extends CanvasLayer

signal order_confirmed(ordered_cards: Array[Control])
signal cancelled

const CardScene := preload("res://scenes/cards/card.tscn")

@onready var dim_bg: ColorRect = $DimBackground
@onready var card_row: HBoxContainer = $DimBackground/CenterVBox/CardRow
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


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)
	confirm_button.disabled = true
	visible = false


## 전체 선택 모드 (턴 종료용)
func show_overlay(hand_cards: Array[Control]) -> void:
	_open(hand_cards, -1)


## N장만 선택 모드 (밑장 빼기 등)
func show_overlay_select(hand_cards: Array[Control], count: int) -> void:
	_open(hand_cards, count)


func _open(hand_cards: Array[Control], required: int) -> void:
	_original_cards.clear()
	_order_sequence.clear()
	_current_order = 0
	_required_count = required

	for slot in _preview_slots:
		slot.queue_free()
	_preview_slots.clear()

	_original_cards.assign(hand_cards)

	for i in range(_original_cards.size()):
		var card: Control = _original_cards[i]

		var slot := Control.new()
		slot.custom_minimum_size = Vector2(180, 255)

		var preview: Control = CardScene.instantiate()
		preview.data = card.data
		preview.is_face_up = true
		preview.scale = Vector2(1.5, 1.5)
		preview.position = Vector2.ZERO
		slot.add_child(preview)

		var order_label := Label.new()
		order_label.name = "OrderLabel"
		order_label.text = ""
		order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		order_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		order_label.add_theme_font_size_override("font_size", 48)
		order_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		order_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		order_label.add_theme_constant_override("shadow_offset_x", 2)
		order_label.add_theme_constant_override("shadow_offset_y", 2)
		order_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(order_label)

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
			var label: Label = _preview_slots[r_idx].get_node("OrderLabel")
			label.text = ""
	else:
		# N장 모드에서 이미 필요한 만큼 선택했으면 무시
		if _required_count > 0 and _order_sequence.size() >= _required_count:
			return
		_order_sequence.append(index)
		_current_order += 1
		var label: Label = _preview_slots[index].get_node("OrderLabel")
		label.text = str(_current_order)

	_update_ui()


func _update_ui() -> void:
	for i in range(_order_sequence.size()):
		var idx := _order_sequence[i]
		var label: Label = _preview_slots[idx].get_node("OrderLabel")
		label.text = str(i + 1)

	var total: int = _original_cards.size() if _required_count < 0 else _required_count
	var selected := _order_sequence.size()
	info_label.text = "버릴 순서를 선택하세요 (%d/%d)" % [selected, total]
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
