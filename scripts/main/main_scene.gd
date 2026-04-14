extends Control

const CardScene := preload("res://scenes/cards/card.tscn")
const DRAW_COUNT := 5
const TURNS_PER_ROUND := 5
const ACTIVE_WINDOW_SIZE := 5

# 카드 종류 (4종)
const CARD_GOLD := preload("res://resources/cards/starter_gold.tres")
const CARD_ATTACK := preload("res://resources/cards/starter_attack.tres")
const CARD_BLOCK := preload("res://resources/cards/starter_block.tres")
const CARD_DRAW := preload("res://resources/cards/starter_draw.tres")

# 덱 구성
const STARTER_DECK: Array = [
	CARD_DRAW, CARD_BLOCK, CARD_BLOCK, CARD_GOLD, CARD_GOLD, CARD_ATTACK, CARD_ATTACK, CARD_GOLD, CARD_GOLD, CARD_GOLD
]

@onready var timeline_belt: HBoxContainer = %TimelineBelt
@onready var resource_bar: PanelContainer = %ResourceBar
@onready var hp_label: Label = %HpLabel
@onready var block_label: Label = %BlockLabel
@onready var boss_hp_label: Label = %BossHpLabel
@onready var boss_block_label: Label = %BossBlockLabel
@onready var end_turn_button: Button = %EndTurnButton
@onready var end_turn_overlay: CanvasLayer = %EndTurnOverlay
@onready var phase_banner: CanvasLayer = %PhaseBanner
@onready var round_label: Label = %RoundLabel
@onready var turn_slots_container: HBoxContainer = %TurnSlotsContainer

# 드롭 존
@onready var play_drop_zone: PanelContainer = %PlayDropZone
@onready var timeline_wrapper: PanelContainer = %TimelineWrapper
@onready var reserve_slot: PanelContainer = %ReserveSlot
@onready var active_slot_1: PanelContainer = %ActiveSlot1
@onready var active_slot_2: PanelContainer = %ActiveSlot2

# 타임라인 — 단일 원형 큐
var timeline_cards: Array[Control] = []
var game_ctx: GameContext
var is_discarding_from_effect: bool = false

# 예비/액티브 슬롯
var reserved_card: Control = null
var active_cards: Array[Control] = [null, null]

# 라운드/턴 시스템
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
	game_ctx.draw_cards = _draw_cards_from_effect
	game_ctx.discard_cards = _discard_cards_with_selection
	game_ctx.player_hp_changed.connect(_on_player_hp_changed)
	game_ctx.player_block_changed.connect(_on_player_block_changed)
	game_ctx.boss_hp_changed.connect(_on_boss_hp_changed)
	game_ctx.boss_block_changed.connect(_on_boss_block_changed)
	_on_player_hp_changed(game_ctx.player_hp, game_ctx.player_max_hp)
	_on_player_block_changed(game_ctx.player_block)
	_on_boss_hp_changed(game_ctx.boss_hp, game_ctx.boss_max_hp)
	_on_boss_block_changed(game_ctx.boss_block)


func _on_player_hp_changed(current: int, max_hp: int) -> void:
	hp_label.text = "HP %d/%d" % [current, max_hp]

func _on_player_block_changed(block: int) -> void:
	block_label.text = "방어력 %d" % block

func _on_boss_hp_changed(current: int, max_hp: int) -> void:
	boss_hp_label.text = "보스 체력\nHP %d/%d" % [current, max_hp]

func _on_boss_block_changed(block: int) -> void:
	boss_block_label.text = "보스 상태\n방어력 %d" % block


# === 드롭 존 설정 ===

func _setup_drop_zones() -> void:
	play_drop_zone.accept_filter = _can_accept_card
	timeline_wrapper.accept_filter = _can_accept_card
	reserve_slot.accept_filter = _can_accept_card
	active_slot_1.accept_filter = _can_accept_card
	active_slot_2.accept_filter = _can_accept_card

	play_drop_zone.card_dropped.connect(_on_play_zone_dropped)
	timeline_wrapper.card_dropped.connect(_on_discard_zone_dropped)
	reserve_slot.card_dropped.connect(_on_reserve_dropped)
	active_slot_1.card_dropped.connect(_on_active_slot_1_dropped)
	active_slot_2.card_dropped.connect(_on_active_slot_2_dropped)


func _can_accept_card(card: Control, zone_type: DropZone.ZoneType) -> bool:
	var idx := timeline_cards.find(card)
	# 액티브 윈도우(앞 5장)에 있는 카드만 허용
	if idx < 0 or idx >= ACTIVE_WINDOW_SIZE:
		return false
	match zone_type:
		DropZone.ZoneType.PLAY:
			return true
		DropZone.ZoneType.DISCARD:
			return true
		DropZone.ZoneType.RESERVE:
			if reserved_card != null:
				return false
			for effect in card.data.effects:
				if effect is GainGoldEffect:
					return true
			return false
		DropZone.ZoneType.ACTIVE:
			return card.data.card_type == CardData.CardType.MODULE
	return false


func _on_play_zone_dropped(card: Control) -> void:
	_play_card(card)


func _on_discard_zone_dropped(card: Control) -> void:
	_move_card_to_queue_back(card)


func _on_reserve_dropped(card: Control) -> void:
	if reserved_card != null:
		return
	reserved_card = card
	timeline_cards.erase(card)
	card.reparent(reserve_slot)
	card.position = Vector2.ZERO
	_update_timeline_display()


func _on_active_slot_1_dropped(card: Control) -> void:
	_equip_module(card, 0)


func _on_active_slot_2_dropped(card: Control) -> void:
	_equip_module(card, 1)


