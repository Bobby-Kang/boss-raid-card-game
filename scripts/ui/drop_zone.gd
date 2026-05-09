class_name DropZone
extends PanelContainer

signal card_dropped(card: Control)

enum ZoneType { PLAY, DISCARD, ACTIVE }
@export var zone_type: ZoneType = ZoneType.PLAY

## true면 평소엔 mouse_filter=IGNORE(클릭 통과), 드래그 중에만 STOP(드롭 대상).
## PlayDropZone처럼 다른 UI(MarketPanel 등) 위를 덮는 투명 드롭존에서 사용.
@export var pass_through_when_idle: bool = false

## 드래그 중 영역에 표시할 라벨(예: "⚔ 보스 공격", "🗑 버리기").
@export var drag_label_text: String = ""

## main_scene에서 설정하는 필터 함수: func(card, zone_type) -> bool
var accept_filter: Callable

var _default_style: StyleBoxFlat
var _highlight_style: StyleBoxFlat       # 호버 시(드롭 가능)
var _accept_overlay_style: StyleBoxFlat  # 드래그 시작·이 카드 수용 가능
var _reject_overlay_style: StyleBoxFlat  # 드래그 시작·수용 불가

var _drag_overlay: PanelContainer        # 드래그 중에만 보이는 라벨 패널
var _drag_label: Label
var _idle_self_modulate: Color = Color.WHITE  # 평소 self_modulate 보존


func _ready() -> void:
	_default_style = get_theme_stylebox("panel").duplicate() if get_theme_stylebox("panel") else null

	_highlight_style = StyleBoxFlat.new()
	_highlight_style.bg_color = Color(0.4, 0.85, 0.4, 0.45)
	_highlight_style.border_color = Color(0.4, 1.0, 0.4, 1.0)
	_highlight_style.set_border_width_all(3)
	_highlight_style.set_corner_radius_all(6)

	_accept_overlay_style = StyleBoxFlat.new()
	_accept_overlay_style.bg_color = Color(0.35, 0.7, 1.0, 0.18)
	_accept_overlay_style.border_color = Color(0.5, 0.85, 1.0, 0.85)
	_accept_overlay_style.set_border_width_all(2)
	_accept_overlay_style.set_corner_radius_all(6)

	_reject_overlay_style = StyleBoxFlat.new()
	_reject_overlay_style.bg_color = Color(0.5, 0.15, 0.15, 0.15)
	_reject_overlay_style.border_color = Color(0.6, 0.2, 0.2, 0.5)
	_reject_overlay_style.set_border_width_all(1)
	_reject_overlay_style.set_corner_radius_all(6)

	if pass_through_when_idle:
		mouse_filter = MOUSE_FILTER_IGNORE

	# 평소 self_modulate를 기억 (드래그 종료 시 복원)
	_idle_self_modulate = self_modulate

	# 드래그 중 표시용 라벨 패널 (평소엔 숨김)
	_build_drag_label()


func _build_drag_label() -> void:
	if drag_label_text == "":
		return
	_drag_overlay = PanelContainer.new()
	_drag_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	_drag_overlay.visible = false
	_drag_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	# 부모 채우기
	_drag_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	_drag_label = Label.new()
	_drag_label.text = drag_label_text
	_drag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_drag_label.add_theme_font_size_override("font_size", 18)
	_drag_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_drag_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_drag_label.add_theme_constant_override("outline_size", 4)
	_drag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drag_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drag_overlay.add_child(_drag_label)
	add_child(_drag_overlay)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Control:
		return false
	if not "data" in data:
		return false
	if accept_filter.is_valid():
		var result: bool = accept_filter.call(data, zone_type)
		# 호버 시 강조
		if result:
			add_theme_stylebox_override("panel", _highlight_style)
		return result
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_restore_style()
	_hide_drag_overlay()
	card_dropped.emit(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		if pass_through_when_idle:
			mouse_filter = MOUSE_FILTER_STOP
		_show_drag_overlay()
	elif what == NOTIFICATION_DRAG_END:
		if pass_through_when_idle:
			mouse_filter = MOUSE_FILTER_IGNORE
		_hide_drag_overlay()
		_restore_style()


func _show_drag_overlay() -> void:
	if _drag_overlay == null:
		return
	# 평소 투명한 드롭존도 드래그 중엔 stylebox가 보이도록 self_modulate 강제 복구
	self_modulate = Color.WHITE
	# 현재 드래그 중인 데이터를 검사해 accept/reject 결정
	var data: Variant = get_viewport().gui_get_drag_data() if get_viewport() else null
	var can_accept: bool = false
	if data != null and accept_filter.is_valid():
		can_accept = accept_filter.call(data, zone_type)
	if can_accept:
		add_theme_stylebox_override("panel", _accept_overlay_style)
		_drag_label.modulate = Color(1, 1, 1, 1)
		_drag_label.text = drag_label_text
		_drag_overlay.visible = true
		_pulse_overlay()
	else:
		# 수용 불가도 약하게 표시 (불가능함을 시각화)
		add_theme_stylebox_override("panel", _reject_overlay_style)
		_drag_label.modulate = Color(1, 0.5, 0.5, 0.4)
		_drag_label.text = "✕ " + drag_label_text
		_drag_overlay.visible = true


func _hide_drag_overlay() -> void:
	if _drag_overlay:
		_drag_overlay.visible = false
	# 평소 self_modulate 복원
	self_modulate = _idle_self_modulate


func _pulse_overlay() -> void:
	if _drag_overlay == null:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(_drag_overlay, "modulate:a", 0.6, 0.6)
	tween.tween_property(_drag_overlay, "modulate:a", 1.0, 0.6)


func _restore_style() -> void:
	if _default_style:
		add_theme_stylebox_override("panel", _default_style)
	else:
		remove_theme_stylebox_override("panel")
