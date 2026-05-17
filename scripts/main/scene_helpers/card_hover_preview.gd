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


func _show_effect_preview(card: Control) -> void:
	_clear_effect_preview()
	if not card.data or card.data.effects == null:
		return
	# 합산 — 같은 종류 효과는 합쳐서 표시
	var totals := {}  # kind → amount
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
			"rage_consume":
				kind = "rage_consume"  # 별도 표시
			"negate_boss":
				kind = "negate_boss"
		if kind == "damage":
			# 보스 방어도 차감 반영
			var blocked := mini(amount, _game_ctx.boss_block) if _game_ctx else 0
			amount = maxi(0, amount - blocked)
		totals[kind] = totals.get(kind, 0) + amount

	# 라벨 스폰
	if totals.get("damage", 0) > 0:
		_spawn_label("−%d" % totals["damage"], COLOR_DAMAGE, _anchor_boss_hp)
	if totals.get("block", 0) > 0:
		_spawn_label("+%d 🛡" % totals["block"], COLOR_BLOCK, _anchor_player_block)
	if totals.get("draw", 0) > 0:
		_spawn_label("+%d 드로우" % totals["draw"], COLOR_DRAW, _anchor_player_hp)
	if totals.get("gold", 0) > 0:
		_spawn_label("+%d 💰" % totals["gold"], COLOR_GOLD, _anchor_player_hp)
	if totals.get("remove", 0) > 0 or totals.get("exile", 0) > 0:
		_spawn_label("✖ 카드 정리", COLOR_REMOVE, _anchor_player_hp)
	if totals.get("rage_consume", 0) > 0:
		_spawn_label("🔥 −%d" % totals["rage_consume"], Color(1.0, 0.55, 0.15, 1), _anchor_player_hp)
	if totals.get("negate_boss", 0) > 0:
		_spawn_label("🛡 보스 무효", COLOR_BLOCK, _anchor_boss_hp)


# 게임 컨텍스트 통한 투기 스택 조회 — 직업 의존 안 함
func _rage_stacks() -> int:
	if _game_ctx and _game_ctx.rage_system:
		return _game_ctx.rage_system.stacks
	return 0


func _spawn_label(text: String, color: Color, anchor: Control) -> void:
	if anchor == null or _root == null:
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
	var anchor_rect := anchor.get_global_rect()
	lbl.global_position = anchor_rect.position + Vector2(anchor_rect.size.x + 8, -6)
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
