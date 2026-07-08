class_name BreakPowerEffect
extends CardEffect

## 파워 브레이커 — 카운트 2 이상인 활성 POWER 1장을 발동 없이 파괴.
## 임박한(카운트 1) 파워는 못 부순다 — 예고를 보고 미리 대응해야 한다.

func execute(ctx: GameContext) -> void:
	if ctx.boss_deck_system:
		ctx.boss_deck_system.break_ready_power(2)


func get_description() -> String:
	return "카운트 2+ POWER 1장 파괴"
