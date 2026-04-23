class_name GoldManager
extends Node

signal gold_changed(current: int, max_value: int)

## 최대 골드는 scripts/data/game_balance.gd → GameBalance.GOLD_MAX 에서 수정하세요.

var current: int = 0


func add(amount: int) -> void:
	current = mini(current + amount, GameBalance.GOLD_MAX)
	gold_changed.emit(current, GameBalance.GOLD_MAX)


func spend(amount: int) -> bool:
	if current < amount:
		return false
	current -= amount
	gold_changed.emit(current, GameBalance.GOLD_MAX)
	return true


func has(amount: int) -> bool:
	return current >= amount


func reset() -> void:
	current = 0
	gold_changed.emit(current, GameBalance.GOLD_MAX)


func set_to(value: int) -> void:
	current = clampi(value, 0, GameBalance.GOLD_MAX)
	gold_changed.emit(current, GameBalance.GOLD_MAX)
