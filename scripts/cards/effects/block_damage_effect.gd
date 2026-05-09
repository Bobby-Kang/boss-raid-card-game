class_name BlockDamageEffect
extends CardEffect

# 현재 플레이어 방어도만큼 보스에게 피해를 입힌다.
# value 필드는 사용하지 않음 (CardEffect 기본값 유지).

func execute(ctx: GameContext) -> void:
	if ctx.player_block > 0:
		ctx.deal_damage_to_boss(ctx.player_block)


func get_description() -> String:
	return "현재 방어도만큼 보스에게 피해"

func get_preview_summary() -> Dictionary:
	# amount는 컨텍스트별로 동적 계산되어야 하므로 -1 마커
	return {"target": "boss", "kind": "block_damage", "amount": -1}
