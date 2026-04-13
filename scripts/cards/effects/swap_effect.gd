class_name SwapEffect
extends CardEffect

## 카드를 value장 뽑고, 손에서 value장 버리는 효과

func execute(ctx: GameContext) -> void:
	if ctx.draw_cards.is_valid():
		ctx.draw_cards.call(value)
	if ctx.discard_cards.is_valid():
		ctx.discard_cards.call(value)

func get_description() -> String:
	return "%d장 뽑고 %d장 버림" % [value, value]
