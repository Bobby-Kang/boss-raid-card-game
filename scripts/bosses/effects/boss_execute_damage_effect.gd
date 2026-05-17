class_name BossExecuteDamageEffect
extends CardEffect

## 플레이어 HP 임계 이하 시 처형 (피의 추격).
## value 미사용. low/high/threshold export.

@export var hp_threshold: float = 0.3
@export var low_damage: int = 5
@export var high_damage: int = 15


func execute(ctx: GameContext) -> void:
	var ratio: float = float(ctx.player_hp) / float(maxi(ctx.player_max_hp, 1))
	var base: int = high_damage if ratio <= hp_threshold else low_damage
	ctx.deal_damage_to_player(ctx.get_boss_attack_modifier(base))


func get_description() -> String:
	return "플레이어 HP %d%% 이하 → %d 피해, 아니면 %d 피해" % [
		int(hp_threshold * 100), high_damage, low_damage
	]
