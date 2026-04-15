class_name CounterStanceAbility
extends ModuleAbility

## 전사 전용 모듈 — 반격 태세.
## 보스 턴 종료 시 플레이어 방어도가 1 이상 남아있으면 보스에게 2 피해.


func on_boss_turn_end(ctx: GameContext) -> void:
	if ctx.player_block >= 1:
		ctx.deal_damage_to_boss(2)
