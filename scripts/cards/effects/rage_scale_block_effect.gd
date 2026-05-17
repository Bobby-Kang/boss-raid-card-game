class_name RageScaleBlockEffect
extends CardEffect

## 투기 스택 누적에 비례하여 방어도 부여.
## 실제 방어 = base_block + (투기 / divisor)

@export var base_block: int = 0
@export var divisor: int = 2  # 기본: 투기/2


func execute(ctx: GameContext) -> void:
	var rage: int = ctx.rage_system.stacks if ctx.rage_system else 0
	var scaled: int = rage / maxi(divisor, 1)
	ctx.add_block(base_block + scaled)


func get_description() -> String:
	return "방어도 (%d + 투기/%d) 획득" % [base_block, divisor]


func get_preview_summary() -> Dictionary:
	return {"target": "player", "kind": "rage_scale_block", "amount": -1,
		"base": base_block, "div": divisor}
