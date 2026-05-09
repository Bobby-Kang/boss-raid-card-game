class_name CardEffect
extends Resource

@export var value: int = 0

func execute(_ctx: GameContext) -> void:
	pass

func get_description() -> String:
	return ""


## 호버 프리뷰용 효과 요약 메타데이터.
## 반환 형식: { "target": "boss"|"player"|"self", "kind": "damage"|"block"|"draw"|"gold"|"exile"|"remove"|"block_damage", "amount": int }
## amount 가 -1 이면 컨텍스트 기반 계산 필요 (예: BlockDamageEffect는 현재 방어도)
func get_preview_summary() -> Dictionary:
	return {}
