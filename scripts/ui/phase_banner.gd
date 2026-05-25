extends CanvasLayer

signal banner_finished
signal title_finished

@onready var label: Label = $Background/BannerLabel
@onready var _bg: ColorRect = $Background

var _queue: Array[String] = []
var _busy: bool = false

# 컬러 타이틀(페이즈 전환 등) 전용 — 큰 글씨 + 부제 + 스케일 팝
var _subtitle: Label = null
var _title_busy: bool = false


func show_message(text: String) -> void:
	_queue.append(text)
	if not _busy:
		_play_next()


func show_sequence(messages: Array[String]) -> void:
	_queue.append_array(messages)
	if not _busy:
		_play_next()


func _play_next() -> void:
	if _queue.is_empty():
		_busy = false
		banner_finished.emit()
		return

	_busy = true
	var text: String = _queue.pop_front()
	# 일반 배너 기본 스타일로 리셋 (직전 타이틀 스타일 누수 방지)
	_reset_label_style()
	if _subtitle:
		_subtitle.visible = false
	label.text = text
	visible = true
	label.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	# 페이드 인
	tween.tween_property(label, "modulate:a", 1.0, 0.25)
	# 표시 유지
	tween.tween_interval(1.0)
	# 페이드 아웃
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_on_message_done)


func _on_message_done() -> void:
	visible = false
	_play_next()


# === 컬러 타이틀 (페이즈 전환 같은 큰 순간) ===
# main_text: 큰 글씨 / subtitle: 아래 작은 부제 / color: 강조색
# await phase_banner.title_finished 로 종료 대기 가능
func show_title(main_text: String, subtitle: String, color: Color) -> void:
	_title_busy = true
	_ensure_subtitle()
	visible = true

	# 메인 라벨 — 큰 글씨 + 색 + 두꺼운 외곽선
	label.text = main_text
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(0.6, 0.6)
	label.modulate = Color(1, 1, 1, 0)

	# 부제
	_subtitle.text = subtitle
	_subtitle.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.35))
	_subtitle.visible = subtitle != ""
	_subtitle.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	# 등장 — 스케일 팝 + 페이드 인 (병렬)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(_subtitle, "modulate:a", 1.0, 0.3).set_delay(0.15)
	# 유지
	tween.tween_interval(1.1)
	# 퇴장 — 페이드 아웃 + 살짝 확대 (병렬)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(label, "scale", Vector2(1.08, 1.08), 0.3)
	tween.parallel().tween_property(_subtitle, "modulate:a", 0.0, 0.25)
	# 종료
	tween.tween_callback(_on_title_done)


func _on_title_done() -> void:
	visible = false
	_reset_label_style()
	if _subtitle:
		_subtitle.visible = false
	_title_busy = false
	title_finished.emit()
	# 타이틀 중 쌓인 일반 메시지가 있으면 이어서 재생
	if not _queue.is_empty() and not _busy:
		_play_next()


func _ensure_subtitle() -> void:
	if _subtitle != null:
		return
	_subtitle = Label.new()
	_subtitle.anchor_left = 0.5
	_subtitle.anchor_top = 0.5
	_subtitle.anchor_right = 0.5
	_subtitle.anchor_bottom = 0.5
	_subtitle.offset_left = -340.0
	_subtitle.offset_right = 340.0
	_subtitle.offset_top = 48.0
	_subtitle.offset_bottom = 92.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 22)
	_subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_subtitle.add_theme_constant_override("outline_size", 5)
	_bg.add_child(_subtitle)


func _reset_label_style() -> void:
	label.remove_theme_font_size_override("font_size")
	label.remove_theme_color_override("font_color")
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.scale = Vector2(1, 1)
