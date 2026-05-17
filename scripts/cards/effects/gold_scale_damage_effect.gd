class_name GoldScaleDamageEffect
extends CardEffect

## 현재 보유 골드에 비례한 보스 피해 — 골드 소비 X.
## 실제 피해 = base_damage + (현재 골드 × multiplier)

@export var base_damage: int = 0
@export var multiplier: int = 1


func execute(ctx: GameContext) -> void:
	var gold: int = ctx.gold_manager.current if ctx.gold_manager else 0
	var total: int = base_damage + (gold * multiplier)
	ctx.deal_damage_to_boss(total)


func get_description() -> String:
	if base_damage > 0:
		return "보스 (%d + 보유 골드×%d) 피해" % [base_damage, multiplier]
	return "보스 보유 골드×%d 피해" % multiplier


func get_preview_summary() -> Dictionary:
	return {"target": "boss", "kind": "gold_scale_damage", "amount": -1,
		"base": base_damage, "mul": multiplier}
