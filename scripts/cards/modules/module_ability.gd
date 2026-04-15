class_name ModuleAbility
extends Resource

## 공용 모듈 능력 베이스 클래스.
## 모든 직업의 모듈 카드가 상속받는 훅 인터페이스.
## 자식 클래스는 필요한 훅만 선택적으로 오버라이드한다.

@export var module_id: String = ""


func on_boss_turn_end(_ctx: GameContext) -> void:
	pass


func on_player_turn_start(_ctx: GameContext) -> void:
	pass


func on_player_turn_end(_ctx: GameContext) -> void:
	pass
