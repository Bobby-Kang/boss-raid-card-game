class_name BossHealEffect
extends CardEffect

## 보스 HP 회복 (강철 벽 발동 효과 등).
func execute(ctx: GameContext) -> void:
	ctx.boss_hp = mini(ctx.boss_hp + value, ctx.boss_max_hp)
	ctx.boss_hp_changed.emit(ctx.boss_hp, ctx.boss_max_hp)

func get_description() -> String:
	return "보스 HP %d 회복" % value
