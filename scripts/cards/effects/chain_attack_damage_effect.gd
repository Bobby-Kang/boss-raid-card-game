class_name ChainAttackDamageEffect
extends CardEffect

## 이번 턴 사용한 ATTACK 카드 수에 비례한 보스 피해.
## 실제 피해 = base_damage + (attacks_this_turn × per_attack_bonus)
## (이 카드 자신이 ATTACK 타입이면 트래커가 이미 +1 된 상태)

@export var base_damage: int = 3
@export var per_attack_bonus: int = 3


func execute(ctx: GameContext) -> void:
	# 이 카드 자신은 카운트에서 제외 (이미 main_scene._play_card에서 ++됨)
	var prior_attacks: int = maxi(0, ctx.attacks_this_turn - 1)
	var total: int = base_damage + (prior_attacks * per_attack_bonus)
	ctx.deal_damage_to_boss(total)


func get_description() -> String:
	return "보스 %d 피해. 이번 턴 사용한 공격 카드 1장당 +%d 피해" % [base_damage, per_attack_bonus]


func get_preview_summary() -> Dictionary:
	return {"target": "boss", "kind": "chain_damage", "amount": -1,
		"base": base_damage, "per": per_attack_bonus}
