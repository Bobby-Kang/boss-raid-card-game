class_name VanguardDamageEffect
extends CardEffect

## 선봉 🚩 — 이 카드가 손패의 첫 장(파이프 맨 앞)으로 드로우됐다면 추가 피해.
## 턴 종료 순서 지정으로 "미래 손패의 선두"에 세우는 플레이를 보상한다.
## .tres: value = 기본 피해, bonus_damage = 선봉 보너스

@export var bonus_damage: int = 6


func execute(ctx: GameContext) -> void:
	var total: int = value
	if ctx.is_acting_card_vanguard():
		total += bonus_damage
	ctx.deal_damage_to_boss(total)


func get_description() -> String:
	return "보스에게 %d 피해 (🚩선봉이면 +%d)" % [value, bonus_damage]


func get_preview_summary() -> Dictionary:
	return {"target": "boss", "kind": "vanguard_damage", "amount": -1,
		"base": value, "bonus": bonus_damage}
