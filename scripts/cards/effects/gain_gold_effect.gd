class_name GainGoldEffect
extends CardEffect

func execute(ctx: GameContext) -> void:
	ctx.gold_manager.add(value)

func get_description() -> String:
	return "금 %d 획득" % value
