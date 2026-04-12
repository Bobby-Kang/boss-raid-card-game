class_name SwapEffect
extends CardEffect

## 카드를 value장 뽑고, 손에서 value장 버리는 효과
## 실제 드로우/버리기는 메인 씬에서 시그널로 처리

func execute(_ctx: GameContext) -> void:
	# 메인 씬에서 시그널 기반으로 처리 (추후 구현)
	pass

func get_description() -> String:
	return "%d장 뽑고 %d장 버림" % [value, value]
