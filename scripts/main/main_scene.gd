extends Control

const CardScene := preload("res://scenes/cards/card.tscn")
const DRAW_COUNT := 5
const TURNS_PER_ROUND := 5

# 카드 종류 (공용 스타터 4종)
const CARD_GOLD := preload("res://resources/cards/starter_gold.tres")
const CARD_ATTACK := preload("res://resources/cards/starter_attack.tres")
const CARD_BLOCK := preload("res://resources/cards/starter_block.tres")
const CARD_DRAW := preload("res://resources/cards/starter_draw.tres")

# 전사 전용 모듈
const MODULE_COUNTER_STANCE := preload("res://resources/cards/warrior/module_counter_stance.tres")

# 버그베어 보스 카드덱 (Phase별 티어 블록)
const BUGBEAR_PHASE1: Array = [
	preload("res://resources/bosses/bugbear/phase1/bugbear_scratch.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_scratch_2.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_growl.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_crouch.tres"),
	preload("res://resources/bosses/bugbear/phase1/bugbear_toxic_claw.tres"),
]
const BUGBEAR_PHASE2: Array = [
	preload("res://resources/bosses/bugbear/phase2/bugbear_heavy_strike.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_rage_roar.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_iron_wall.tres"),
	preload("res://resources/bosses/bugbear/phase2/bugbear_combo_scratch.tres"),
]
const BUGBEAR_PHASE3: Array = [
	preload("res://resources/bosses/bugbear/phase3/bugbear_frenzy.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_crush.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_despair_roar.tres"),
	preload("res://resources/bosses/bugbear/phase3/bugbear_last_stand.tres"),
]

# Rage UI
const RAGE_COLOR := Color(1.0, 0.55, 0.15, 1.0)
const RAGE_EMPTY_COLOR := Color(0.35, 0.35, 0.35, 1.0)
const RAGE_ORB_SIZE := 12

# Phase UI
const PHASE_COLORS := {
	1: Color(1, 1, 1, 1),
	2: Color(0.5, 0.7, 1.0, 1),
	3: Color(1.0, 0.4, 0.4, 1),
}

const STARTER_DECK: Array = [
	CARD_GOLD, CARD_GOLD, CARD_GOLD, CARD_ATTACK, CARD_BLOCK,
	CARD_GOLD, CARD_GOLD, CARD_ATTACK, CARD_BLOCK, CARD_DRAW
]

# 손패 존
@onready var hand_belt: HBoxContainer = %HandBelt
# 타임라인 파이프
@onready var pipe_queue: VBoxContainer = %PipeQueue
@onready var queue_card_holder: Control = %QueueCardHolder

@onready var resource_bar: PanelContainer = %ResourceBar
@onready var hp_label: Label = %HpLabel
@onready var block_label: Label = %BlockLabel
@onready var boss_hp_label: Label = %BossHpLabel
@onready var boss_block_label: Label = %BossBlockLabel
@onready var end_turn_button: Button = %EndTurnButton
@onready var end_turn_overlay: CanvasLayer = %EndTurnOverlay
@onready var phase_banner: CanvasLayer = %PhaseBanner
@onready var game_result_screen: CanvasLayer = %GameResultScreen
@onready var round_label: Label = %RoundLabel
@onready var phase_label: Label = %PhaseLabel
@onready var turn_slots_container: HBoxContainer = %TurnSlotsContainer

# 드롭 존
@onready var play_drop_zone: PanelContainer = %PlayDropZone
@onready var timeline_pipe_panel: PanelContainer = %TimelinePipePanel
@onready var active_slot_1: PanelContainer = %ActiveSlot1
@onready var active_slot_2: PanelContainer = %ActiveSlot2

# Rage UI (전사 투기 발산)
@onready var rage_label: Label = %RageLabel
@onready var rage_orbs: HBoxContainer = %RageOrbs
@onready var rage_button: Button = %RageButton

# 마켓 (MarketPanel — class_name 등록 race 회피 위해 PanelContainer로 타이핑)
@onready var market_panel: PanelContainer = %MarketPanel

