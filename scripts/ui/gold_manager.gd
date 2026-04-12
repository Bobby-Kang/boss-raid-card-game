class_name GoldManager
extends Node

signal gold_changed(current: int, max_value: int)

const MAX_GOLD := 10

var current: int = 0


func add(amount: int) -> void:
	current = mini(current + amount, MAX_GOLD)
	gold_changed.emit(current, MAX_GOLD)


func spend(amount: int) -> bool:
	if current < amount:
		return false
	current -= amount
	gold_changed.emit(current, MAX_GOLD)
	return true


func has(amount: int) -> bool:
	return current >= amount


func reset() -> void:
	current = 0
	gold_changed.emit(current, MAX_GOLD)


func set_to(value: int) -> void:
	current = clampi(value, 0, MAX_GOLD)
	gold_changed.emit(current, MAX_GOLD)
