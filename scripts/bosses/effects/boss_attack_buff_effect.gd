class_name BossAttackBuffEffect
extends CardEffect

## 보스 공격력 영구 +N (분노의 포효).
func execute(ctx: GameContext) -> void:
	ctx.boss_attack_bonus += value

func get_description() -> String:
	return "보스 공격력 +%d 영구" % value
