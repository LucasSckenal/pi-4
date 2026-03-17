extends CanvasLayer

@onready var fundo_escuro = $FundoEscuro
@onready var caixa_texto = $CaixaTexto
@onready var seta = $Seta

var alvo_3d_atual: Node3D = null
var alvo_2d_atual: Control = null

func _ready():
	visible = false

func _process(_delta):
	if not visible: return
	
	# Faz a seta seguir um objeto 3D no mapa
	if alvo_3d_atual:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var pos_tela = camera.unproject_position(alvo_3d_atual.global_position)
			seta.global_position = pos_tela + Vector2(0, -80)
			
	# Faz a seta seguir um botão 2D na interface
	elif alvo_2d_atual:
		var centro_do_botao = alvo_2d_atual.global_position + (alvo_2d_atual.size / 2.0)
		seta.global_position = centro_do_botao + Vector2(0, -80)

# ==========================================
# FUNÇÕES CHAMADAS PELO ROTEIRO
# ==========================================
func focar_em_slot_3d(slot_alvo: Node3D, texto: String):
	visible = true
	caixa_texto.text = texto
	alvo_3d_atual = slot_alvo
	alvo_2d_atual = null
	
	# O Tutorial PAUSA nesta linha e fica à espera que o slot seja clicado!
	await slot_alvo.slot_clicado
	
	esconder()

func focar_em_ui_2d(botao_alvo: Control, texto: String):
	if botao_alvo == null:
		push_error("🚨 ERRO NO TUTORIAL: Botão não encontrado! Texto: " + texto)
		return
		
	visible = true
	caixa_texto.text = texto
	alvo_2d_atual = botao_alvo
	alvo_3d_atual = null
	
	# === NOVA TRAVA AGRESSIVA E VISUAL PARA OS BOTÕES ===
	var pai_do_botao = botao_alvo.get_parent()
	if pai_do_botao:
		for irmao in pai_do_botao.get_children():
			# Se for outro botão/elemento e não for o texto do menu (Label)
			if irmao != botao_alvo and (irmao is Control) and not (irmao is Label):
				# 1. Bloqueia totalmente o rato (Ignora cliques)
				irmao.mouse_filter = Control.MOUSE_FILTER_IGNORE
				
				# 2. Desativa se for possível
				if "disabled" in irmao:
					irmao.disabled = true
					
				# 3. Escurece os botões errados para o jogador saber que estão bloqueados!
				irmao.modulate = Color(0.3, 0.3, 0.3, 0.3)
	# ====================================================
	
	var estado = {"clicado": false}
	var ao_clicar = func(): estado.clicado = true
	
	if botao_alvo.has_signal("pressed"):
		botao_alvo.pressed.connect(ao_clicar)
		
	while not estado.clicado and is_instance_valid(botao_alvo) and botao_alvo.is_inside_tree():
		await get_tree().create_timer(0.1).timeout
		
	if is_instance_valid(botao_alvo) and botao_alvo.has_signal("pressed"):
		if botao_alvo.pressed.is_connected(ao_clicar):
			botao_alvo.pressed.disconnect(ao_clicar)
			
	esconder()

func esconder():
	visible = false
	alvo_3d_atual = null
	alvo_2d_atual = null
