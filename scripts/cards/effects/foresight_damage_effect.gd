class_name ForesightDamageEffect
extends CardEffect

## 예지의 일격 — 보스의 다음 예고 카드가 ATTACK이면 추가 피해.
## 보스 타임라인을 "읽는" 공격 (내 파이프 인접의 보스 쪽 미러).
## .tres: value = 기본 피해, bonus_damage = 예지 보너스

@export var bonus_damage: int = 6


func execute(ctx: GameContext) -> void:
	var total: int = value
	if ctx.boss_next_card_is_attack():
		total += bonus_damage
	ctx.deal_damage_to_boss(total)


func get_description() -> String:
	return "보스에게 %d 피해 (보스 다음이 공격이면 +%d)" % [value, bonus_damage]


func get_preview_summary() -> Dictionary:
	return {"target": "boss", "kind": "foresight_damage", "amount": -1,
		"base": value, "bonus": bonus_damage}
