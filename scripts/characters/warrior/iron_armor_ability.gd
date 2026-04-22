class_name IronArmorAbility
extends ModuleAbility

# 견고한 갑옷 — 모듈 능력
# 매 플레이어 턴 시작 시 방어도 +2를 부여한다.

func on_player_turn_start(ctx: GameContext) -> void:
	ctx.add_block(2)
