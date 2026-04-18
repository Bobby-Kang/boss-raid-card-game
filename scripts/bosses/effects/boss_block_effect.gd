class_name BossBlockEffect
extends CardEffect

# 보스가 방어도를 획득한다 (보스 카드 전용)
func execute(ctx: GameContext) -> void:
	ctx.add_boss_block(value)

func get_description() -> String:
	return "보스 방어도 +%d" % value
