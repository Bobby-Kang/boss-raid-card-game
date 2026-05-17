class_name BossPercentDamageEffect
extends CardEffect

## 플레이어 현재 HP의 N% 피해 (최후의 발악 대안). value = 백분율 (예: 50 = 50%).
## 피 냄새 / 공격력 보너스는 적용 안 함 (이미 비례 피해라서).

func execute(ctx: GameContext) -> void:
	var damage: int = ctx.player_hp * value / 100
	ctx.deal_damage_to_player(damage)

func get_description() -> String:
	return "플레이어 현재 HP의 %d%% 피해" % value
