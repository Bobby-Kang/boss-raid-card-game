class_name ConsumeRageEffect
extends CardEffect

## 투기 스택을 N(value) 소비한다.
## 같은 카드의 후속 효과는 이 효과가 성공한 경우에만 실행되어야 하지만,
## 현재 효과 체인은 무조건 실행되므로 — 부족하면 *사일런트 페일*하고 가능한 만큼만 소비.
## (밸런스 관점: 후속 피해 카드는 투기 부족 시에도 기본 효과는 발휘)

func execute(ctx: GameContext) -> void:
	if ctx.rage_system == null:
		return
	var amount: int = mini(value, ctx.rage_system.stacks)
	if amount > 0:
		ctx.rage_system.spend(amount)


func get_description() -> String:
	return "투기 %d 소비" % value


func get_preview_summary() -> Dictionary:
	return {"target": "self", "kind": "rage_consume", "amount": value}
