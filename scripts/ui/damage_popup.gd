class_name DamagePopup
extends Label

# 피해/회복 숫자가 떠오르다 사라지는 팝업 레이블
# 사용: DamagePopup.spawn(parent, position, amount, is_heal)

static func spawn(parent: Control, pos: Vector2, amount: int, is_heal: bool = false) -> void:
	var popup := DamagePopup.new()
	parent.add_child(popup)
	popup._play(pos, amount, is_heal)


func _play(pos: Vector2, amount: int, is_heal: bool) -> void:
	# 텍스트·스타일
	text = ("+%d" if is_heal else "-%d") % amount
	add_theme_font_size_override("font_size", 36)
	add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.45, 1) if is_heal else Color(1.0, 0.28, 0.28, 1))

	# 외곽선 (가독성)
	add_theme_constant_override("outline_size", 4)
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))

	# 초기 위치 (중앙 정렬 보정은 Tween 시작 후)
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = pos

	var tween := create_tween()
	tween.set_parallel(true)
	# 위로 떠오름
	tween.tween_property(self, "position:y", pos.y - 72, 0.9) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 살짝 옆으로 흔들 (피해만)
	if not is_heal:
		tween.tween_property(self, "position:x", pos.x + randf_range(-12, 12), 0.15) \
			.set_ease(Tween.EASE_OUT)
	# 0.4초 후 페이드 아웃
	tween.tween_property(self, "modulate:a", 0.0, 0.5) \
		.set_ease(Tween.EASE_IN).set_delay(0.4)
	# 완료 후 제거
	tween.chain().tween_callback(queue_free)
