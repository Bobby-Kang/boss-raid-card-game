class_name RageInfusionAbility
extends ModuleAbility

## 광기의 인장 — 매 플레이어 턴 시작 시 투기 +1.
## 추가: 투기 ≥5면 보스에게 1 피해 (작은 패시브 압박).

func on_player_turn_start(ctx: GameContext) -> void:
	if ctx.rage_system == null:
		return
	ctx.rage_system.add(1)
	if ctx.rage_system.stacks >= 5:
		ctx.deal_damage_to_boss(1)
