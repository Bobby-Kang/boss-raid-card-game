class_name VanguardBlockEffect
extends CardEffect

## 선봉 🚩 — 이 카드가 손패의 첫 장(파이프 맨 앞)으로 드로우됐다면 추가 방어.
## .tres: value = 기본 방어, bonus_block = 선봉 보너스

@export var bonus_block: int = 5


func execute(ctx: GameContext) -> void:
	var total: int = value
	if ctx.is_acting_card_vanguard():
		total += bonus_block
	ctx.add_block(total)


func get_description() -> String:
	return "방어 +%d (🚩선봉이면 +%d)" % [value, bonus_block]


func get_preview_summary() -> Dictionary:
	return {"target": "player", "kind": "vanguard_block", "amount": -1,
		"base": value, "bonus": bonus_block}
