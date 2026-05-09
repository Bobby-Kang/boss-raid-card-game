class_name ExileAnimator
extends Node
## 카드 영구 소멸 연출 — 슬라이드 → 흔들림 → 찢어짐 + 후속 안내 라벨.
## 페이즈 보상 / 마켓 각인의 의식 / 향후 강제 소멸 트리거 모두 재사용.

# 연출 파라미터
const SLIDE_DURATION := 0.45
const FOCUS_SCALE := Vector2(1.3, 1.3)
const FOCUS_TINT := Color(1.5, 0.7, 0.5, 1)
const SHAKE_TILT_DEG := 12.0
const TEAR_DURATION := 0.5
const TEAR_SCALE := Vector2(1.5, 0.04)
const NOTICE_HOLD := 0.7

var _root: Control = null   # 카드를 reparent할 부모 (보통 main_scene)


func setup(root: Control) -> void:
	_root = root


# 카드를 영구 소멸시키는 연출. 호출자가 await 가능.
# 카드는 함수 내부에서 reparent되며, 함수 종료 후 호출자가 queue_free 책임.
func play(card: Control) -> void:
	if not is_instance_valid(card) or _root == null:
		return
	var card_name: String = card.data.card_name if card.data else "카드"
	var start_global: Vector2 = card.get_global_rect().position

	# self/_root로 reparent (queue_card_holder는 invisible이라 옮겨야 보임)
	if card.get_parent() != null:
		card.reparent(_root)
	card.visible = true
	card.z_index = 250
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := _root.get_viewport_rect().size
	var card_size: Vector2 = card.custom_minimum_size if card.custom_minimum_size != Vector2.ZERO else card.size
	if card_size == Vector2.ZERO:
		card_size = Vector2(120, 170)
	card.pivot_offset = card_size * 0.5
	card.scale = Vector2(0.85, 0.85)
	card.modulate = Color.WHITE
	if start_global.length() > 0:
		card.global_position = start_global
	else:
		card.global_position = (viewport - card_size) * 0.5 + Vector2(0, 200)
	var center := (viewport - card_size) * 0.5

	AudioManager.play_sfx("card.exile", 2.0, 0.05)

	# 1. 슬라이드 + 확대 + 틴트
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(card, "position", center, SLIDE_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t1.tween_property(card, "scale", FOCUS_SCALE, SLIDE_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t1.tween_property(card, "modulate", FOCUS_TINT, SLIDE_DURATION)
	await t1.finished

	# 1.5. "✖ 영구 소멸" 부유 텍스트
	var doom_label := _spawn_doom_label(center, card_size)

	# 2. 격렬한 좌우 흔들림
	var t2 := create_tween()
	t2.tween_property(card, "rotation", deg_to_rad(SHAKE_TILT_DEG), 0.05)
	t2.tween_property(card, "rotation", deg_to_rad(-SHAKE_TILT_DEG), 0.06)
	t2.tween_property(card, "rotation", deg_to_rad(SHAKE_TILT_DEG * 0.66), 0.05)
	t2.tween_property(card, "rotation", deg_to_rad(-SHAKE_TILT_DEG * 0.5), 0.05)
	t2.tween_property(card, "rotation", 0.0, 0.04)
	await t2.finished

	# 3. 찢어짐 — scale Y 압축 + 회전 + 회색 페이드
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(card, "scale", TEAR_SCALE, TEAR_DURATION)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t3.tween_property(card, "rotation", deg_to_rad(220), TEAR_DURATION)\
		.set_ease(Tween.EASE_IN)
	t3.tween_property(card, "modulate", Color(0.5, 0.5, 0.5, 0.0), TEAR_DURATION)\
		.set_ease(Tween.EASE_IN)
	t3.tween_property(doom_label, "modulate:a", 0.0, TEAR_DURATION - 0.1)
	t3.tween_property(doom_label, "position:y", doom_label.position.y - 30, TEAR_DURATION)
	await t3.finished
	if is_instance_valid(doom_label):
		doom_label.queue_free()

	# 4. 후속 안내 라벨 ("💀 {이름}이 영원히 사라졌다")
	await _show_notice(card_name, viewport)


func _spawn_doom_label(center: Vector2, card_size: Vector2) -> Label:
	var lbl := Label.new()
	lbl.text = "✖ 영구 소멸"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 260
	_root.add_child(lbl)
	lbl.global_position = center + Vector2(card_size.x * 0.5 - 70, -36)
	lbl.modulate.a = 0.0
	create_tween().tween_property(lbl, "modulate:a", 1.0, 0.12)
	return lbl


func _show_notice(card_name: String, viewport: Vector2) -> void:
	var notice := Label.new()
	notice.text = "💀 %s 이(가) 영원히 사라졌다" % card_name
	notice.add_theme_font_size_override("font_size", 22)
	notice.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4, 1))
	notice.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	notice.add_theme_constant_override("outline_size", 5)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.z_index = 260
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(notice)
	notice.size = Vector2(viewport.x, 40)
	notice.global_position = Vector2(0, viewport.y * 0.5 - 20)
	notice.modulate.a = 0.0
	var nt := create_tween()
	nt.tween_property(notice, "modulate:a", 1.0, 0.18)
	nt.tween_interval(NOTICE_HOLD)
	nt.tween_property(notice, "modulate:a", 0.0, 0.25)
	await nt.finished
	notice.queue_free()