# 보스 카드 UI
@onready var boss_deck_count_label: Label = %BossDeckCountLabel
@onready var boss_discard_label: Label = %BossDiscardLabel
@onready var boss_current_card_label: Label = %BossCurrentCardLabel
@onready var boss_power_zone: VBoxContainer = %BossPowerZone

# 카드 배열
var hand_cards: Array[Control] = []    # 손패 (최대 5장, 사용 가능)
var queue_cards: Array[Control] = []   # 타임라인 파이프 (대기 중)

var game_ctx: GameContext
var rage_system: WarriorRageSystem
var phase_system: BossPhaseSystem
var boss_deck_system: BossDeckSystem
var is_discarding_from_effect: bool = false
var game_over: bool = false

# 액티브 슬롯
var active_cards: Array[Control] = [null, null]

# 라운드/턴
var current_round: int = 1
var current_turn: int = 0
var turn_order: Array[String] = []
var turn_slot_labels: Array[Label] = []


func _ready() -> void:
	_setup_game_context()
	_setup_drop_zones()
	_init_starter_deck()
	resource_bar.gold_manager.set_to(0)
	resource_bar.ap_manager.set_to(3)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	end_turn_overlay.order_confirmed.connect(_on_end_turn_order_confirmed)
	end_turn_overlay.cancelled.connect(_on_end_turn_cancelled)


# === 게임 컨텍스트 ===

func _setup_game_context() -> void:
	game_ctx = GameContext.new()
	game_ctx.gold_manager = resource_bar.gold_manager
	game_ctx.ap_manager = resource_bar.ap_manager
	game_ctx.draw_cards = _draw_extra_cards
	game_ctx.discard_cards = _discard_cards_with_selection
	game_ctx.player_hp_changed.connect(_on_player_hp_changed)
	game_ctx.player_block_changed.connect(_on_player_block_changed)
	game_ctx.boss_hp_changed.connect(_on_boss_hp_changed)
	game_ctx.boss_block_changed.connect(_on_boss_block_changed)
	_on_player_hp_changed(game_ctx.player_hp, game_ctx.player_max_hp)
	_on_player_block_changed(game_ctx.player_block)
	_on_boss_hp_changed(game_ctx.boss_hp, game_ctx.boss_max_hp)
	_on_boss_block_changed(game_ctx.boss_block)

	# 전사 전용 — 투기 발산 시스템
	rage_system = WarriorRageSystem.new(game_ctx)
	rage_system.rage_changed.connect(_on_rage_changed)
	_create_rage_orbs(WarriorRageSystem.MAX_RAGE)
	rage_button.pressed.connect(_on_rage_button_pressed)
	_on_rage_changed(rage_system.stacks, WarriorRageSystem.MAX_RAGE)

	# 라운드 마켓
	market_panel.setup(resource_bar.ap_manager, resource_bar.gold_manager)
	market_panel.card_purchased.connect(_on_market_card_purchased)
	market_panel.set_player_turn(false)

	# 보스 페이즈 시스템 (HP/라운드 트리거 → 마켓 티어 매칭)
	phase_system = BossPhaseSystem.new(game_ctx)
	phase_system.phase_changed.connect(_on_phase_changed)
	_apply_phase_label(phase_system.current_phase)

	# 보스 덱 시스템 (에이언즈 엔드 방식 — 티어 블록 FIFO, 파워 카운트다운)
	boss_deck_system = BossDeckSystem.new(game_ctx)
	boss_deck_system.deck_changed.connect(_on_boss_deck_changed)
	boss_deck_system.power_zone_updated.connect(_on_boss_power_zone_updated)
	boss_deck_system.card_discarded.connect(_on_boss_card_discarded)
	boss_deck_system.setup(BUGBEAR_PHASE1, BUGBEAR_PHASE2, BUGBEAR_PHASE3)
	_on_boss_deck_changed(boss_deck_system.get_remaining_count())
	_on_boss_power_zone_updated([])


func _on_player_hp_changed(current: int, max_hp: int) -> void:
	hp_label.text = "HP %d/%d" % [current, max_hp]
	if current <= 0 and not game_over:
		_trigger_game_over(false)

func _on_player_block_changed(block: int) -> void:
	block_label.text = "방어력 %d" % block

