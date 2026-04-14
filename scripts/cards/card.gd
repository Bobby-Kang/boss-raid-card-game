extends Control

@onready var card_back: TextureRect = $CardBack
@onready var card_front: Control = $CardFront

@onready var artwork_area: TextureRect = %ArtworkArea
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var type_label: Label = %TypeLabel
@onready var cost_label: Label = %CostLabel

var is_face_up: bool = false
var data: CardData


func _ready() -> void:
	# 모든 자식의 mouse_filter를 IGNORE로 설정하여
	# 드래그 이벤트가 Card 루트까지 도달하도록 함
	_set_children_mouse_ignore(self)

	if data != null:
		_apply_data()

	if is_face_up:
		_show_front()
	else:
		_show_back()


func _set_children_mouse_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_ignore(child)


func _apply_data() -> void:
	cost_label.text = str(data.cost)
	name_label.text = data.card_name
	desc_label.text = data.get_description_text()

	if data.artwork != null:
		artwork_area.texture = data.artwork

	match data.card_type:
		CardData.CardType.ATTACK:
			type_label.text = "공격"
		CardData.CardType.SKILL:
			type_label.text = "스킬"
		CardData.CardType.POWER:
			type_label.text = "파워"
		CardData.CardType.MODULE:
			type_label.text = "모듈"
		_:
			type_label.text = "알 수 없음"


# --- 드래그 앤 드롭 ---

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not is_face_up:
		return null
	# 프리뷰 생성
	set_drag_preview(_create_drag_preview())
	modulate.a = 0.4
	return self


func _create_drag_preview() -> Control:
	# 커서가 프리뷰 중앙에 오도록 offset 컨테이너 사용
	var offset_container := Control.new()

	var preview := PanelContainer.new()
	preview.custom_minimum_size = custom_minimum_size
	preview.position = -custom_minimum_size / 2.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.85, 0.9)
	style.border_color = Color(0.3, 0.25, 0.2, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	preview.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = data.card_name if data else "카드"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	preview.add_child(label)
	offset_container.add_child(preview)
	return offset_container


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0


# --- 뒤집기 애니메이션 ---

func flip_to_front() -> void:
	if is_face_up:
		return
	is_face_up = true
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	tween.tween_callback(_show_front)
	tween.tween_property(self, "scale:x", 1.0, 0.15)


func flip_to_back() -> void:
	if not is_face_up:
		return
	is_face_up = false
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	tween.tween_callback(_show_back)
	tween.tween_property(self, "scale:x", 1.0, 0.15)


func _show_front() -> void:
	if card_back: card_back.visible = false
	if card_front: card_front.visible = true


func _show_back() -> void:
	if card_back: card_back.visible = true
	if card_front: card_front.visible = false
