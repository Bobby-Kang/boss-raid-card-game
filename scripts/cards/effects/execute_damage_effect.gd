class_name ExecuteDamageEffect
extends CardEffect

## 보스 HP가 hp_threshold(0.0~1.0) 이하일 때 high_damage, 아니면 low_damage.

@export var hp_threshold: float = 0.3
@export var low_damage: int = 8
@export var high_damage: int = 25


func execute(ctx: GameContext) -> void:
	var ratio: float = float(ctx.boss_hp) / float(maxi(ctx.boss_max_hp, 1))
	var dmg: int = high_damage if ratio <= hp_threshold else low_damage
	ctx.deal_damage_to_boss(dmg)


func get_description() -> String:
	return "보스 HP %d%% 이하 → %d 피해, 아니면 %d 피해" % [
		int(hp_threshold * 100), high_damage, low_damage
	]


func get_preview_summary() -> Dictionary:
	return {"target": "boss", "kind": "execute_damage", "amount": -1,
		"low": low_damage, "high": high_damage, "threshold": hp_threshold}