func _on_boss_hp_changed(current: int, max_hp: int) -> void:
	boss_hp_label.text = "보스 체력\nHP %d/%d" % [current, max_hp]
	if phase_system:
		phase_system.check_hp_trigger()
	if current <= 0 and not game_over:
		_trigger_game_over(true)

func _on_boss_block_changed(block: int) -> void:
	boss_block_label.text = "보스 상태\n방어력 %d" % block


# === 드롭 존 설정 ===

func _setup_drop_zones() -> void:
	play_drop_zone.accept_filter = _can_accept_card
	timeline_pipe_panel.accept_filter = _can_accept_card
	active_slot_1.accept_filter = _can_accept_card
	active_slot_2.accept_filter = _can_accept_card

	play_drop_zone.card_dropped.connect(_on_play_zone_dropped)
	timeline_pipe_panel.card_dropped.connect(_on_pipe_dropped)
	active_slot_1.card_dropped.connect(_on_active_slot_1_dropped)
	active_slot_2.card_dropped.connect(_on_active_slot_2_dropped)


func _can_accept_card(card: Control, zone_type: DropZone.ZoneType) -> bool:
	# 손패에 있는 카드만 허용
	if card not in hand_cards:
		return false
	var is_module: bool = card.data.card_type == CardData.CardType.MODULE
	match zone_type:
		DropZone.ZoneType.PLAY:
			# 모듈은 사용 불가 (장착 전용)
			return not is_module
		DropZone.ZoneType.DISCARD:
			# 모듈은 파이프로 버릴 수 없음 (장착 전용)
			return not is_module
		DropZone.ZoneType.ACTIVE:
			return is_module
	return false


func _on_play_zone_dropped(card: Control) -> void:
	_play_card(card)


func _on_pipe_dropped(card: Control) -> void:
	# 손패 → 파이프 맨 뒤 (효과 없이 버리기)
	_send_to_pipe_back(card)


func _on_active_slot_1_dropped(card: Control) -> void:
	_equip_module(card, 0)


func _on_active_slot_2_dropped(card: Control) -> void:
	_equip_module(card, 1)


func _equip_module(card: Control, slot_index: int) -> void:
	var slot: PanelContainer = active_slot_1 if slot_index == 0 else active_slot_2
	if active_cards[slot_index] != null:
		var old := active_cards[slot_index]
		old.reparent(hand_belt)
		hand_cards.append(old)
		_update_hand_display()
	active_cards[slot_index] = card
	hand_cards.erase(card)
	card.reparent(slot)
	card.position = Vector2.ZERO
	_update_hand_display()


# === 덱 초기화 ===

func _init_starter_deck() -> void:
	_clear_cards()
	for card_data: CardData in STARTER_DECK:
		var card: Control = CardScene.instantiate()
		card.data = card_data.duplicate()
		card.is_face_up = true
		queue_card_holder.add_child(card)
		queue_cards.append(card)
	_rebuild_pipe_ui()
	_equip_warrior_modules()
	_start_round()


func _equip_warrior_modules() -> void:
	# 반격 태세를 액티브 슬롯 1에 기본 장착 (파이프/손패와 별개)
	var card: Control = CardScene.instantiate()
	card.data = MODULE_COUNTER_STANCE.duplicate()
	card.is_face_up = true
	active_slot_1.add_child(card)
	card.position = Vector2.ZERO
	active_cards[0] = card
	card.set_active(false)


# === 손패 드로우 ===

func _draw_hand() -> void:
	# 파이프 앞에서 DRAW_COUNT장 꺼내 손패로
	var count := mini(DRAW_COUNT, queue_cards.size())
	for i in count:
		var card: Control = queue_cards.pop_front()
		card.reparent(hand_belt)
		card.set_active(true)
		hand_cards.append(card)
	_update_hand_display()
	_rebuild_pipe_ui()


func _draw_extra_cards(count: int) -> void:
	# 효과에 의한 추가 드로우
	var actual := mini(count, queue_cards.size())
	for i in actual:
		var card: Control = queue_cards.pop_front()
		card.reparent(hand_belt)
		card.set_active(true)
		hand_cards.append(card)
	_update_hand_display()
	_rebuild_pipe_ui()


