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
var _deck_system: BossDeckSystem = null


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


func setup(combat_fx: CombatFeedback, boss_face: Control, player_face: Control, deck_system: BossDeckSystem = null) -> void:
	_combat_fx = combat_fx
	_boss_face = boss_face
	_player_face = player_face
	_deck_system = deck_system


# 보스 덱이 main_scene._setup_helpers 이후 생성되므로 별도 주입 시점 제공
func set_deck_system(deck_system: BossDeckSystem) -> void:
	_deck_system = deck_system


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
	var phase: int = _deck_system.get_phase_of(card) if _deck_system else 0
	disp.setup(card, card.countdown, CARD_SIZE, phase)
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
			_play_card_signature_fx(card)   # 카드별 시그니처 VFX (자체 셰이크/플래시 포함)
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


# =========================================================================
# 카드별 시그니처 VFX — 임팩트 순간 카드 고유 연출.
# 카드명 → [아키타입, 강조색]. 미등록 카드는 기본 impact.
# =========================================================================
const CARD_FX := {
	# Phase 1
	"할퀴기":       ["slash",  Color(0.95, 0.40, 0.32)],
	"맹독 발톱":     ["poison", Color(0.55, 0.90, 0.35)],
	"위협":         ["roar",   Color(0.95, 0.30, 0.30)],
	"으르렁":       ["roar",   Color(0.90, 0.45, 0.30)],
	"웅크리기":     ["shield", Color(0.50, 0.75, 1.00)],
	"사냥의 시작":   ["charge", Color(0.85, 0.70, 0.35)],
	# Phase 2
	"연속 할퀴기":   ["slash",  Color(0.98, 0.45, 0.40)],
	"잔혹한 일격":   ["impact", Color(0.95, 0.20, 0.25)],
	"강타":         ["impact", Color(1.00, 0.55, 0.20)],
	"강철 벽":       ["shield", Color(0.60, 0.70, 0.95)],
	"분노의 포효":   ["roar",   Color(1.00, 0.40, 0.25)],
	"야수의 외침":   ["roar",   Color(0.95, 0.75, 0.30)],
	# Phase 3
	"피의 추격":     ["charge", Color(0.95, 0.15, 0.20)],
	"분쇄":         ["impact", Color(0.85, 0.15, 0.15)],
	"절망의 포효":   ["frenzy", Color(0.80, 0.20, 0.50)],
	"광란":         ["frenzy", Color(1.00, 0.30, 0.20)],
	"최후의 발악":   ["frenzy", Color(0.90, 0.10, 0.10)],
	"광기의 돌진":   ["charge", Color(1.00, 0.35, 0.15)],
}


func _play_card_signature_fx(card: BossCardData) -> void:
	if card == null:
		return
	var entry: Array = CARD_FX.get(card.card_name, ["impact", Color(0.90, 0.32, 0.28)])
	match String(entry[0]):
		"slash":  _fx_slash(entry[1])
		"impact": _fx_impact(entry[1])
		"roar":   _fx_roar(entry[1])
		"poison": _fx_poison(entry[1])
		"shield": _fx_shield(entry[1])
		"charge": _fx_charge(entry[1])
		"frenzy": _fx_frenzy(entry[1])
		_:        _fx_impact(entry[1])


# --- FX 프리미티브 -------------------------------------------------------

# 화면 중앙(_holder 원점)에서 퍼지는(또는 조여드는) 원형 링. end_scale<1이면 수축.
func _spawn_ring(color: Color, start_size: float, end_scale: float, dur: float, width: int) -> void:
	var ring := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(width)
	sb.border_color = color
	sb.set_corner_radius_all(int(start_size))   # 자동으로 절반까지 캡 → 원형
	ring.add_theme_stylebox_override("panel", sb)
	ring.size = Vector2(start_size, start_size)
	ring.position = -Vector2(start_size, start_size) * 0.5
	ring.pivot_offset = Vector2(start_size, start_size) * 0.5
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(end_scale, end_scale), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(ring.queue_free)


# 대각선/수평 섬광 선 (발톱·돌진). offset 은 _holder 원점 기준 중심.
func _spawn_streak(color: Color, angle_deg: float, offset: Vector2, length: float, thick: float, delay: float) -> void:
	var line := ColorRect.new()
	line.color = color
	line.size = Vector2(length, thick)
	line.position = offset - Vector2(length, thick) * 0.5
	line.pivot_offset = Vector2(length, thick) * 0.5
	line.rotation = deg_to_rad(angle_deg)
	line.modulate.a = 0.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(line)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(line, "modulate:a", 1.0, 0.05)
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)


# --- 아키타입 ------------------------------------------------------------

func _fx_slash(color: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(color, 0.16, 0.28)
		_combat_fx.shake_screen(9.0, 0.28)
	var white := Color(1.0, 0.95, 0.9)
	_spawn_streak(white, -32, Vector2(-30, -22), 260, 5, 0.00)
	_spawn_streak(color, -27, Vector2(6, 6),     240, 4, 0.05)
	_spawn_streak(white, -36, Vector2(42, 38),   220, 5, 0.10)


func _fx_impact(color: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(color, 0.28, 0.4)
		_combat_fx.shake_screen(15.0, 0.4)
		_combat_fx.hit_stop()
	_spawn_ring(Color(1.0, 0.95, 0.85), 70, 5.0, 0.4, 6)
	_spawn_ring(color, 50, 6.5, 0.5, 4)


func _fx_roar(color: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(color, 0.22, 0.45)
		_combat_fx.shake_screen(12.0, 0.4)
	_spawn_ring(color, 80, 6.0, 0.55, 5)
	_spawn_ring(color.lightened(0.3), 60, 5.0, 0.45, 3)


func _fx_poison(color: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(color, 0.20, 0.5)
		_combat_fx.shake_screen(6.0, 0.25)
	_spawn_ring(color, 90, 4.0, 0.6, 10)              # 두껍고 느린 독무
	_spawn_ring(color.lightened(0.2), 60, 3.0, 0.5, 8)


func _fx_shield(color: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(color, 0.16, 0.35)
		_combat_fx.shake_screen(5.0, 0.2)
	_spawn_ring(color, 260, 0.35, 0.45, 5)            # 큰 링이 조여드는 방어막
	_spawn_ring(color.lightened(0.25), 200, 0.4, 0.4, 3)


func _fx_charge(color: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(color, 0.22, 0.35)
		_combat_fx.shake_screen(13.0, 0.35)
	_spawn_streak(Color(1.0, 0.95, 0.9), 0, Vector2(-40, -12), 360, 7, 0.00)
	_spawn_streak(color, 0, Vector2(-20, 18), 330, 5, 0.06)


func _fx_frenzy(color: Color) -> void:
	if _combat_fx:
		_combat_fx.shake_screen(16.0, 0.5)
	for i in 3:
		var c: Color = color if i % 2 == 0 else color.lightened(0.4)
		var t := get_tree().create_timer(0.12 * float(i))
		t.timeout.connect(_frenzy_burst.bind(c))


func _frenzy_burst(c: Color) -> void:
	if _combat_fx:
		_combat_fx.screen_flash(c, 0.20, 0.2)
	_spawn_ring(c, 60, 4.5, 0.35, 4)
