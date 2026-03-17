extends CanvasLayer

@onready var fundo_escuro = $FundoEscuro
@onready var caixa_texto = $CaixaTexto
@onready var seta = $Seta

var alvo_3d_atual: Node3D = null

func _ready():
	visible = false

func _process(_delta):
	if visible and alvo_3d_atual:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var pos_tela = camera.unproject_position(alvo_3d_atual.global_position)
			# Ajuste o -80 conforme o tamanho da sua imagem da seta
			seta.global_position = pos_tela + Vector2(0, -80)

# Função atualizada para usar "slot"
func focar_em_slot_3d(slot_alvo: Node3D, texto: String):
	visible = true
	caixa_texto.text = texto
	alvo_3d_atual = slot_alvo
	
	# O Tutorial espera o sinal do build_slot.gd
	await slot_alvo.slot_clicado
	
	esconder()

func esconder():
	visible = false
	alvo_3d_atual = null
