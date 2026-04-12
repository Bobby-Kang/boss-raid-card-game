extends CanvasLayer

signal banner_finished

@onready var label: Label = $Background/BannerLabel

var _queue: Array[String] = []
var _busy: bool = false


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
