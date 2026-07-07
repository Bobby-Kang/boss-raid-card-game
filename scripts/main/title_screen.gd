extends Control

@onready var start_button: Button = %StartButton
@onready var help_button: Button = %HelpButton

var _help_root: Control = null

const _HELP_BBCODE := "[center][font_size=34][color=eac77a]📖 게임 방법[/color][/font_size][/center]

[font_size=21][color=eac77a]🎯 목표[/color][/font_size]
버그베어(보스)의 HP를 0으로 만들면 승리. 내 HP가 0이 되면 패배.

[font_size=21][color=eac77a]🃏 타임라인 파이프[/color][/font_size]
덱을 [b]섞지 않습니다.[/b] 카드 순서가 항상 공개되어 [b]다음에 뭐가 올지 미리 압니다.[/b]
쓰거나 버린 카드는 파이프 맨 뒤로 가서 순환합니다. (시작할 때 한 번만 섞임)

[font_size=21][color=eac77a]⚡ AP & 🔥 투기[/color][/font_size]
매 턴 AP 3을 받아 카드 사용에 씁니다.
[b]공격 카드를 쓸 때마다 투기 +1[/b] — 휘두를수록 달아오릅니다. (남은 AP도 투기로)
투기 10이 되면 [b]투기 발산[/b](보스 10 피해 + 방어 10)!

[font_size=21][color=eac77a]💰 골드[/color][/font_size]
재화 카드로 골드를 벌 수 있어요. [b]턴이 끝나면 사라지니[/b] 그 턴에 [color=eac77a]🛒 상점[/color]에서 카드를 사세요.

[font_size=21][color=eac77a]💀 보스 카드덱[/color][/font_size]
보스도 카드를 씁니다. [b]다음 예고[/b]로 다음 행동을, [b]파워 존[/b]의 카운트다운으로 곧 터질 강력한 기술을 미리 보고 대비하세요.
보스 페이즈(1→2→3)가 오를수록 강해집니다.

[font_size=21][color=eac77a]🖱 조작[/color][/font_size]
카드를 [b]드래그[/b]해서:
• 가운데 대결 무대로 → [b]카드 사용[/b]
• 타임라인 파이프로 → [b]그냥 버리기[/b] (효과 없이 뒤로)
• 액티브 슬롯으로 → [b]모듈 장착[/b]

[font_size=21][color=eac77a]📜 기록[/color][/font_size]
전투 중 상단 [color=eac77a]📜 기록[/color] 버튼으로 지금까지 벌어진 일을 다시 볼 수 있어요."


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	help_button.pressed.connect(_show_help)
	_build_help_overlay()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/character_select.tscn")


# === 도움말 오버레이 (코드 동적 생성) ===

func _build_help_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	_help_root = Control.new()
	_help_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help_root.visible = false
	layer.add_child(_help_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.03, 0.02, 0.85)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_help())
	_help_root.add_child(dim)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -450
	frame.offset_right = 450
	frame.offset_top = -340
	frame.offset_bottom = 340
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.11, 0.08, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(0.78, 0.62, 0.34)
	style.set_corner_radius_all(10)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	frame.add_theme_stylebox_override("panel", style)
	_help_root.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	frame.add_child(vb)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich.add_theme_font_size_override("normal_font_size", 17)
	rich.add_theme_color_override("default_color", Color(0.91, 0.85, 0.73))
	rich.text = _HELP_BBCODE
	scroll.add_child(rich)

	var close_btn := Button.new()
	close_btn.text = "✕ 닫기"
	close_btn.custom_minimum_size = Vector2(0, 44)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_help)
	vb.add_child(close_btn)


func _show_help() -> void:
	if _help_root:
		_help_root.visible = true


func _close_help() -> void:
	if _help_root:
		_help_root.visible = false
