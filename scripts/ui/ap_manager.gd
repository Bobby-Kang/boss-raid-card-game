class_name ApManager
extends Node

signal ap_changed(current: int, max_value: int)

const MAX_AP := 3

var current: int = 0


func add(amount: int) -> void:
	current = mini(current + amount, MAX_AP)
	ap_changed.emit(current, MAX_AP)


func spend(amount: int) -> bool:
	if current < amount:
		return false
	current -= amount
	ap_changed.emit(current, MAX_AP)
	return true


func has(amount: int) -> bool:
	return current >= amount


func reset() -> void:
	current = 0
	ap_changed.emit(current, MAX_AP)


func set_to(value: int) -> void:
	current = clampi(value, 0, MAX_AP)
	ap_changed.emit(current, MAX_AP)
