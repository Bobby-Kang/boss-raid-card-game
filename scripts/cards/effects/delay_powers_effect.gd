class_name DelayPowersEffect
extends CardEffect

## 시간의 족쇄 — 모든 활성 POWER 카운트 +value (발동 지연).
## 보스 *야수의 외침*(전체 -1)의 플레이어 측 미러.

func execute(ctx: GameContext) -> void:
	if ctx.boss_deck_system:
		ctx.boss_deck_system.delay_all_powers(maxi(value, 1))


func get_description() -> String:
	return "모든 활성 POWER 카운트 +%d" % maxi(value, 1)
