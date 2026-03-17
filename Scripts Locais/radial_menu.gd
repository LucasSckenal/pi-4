extends Control

## Distância dos botões em relação ao centro do menu
@export var raio_menu: float = 200.0
## Referência para a cena do botão do menu radial
@export var prefab_botao: PackedScene

@onready var info_label: Label = $InfoLabel

var _botoes_ativos: Array[Node] = []
var _slot_alvo: Node = null

# Cores para a estilização visual
var _cor_divisoria = Color(0.3, 0.32, 0.35, 0.8) # Borda cinza suave
var _cor_fundo_fatia = Color(0.1, 0.11, 0.13, 0.9) # Fundo escuro para contraste

func _ready() -> void:
	hide()
	info_label.text = ""
	# Garante que o menu seja redesenhado se o raio mudar
	queue_redraw()

# ==========================================
# DESENHO VISUAL DO MENU (BACKGROUND E DIVISÓRIAS)
# ==========================================
func _draw() -> void:
	# Cores para o fundo e o anel
	var cor_fundo_geral = Color(0.15, 0.16, 0.18, 0.95)
	
	# Desenha o círculo de fundo principal (fundo de todo o HUD)
	draw_circle(Vector2.ZERO, raio_menu + 70.0, cor_fundo_geral)
	
	# Obtém as construções para saber quantas divisórias desenhar
	var construcoes = GameManager.get_construcoes_disponiveis()
	if construcoes.is_empty():
		return
		
	var quantidade = construcoes.size()
	var angulo_passo = (2 * PI) / quantidade
	var angulo_inicial = -PI / 2.0 # Começa no topo
	
	# Desenha as fatias de fundo e as linhas divisórias
	for i in range(quantidade):
		var angulo_atual = angulo_inicial + (i * angulo_passo)
		var angulo_linha = angulo_atual + (angulo_passo / 2.0) # Desloca a linha para a metade do espaço entre as fatias
		
		# Define os pontos para desenhar a linha divisória (do centro para fora) usando o ângulo deslocado
		var ponto_interno = Vector2(cos(angulo_linha), sin(angulo_linha)) * (raio_menu - 40.0)
		var ponto_externo = Vector2(cos(angulo_linha), sin(angulo_linha)) * (raio_menu + 70.0)
		
		# Desenha a linha divisória
		draw_line(ponto_interno, ponto_externo, _cor_divisoria, 2.0)
		
	# Desenha os anéis de borda para dar acabamento
	draw_arc(Vector2.ZERO, raio_menu + 70.0, 0, 2*PI, 128, _cor_divisoria, 2.0)
	draw_arc(Vector2.ZERO, raio_menu - 40.0, 0, 2*PI, 128, _cor_divisoria, 2.0)

# ==========================================
# LÓGICA DE ABERTURA E FECHAMENTO
# ==========================================
func abrir_menu(slot: Node) -> void:
	_slot_alvo = slot
	_limpar_botoes()
	
	var construcoes_disponiveis = GameManager.get_construcoes_disponiveis()
	
	if construcoes_disponiveis.is_empty():
		info_label.text = "Nenhuma torre liberada"
		show()
		return
		
	info_label.text = "Selecione\numa torre"
	
	var quantidade = construcoes_disponiveis.size()
	var angulo_passo = (2 * PI) / quantidade
	var angulo_inicial = -PI / 2.0 # Começa no topo (-90 graus)
	
	for i in range(quantidade):
		var cena_torre = construcoes_disponiveis[i]
		var angulo_atual = angulo_inicial + (i * angulo_passo)
		
		var novo_botao = prefab_botao.instantiate()
		add_child(novo_botao)
		_botoes_ativos.append(novo_botao)
		
		# Calcula a posição circular e subtrai metade do tamanho para centralizar o botão na linha
		var direcao = Vector2(cos(angulo_atual), sin(angulo_atual))
		novo_botao.position = (direcao * raio_menu) - (novo_botao.size / 2.0)
		
		# Instancia temporariamente para pegar os dados
		var temp_instancia = cena_torre.instantiate()
		var nome = temp_instancia.get("nome_construcao") if "nome_construcao" in temp_instancia else "Torre"
		var icone = temp_instancia.get("icone") if "icone" in temp_instancia else null
		var custo = temp_instancia.get("custo_moedas") if "custo_moedas" in temp_instancia else 0
		temp_instancia.queue_free()
		
		# A MÁGICA PARA O TUTORIAL ESTÁ AQUI: Dá o nome exato da construção ao botão!
		novo_botao.name = nome 
		# ================================
		
		novo_botao.configurar(cena_torre, icone, nome, custo, self)
		
	# Garante que as divisórias sejam desenhadas
	queue_redraw()
	show()

func fechar_menu() -> void:
	hide()
	_limpar_botoes()
	_slot_alvo = null
	info_label.text = ""

# ==========================================
# LÓGICA DE INTERAÇÃO DOS BOTÕES
# ==========================================
func atualizar_informacoes(nome: String, custo: int) -> void:
	# Aplica desconto antes de exibir (opcional, se o menu já receber o custo final)
	var custo_final = GameManager.obter_custo_com_desconto(custo)
	info_label.text = "%s\nCusta: %d" % [nome, custo_final]

func limpar_informacoes() -> void:
	info_label.text = "Selecione\numa torre"

func _solicitar_construcao(cena_torre: PackedScene, _custo: int) -> void:
	# Como o TutorialManager já bloqueia os cliques nos outros botões, 
	# se chegou aqui, é porque o jogador clicou no sítio certo!
	if _slot_alvo and _slot_alvo.has_method("construir"):
		_slot_alvo.construir(cena_torre)
		fechar_menu()

func _limpar_botoes() -> void:
	for botao in _botoes_ativos:
		if is_instance_valid(botao):
			botao.queue_free()
	_botoes_ativos.clear()
	
# ==========================================
# LÓGICA DE DETECÇÃO DE CLIQUE FORA (PC E MOBILE)
# ==========================================
func _input(event: InputEvent) -> void:
	# Só tenta detectar cliques se o menu estiver aberto na tela
	if not visible:
		return
		
	# ==========================================
	# TRAVA DO TUTORIAL (MENU)
	# ==========================================
	if GameManager.is_tutorial_ativo:
		var tutorial = get_tree().get_first_node_in_group("TutorialManager")
		if tutorial and tutorial.visible and tutorial.alvo_2d_atual != null:
			# Se o tutorial está a mandar clicar num botão deste menu, 
			# IMPEDE o jogador de fechar o menu clicando fora!
			return 
	# ==========================================
		
	var clicou: bool = false
	var pos_clique: Vector2 = Vector2.ZERO
	
	# Detecta clique esquerdo do mouse (PC)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicou = true
		pos_clique = event.position
	# Detecta toque na tela (Mobile)
	elif event is InputEventScreenTouch and event.pressed:
		clicou = true
		pos_clique = event.position
		
	if clicou:
		# Calcula a distância exata entre o clique e o centro do menu radial
		var distancia = pos_clique.distance_to(global_position)
		
		# (raio_menu + 70.0) é exatamente o tamanho do círculo de fundo que desenhamos no _draw()
		if distancia > (raio_menu + 70.0):
			# Usa call_deferred por segurança para o Godot não deletar a UI no meio do clique
			if _slot_alvo and _slot_alvo.has_method("fechar_ui"):
				_slot_alvo.call_deferred("fechar_ui")
				
				# (Opcional) Impede que o clique vaze e faça o personagem andar ou atirar sem querer
				get_viewport().set_input_as_handled()
