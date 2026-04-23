class_name ApManager
extends Node

signal ap_changed(current: int, max_value: int)

## 최대 AP는 scripts/data/game_balance.gd → GameBalance.AP_MAX 에서 수정하세요.

var current: int = 0


func add(amount: int) -> void:
	current = mini(current + amount, GameBalance.AP_MAX)
	ap_changed.emit(current, GameBalance.AP_MAX)


func spend(amount: int) -> bool:
	if current < amount:
		return false
	current -= amount
	ap_changed.emit(current, GameBalance.AP_MAX)
	return true


func has(amount: int) -> bool:
	return current >= amount


func reset() -> void:
	current = 0
	ap_changed.emit(current, GameBalance.AP_MAX)


func set_to(value: int) -> void:
	current = clampi(value, 0, GameBalance.AP_MAX)
	ap_changed.emit(current, GameBalance.AP_MAX)
