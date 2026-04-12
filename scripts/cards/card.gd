extends Control

signal card_clicked(card: Control)

# 기존처럼 카드를 뒤집기 위한 부모 노드들이 있다고 가정합니다.
# (VBox, CostBadge 등이 CardFront의 자식으로 들어있어야 합니다)
@onready var card_back: TextureRect = $CardBack
@onready var card_front: Control = $CardFront

# 씬 고유 이름(%)을 사용하여 깊은 경로 없이 바로 노드 연결
@onready var artwork_area: TextureRect = %ArtworkArea
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var type_label: Label = %TypeLabel
@onready var cost_label: Label = %CostLabel
@onready var click_area: Button = %ClickArea

var is_face_up: bool = false
var data: CardData


func _ready() -> void:
	click_area.pressed.connect(_on_click)
	
	# 데이터가 들어왔다면 화면에 세팅합니다.
	if data != null:
		_apply_data()
		
	# 처음 생성될 때 앞면/뒷면 상태 초기화
	if is_face_up:
		_show_front()
	else:
		_show_back()


func _apply_data() -> void:
	# 1. 텍스트 데이터 적용
	cost_label.text = str(data.cost)
	name_label.text = data.card_name
	desc_label.text = data.get_description_text()
	
	# 2. 일러스트 이미지 적용 (데이터에 이미지가 등록되어 있을 경우만)
	if data.artwork != null:
		artwork_area.texture = data.artwork
		
	# 3. Enum 타입(ATTACK, SKILL, POWER)을 한글 문자열로 변환하여 적용
	match data.card_type:
		CardData.CardType.ATTACK:
			type_label.text = "공격"
		CardData.CardType.SKILL:
			type_label.text = "스킬"
		CardData.CardType.POWER:
			type_label.text = "파워"
		_:
			type_label.text = "알 수 없음"


# --- 아래는 이전에 만드신 뒤집기 애니메이션 로직 ---

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


func _on_click() -> void:
	card_clicked.emit(self)
