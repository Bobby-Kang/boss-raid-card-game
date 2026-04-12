class_name CardData
extends Resource

enum CardType { ATTACK, SKILL, POWER }

@export var card_name: String = ""
@export var cost: int = 0
@export var description: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var artwork: Texture2D = null
@export var effects: Array[CardEffect] = []


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
