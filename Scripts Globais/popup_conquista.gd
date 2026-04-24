extends CanvasLayer

@onready var panel = $PanelContainer

var labelName: Label
var iconeRect: TextureRect
var _tween_popup: Tween = null

func _ready():
	labelName = find_child("LabelName", true, false) as Label
	iconeRect = find_child("Icone", true, false) as TextureRect
	if panel:
		panel.modulate.a = 0.0
		panel.position.y = -140.0
	if Global.has_signal("conquista_desbloqueada"):
		Global.conquista_desbloqueada.connect(_exibir_popup)

func _exibir_popup(nome_conquista, _index_liberado, icone_conquista):
	if not labelName:
		labelName = find_child("LabelName", true, false) as Label
	if not iconeRect:
		iconeRect = find_child("Icone", true, false) as TextureRect

	if labelName:
		labelName.text = str(nome_conquista)
	if iconeRect and icone_conquista != null:
		iconeRect.texture = icone_conquista

	if _tween_popup != null and is_instance_valid(_tween_popup):
		_tween_popup.kill()

	panel.position.y = -140.0
	panel.modulate.a = 0.0

	_tween_popup = create_tween()
	_tween_popup.tween_property(panel, "position:y", 10.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween_popup.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)
	_tween_popup.tween_interval(5.5)
	_tween_popup.tween_property(panel, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween_popup.parallel().tween_property(panel, "position:y", -140.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
