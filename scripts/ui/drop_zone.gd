class_name DropZone
extends PanelContainer

signal card_dropped(card: Control)

enum ZoneType { PLAY, DISCARD, ACTIVE }
@export var zone_type: ZoneType = ZoneType.PLAY

## main_scene에서 설정하는 필터 함수: func(card, zone_type) -> bool
var accept_filter: Callable

var _default_style: StyleBoxFlat
var _highlight_style: StyleBoxFlat


func _ready() -> void:
	_default_style = get_theme_stylebox("panel").duplicate() if get_theme_stylebox("panel") else null
	_highlight_style = StyleBoxFlat.new()
	_highlight_style.bg_color = Color(0.4, 0.8, 0.4, 0.3)
	_highlight_style.border_color = Color(0.3, 0.9, 0.3, 0.8)
	_highlight_style.set_border_width_all(2)
	_highlight_style.set_corner_radius_all(4)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Control:
		return false
	if not "data" in data:
		return false
	if accept_filter.is_valid():
		var result: bool = accept_filter.call(data, zone_type)
		# 하이라이트
		if result:
			add_theme_stylebox_override("panel", _highlight_style)
		return result
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_restore_style()
	card_dropped.emit(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_restore_style()


func _restore_style() -> void:
	if _default_style:
		add_theme_stylebox_override("panel", _default_style)
	else:
		remove_theme_stylebox_override("panel")
