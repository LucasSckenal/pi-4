extends CanvasLayer

# ==========================================
# REFERÊNCIAS AOS NÓS DA INTERFACE
# ==========================================
@onready var nome_inimigo_label = $CartaoCentral/Margin/VBox/NomeInimigo
@onready var dica_texto = $CartaoCentral/Margin/VBox/DicaTexto
@onready var vel_info = $CartaoCentral/Margin/VBox/Status/VelocidadeInfo
@onready var vida_info = $CartaoCentral/Margin/VBox/Status/VidaInfo
@onready var viewport_3d = $CartaoCentral/Margin/VBox/Estudo3D/Viewport

var modelo_atual: Node3D = null

func _ready():
	# Garante que o ecrã começa invisível
	hide()

func _process(delta):
	# Faz o modelo 3D rodar lentamente (eixo Y) enquanto o jogador lê as dicas
	if modelo_atual != null:
		modelo_atual.rotation.y += 1.0 * delta

# ==========================================
# FUNÇÃO PRINCIPAL (Chamada pelo Inimigo)
# ==========================================
func mostrar_novo_inimigo(nome: String, dica: String, modelo_original: Node3D, vel_desc: String, hp_desc: String):
	# 1. Atualiza os textos
	nome_inimigo_label.text = nome.to_upper()
	dica_texto.text = dica
	vel_info.text = "⚡ Speed: " + vel_desc
	vida_info.text = "❤️ HP: " + hp_desc
	
	# 2. Limpa o monstro anterior do estúdio, se houver algum
	if modelo_atual != null:
		modelo_atual.queue_free()
		modelo_atual = null
		
	# 3. Clona o modelo 3D do inimigo e coloca-o no "Mini Estúdio"
	if modelo_original != null:
		modelo_atual = modelo_original.duplicate()
		
		# MUITO IMPORTANTE: Desativa o script/IA do clone para ele não tentar atacar no ecrã!
		modelo_atual.process_mode = Node.PROCESS_MODE_DISABLED 
		
		viewport_3d.add_child(modelo_atual)
		
		# Centraliza o modelo e zera a rotação inicial
		modelo_atual.position = Vector3.ZERO
		modelo_atual.rotation = Vector3.ZERO
		
	# 4. Pausa o jogo e mostra o cartão no ecrã
	get_tree().paused = true
	show()

# ==========================================
# CONTROLOS PARA FECHAR O CARTÃO
# ==========================================
func _input(event):
	# Se a janela estiver visível e o jogador clicar (rato) ou tocar no ecrã, fecha
	if visible and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_fechar_aviso()

func _fechar_aviso():
	# Retoma o jogo e esconde o cartão
	get_tree().paused = false
	hide()
