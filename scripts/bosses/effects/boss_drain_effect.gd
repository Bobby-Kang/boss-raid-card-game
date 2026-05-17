class_name BossDrainEffect
extends CardEffect

## 보스 흡혈 — 플레이어 피해 N + 보스 HP +N (위협 카드).
func execute(ctx: GameContext) -> void:
	ctx.deal_damage_to_player(value)
	ctx.boss_hp = mini(ctx.boss_hp + value, ctx.boss_max_hp)
	ctx.boss_hp_changed.emit(ctx.boss_hp, ctx.boss_max_hp)

func get_description() -> String:
	return "플레이어 %d 피해 + 보스 %d 회복 (흡혈)" % [value, value]
