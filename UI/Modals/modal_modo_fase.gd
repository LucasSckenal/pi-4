extends CanvasLayer
class_name ModalModoFase

# Emitido quando o jogador confirma um modo. infinito = true/false
signal modo_confirmado(infinito: bool)
signal cancelado

const NOMES_FASES = {
	1: "Tutorial",
	2: "Deserto Carmesim",
	3: "Casa da Bruxa",
	4: "Fenda dos Piratas",
	5: "Espaço Sideral",
	6: "Covil do Dragão"
}

@onready var fundo: ColorRect = $Fundo
@onready var painel: PanelContainer = $CenterContainer/Painel
@onready var titulo: Label = $CenterContainer/Painel/Margin/VBox/Titulo
@onready var subtitulo: Label = $CenterContainer/Painel/Margin/VBox/Subtitulo
@onready var estrelas_hbox: HBoxContainer = $CenterContainer/Painel/Margin/VBox/EstrelasHBox
@onready var btn_normal: Button = $CenterContainer/Painel/Margin/VBox/BotoesHBox/BtnNormal
@onready var btn_infinito: Button = $CenterContainer/Painel/Margin/VBox/BotoesHBox/BtnInfinito
@onready var aviso_bloqueado: Label = $CenterContainer/Painel/Margin/VBox/AvisoBloqueado
@onready var btn_fechar: Button = $CenterContainer/Painel/Margin/VBox/TopBar/BtnFechar

var fase_numero: int = 1

const ESTRELA_CHEIA = preload("res://Icons/star.png")
const ESTRELA_VAZIA = preload("res://Icons/star_outline_depth.png")


func _ready() -> void:
	layer = 100
	btn_normal.pressed.connect(_on_normal)
	btn_infinito.pressed.connect(_on_infinito)
	btn_fechar.pressed.connect(_on_fechar)
	fundo.gui_input.connect(_on_fundo_input)


func abrir(numero_fase: int) -> void:
	fase_numero = numero_fase
	var qtd_estrelas: int = Global.estrelas_por_fase.get(str(numero_fase), 0)
	var tem_3_estrelas: bool = qtd_estrelas >= 3

	titulo.text = "FASE %d" % numero_fase
	subtitulo.text = NOMES_FASES.get(numero_fase, "")

	_montar_estrelas(qtd_estrelas)

	btn_infinito.disabled = not tem_3_estrelas
	aviso_bloqueado.visible = not tem_3_estrelas
	if tem_3_estrelas:
		btn_infinito.text = "∞  MODO INFINITO"
	else:
		btn_infinito.text = "🔒  MODO INFINITO"

	_animar_entrada()


func _montar_estrelas(qtd: int) -> void:
	for c in estrelas_hbox.get_children():
		c.queue_free()
	for i in range(3):
		var tex := TextureRect.new()
		tex.texture = ESTRELA_CHEIA if i < qtd else ESTRELA_VAZIA
		tex.custom_minimum_size = Vector2(48, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		estrelas_hbox.add_child(tex)


func _animar_entrada() -> void:
	painel.scale = Vector2(0.7, 0.7)
	painel.modulate.a = 0.0
	fundo.modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(painel, "scale", Vector2.ONE, 0.35)
	tw.tween_property(painel, "modulate:a", 1.0, 0.25)
	tw.tween_property(fundo, "modulate:a", 1.0, 0.25)


func _fechar_com_animacao(cb: Callable) -> void:
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_IN)
	tw.tween_property(painel, "scale", Vector2(0.8, 0.8), 0.18)
	tw.tween_property(painel, "modulate:a", 0.0, 0.18)
	tw.tween_property(fundo, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(cb)


func _on_normal() -> void:
	_fechar_com_animacao(func():
		modo_confirmado.emit(false)
		queue_free()
	)


func _on_infinito() -> void:
	if btn_infinito.disabled:
		return
	_fechar_com_animacao(func():
		modo_confirmado.emit(true)
		queue_free()
	)


func _on_fechar() -> void:
	_fechar_com_animacao(func():
		cancelado.emit()
		queue_free()
	)


func _on_fundo_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_fechar()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_fechar()
		get_viewport().set_input_as_handled()