func _start_player_turn() -> void:
	end_turn_button.disabled = false
	_draw_hand()


# === 파이프로 보내기 ===

func _send_to_pipe_back(card: Control) -> void:
	hand_cards.erase(card)
	card.set_active(false)
	card.reparent(queue_card_holder)
	queue_cards.append(card)
	_update_hand_display()
	_rebuild_pipe_ui()


# === 손패 UI 갱신 ===

func _update_hand_display() -> void:
	if hand_cards.is_empty():
		return
	var spacing := hand_cards[0].custom_minimum_size.x + 8
	for i in hand_cards.size():
		var card: Control = hand_cards[i]
		var tween := create_tween()
		tween.tween_property(card, "position", Vector2(i * spacing, 0), 0.18)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# === 파이프 UI 재빌드 ===

func _rebuild_pipe_ui() -> void:
	# 기존 UI 행 제거
	for child in pipe_queue.get_children():
		child.queue_free()

	# 큐 카드마다 행 생성
	for i in queue_cards.size():
		var card: Control = queue_cards[i]
		var row := _create_pipe_row(i + 1, card)
		pipe_queue.add_child(row)


func _create_pipe_row(index: int, card: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# 순서 번호
	var num_label := Label.new()
	num_label.text = str(index)
	num_label.custom_minimum_size = Vector2(18, 0)
	num_label.add_theme_font_size_override("font_size", 16)
	num_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(num_label)

	# 미니 카드 패널
	var mini := PanelContainer.new()
	mini.custom_minimum_size = Vector2(0, 28)
	mini.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.20, 0.18, 0.9)
	style.border_color = Color(0.55, 0.45, 0.3, 1)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	mini.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var cost_lbl := Label.new()
	cost_lbl.text = "[%d]" % card.data.cost
	cost_lbl.add_theme_font_size_override("font_size", 15)
	cost_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4, 1))
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(cost_lbl)

	var name_lbl := Label.new()
	name_lbl.text = card.data.card_name
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	mini.add_child(hbox)
	row.add_child(mini)
	return row


# === 버리기 선택 (이펙트용) ===

func _discard_cards_with_selection(count: int) -> void:
	if hand_cards.is_empty():
		return
	is_discarding_from_effect = true
	var actual := mini(count, hand_cards.size())
	end_turn_overlay.show_overlay_select(hand_cards.duplicate(), actual)
	var ordered: Array[Control] = await end_turn_overlay.order_confirmed
	for card in ordered:
		_send_to_pipe_back(card)
	is_discarding_from_effect = false


# === 카드 사용 ===

func _play_card(card: Control) -> void:
	if not card.data:
		return
	var cost: int = card.data.cost
	if not resource_bar.ap_manager.has(cost):
		return
	resource_bar.ap_manager.spend(cost)
	_send_to_pipe_back(card)
	for effect in card.data.effects:
		effect.execute(game_ctx)


# === 라운드/턴 시스템 ===

func _start_round() -> void:
	_build_turn_order()
	_update_round_label()
	_update_turn_order_ui()
	current_turn = 0
	if market_panel:
		market_panel.refresh_slots()
	_advance_turn()


func _build_turn_order() -> void:
	turn_order.clear()
	turn_order = ["player", "player", "boss", "boss"]
	for _attempt in range(100):
		turn_order.shuffle()
		if _validate_turn_order():
			break


func _validate_turn_order() -> bool:
	var full_order: Array[String] = ["player"]
	full_order.append_array(turn_order)
	var consecutive_boss := 0
	for who in full_order:
		if who == "boss":
			consecutive_boss += 1
			if consecutive_boss > 2:
				return false
		else:
			consecutive_boss = 0
	return true


func _advance_turn() -> void:
	if game_over:
		return
	current_turn += 1
	if current_turn > TURNS_PER_ROUND:
		# 라운드 종료 — 방어도 리셋
		game_ctx.reset_block()
		current_round += 1
		_start_round()
		return
	_update_turn_order_ui()
	if current_turn == 1:
		_begin_player_turn()
	else:
		var who: String = turn_order[current_turn - 2]
		if who == "player":
			_begin_player_turn()
		else:
			_begin_boss_turn()


