extends Control

@onready var fight_button: Button = %FightButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	# 메인 씬과 동일한 다크 판타지 테마 적용 — 패널·버튼·라벨 통일
	theme = DarkFantasyTheme.build()
	_setup_background_atmosphere()

	fight_button.pressed.connect(_on_fight_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_scene.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/title_screen.tscn")


# 배경 깊이감 — 메인 씬과 동일한 세로 그라데이션 + 가장자리 비네팅
func _setup_background_atmosphere() -> void:
	# 1) 세로 그라데이션 (상단 갈색 → 하단 흑갈색)
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_LINEAR
	grad.fill_from = Vector2(0.5, 0.0)
	grad.fill_to = Vector2(0.5, 1.0)
	var g := Gradient.new()
	g.set_color(0, DarkFantasyTheme.BG_MID)
	g.set_color(1, DarkFantasyTheme.BG_DEEP)
	grad.gradient = g
	var grad_rect := TextureRect.new()
	grad_rect.name = "BgGradient"
	grad_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grad_rect.texture = grad
	grad_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(grad_rect)
	move_child(grad_rect, 1)   # Background 바로 위

	# 2) 가장자리 비네팅 (radial: 중앙 투명 → 가장자리 어둠)
	var vig_grad := GradientTexture2D.new()
	vig_grad.fill = GradientTexture2D.FILL_RADIAL
	vig_grad.fill_from = Vector2(0.5, 0.5)
	vig_grad.fill_to = Vector2(1.0, 0.5)
	var vg := Gradient.new()
	vg.set_color(0, Color(0, 0, 0, 0.0))
	vg.set_color(1, Color(0, 0, 0, 0.55))
	vig_grad.gradient = vg
	var vig := TextureRect.new()
	vig.name = "BgVignette"
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.texture = vig_grad
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(vig)
	move_child(vig, 2)   # gradient 위
