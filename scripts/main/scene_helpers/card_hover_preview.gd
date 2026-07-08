class_name CardHoverPreview
extends Node
## 카드 호버 프리뷰 — 효과 부동 라벨 + 파이프 행 호버 시 풀사이즈 카드 프리뷰.
## 효과 식별은 CardEffect.get_preview_summary() 가상 메서드 결과를 사용해
## 효과 클래스 추가/리네임에 강함.

const PREVIEW_FONT_SIZE := 22
const CARD_PREVIEW_SCALE := Vector2(1.05, 1.05)
const CARD_PREVIEW_Z := 200

# 색상 — 효과 종류별
const COLOR_DAMAGE := Color(1.0, 0.4, 0.4, 1)
const COLOR_BLOCK  := Color(0.5, 0.85, 1.0, 1)
const COLOR_DRAW   := Color(0.85, 0.85, 0.5, 1)
const COLOR_GOLD   := Color(1.0, 0.85, 0.3, 1)
const COLOR_REMOVE := Color(0.95, 0.4, 0.4, 1)

# 의존성 (setup으로 주입)
var _root: Control = null   # 라벨/카드 프리뷰의 부모
var _card_scene: PackedScene = null
var _anchor_boss_hp: Control = null
var _anchor_player_block: Control = null
var _anchor_player_hp: Control = null
var _game_ctx: GameContext = null

# 상태
var _hover_preview_labels: Array[Label] = []
var _hover_card: Control = null
var _pipe_card_preview: Control = null


func setup(p_root: Control, p_card_scene: PackedScene, p_game_ctx: GameContext,
		boss_hp_anchor: Control, player_block_anchor: Control, player_hp_anchor: Control) -> void:
	_root = p_root
	_card_scene = p_card_scene
	_game_ctx = p_game_ctx
	_anchor_boss_hp = boss_hp_anchor
	_anchor_player_block = player_block_anchor
	_anchor_player_hp = player_hp_anchor


# === 일반 카드 호버 (손패 카드의 hover_changed 시그널) ===

func on_card_hover_changed(card: Control, entered: bool) -> void:
	if entered:
		_hover_card = card
		_show_effect_preview(card)
	else:
		if _hover_card == card:
			_hover_card = null
			_clear_effect_preview()


