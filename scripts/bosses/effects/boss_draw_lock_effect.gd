class_name BossDrawLockEffect
extends CardEffect

## 플레이어에게 드로우 봉인 N 부여 — 다음 플레이어 턴 드로우 -N (1회성, 사용 후 0 리셋).

func execute(ctx: GameContext) -> void:
	ctx.apply_draw_lock(value)

func get_description() -> String:
	return "드로우 봉인 %d" % value
