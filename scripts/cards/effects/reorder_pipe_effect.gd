class_name ReorderPipeEffect
extends CardEffect

## 운명 재배치 — 파이프 카드 1장을 선택해 맨 앞으로 끌어온다 (핀포인트).
## 선택 UI를 띄우므로 비동기로 처리 (main_scene Callable에 위임).

func execute(ctx: GameContext) -> void:
	if ctx.reorder_pipe_to_front.is_valid():
		ctx.reorder_pipe_to_front.call()


func get_description() -> String:
	return "파이프 카드 1장을 맨 앞으로"
