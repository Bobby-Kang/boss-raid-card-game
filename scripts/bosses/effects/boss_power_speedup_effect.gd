class_name BossPowerSpeedupEffect
extends CardEffect

## 야수의 외침 — 현재 활성 POWER 카드 카운트 모두 -1 (0 도달 시 즉시 발동).
## boss_deck_system 참조가 필요해 ctx에 등록되어 있어야 함.
## value 미사용.

func execute(ctx: GameContext) -> void:
	if ctx.boss_deck_system == null:
		return
	ctx.boss_deck_system.accelerate_all_powers()


func get_description() -> String:
	return "모든 활성 POWER 카운트 -1"
