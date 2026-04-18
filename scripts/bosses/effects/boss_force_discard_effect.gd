class_name BossForceDiscardEffect
extends CardEffect

# 플레이어에게 손패 버리기를 강제한다 (보스 카드 전용)
func execute(ctx: GameContext) -> void:
	if ctx.discard_cards.is_valid():
		ctx.discard_cards.call(value)

func get_description() -> String:
	return "플레이어 카드 %d장 강제 버리기" % value