## 카드가 *지금 상황*에서 낼 실효 수치 합산 — 호버 프리뷰와 손패 뱃지가 공유.
## 반환: {"damage": int(보스 방어 차감 후), "block": int, "draw": int, "gold": int, ...}
func compute_card_totals(card: Control) -> Dictionary:
	var totals := {}  # kind → amount
	if card == null or not card.data or card.data.effects == null:
		return totals
	for eff in card.data.effects:
		if eff == null:
			continue
		var info: Dictionary = eff.get_preview_summary()
		if info.is_empty():
			continue
		var kind: String = info.get("kind", "")
		var amount: int = info.get("amount", 0)
		# 컨텍스트 의존 효과 — 실시간 계산
		match kind:
			"block_damage":
				amount = _game_ctx.player_block if _game_ctx else 0
				kind = "damage"
			"rage_scale_damage":
				var rage: int = _rage_stacks()
				amount = int(info.get("base", 0)) + rage * int(info.get("mul", 1)) / maxi(int(info.get("div", 1)), 1)
				kind = "damage"
			"rage_scale_block":
				var rage_b: int = _rage_stacks()
				amount = int(info.get("base", 0)) + rage_b / maxi(int(info.get("div", 1)), 1)
				kind = "block"
			"execute_damage":
				var ratio: float = float(_game_ctx.boss_hp) / float(maxi(_game_ctx.boss_max_hp, 1)) if _game_ctx else 1.0
				var threshold: float = float(info.get("threshold", 0.3))
				amount = int(info.get("high", 0)) if ratio <= threshold else int(info.get("low", 0))
				kind = "damage"
			"chain_damage":
				# 미리보기: 이번 턴 사용된 공격 카드 수 기준 (이 카드 자신 제외 — 사용 *직후* 계산이라)
				var prior: int = _game_ctx.attacks_this_turn if _game_ctx else 0
				amount = int(info.get("base", 0)) + prior * int(info.get("per", 0))
				kind = "damage"
			"gold_scale_damage":
				var gold: int = _game_ctx.gold_manager.current if _game_ctx and _game_ctx.gold_manager else 0
				amount = int(info.get("base", 0)) + gold * int(info.get("mul", 1))
				kind = "damage"
			"tempered_damage":
				# 단련 — 호버 카드의 현재 단련 횟수로 보정
				var temper: int = int(card.temper) if "temper" in card else 0
				amount = int(info.get("base", 0)) + temper * int(info.get("per_temper", 0))
				kind = "damage"
			"adjacency_damage":
				# 인접 — 파이프 맨 앞이 require_type이면 보너스 포함
				var hit: bool = _game_ctx != null and _game_ctx.pipe_front_has_type(
					int(info.get("require_type", 0)), int(info.get("peek_count", 1)))
				amount = int(info.get("base", 0)) + (int(info.get("bonus", 0)) if hit else 0)
				kind = "damage"
			"adjacency_block":
				var hit_b: bool = _game_ctx != null and _game_ctx.pipe_front_has_type(
					int(info.get("require_type", 1)), int(info.get("peek_count", 1)))
				amount = int(info.get("base", 0)) + (int(info.get("bonus", 0)) if hit_b else 0)
				kind = "block"
			"tempered_block":
				var temper_b: int = int(card.temper) if "temper" in card else 0
				amount = int(info.get("base", 0)) + temper_b * int(info.get("per_temper", 0))
				kind = "block"
			"vanguard_damage":
				# 선봉 — 이 카드가 이번 손패의 첫 장으로 드로우됐으면 보너스
				var vg: bool = "vanguard" in card and card.vanguard
				amount = int(info.get("base", 0)) + (int(info.get("bonus", 0)) if vg else 0)
				kind = "damage"
			"vanguard_block":
				var vg_b: bool = "vanguard" in card and card.vanguard
				amount = int(info.get("base", 0)) + (int(info.get("bonus", 0)) if vg_b else 0)
				kind = "block"
			"foresight_damage":
				# 예지 — 보스 다음 예고가 공격이면 보너스
				var fs: bool = _game_ctx != null and _game_ctx.boss_next_card_is_attack()
				amount = int(info.get("base", 0)) + (int(info.get("bonus", 0)) if fs else 0)
				kind = "damage"
			"rage_consume":
				kind = "rage_consume"  # 별도 표시
			"negate_boss":
				kind = "negate_boss"
		if kind == "damage":
			# 보스 방어도 차감 반영
			var blocked := mini(amount, _game_ctx.boss_block) if _game_ctx else 0
			amount = maxi(0, amount - blocked)
		totals[kind] = totals.get(kind, 0) + amount
	return totals


func _show_effect_preview(card: Control) -> void:
	_clear_effect_preview()
	var totals: Dictionary = compute_card_totals(card)
	if totals.is_empty():
		return

	# 라벨 스폰
	# 보스 대상(데미지·무효)은 보스 HP 옆, 자기 대상(방어·드로우·골드 등)은 호버 카드 위에 세로로.
	var boss_i := 0
	if totals.get("damage", 0) > 0:
		_spawn_label("−%d" % totals["damage"], COLOR_DAMAGE, _pos_beside(_anchor_boss_hp, boss_i)); boss_i += 1
	if totals.get("negate_boss", 0) > 0:
		_spawn_label("🛡 보스 무효", COLOR_BLOCK, _pos_beside(_anchor_boss_hp, boss_i)); boss_i += 1

	var slot := 0
	if totals.get("block", 0) > 0:
		_spawn_label("+%d 🛡" % totals["block"], COLOR_BLOCK, _pos_above(_hover_card, slot)); slot += 1
	if totals.get("draw", 0) > 0:
		_spawn_label("+%d 드로우" % totals["draw"], COLOR_DRAW, _pos_above(_hover_card, slot)); slot += 1
	if totals.get("gold", 0) > 0:
		_spawn_label("+%d 💰" % totals["gold"], COLOR_GOLD, _pos_above(_hover_card, slot)); slot += 1
	if totals.get("remove", 0) > 0 or totals.get("exile", 0) > 0:
		_spawn_label("✖ 카드 정리", COLOR_REMOVE, _pos_above(_hover_card, slot)); slot += 1
	if totals.get("rage_consume", 0) > 0:
		_spawn_label("🔥 −%d" % totals["rage_consume"], Color(1.0, 0.55, 0.15, 1), _pos_above(_hover_card, slot)); slot += 1