func _begin_player_turn() -> void:
	resource_bar.ap_manager.set_to(3)

	var messages: Array[String] = ["플레이어 차례입니다"]
	phase_banner.show_sequence(messages)
	await phase_banner.banner_finished
	if market_panel:
		market_panel.set_player_turn(true)
	_start_player_turn()


func _begin_boss_turn() -> void:
	if market_panel:
		market_panel.set_player_turn(false)

	# 1. 파워 카운트다운 틱 (0이 된 파워 카드 즉시 발동)
	var triggered: Array[BossCardData] = boss_deck_system.tick_powers()

	# 2. 다음 카드 드로우
	var drawn: BossCardData = boss_deck_system.draw_next()

	# 3. 배너 메시지 구성
	var messages: Array[String] = ["보스 차례입니다"]
	for card in triggered:
		messages.append("💥 %s 발동!" % card.card_name)
		messages.append(card.description)
	if drawn:
		messages.append(drawn.get_intent_text())
		if drawn.card_type == BossCardData.BossCardType.POWER:
			messages.append("⏳ 파워 존에 배치됩니다")

	phase_banner.show_sequence(messages)
	await phase_banner.banner_finished

	# 4. 카드 실행 + 현재 카드 UI 업데이트
	if drawn:
		boss_current_card_label.text = drawn.get_intent_text()
		boss_deck_system.play_card(drawn)
	else:
		boss_current_card_label.text = "—"

	# 5. 장착된 모듈의 보스 턴 종료 훅 실행
	for card in active_cards:
		if card and card.data and card.data.module_ability:
			card.data.module_ability.on_boss_turn_end(game_ctx)
	_advance_turn()


# === 보스 덱 UI 핸들러 ===

func _on_boss_deck_changed(_remaining: int) -> void:
	var names := boss_deck_system.get_remaining_names_sorted()
	if names.is_empty():
		boss_deck_count_label.text = "덱 (0장)\n—"
		return
	var lines: PackedStringArray = ["덱 (%d장)" % names.size()]
	for name in names:
		lines.append("· " + name)
	boss_deck_count_label.text = "\n".join(lines)

func _on_boss_card_discarded(_card: BossCardData) -> void:
	boss_discard_label.text = "버린 카드\n%d장" % boss_deck_system.get_discard_count()

func _on_boss_power_zone_updated(active_powers: Array) -> void:
	for child in boss_power_zone.get_children():
		child.queue_free()
	if active_powers.is_empty():
		var lbl := Label.new()
		lbl.text = "—"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_power_zone.add_child(lbl)
	else:
		for entry in active_powers:
			var lbl := Label.new()
			lbl.text = "⏳ %s  (%d턴 후)" % [entry.card.card_name, entry.tokens]
			lbl.add_theme_color_override("font_color", Color(1, 0.7, 0.2, 1))
			lbl.add_theme_font_size_override("font_size", 15)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			boss_power_zone.add_child(lbl)


# === 턴 오더 UI ===

func _update_round_label() -> void:
	round_label.text = "라운드 %d" % current_round


func _update_turn_order_ui() -> void:
	if turn_slot_labels.is_empty():
		for i in range(TURNS_PER_ROUND):
			var slot := PanelContainer.new()
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var lbl := Label.new()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 13)
			slot.add_child(lbl)
			turn_slots_container.add_child(slot)
			turn_slot_labels.append(lbl)

	for i in range(TURNS_PER_ROUND):
		var lbl := turn_slot_labels[i]
		var slot: PanelContainer = lbl.get_parent()
		var turn_num := i + 1

		if turn_num == 1:
			lbl.text = "T1\n플레이어"
			lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
		elif turn_num <= current_turn:
			var who: String = turn_order[i - 1]
			lbl.text = "T%d\n%s" % [turn_num, "플레이어" if who == "player" else "보스"]
			lbl.add_theme_color_override("font_color",
				Color(0.3, 0.5, 1.0) if who == "player" else Color(0.9, 0.25, 0.25))
		else:
			lbl.text = "T%d\n???" % turn_num
			lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		if turn_num == current_turn:
			slot.modulate = Color(1, 1, 1, 1)
		elif turn_num < current_turn:
			slot.modulate = Color(1, 1, 1, 0.4)
		else:
			slot.modulate = Color(1, 1, 1, 0.7)


