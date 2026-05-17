class_name RageScaleDamageEffect
extends CardEffect

## 투기 스택 누적에 비례하여 보스에게 피해.
## 실제 피해 = base_damage + (투기 × multiplier)
## multiplier는 정수 (1, 2 등). 0.5 같은 값이 필요하면 base_damage 식으로 표현 (rage/2 = stacks * 1 / 2 인데 정수 처리).
##
## .tres 인스펙터에서 base_damage / multiplier 명시. value 필드는 사용 안 함.

@export var base_damage: int = 0
@export var multiplier: int = 1
@export var divisor: int = 1  # divisor=2면 (base + stacks/2)


func execute(ctx: GameContext) -> void:
	var rage: int = ctx.rage_system.stacks if ctx.rage_system else 0
	var scaled: int = rage * multiplier / maxi(divisor, 1)
	var total: int = base_damage + scaled
	ctx.deal_damage_to_boss(total)


func get_description() -> String:
	if divisor > 1:
		return "보스 (%d + 투기/%d) 피해" % [base_damage, divisor]
	if multiplier > 1:
		return "보스 (%d + 투기×%d) 피해" % [base_damage, multiplier]
	return "보스 (%d + 투기) 피해" % base_damage


func get_preview_summary() -> Dictionary:
	# 동적 계산 마커 — 호버 시 main_scene이 보정
	return {"target": "boss", "kind": "rage_scale_damage", "amount": -1,
		"base": base_damage, "mul": multiplier, "div": divisor}