func _equip_module(card: Control, slot_index: int) -> void:
	var slot: PanelContainer = active_slot_1 if slot_index == 0 else active_slot_2
	if active_cards[slot_index] != null:
		var old := active_cards[slot_index]
		old.reparent(timeline_belt)
		timeline_cards.insert(0, old)
		_update_timeline_display()
	active_cards[slot_index] = card
	timeline_cards.erase(card)
	card.reparent(slot)
	card.position = Vector2.ZERO
	_update_timeline_display()


# === 덱 초기화 ===

func _build_cards_from(deck_def: Array) -> Array[Control]:
	var cards: Array[Control] = []
	for card_data: CardData in deck_def:
		var card: Control = CardScene.instantiate()
		card.data = card_data.duplicate()
		card.is_face_up = true
		cards.append(card)
	return cards


func _init_starter_deck() -> void:
	_clear_cards()
	var all_cards := _build_cards_from(STARTER_DECK)
	for card in all_cards:
		timeline_belt.add_child(card)
		timeline_cards.append(card)
	_update_timeline_display()
	_start_round()


# === 타임라인 큐 ===

func _move_card_to_queue_back(card: Control) -> void:
	timeline_cards.erase(card)
	timeline_cards.append(card)
	card.reparent(timeline_belt)
	_update_timeline_display()


func _update_timeline_display() -> void:
	for i in timeline_cards.size():
		var card: Control = timeline_cards[i]
		timeline_belt.move_child(card, i)
		card.set_active(i < ACTIVE_WINDOW_SIZE)


func _activate_window() -> void:
	_update_timeline_display()


# === 라운드/턴 시스템 ===

func _start_round() -> void:
	_build_turn_order()
	_update_round_label()
	_update_turn_order_ui()
	current_turn = 0
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
	current_turn += 1
	if current_turn > TURNS_PER_ROUND:
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

	# 예비 슬롯 카드를 타임라인 맨 앞에 복귀
	if reserved_card != null:
		reserved_card.reparent(timeline_belt)
		timeline_cards.insert(0, reserved_card)
		reserved_card = null

	_activate_window()

	var messages: Array[String] = ["플레이어 차례입니다"]
	phase_banner.show_sequence(messages)
	await phase_banner.banner_finished
	_start_player_turn()


func _begin_boss_turn() -> void:
	var messages: Array[String] = [
		"보스 차례입니다",
		"플레이어에게 5 피해를 입힙니다",
	]
	phase_banner.show_sequence(messages)
	await phase_banner.banner_finished
	game_ctx.deal_damage_to_player(5)
	_advance_turn()


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
			lbl.add_theme_font_size_override("font_size", 10)
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
			if who == "player":
				lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
			else:
				lbl.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25))
		else:
			lbl.text = "T%d\n???" % turn_num
			lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		if turn_num == current_turn:
			slot.modulate = Color(1, 1, 1, 1)
		elif turn_num < current_turn:
			slot.modulate = Color(1, 1, 1, 0.4)
		else:
			slot.modulate = Color(1, 1, 1, 0.7)


# === 드로우 (효과용) ===

func _draw_cards_from_effect(count: int) -> void:
	# 타임라인에서 비활성 카드를 앞으로 당겨 활성화
	# (큐에서 카드를 앞으로 이동 — 실질적으로 즉시 사용 가능하게)
	var activated := 0
	for i in range(timeline_cards.size() - 1, -1, -1):
		if activated >= count:
			break
		if i >= ACTIVE_WINDOW_SIZE:
			var card: Control = timeline_cards[i]
			timeline_cards.erase(card)
			timeline_cards.insert(0, card)
			activated += 1
	_update_timeline_display()


func _start_player_turn(_count: int = DRAW_COUNT) -> void:
	end_turn_button.disabled = false
	_activate_window()


# === 버리기 선택 (이펙트용) ===

func _discard_cards_with_selection(count: int) -> void:
	var active: Array[Control] = []
	for i in min(ACTIVE_WINDOW_SIZE, timeline_cards.size()):
		active.append(timeline_cards[i])
	if active.is_empty():
		return
	is_discarding_from_effect = true
	var actual := mini(count, active.size())
	end_turn_overlay.show_overlay_select(active, actual)
	var ordered: Array[Control] = await end_turn_overlay.order_confirmed
	for card in ordered:
		_move_card_to_queue_back(card)
	is_discarding_from_effect = false


# === 카드 사용 ===

func _play_card(card: Control) -> void:
	if not card.data:
		return

	var cost: int = card.data.cost
	if not resource_bar.ap_manager.has(cost):
		return

	resource_bar.ap_manager.spend(cost)
	_move_card_to_queue_back(card)

	for effect in card.data.effects:
		effect.execute(game_ctx)


# === 턴 종료 ===

func _on_end_turn_pressed() -> void:
	# 미사용 액티브 카드 수집
	var remaining: Array[Control] = []
	for i in min(ACTIVE_WINDOW_SIZE, timeline_cards.size()):
		remaining.append(timeline_cards[i])

	if remaining.is_empty():
		_finish_turn()
		return
	end_turn_button.disabled = true
	end_turn_overlay.show_overlay(remaining)


func _on_end_turn_order_confirmed(ordered_cards: Array[Control]) -> void:
	if is_discarding_from_effect:
		return
	for card in ordered_cards:
		_move_card_to_queue_back(card)
	end_turn_button.disabled = false
	_finish_turn()


func _on_end_turn_cancelled() -> void:
	end_turn_button.disabled = false


func _finish_turn() -> void:
	game_ctx.reset_block()
	resource_bar.gold_manager.reset()
	end_turn_button.disabled = true
	_advance_turn()


# === 정리 ===

func _clear_cards() -> void:
	for card in timeline_cards:
		card.queue_free()
	timeline_cards.clear()
