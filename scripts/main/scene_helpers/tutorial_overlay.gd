class_name TutorialOverlay
extends Node
## 첫 플레이 스포트라이트 튜토리얼.
## 화면 전체를 딤 처리하되 대상 UI 영역만 밝게(4-패널 구멍) + 금색 테두리 강조 + 말풍선.
## show_tutorial([{target: Control, text: String}]) 로 단계 재생. 스킵 가능.

signal finished

const DIM := Color(0, 0, 0, 0.72)
const GOLD := Color(0.92, 0.78, 0.48)

var _layer: CanvasLayer
var _root: Control
var _dim_panels: Array[ColorRect] = []   # 상/하/좌/우 4장
var _highlight: Panel
var _bubble: PanelContainer
var _bubble_label: RichTextLabel
var _progress_label: Label
var _next_button: Button
var _skip_button: Button

var _steps: Array = []
var _step: int = 0


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 25
	add_child(_layer)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	_layer.add_child(_root)

	# 딤 4장 (대상 영역만 남기고 주변을 덮음)
	for i in 4:
		var p := ColorRect.new()
		p.color = DIM
		p.mouse_filter = Control.MOUSE_FILTER_STOP   # 뒤 클릭 차단
		_root.add_child(p)
		_dim_panels.append(p)

	# 대상 강조 테두리
	_highlight = Panel.new()
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0, 0, 0, 0)
	hs.set_border_width_all(3)
	hs.border_color = GOLD
	hs.set_corner_radius_all(8)
	_highlight.add_theme_stylebox_override("panel", hs)
	_root.add_child(_highlight)

	# 말풍선
	_bubble = PanelContainer.new()
	_bubble.custom_minimum_size = Vector2(460, 0)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.14, 0.11, 0.08, 0.98)
	bs.set_border_width_all(2)
	bs.border_color = GOLD
	bs.set_corner_radius_all(10)
	bs.content_margin_left = 20
	bs.content_margin_right = 20
	bs.content_margin_top = 16
	bs.content_margin_bottom = 16
	bs.shadow_color = Color(0, 0, 0, 0.5)
	bs.shadow_size = 8
	_bubble.add_theme_stylebox_override("panel", bs)
	_root.add_child(_bubble)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_bubble.add_child(vb)

	_bubble_label = RichTextLabel.new()
	_bubble_label.bbcode_enabled = true
	_bubble_label.fit_content = true
	_bubble_label.scroll_active = false
	_bubble_label.custom_minimum_size = Vector2(420, 0)
	_bubble_label.add_theme_font_size_override("normal_font_size", 18)
	_bubble_label.add_theme_color_override("default_color", Color(0.91, 0.85, 0.73))
	vb.add_child(_bubble_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)

	_skip_button = Button.new()
	_skip_button.text = "건너뛰기"
	_skip_button.add_theme_font_size_override("font_size", 14)
	_skip_button.pressed.connect(_finish)
	row.add_child(_skip_button)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", Color(0.62, 0.55, 0.45))
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_progress_label)

	_next_button = Button.new()
	_next_button.text = "다음 ▶"
	_next_button.add_theme_font_size_override("font_size", 15)
	_next_button.add_theme_color_override("font_color", GOLD)
	_next_button.pressed.connect(_next)
	row.add_child(_next_button)


func show_tutorial(steps: Array) -> void:
	if steps.is_empty():
		finished.emit()
		return
	_steps = steps
	_step = 0
	_root.visible = true
	_render_step()


func _next() -> void:
	_step += 1
	if _step >= _steps.size():
		_finish()
	else:
		_render_step()


func _finish() -> void:
	_root.visible = false
	finished.emit()


func _render_step() -> void:
	var data: Dictionary = _steps[_step]
	var target: Control = data.get("target", null)
	_bubble_label.text = data.get("text", "")
	_progress_label.text = "%d / %d" % [_step + 1, _steps.size()]
	_next_button.text = "시작! ✓" if _step == _steps.size() - 1 else "다음 ▶"

	var vp: Vector2 = _root.get_viewport_rect().size
	var r: Rect2
	if target != null and is_instance_valid(target) and target.is_visible_in_tree():
		r = target.get_global_rect()
		# 약간의 여백
		r = r.grow(6)
	else:
		# 대상 없으면 화면 중앙 작은 영역 (전체 딤 효과)
		r = Rect2(vp * 0.5, Vector2.ZERO)

	_layout_spotlight(r, vp)
	_layout_bubble(r, vp)


# 대상 rect를 제외한 4방향을 딤으로 덮어 스포트라이트 효과
func _layout_spotlight(r: Rect2, vp: Vector2) -> void:
	var x0: float = clampf(r.position.x, 0, vp.x)
	var y0: float = clampf(r.position.y, 0, vp.y)
	var x1: float = clampf(r.position.x + r.size.x, 0, vp.x)
	var y1: float = clampf(r.position.y + r.size.y, 0, vp.y)
	# 상
	_dim_panels[0].position = Vector2(0, 0)
	_dim_panels[0].size = Vector2(vp.x, y0)
	# 하
	_dim_panels[1].position = Vector2(0, y1)
	_dim_panels[1].size = Vector2(vp.x, vp.y - y1)
	# 좌
	_dim_panels[2].position = Vector2(0, y0)
	_dim_panels[2].size = Vector2(x0, y1 - y0)
	# 우
	_dim_panels[3].position = Vector2(x1, y0)
	_dim_panels[3].size = Vector2(vp.x - x1, y1 - y0)

	_highlight.visible = r.size.x > 1.0 and r.size.y > 1.0
	_highlight.position = r.position
	_highlight.size = r.size


# 말풍선을 대상 아래(공간 없으면 위)에 배치
func _layout_bubble(r: Rect2, vp: Vector2) -> void:
	var bsize: Vector2 = _bubble.get_combined_minimum_size()
	bsize.x = maxf(bsize.x, 460)
	var bx: float = clampf(r.get_center().x - bsize.x * 0.5, 12, vp.x - bsize.x - 12)
	var by: float
	if r.position.y + r.size.y + bsize.y + 20 < vp.y:
		by = r.position.y + r.size.y + 16   # 아래
	else:
		by = r.position.y - bsize.y - 16     # 위
	by = clampf(by, 12, vp.y - bsize.y - 12)
	_bubble.position = Vector2(bx, by)
	_bubble.size = bsize
