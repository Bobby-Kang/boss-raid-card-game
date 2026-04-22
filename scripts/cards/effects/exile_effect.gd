class_name ExileEffect
extends CardEffect

# value 장 만큼 손패에서 선택한 카드를 영구 소멸시킨다 (파이프로 돌아가지 않음).
# ctx.exile_cards Callable이 main_scene에서 등록되어 있어야 한다.

func execute(ctx: GameContext) -> void:
	if ctx.exile_cards.is_valid():
		ctx.exile_cards.call(value)


func get_description() -> String:
	return "패의 카드 %d장 소멸" % value
