extends CanvasLayer

#OBS.: NÃO MOVER PARA CIMA DO TUTORIALMANAGER, QUEBRA NA HORA A LÓGICA DE MOVIMENTAÇÃO DO PERSONAGEM
# E EU NÂO TENHO A MENOR IDEIA DO POR QUÊ

# ==========================================
# REFERÊNCIAS DA INTERFACE PRINCIPAL
# ==========================================
@onready var hud_mobile_completo = $InterfacePrincipal/HudMobileCompleto
@onready var label_wave = $InterfacePrincipal/CentroTela/LabelWave
@onready var botao_noite = $InterfacePrincipal/MarginInferior/CenterContainer/BotaoNoite
@onready var label_moedas = $InterfacePrincipal/MarginDireita/VBoxDireita/FundoMoedas/LabelMoedas
@onready var margin_direita = $InterfacePrincipal/MarginDireita
@export var cena_carta_ui: PackedScene

@onready var anim_bau = $InterfacePrincipal/MarginDireita/VBoxDireita/ContainerBau/SubViewport/chest2/AnimationPlayer

# ==========================================
# SISTEMA DE UPGRADE POR CARTAS (ROGUELIKE)
# ==========================================
@onready var menu_upgrade = $InterfacePrincipal/MenuUpgrade
@onready var container_cartas = $InterfacePrincipal/MenuUpgrade/HBoxContainer
@onready var botao_reroll = $InterfacePrincipal/MenuUpgrade/BotaoReroll

# ==========================================
# INDICADORES DE ONDA (BOLINHAS NA BORDA)
# ==========================================
@onready var container_direcoes = $ContainerDirecoes
@export var cena_enemy_icon: PackedScene
@export var tamanho_container: Vector2 = Vector2(80, 100)
@export var margem_borda: float = 20.0

var containers_por_direcao = {}

# ==========================================
# UI DE UPGRADE INDIVIDUAL (PATHS)
# ==========================================
@export var upgrade_ui_scene: PackedScene          # Arraste a cena UpgradeUI.tscn aqui
@export var cena_opcao_button: PackedScene         # Arraste a cena OpcaoUpgradeButton.tscn aqui
var upgrade_ui_instance: Control = null
var torre_atual = null
# ==========================================
# UI DE AMPULHETA E PROGRESSÃO
# ==========================================
@onready var pivot_ampulheta: Control = $InterfacePrincipal/MarginEsquerda/HBoxTempo/PivotAmpulheta
@onready var ampulheta_dia: TextureRect = $InterfacePrincipal/MarginEsquerda/HBoxTempo/PivotAmpulheta/Dia
@onready var ampulheta_noite: TextureRect = $InterfacePrincipal/MarginEsquerda/HBoxTempo/PivotAmpulheta/Noite
@onready var label_onda: Label = $InterfacePrincipal/MarginEsquerda/HBoxTempo/VBoxTextos/LabelOnda
@onready var label_turno: Label = $InterfacePrincipal/MarginEsquerda/HBoxTempo/VBoxTextos/LabelTurno

# ==========================================
# UI DE GAME OVER
# ==========================================
@export var cena_game_over: PackedScene
var game_over_instance: Control = null

# ==========================================
# UI DE VITÓRIA
# ==========================================
@export var cena_vitoria: PackedScene
var vitoria_instance: CanvasLayer = null

