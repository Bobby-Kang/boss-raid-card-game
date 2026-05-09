class_name RemoveCardEffect
extends CardEffect

## 손패 또는 파이프에서 카드 1장을 영구 제거 (선택 UI를 통해).
## 자세한 흐름은 main_scene._grant_card_removal_reward 가 담당하며,
## 이 효과는 GameContext.request_card_removal 콜러블을 호출해 위임한다.

func execute(ctx: GameContext) -> void:
	if ctx.request_card_removal.is_valid():
		ctx.request_card_removal.call()


func get_description() -> String:
	return "카드 1장을 영구 제거"

func get_preview_summary() -> Dictionary:
	return {"target": "self", "kind": "remove", "amount": 1}
