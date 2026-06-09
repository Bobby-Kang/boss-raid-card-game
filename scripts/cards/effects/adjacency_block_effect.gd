class_name AdjacencyBlockEffect
extends CardEffect

## 인접 시너지 — 파이프 맨 앞(다음에 올) 카드가 특정 타입이면 추가 방어.
## 기본 방어 value + (조건 충족 시 bonus_block).
##
## .tres: value = 기본 방어, bonus_block = 추가 방어,
##        require_type = 0:ATTACK / 1:SKILL / 2:POWER / 3:MODULE
##        peek_count = 파이프 앞 몇 장까지 볼지 (기본 1)

@export var bonus_block: int = 3
@export var require_type: int = 1   # CardData.CardType.SKILL (방어 카드는 SKILL)
@export var peek_count: int = 1


func execute(ctx: GameContext) -> void:
	var total: int = value
	if ctx.pipe_front_has_type(require_type, peek_count):
		total += bonus_block
	ctx.add_block(total)


func get_description() -> String:
	return "방어 +%d (파이프 다음이 %s면 +%d)" % [value, _type_name(), bonus_block]


func get_preview_summary() -> Dictionary:
	return {"target": "player", "kind": "adjacency_block", "amount": -1,
		"base": value, "bonus": bonus_block, "require_type": require_type, "peek_count": peek_count}


func _type_name() -> String:
	match require_type:
		0: return "공격"
		1: return "스킬"
		2: return "파워"
		3: return "모듈"
	return "?"
