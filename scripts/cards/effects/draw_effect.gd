class_name DrawEffect
extends CardEffect

func execute(_ctx: GameContext) -> void:
	# TODO: 카드 드로우 로직은 메인에서 처리 필요
	pass

func get_description() -> String:
	return "카드 %d장 드로우" % value
