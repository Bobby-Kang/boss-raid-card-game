class_name DiscardEffect
extends CardEffect

func execute(ctx: GameContext) -> void:
	if ctx.discard_cards.is_valid():
		ctx.discard_cards.call(value)

func get_description() -> String:
	return "카드 %d장 버림" % value
