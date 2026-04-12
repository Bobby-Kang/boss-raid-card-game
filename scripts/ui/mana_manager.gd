class_name ManaManager
extends Node

signal mana_changed(current: int, max_value: int)

const MAX_MANA := 10

var current: int = 0


func add(amount: int) -> void:
	current = mini(current + amount, MAX_MANA)
	mana_changed.emit(current, MAX_MANA)


func spend(amount: int) -> bool:
	if current < amount:
		return false
	current -= amount
	mana_changed.emit(current, MAX_MANA)
	return true


func has(amount: int) -> bool:
	return current >= amount


func reset() -> void:
	current = 0
	mana_changed.emit(current, MAX_MANA)


func set_to(value: int) -> void:
	current = clampi(value, 0, MAX_MANA)
	mana_changed.emit(current, MAX_MANA)
