extends Control

const CardScene := preload("res://scenes/cards/card.tscn")
const DRAW_COUNT := 5  # 기본 드로우 수 (추후 6~7 등 확장 가능)

# 카드 종류 (4종)
const CARD_GOLD := preload("res://resources/cards/starter_gold.tres")
const CARD_ATTACK := preload("res://resources/cards/starter_attack.tres")
const CARD_BLOCK := preload("res://resources/cards/starter_block.tres")
const CARD_SWAP := preload("res://resources/cards/starter_swap.tres")

# 덱 구성: [리소스, 수량]
const FIRST_HAND: Array = [
	[CARD_GOLD, 3], [CARD_ATTACK, 1], [CARD_BLOCK, 1]
]
const SECOND_HAND: Array = [
	[CARD_GOLD, 2], [CARD_ATTACK, 1], [CARD_BLOCK, 1], [CARD_SWAP, 1]
]

@onready var discard_holder: Control = %DiscardCardHolder
@onready var deck_holder: Control = %DeckCardHolder
@onready var draw_pile_holder: Control = %DrawPileCardHolder
@onready var discard_label: Label = %DiscardLabel
@onready var deck_label: Label = %DeckLabel
@onready var draw_pile_label: Label = %DrawPileLabel
@onready var resource_bar: PanelContainer = %ResourceBar
@onready var hp_label: Label = %HpLabel
@onready var block_label: Label = %BlockLabel
@onready var boss_hp_label: Label = %BossHpLabel
@onready var boss_block_label: Label = %BossBlockLabel
@onready var end_turn_button: Button = %EndTurnButton
@onready var end_turn_overlay: CanvasLayer = %EndTurnOverlay
@onready var phase_banner: CanvasLayer = %PhaseBanner

var discard_cards: Array[Control] = []
var deck_cards: Array[Control] = []       # 손패 (카드덱 영역에 펼쳐진 카드)
var draw_pile_cards: Array[Control] = []  # 뽑을 카드 더미
var game_ctx: GameContext


func _ready() -> void:
	_setup_game_context()
	_init_starter_deck()
	resource_bar.gold_manager.set_to(0)
	resource_bar.mana_manager.set_to(3)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	end_turn_overlay.order_confirmed.connect(_on_end_turn_order_confirmed)
	end_turn_overlay.cancelled.connect(_on_end_turn_cancelled)


# === 게임 컨텍스트 ===

func _setup_game_context() -> void:
	game_ctx = GameContext.new()
	game_ctx.gold_manager = resource_bar.gold_manager
	game_ctx.mana_manager = resource_bar.mana_manager
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


# === 덱 초기화 ===

func _build_cards_from(hand_def: Array) -> Array[Control]:
	var cards: Array[Control] = []
	for entry in hand_def:
		var card_data: CardData = entry[0]
		var count: int = entry[1]
		for i in range(count):
			var card: Control = CardScene.instantiate()
			card.data = card_data.duplicate()
			card.is_face_up = false
			cards.append(card)
	return cards


func _init_starter_deck() -> void:
	_clear_cards()

	# 뽑을 카드 더미에 넣기 (pop_back으로 뽑으므로, 나중에 넣은 게 먼저 뽑힘)
	var second := _build_cards_from(SECOND_HAND)
	var first := _build_cards_from(FIRST_HAND)
	for card in second:
		_add_to_draw_pile(card)
	for card in first:
		_add_to_draw_pile(card)

	_update_draw_pile_label()

	# 게임 시작: 첫 "플레이어 차례입니다" 배너 → 드로우
	_show_banner_then_draw(["플레이어 차례입니다"])


# === 뽑을 카드 더미 ===

func _add_to_draw_pile(card: Control) -> void:
	card.is_face_up = false
	draw_pile_holder.add_child(card)
	var idx := draw_pile_cards.size()
	card.position = Vector2(idx * 3, idx * 2)
	draw_pile_cards.append(card)


func _update_draw_pile_label() -> void:
	draw_pile_label.text = "뽑을 카드\n%d장" % draw_pile_cards.size()


func _recycle_discard_to_draw_pile() -> void:
	# 버린 카드 더미를 뒤집어서 뽑을 카드 더미로 (먼저 버린 카드가 먼저 뽑힘)
	discard_cards.reverse()
	for card in discard_cards:
		card.reparent(draw_pile_holder)
		card.flip_to_back()
		var idx := draw_pile_cards.size()
		card.position = Vector2(idx * 3, idx * 2)
		draw_pile_cards.append(card)
	discard_cards.clear()
	_update_draw_pile_label()


