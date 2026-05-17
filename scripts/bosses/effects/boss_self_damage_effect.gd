class_name BossSelfDamageEffect
extends CardEffect

## 보스 자해 — HP -N (광란 등). 방어도 무시.
func execute(ctx: GameContext) -> void:
	ctx.boss_hp = maxi(ctx.boss_hp - value, 0)
	ctx.boss_hp_changed.emit(ctx.boss_hp, ctx.boss_max_hp)

func get_description() -> String:
	return "보스 자해 %d" % value