func _ready():
	add_to_group("Interface")
	
	# Conecta sinais do GameManager (upgrade de cartas)
	if GameManager.has_signal("mostrar_menu_upgrade"):
		GameManager.mostrar_menu_upgrade.connect(_on_abrir_menu_upgrade)
	
	menu_upgrade.hide()
	
	# Instancia a UI de upgrade individual
	if upgrade_ui_scene:
		upgrade_ui_instance = upgrade_ui_scene.instantiate()
		add_child(upgrade_ui_instance)
		upgrade_ui_instance.hide()
		# Conecta o sinal de fechamento (se existir)
		if upgrade_ui_instance.has_signal("fechado"):
			upgrade_ui_instance.fechado.connect(_on_upgrade_ui_fechado)
		# Passa a cena do botão de opção para a UI
		if upgrade_ui_instance.has_method("set_cena_opcao_button"):
			upgrade_ui_instance.set_cena_opcao_button(cena_opcao_button)
		print("UI de upgrade instanciada com sucesso.")
	else:
		print("ERRO: upgrade_ui_scene não atribuída na HUD!")
	
	# Configurações iniciais da interface
	if label_wave != null:
		label_wave.modulate.a = 0.0
	
	if botao_reroll != null:
		botao_reroll.pressed.connect(_on_botao_reroll_pressed)
	
	atualizar_moedas()
	verificar_estado_dia_noite()
	
	# Configura o container de direções (para os ícones de onda)
	if container_direcoes == null:
		container_direcoes = Control.new()
		container_direcoes.name = "ContainerDirecoes"
		add_child(container_direcoes)
	container_direcoes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container_direcoes.z_index = 100
	container_direcoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Carrega a cena do ícone de inimigo se necessário (fallback)
	if cena_enemy_icon == null:
		cena_enemy_icon = preload("res://Enemys/enemy_icon.tscn")
		if cena_enemy_icon == null:
			print("ERRO: Não foi possível carregar enemy_icon.tscn")
	
	# Conecta aos spawners (indicadores de onda)
	_conectar_spawners()
	get_tree().create_timer(1.0).timeout.connect(_conectar_spawners)
	
	# Conecta às construções (upgrade individual)
	_conectar_construcoes()
	get_tree().node_added.connect(_on_node_added)
	
	if GameManager.has_signal("dia_iniciado"):
		GameManager.dia_iniciado.connect(_ao_iniciar_dia_hud)
	if GameManager.has_signal("noite_iniciada"):
		GameManager.noite_iniciada.connect(_ao_iniciar_noite_hud)
		
	# Instancia a UI de Game Over escondida
	if cena_game_over:
		game_over_instance = cena_game_over.instantiate()
		add_child(game_over_instance)
	else:
		print("ERRO: cena_game_over não atribuída na HUD!")
	
	if cena_vitoria:
		vitoria_instance = cena_vitoria.instantiate()
		add_child(vitoria_instance)
	else:
		print("ERRO: cena_vitoria não atribuída na HUD!")
	
	# Conecta o sinal de morte do GameManager à HUD
	if GameManager.has_signal("game_over"):
		GameManager.game_over.connect(_on_game_over_hud)	

# ==========================================
# CONEXÃO COM CONSTRUÇÕES (UPGRADE INDIVIDUAL)
# ==========================================
func _on_node_added(node: Node):
	if node.is_in_group("Spawner"):
		_conectar_spawners()
	if node.is_in_group("Construcao"):
		_conectar_construcao(node)

func _conectar_construcoes():
	for construcao in get_tree().get_nodes_in_group("Construcao"):
		_conectar_construcao(construcao)

func _conectar_construcao(construcao: Node):
	if not construcao.is_connected("construcao_selecionada", _on_construcao_selecionada):
		construcao.connect("construcao_selecionada", _on_construcao_selecionada)
		print("HUD conectada à construção: ", construcao.name)

func _on_construcao_selecionada(construcao):
	print("Construção selecionada: ", construcao.name)
	
	torre_atual = construcao
	if upgrade_ui_instance:
		print("Chamando upgrade_ui_instance.abrir()")
		upgrade_ui_instance.abrir(construcao)
	else:
		print("ERRO: upgrade_ui_instance é null")

func _on_upgrade_ui_fechado():
	if torre_atual:
		if torre_atual.has_method("esconder_indicador"):
			torre_atual.esconder_indicador()
		torre_atual = null # Limpa a memória para o próximo clique
	
	get_tree().paused = false

# ==========================================
# FUNÇÕES DE DIA/NOITE E MOEDAS
# ==========================================
func verificar_estado_dia_noite():
	if botao_noite != null:
		botao_noite.visible = not GameManager.is_night

