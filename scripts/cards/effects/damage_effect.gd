class_name DamageEffect
extends CardEffect

func execute(ctx: GameContext) -> void:
	ctx.deal_damage_to_boss(value)

func get_description() -> String:
	return "보스에게 %d 데미지" % value
