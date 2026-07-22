extends CanvasLayer

# 승리/패배 결과 화면
# show_result(true)  → 승리 연출
# show_result(false) → 패배 연출

@onready var background: ColorRect = $Background
@onready var result_label: Label = $Background/VBox/ResultLabel
@onready var sub_label: Label = $Background/VBox/SubLabel
@onready var restart_button: Button = $Background/VBox/RestartButton


func _ready() -> void:
	visible = false
	background.theme = DarkFantasyTheme.build()   # 버튼·패널 다크 판타지 톤 통일
	restart_button.pressed.connect(_on_restart_pressed)


func show_result(is_win: bool) -> void:
	if is_win:
		result_label.text = "승리!"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
		sub_label.text = "보스를 쓰러뜨렸다!"
	else:
		result_label.text = "패배"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25, 1.0))
		sub_label.text = "쓰러지고 말았다..."
	visible = true
	# 페이드 인 (CanvasLayer는 modulate 없음 → Background CanvasItem으로 처리)
	background.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 0.5)


func _on_restart_pressed() -> void:
	# 타이틀 화면을 없앴으므로 전투를 바로 다시 시작한다
	get_tree().reload_current_scene()
