class_name TemperedBlockEffect
extends CardEffect

## 단련 🔨 — 파이프를 돌수록 단단해지는 방어.
## 실제 방어 = value + (단련 횟수 × per_temper)

@export var per_temper: int = 2


func execute(ctx: GameContext) -> void:
	var temper: int = ctx.get_acting_card_temper()
	ctx.add_block(value + temper * per_temper)


func get_description() -> String:
	return "방어 +%d (단련 1회당 +%d)" % [value, per_temper]


func get_preview_summary() -> Dictionary:
	return {"target": "player", "kind": "tempered_block", "amount": -1,
		"base": value, "per_temper": per_temper}
