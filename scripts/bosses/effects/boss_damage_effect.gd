class_name BossDamageEffect
extends CardEffect

# 플레이어에게 피해를 입힌다 (보스 카드 전용)
func execute(ctx: GameContext) -> void:
	ctx.deal_damage_to_player(value)

func get_description() -> String:
	return "플레이어에게 %d 피해" % value