# 게임 컨텍스트 통한 투기 스택 조회 — 직업 의존 안 함
func _rage_stacks() -> int:
	if _game_ctx and _game_ctx.rage_system:
		return _game_ctx.rage_system.stacks
	return 0


# 앵커(보스 HP 등) 오른쪽 위치 — i는 세로 슬롯
func _pos_beside(anchor: Control, i: int = 0) -> Vector2:
	if anchor == null or _root == null:
		return Vector2.ZERO
	var r := anchor.get_global_rect()
	return r.position - _root.global_position + Vector2(r.size.x + 8, -6 + i * 26)


# 호버 카드 위쪽 위치 — slot은 위로 쌓이는 세로 슬롯
func _pos_above(card: Control, slot: int = 0) -> Vector2:
	if card == null or _root == null:
		return Vector2.ZERO
	var r := card.get_global_rect()
	return r.position - _root.global_position + Vector2(r.size.x * 0.5 - 30, -34 - slot * 28)


func _spawn_label(text: String, color: Color, local_pos: Vector2) -> void:
	if _root == null or local_pos == Vector2.ZERO:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", PREVIEW_FONT_SIZE)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 100
	_root.add_child(lbl)
	lbl.position = local_pos
	# 살짝 떠오르는 모션
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 6, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_preview_labels.append(lbl)


func _clear_effect_preview() -> void:
	for lbl in _hover_preview_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_hover_preview_labels.clear()


# === 파이프 행 호버 — 풀사이즈 카드 프리뷰 + 효과 라벨 ===

func on_pipe_row_hover(card: Control, anchor: Control, entered: bool) -> void:
	on_card_hover_changed(card, entered)
	if entered:
		_spawn_pipe_card_preview(card, anchor)
	else:
		clear_pipe_card_preview()


func _spawn_pipe_card_preview(card: Control, anchor: Control) -> void:
	clear_pipe_card_preview()
	if card == null or card.data == null or _card_scene == null or _root == null:
		return
	var preview: Control = _card_scene.instantiate()
	preview.data = card.data
	preview.is_face_up = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.scale = CARD_PREVIEW_SCALE
	preview.z_index = CARD_PREVIEW_Z
	_root.add_child(preview)
	if anchor != null:
		var anchor_rect := anchor.get_global_rect()
		var card_size := preview.custom_minimum_size * preview.scale
		var target_pos := anchor_rect.position \
			+ Vector2(anchor_rect.size.x + 12, -card_size.y * 0.5 + anchor_rect.size.y * 0.5) \
			- _root.global_position
		var viewport_size := _root.get_viewport_rect().size
		if target_pos.x + card_size.x > viewport_size.x - 8:
			target_pos.x = anchor_rect.position.x - card_size.x - 12 - _root.global_position.x
		if target_pos.y < 8:
			target_pos.y = 8
		preview.position = target_pos
	preview.modulate.a = 0.0
	var start_y := preview.position.y + 8.0
	preview.position.y = start_y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(preview, "modulate:a", 1.0, 0.12)
	tween.tween_property(preview, "position:y", start_y - 8.0, 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_pipe_card_preview = preview


func clear_pipe_card_preview() -> void:
	if is_instance_valid(_pipe_card_preview):
		_pipe_card_preview.queue_free()
	_pipe_card_preview = null
