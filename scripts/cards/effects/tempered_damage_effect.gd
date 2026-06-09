class_name TemperedDamageEffect
extends CardEffect

## 단련 — 파이프를 돌수록 강해지는 공격.
## 실제 피해 = base_damage + (단련 횟수 × per_temper)
## 단련 횟수는 card.temper (파이프를 한 바퀴 돌 때마다 +1).
##
## .tres: value = base_damage, per_temper = 바퀴당 증가량

@export var per_temper: int = 3


func execute(ctx: GameContext) -> void:
	var temper: int = ctx.get_acting_card_temper()
	ctx.deal_damage_to_boss(value + temper * per_temper)


func get_description() -> String:
	return "보스에게 %d 피해 (단련 1회당 +%d)" % [value, per_temper]


func get_preview_summary() -> Dictionary:
	# 동적 계산 마커 — 호버 시 main_scene이 acting 카드 단련도로 보정
	return {"target": "boss", "kind": "tempered_damage", "amount": -1,
		"base": value, "per_temper": per_temper}
