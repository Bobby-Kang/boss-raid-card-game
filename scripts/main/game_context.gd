class_name GameContext
extends RefCounted

signal player_hp_changed(current: int, max_hp: int)
signal player_block_changed(block: int)
signal boss_hp_changed(current: int, max_hp: int)
signal boss_block_changed(block: int)

var gold_manager: GoldManager
var ap_manager: ApManager

# 카드 조작 Callable (main_scene에서 등록)
var draw_cards: Callable    # func(count: int) -> void
var discard_cards: Callable # func(count: int) -> void (선택 UI 포함)
var exile_cards: Callable   # func(count: int) -> void (영구 소멸, 파이프로 복귀 안 함)

var player_hp: int = 50
var player_max_hp: int = 50
var player_block: int = 0

var boss_hp: int = 100
var boss_max_hp: int = 100
var boss_block: int = 0


func deal_damage_to_boss(amount: int) -> void:
	var blocked := mini(amount, boss_block)
	boss_block -= blocked
	var remaining := amount - blocked
	boss_hp = maxi(boss_hp - remaining, 0)
	boss_block_changed.emit(boss_block)
	boss_hp_changed.emit(boss_hp, boss_max_hp)


func add_boss_block(amount: int) -> void:
	boss_block += amount
	boss_block_changed.emit(boss_block)


func reset_boss_block() -> void:
	boss_block = 0
	boss_block_changed.emit(boss_block)


func deal_damage_to_player(amount: int) -> void:
	var blocked := mini(amount, player_block)
	player_block -= blocked
	var remaining := amount - blocked
	player_hp = maxi(player_hp - remaining, 0)
	player_block_changed.emit(player_block)
	player_hp_changed.emit(player_hp, player_max_hp)


func add_block(amount: int) -> void:
	player_block += amount
	player_block_changed.emit(player_block)


func reset_block() -> void:
	player_block = 0
	player_block_changed.emit(player_block)


func heal_player(amount: int) -> void:
	player_hp = mini(player_hp + amount, player_max_hp)
	player_hp_changed.emit(player_hp, player_max_hp)
