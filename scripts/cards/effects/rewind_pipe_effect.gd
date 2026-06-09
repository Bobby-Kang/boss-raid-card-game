class_name RewindPipeEffect
extends CardEffect

## 시간 역행 — 파이프 맨 뒤 value장을 맨 앞으로 (방금 버린 카드 회수).
## .tres: value = 회수할 장수

func execute(ctx: GameContext) -> void:
	if ctx.rewind_pipe.is_valid():
		ctx.rewind_pipe.call(value)


func get_description() -> String:
	return "파이프 맨 뒤 %d장을 맨 앞으로" % value
