class_name AdjacencyDamageEffect
extends CardEffect

## 인접 시너지 — 파이프 맨 앞(다음에 올) 카드가 특정 타입이면 추가 피해.
## 기본 피해 value + (조건 충족 시 bonus_damage).
##
## .tres: value = 기본 피해, bonus_damage = 추가 피해,
##        require_type = 0:ATTACK / 1:SKILL / 2:POWER / 3:MODULE (CardData.CardType)
##        peek_count = 파이프 앞 몇 장까지 볼지 (기본 1)

@export var bonus_damage: int = 4
@export var require_type: int = 0   # CardData.CardType.ATTACK
@export var peek_count: int = 1


func execute(ctx: GameContext) -> void:
	var total: int = value
	if ctx.pipe_front_has_type(require_type, peek_count):
		total += bonus_damage
	ctx.deal_damage_to_boss(total)


func get_description() -> String:
	return "보스에게 %d 피해 (파이프 다음이 %s면 +%d)" % [value, _type_name(), bonus_damage]


func get_preview_summary() -> Dictionary:
	return {"target": "boss", "kind": "adjacency_damage", "amount": -1,
		"base": value, "bonus": bonus_damage, "require_type": require_type, "peek_count": peek_count}


func _type_name() -> String:
	match require_type:
		0: return "공격"
		1: return "스킬"
		2: return "파워"
		3: return "모듈"
	return "?"