func mostrar_wave_na_tela(texto: String):
	if label_wave == null: return
	label_wave.text = texto
	var tween = create_tween()
	tween.tween_property(label_wave, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(label_wave, "modulate:a", 0.0, 1.0)

func atualizar_moedas():
	if label_moedas != null: 
		label_moedas.text = "💰 " + str(GameManager.moedas)

func animar_bau_abrindo():
	if anim_bau != null:
		anim_bau.play("open") 
		await get_tree().create_timer(1.0).timeout 
		anim_bau.play_backwards("open")

# ==========================================
# SISTEMA DE UPGRADE POR CARTAS
# ==========================================
func _on_abrir_menu_upgrade(cartas_sorteadas):
	# ELEVA A HUD INTEIRA PARA COBRIR TUDO
	self.layer = 128 
	
	for crianca in container_cartas.get_children():
		crianca.queue_free()
	
	menu_upgrade.show()
	
	# ESCONDE TUDO QUE PODE BUGAR OU ATRAPALHAR O CURSOR
	if container_direcoes:
		container_direcoes.hide()
	if hud_mobile_completo:
		hud_mobile_completo.hide()
	
	# PAUSAR O JOGO
	get_tree().paused = true
	
	var indice_carta = 0 
	
	for dados in cartas_sorteadas:
		if cena_carta_ui != null:
			var nova_carta = cena_carta_ui.instantiate()
			nova_carta.name = "CartaTutorial" + str(indice_carta)
			indice_carta += 1
			
			container_cartas.add_child(nova_carta)
			
			if nova_carta.has_method("configurar"):
				nova_carta.configurar(dados) 
				
			nova_carta.pressed.connect(_ao_escolher_upgrade.bind(dados))
			
	if botao_reroll != null:
		botao_reroll.disabled = GameManager.reroll_usado
		if GameManager.moedas < GameManager.custo_reroll:
			botao_reroll.modulate = Color(0.5, 0.5, 0.5)
		else:
			botao_reroll.modulate = Color(1, 1, 1)

func _ao_escolher_upgrade(dados):
	GameManager.aplicar_upgrade(dados)
	menu_upgrade.hide()
	
	# REVERTE A CAMADA DA HUD PARA O NORMAL
	self.layer = 1 
	
	# Restaura a visiblidade se estiver de dia
	if container_direcoes and not GameManager.is_night:
		container_direcoes.show()
		margin_direita.show()
	if hud_mobile_completo:
		hud_mobile_completo.show()
		
	get_tree().paused = false

func _on_botao_reroll_pressed():
	GameManager.rerolar_cartas()

# ==========================================
# INDICADORES DE ONDA (CONEXÃO COM SPAWNERS)
# ==========================================
func _conectar_spawners():
	var spawners = get_tree().get_nodes_in_group("Spawner")
	print("HUD: tentando conectar a ", spawners.size(), " spawners")
	for spawner in spawners:
		if not spawner.is_connected("info_proxima_onda", _on_info_spawner):
			spawner.connect("info_proxima_onda", _on_info_spawner)
			print("HUD conectada ao spawner: ", spawner.name)
			spawner.emitir_info()

func _on_info_spawner(direcao: String, inimigos: Array, posicao_mundo: Vector3):
	print("HUD recebeu: direcao=", direcao, " inimigos=", inimigos, " pos=", posicao_mundo)
	
	# Remove container antigo dessa direção
	if containers_por_direcao.has(direcao):
		containers_por_direcao[direcao].queue_free()
		containers_por_direcao.erase(direcao)
	
	# Se não há inimigos ou direção vazia, apenas remove e sai
	if direcao == "" or inimigos.size() == 0:
		return
	
	# Verifica se a cena do ícone está carregada
	if cena_enemy_icon == null:
		print("ERRO: cena_enemy_icon é null")
		return
	
	# Cria container para esta direção
	var container_dir = Control.new()
	container_dir.name = "Direcao_" + direcao
	container_dir.set_meta("posicao_mundo", posicao_mundo) # Adicione esta linha 
	container_direcoes.add_child(container_dir)
	
	# Define se os ícones serão empilhados na horizontal ou vertical dependendo da direção
	var tamanho_real = tamanho_container
	var box = null
	if direcao == "Leste" or direcao == "Oeste":
		tamanho_real = Vector2(tamanho_container.y, tamanho_container.x)
		box = HBoxContainer.new()
	else:
		box = VBoxContainer.new()
	
	# Calcula posição na borda
	var pos_tela = _calcular_posicao_borda(posicao_mundo, tamanho_real)
	container_dir.position = pos_tela
	container_dir.size = tamanho_real
	
	# Configura o container para empilhar os ícones
	box.size = tamanho_real
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	container_dir.add_child(box)
	
	# Adiciona os ícones dos inimigos
	for info in inimigos:
		var icon = cena_enemy_icon.instantiate()
		box.add_child(icon)
		if icon.has_method("configurar"):
			icon.configurar(info.get("icone"), info.get("cor"), info.qtd)
		else:
			print("ERRO: enemy_icon não tem método configurar")
	
	# Armazena referência
	containers_por_direcao[direcao] = container_dir
	print("Container criado para ", direcao, " com ", inimigos.size(), " ícones")

func _calcular_posicao_borda(posicao_mundo: Vector3, tamanho: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(100, 100)
	
	var pos_tela = camera.unproject_position(posicao_mundo)
	var viewport_size = get_viewport().get_visible_rect().size
	var centro = viewport_size / 2
	
	var dir = pos_tela - centro
	if dir.length() < 0.001:
		dir = Vector2(0, -1)
	
	dir = dir.normalized()
	
	var t_x = INF
	var t_y = INF
	if dir.x > 0:
		t_x = (viewport_size.x - centro.x) / dir.x
	elif dir.x < 0:
		t_x = -centro.x / dir.x
	
	if dir.y > 0:
		t_y = (viewport_size.y - centro.y) / dir.y
	elif dir.y < 0:
		t_y = -centro.y / dir.y
	
	var t = min(t_x, t_y)
	var ponto_borda = centro + dir * t
	
	# Margens de segurança customizadas para evitar sobreposição com os elementos de interface
	var margem_topo: float = 200.0
	var margem_baixo: float = 120.0
	var margem_esq: float = 120.0
	var margem_dir: float = 280.0
	
	var metade = tamanho / 2
	var min_x = metade.x + margem_esq
	var max_x = viewport_size.x - metade.x - margem_dir
	var min_y = metade.y + margem_topo
	var max_y = viewport_size.y - metade.y - margem_baixo
	
	ponto_borda.x = clamp(ponto_borda.x, min_x, max_x)
	ponto_borda.y = clamp(ponto_borda.y, min_y, max_y)
	
	return ponto_borda - metade

# Atualiza os rótulos de texto, inicia a transição visual e exibe os controles de preparação
# Atualiza os rótulos de texto, inicia a transição visual e exibe os controles de preparação
func _ao_iniciar_dia_hud(onda: int) -> void:
	label_onda.text = "ONDA " + str(onda)
	label_turno.text = "DIA"
	_animar_transicao_ampulheta(true)
	
	# SÓ MOSTRA SE O MENU DE UPGRADE NÃO ESTIVER VISÍVEL (Evita o bug na pausa)
	if container_direcoes and not menu_upgrade.visible:
		container_direcoes.show()
	if margin_direita and not menu_upgrade.visible:
		margin_direita.show()

# Atualiza os rótulos de texto, inicia a transição visual e oculta os controles de preparação
func _ao_iniciar_noite_hud(onda: int) -> void:
	label_onda.text = "ONDA " + str(onda)
	label_turno.text = "NOITE"
	_animar_transicao_ampulheta(false)
	
	if container_direcoes:
		container_direcoes.hide()
	if margin_direita:
		margin_direita.hide()

# Executa a animação de rotação e distorção ("smear") da ampulheta.
# A troca entre as texturas ocorre instantaneamente no meio da rotação para mascarar a mudança.
func _animar_transicao_ampulheta(indo_para_dia: bool) -> void:
	# Define o ponto de origem da rotação e escala para o centro absoluto do controle
	pivot_ampulheta.pivot_offset = pivot_ampulheta.size / 2.0
	
	# Calcula a rotação alvo (gira 180 graus / PI radianos a partir da rotação atual)
	var rotacao_alvo = pivot_ampulheta.rotation + PI  * 2
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animação principal de rotação (0.5 segundos de duração para esconder troca de imagens)
	tween.tween_property(pivot_ampulheta, "rotation", rotacao_alvo, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	# Efeito "Smear": Estica a ampulheta no eixo Y durante a primeira metade do giro
	tween.tween_property(pivot_ampulheta, "scale", Vector2(0.9, 1.1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Retorna a ampulheta ao tamanho normal na segunda metade do giro
	tween.chain().tween_property(pivot_ampulheta, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Lógica paralela para gerenciar a visibilidade (Alpha) das texturas no meio do giro (0.25s)
	var tween_fade = create_tween()
	tween_fade.tween_interval(0.25) 
	if indo_para_dia:
		tween_fade.tween_property(ampulheta_noite, "modulate:a", 0.0, 0.0)
		tween_fade.tween_property(ampulheta_dia, "modulate:a", 1.0, 0.0)
	else:
		tween_fade.tween_property(ampulheta_dia, "modulate:a", 0.0, 0.0)
		tween_fade.tween_property(ampulheta_noite, "modulate:a", 1.0, 0.0)

func _process(_delta: float) -> void:
	if menu_upgrade.visible:
		return
		
	for direcao in containers_por_direcao:
		var container = containers_por_direcao[direcao]
		
		# Verifica se o container ainda é válido antes de atualizar
		if is_instance_valid(container) and container.has_meta("posicao_mundo"):
			var pos_mundo = container.get_meta("posicao_mundo")
			# Recalcula a posição com base no tamanho atual da tela utilizando o tamanho dinâmico do container
			container.position = _calcular_posicao_borda(pos_mundo, container.size)
			
			# Calcula a rotação da seta apontando para a posição real do spawner
			var camera = get_viewport().get_camera_3d()
			if camera:
				var pos_tela = camera.unproject_position(pos_mundo)
				var centro = get_viewport().get_visible_rect().size / 2.0
				var dir_vetor = (pos_tela - centro).normalized()
				var angulo = dir_vetor.angle()
				
				# Atualiza a rotação da seta nos ícones filhos deste container
				var box = container.get_child(0)
				if box:
					for icon in box.get_children():
						if icon.has_method("atualizar_seta"):
							icon.atualizar_seta(angulo)
							
# ==========================================
# EVENTOS DE GAME OVER
# ==========================================
func _on_game_over_hud():
	if game_over_instance and game_over_instance.has_method("mostrar"):
		game_over_instance.mostrar()
