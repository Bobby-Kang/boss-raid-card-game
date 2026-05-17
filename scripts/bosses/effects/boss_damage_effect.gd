class_name BossDamageEffect
extends CardEffect

# 플레이어에게 피해를 입힌다 (보스 카드 전용)
# 보스 공격력 보너스 (분노의 포효) + 피 냄새 보정 자동 적용.
func execute(ctx: GameContext) -> void:
	var final_damage: int = ctx.get_boss_attack_modifier(value)
	ctx.deal_damage_to_player(final_damage)

func get_description() -> String:
	return "플레이어에게 %d 피해" % value
