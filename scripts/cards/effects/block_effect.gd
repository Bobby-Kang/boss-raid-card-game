class_name BlockEffect
extends CardEffect

func execute(ctx: GameContext) -> void:
	ctx.add_block(value)

func get_description() -> String:
	return "방어력 %d 획득" % value

func get_preview_summary() -> Dictionary:
	return {"target": "player", "kind": "block", "amount": value}
