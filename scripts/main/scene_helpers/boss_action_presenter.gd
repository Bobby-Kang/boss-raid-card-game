class_name BossActionPresenter
extends Node
## 보스 턴 행동을 화면 중앙 큰 카드 연출로 표현 (텍스트 배너 대체).
## main_scene이 child로 추가하고 setup()으로 연출 대상(combat_fx, 얼굴)을 주입한다.
##
## present(card, kind, resolve_cb) — 카드가 보스 쪽에서 날아와 중앙에 제시된 뒤
## kind에 따라 슬램(공격)/흡수(파워)/차단(무효)으로 마무리. await 가능.
## resolve_cb는 임팩트 순간에 호출 → 실제 피해/효과 적용을 연출과 동기화.

enum Kind { ATTACK, POWER, TRIGGER, NEGATED }

const CARD_SIZE := Vector2(210, 294)

var _layer: CanvasLayer
var _root: Control
var _dim: ColorRect
var _holder: Control
var _header: Label

var _combat_fx: CombatFeedback = null
var _boss_face: Control = null
var _player_face: Control = null


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 12
	add_child(_layer)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	_layer.add_child(_root)

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	# 화면 중앙(0크기) 앵커 — 자식 카드/헤더는 이 원점 기준 상대 배치
	_holder = Control.new()
	_holder.anchor_left = 0.5
	_holder.anchor_top = 0.5
	_holder.anchor_right = 0.5
	_holder.anchor_bottom = 0.5
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_holder)

	_header = Label.new()
	_header.custom_minimum_size = Vector2(520, 56)
	_header.position = Vector2(-260, -CARD_SIZE.y * 0.5 - 76)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header.add_theme_font_size_override("font_size", 34)
	_header.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_header.add_theme_constant_override("outline_size", 6)
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_header)


func setup(combat_fx: CombatFeedback, boss_face: Control, player_face: Control) -> void:
	_combat_fx = combat_fx
	_boss_face = boss_face
	_player_face = player_face


# 보스 카드 1장을 연출. resolve_cb는 임팩트 시점에 1회 호출(실제 효과 적용).
func present(card: BossCardData, kind: int, resolve_cb: Callable = Callable()) -> void:
	if card == null:
		if resolve_cb.is_valid():
			resolve_cb.call()
		return

	_root.visible = true

	# 헤더 텍스트/색
	var meta: Dictionary = _meta_for(kind)
	_header.text = meta["text"]
	_header.add_theme_color_override("font_color", meta["color"])
	_header.modulate.a = 0.0

	# 카드 위젯
	var disp := BossCardDisplay.new()
	disp.setup(card, card.countdown, CARD_SIZE)
	disp.pivot_offset = CARD_SIZE / 2.0
	_holder.add_child(disp)

	var center := -CARD_SIZE / 2.0
	disp.position = center + _boss_start_offset()
	disp.scale = Vector2(0.4, 0.4)
	disp.rotation = deg_to_rad(-12)
	disp.modulate.a = 0.0

	# 딤 + 카드 등장 (보스 쪽 → 중앙)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.55, 0.25)
	tw.tween_property(disp, "position", center, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(disp, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(disp, "rotation", 0.0, 0.35)
	tw.tween_property(disp, "modulate:a", 1.0, 0.22)
	tw.tween_property(_header, "modulate:a", 1.0, 0.28)
	await tw.finished

	# 제시 유지
	await get_tree().create_timer(0.7).timeout

	# 마무리 — 종류별
	match kind:
		Kind.ATTACK, Kind.TRIGGER:
			var slam := create_tween().set_parallel(true)
			slam.tween_property(disp, "scale", Vector2(1.18, 1.18), 0.12).set_ease(Tween.EASE_IN)
			slam.tween_property(disp, "position", center + Vector2(-60, 44), 0.12).set_ease(Tween.EASE_IN)
			await slam.finished
			if resolve_cb.is_valid():
				resolve_cb.call()
			if _combat_fx:
				_combat_fx.shake_screen(9.0, 0.3)
			disp.modulate = Color(1.6, 1.2, 1.0, 1)  # 임팩트 화이트 플래시
			var hit := create_tween()
			hit.tween_property(disp, "modulate", Color.WHITE, 0.18)
			await hit.finished
		Kind.POWER:
			if resolve_cb.is_valid():
				resolve_cb.call()
			# 파워존(우측)으로 흡수되듯 축소 이동
			var pw := create_tween().set_parallel(true)
			pw.tween_property(disp, "position", center + Vector2(440, -150), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			pw.tween_property(disp, "scale", Vector2(0.3, 0.3), 0.45)
			pw.tween_property(disp, "modulate:a", 0.0, 0.45)
			await pw.finished
		Kind.NEGATED:
			# 차단 표시 — 흔들고 회색조로 사그라듦
			if _combat_fx:
				_combat_fx.flash_buff(disp, Color(0.5, 0.85, 1.4, 1))
			var ng := create_tween()
			ng.tween_property(disp, "rotation", deg_to_rad(6), 0.06)
			ng.tween_property(disp, "rotation", deg_to_rad(-6), 0.06)
			ng.tween_property(disp, "rotation", 0.0, 0.06)
			await ng.finished
			if resolve_cb.is_valid():
				resolve_cb.call()
			await get_tree().create_timer(0.25).timeout

	# 정리 (POWER는 이미 페이드됨)
	var out := create_tween().set_parallel(true)
	out.tween_property(disp, "modulate:a", 0.0, 0.25)
	out.tween_property(_dim, "color:a", 0.0, 0.28)
	out.tween_property(_header, "modulate:a", 0.0, 0.22)
	await out.finished
	disp.queue_free()
	_root.visible = false


func _meta_for(kind: int) -> Dictionary:
	match kind:
		Kind.POWER:
			return {"text": "⏳ 파워 가동", "color": Color(0.95, 0.65, 0.25, 1)}
		Kind.TRIGGER:
			return {"text": "💥 파워 발동!", "color": Color(0.98, 0.45, 0.30, 1)}
		Kind.NEGATED:
			return {"text": "🛡 행동 무효화!", "color": Color(0.55, 0.80, 1.0, 1)}
		_:
			return {"text": "⚔ 보스의 공격", "color": Color(0.90, 0.32, 0.28, 1)}


# 화면 중앙에서 보스 얼굴 중심까지의 오프셋 (카드 등장 시작점)
func _boss_start_offset() -> Vector2:
	if _boss_face == null or not is_instance_valid(_boss_face):
		return Vector2(360, -160)
	var vp: Vector2 = _boss_face.get_viewport_rect().size
	var bc: Vector2 = _boss_face.get_global_rect().get_center()
	return bc - vp / 2.0
