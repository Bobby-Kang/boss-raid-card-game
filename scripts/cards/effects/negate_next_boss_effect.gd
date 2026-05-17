class_name NegateNextBossEffect
extends CardEffect

## 다음 보스 행동 1회 무효화 플래그 설정.
## 보스 턴 시작 시 GameContext.negate_next_boss_action을 확인해 카드 효과를 스킵.

func execute(ctx: GameContext) -> void:
	ctx.negate_next_boss_action = true


func get_description() -> String:
	return "다음 보스 행동 1회 무효"


func get_preview_summary() -> Dictionary:
	return {"target": "self", "kind": "negate_boss", "amount": 1}
