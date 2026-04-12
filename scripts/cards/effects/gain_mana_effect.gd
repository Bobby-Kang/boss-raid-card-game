class_name GainManaEffect
extends CardEffect

func execute(ctx: GameContext) -> void:
	ctx.mana_manager.add(value)

func get_description() -> String:
	return "마나 %d 획득" % value