# === 턴 종료 ===

func _on_end_turn_pressed() -> void:
	if hand_cards.is_empty():
		_finish_turn()
		return
	end_turn_button.disabled = true
	end_turn_overlay.show_overlay(hand_cards.duplicate())


func _on_end_turn_order_confirmed(ordered_cards: Array[Control]) -> void:
	if is_discarding_from_effect:
		return
	for card in ordered_cards:
		_send_to_pipe_back(card)
	end_turn_button.disabled = false
	_finish_turn()


func _on_end_turn_cancelled() -> void:
	end_turn_button.disabled = false


func _finish_turn() -> void:
	# 남은 AP를 투기 스택으로 치환 (플레이어 턴 종료 시)
	rage_system.add(resource_bar.ap_manager.current)
	# 골드는 턴 종료 시 증발, 방어도는 라운드 종료까지 유지
	resource_bar.gold_manager.reset()
	end_turn_button.disabled = true
	if market_panel:
		market_panel.set_player_turn(false)
	_advance_turn()


# === 정리 ===

func _clear_cards() -> void:
	for card in hand_cards:
		card.queue_free()
	for card in queue_cards:
		card.queue_free()
	hand_cards.clear()
	queue_cards.clear()
	_rebuild_pipe_ui()


# === 투기 발산 UI (전사 전용) ===

func _create_rage_orbs(count: int) -> void:
	for child in rage_orbs.get_children():
		child.queue_free()
	for i in range(count):
		var orb := ColorRect.new()
		orb.custom_minimum_size = Vector2(RAGE_ORB_SIZE, RAGE_ORB_SIZE)
		orb.color = RAGE_EMPTY_COLOR
		rage_orbs.add_child(orb)


func _on_rage_changed(stacks: int, max_stacks: int) -> void:
	rage_label.text = "투기 %d/%d" % [stacks, max_stacks]
	var orbs := rage_orbs.get_children()
	for i in range(orbs.size()):
		orbs[i].color = RAGE_COLOR if i < stacks else RAGE_EMPTY_COLOR
	rage_button.disabled = stacks < max_stacks


# === 마켓 ===

func _on_market_card_purchased(card_data: CardData) -> void:
	# 구매한 카드는 파이프 맨 뒤에 추가됨
	var card: Control = CardScene.instantiate()
	card.data = card_data.duplicate()
	card.is_face_up = true
	queue_card_holder.add_child(card)
	card.set_active(false)
	queue_cards.append(card)
	_rebuild_pipe_ui()


func _on_rage_button_pressed() -> void:
	# 플레이어 턴일 때만 발동 가능 (턴 종료 버튼이 활성 상태 == 플레이어 턴)
	if end_turn_button.disabled:
		return
	if not rage_system.can_consume():
		return
	rage_system.consume()


# === 보스 페이즈 ===

func _on_phase_changed(new_phase: int, _old_phase: int) -> void:
	if market_panel:
		market_panel.set_phase(new_phase)
	_apply_phase_label(new_phase)
	if phase_banner:
		var messages: Array[String] = ["페이즈 %d 진입!" % new_phase]
		phase_banner.show_sequence(messages)


func _apply_phase_label(phase: int) -> void:
	if not phase_label:
		return
	phase_label.text = "페이즈 %d" % phase
	var color: Color = PHASE_COLORS.get(phase, Color.WHITE)
	phase_label.add_theme_color_override("font_color", color)


# === 게임 종료 ===

func _trigger_game_over(is_win: bool) -> void:
	game_over = true
	# 모든 입력 차단
	end_turn_button.disabled = true
	if market_panel:
		market_panel.set_player_turn(false)
	# 결과 화면 표시 (배너가 재생 중이라면 잠깐 기다렸다가)
	if phase_banner and phase_banner.visible:
		await phase_banner.banner_finished
	game_result_screen.show_result(is_win)