# === 드로우 (뽑을 카드 → 손패) ===

func _start_player_turn(count: int = DRAW_COUNT) -> void:
	end_turn_button.disabled = false

	# 뽑을 카드가 부족하면 버린 카드 재활용
	if draw_pile_cards.size() < count:
		_recycle_discard_to_draw_pile()

	# 실제 뽑을 수 있는 만큼만
	var actual_count := mini(count, draw_pile_cards.size())

	deck_label.visible = false

	for i in range(actual_count):
		# 뽑을 카드 더미 맨 위(마지막)에서 꺼냄
		var card: Control = draw_pile_cards.pop_back()
		card.reparent(deck_holder)

		var spacing := card.custom_minimum_size.x + 12
		var target_x: float = i * spacing
		card.position = Vector2(target_x + 200, 5)

		var tween := create_tween()
		tween.tween_property(card, "position", Vector2(target_x, 5), 0.3 + i * 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_callback(card.flip_to_front)

		card.card_clicked.connect(_on_deck_card_clicked)
		deck_cards.append(card)

	_update_draw_pile_label()


# === 카드 사용 ===

func _on_deck_card_clicked(card: Control) -> void:
	_play_card(card)


func _play_card(card: Control) -> void:
	if not card.data:
		return

	var cost: int = card.data.cost
	if not resource_bar.mana_manager.has(cost):
		print("[카드] 마나 부족: %d 필요, %d 보유" % [cost, resource_bar.mana_manager.current])
		return

	resource_bar.mana_manager.spend(cost)

	for effect in card.data.effects:
		effect.execute(game_ctx)

	print("[카드] '%s' 사용 | 보스 HP: %d/%d | 방어: %d" % [
		card.data.card_name, game_ctx.boss_hp, game_ctx.boss_max_hp, game_ctx.player_block
	])

	# 손패 → 버린 카드 더미
	_move_card_to_discard(card)


func _move_card_to_discard(card: Control) -> void:
	# 앞면 유지 (버린 순서를 볼 수 있도록)
	if card.card_clicked.is_connected(_on_deck_card_clicked):
		card.card_clicked.disconnect(_on_deck_card_clicked)
	deck_cards.erase(card)

	card.reparent(discard_holder)
	var idx := discard_cards.size()
	card.position = Vector2(idx * 4, idx * 3)
	discard_cards.append(card)

	if deck_cards.is_empty():
		deck_label.visible = true


# === 턴 종료 ===

func _on_end_turn_pressed() -> void:
	if deck_cards.is_empty():
		_finish_turn()
		return
	end_turn_button.disabled = true
	end_turn_overlay.show_overlay(deck_cards.duplicate())


func _on_end_turn_order_confirmed(ordered_cards: Array[Control]) -> void:
	for card in ordered_cards:
		if not card.is_face_up:
			continue
		_move_card_to_discard(card)

	end_turn_button.disabled = false
	_finish_turn()


func _on_end_turn_cancelled() -> void:
	end_turn_button.disabled = false


func _finish_turn() -> void:
	game_ctx.reset_block()
	end_turn_button.disabled = true
	_boss_turn()


# === 보스 차례 ===

func _boss_turn() -> void:
	var messages: Array[String] = [
		"보스 차례입니다",
		"플레이어에게 5 피해를 입힙니다",
	]
	phase_banner.show_sequence(messages)
	# 배너 시퀀스 끝나면 → 데미지 적용 + 플레이어 차례 시작
	await phase_banner.banner_finished
	game_ctx.deal_damage_to_player(5)
	_show_banner_then_draw(["플레이어 차례입니다"])


func _show_banner_then_draw(messages: Array[String], draw_count: int = DRAW_COUNT) -> void:
	phase_banner.show_sequence(messages)
	await phase_banner.banner_finished
	_start_player_turn(draw_count)


# === 정리 ===

func _clear_cards() -> void:
	for card in discard_cards:
		card.queue_free()
	for card in deck_cards:
		card.queue_free()
	for card in draw_pile_cards:
		card.queue_free()
	discard_cards.clear()
	deck_cards.clear()
	draw_pile_cards.clear()
