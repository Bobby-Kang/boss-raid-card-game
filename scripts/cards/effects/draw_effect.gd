class_name DrawEffect
extends CardEffect

func execute(ctx: GameContext) -> void:
	if ctx.draw_cards.is_valid():
		ctx.draw_cards.call(value)

func get_description() -> String:
	return "카드 %d장 드로우" % value
