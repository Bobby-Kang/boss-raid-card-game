class_name CardData
extends Resource

# class_name 등록 순서 회피를 위한 preload (ModuleAbility 타입 힌트용)
const _ModuleAbilityType = preload("res://scripts/cards/modules/module_ability.gd")

enum CardType { ATTACK, SKILL, POWER, MODULE }

@export var card_name: String = ""
@export var cost: int = 0
@export var gold_cost: int = 0
@export var tier: int = 1
@export var description: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var artwork: Texture2D = null
@export var effects: Array[CardEffect] = []
@export var module_ability: ModuleAbility = null


func get_description_text() -> String:
	if description != "":
		return description
	if effects.is_empty():
		return ""
	var parts: PackedStringArray = []
	for effect in effects:
		var desc := effect.get_description()
		if desc != "":
			parts.append(desc)
	return ", ".join(parts) + "."
