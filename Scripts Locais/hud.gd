extends CanvasLayer

#OBS.: NÃO MOVER PARA CIMA DO TUTORIALMANAGER, QUEBRA NA HORA A LÓGICA DE MOVIMENTAÇÃO DO PERSONAGEM
# E EU NÂO TENHO A MENOR IDEIA DO POR QUÊ

const _ScriptPainelConselheiro = preload("res://UI/HUD/painel_conselheiro.gd")
const _CenaMenuPausa = preload("res://UI/Menus/menu_pausa.tscn")
const _TexBauFechado = preload("res://Assets/UI/BauFechado.png")
const _TexBauAberto = preload("res://Assets/UI/BauAberto.png")
const _TexBotaoMenu = preload("res://Assets/UI/BotaoMenu.png")

var _menu_pausa_inst = null

# ==========================================
# REFERÊNCIAS DA INTERFACE PRINCIPAL
# ==========================================
@onready var hud_mobile_completo = $InterfacePrincipal/HudMobileCompleto
@onready var label_wave = $InterfacePrincipal/CentroTela/LabelWave
@onready var label_moedas = $InterfacePrincipal/MarginDireita/VBoxDireita/FundoMoedas/LabelMoedas
@onready var margin_direita = $InterfacePrincipal/MarginDireita
@export var cena_carta_ui: PackedScene

@onready var imagem_bau: TextureRect = $InterfacePrincipal/MarginDireita/VBoxDireita/ContainerBau/BauIcon

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

var containers_por_spawner = {}
# ==========================================
# UI DE UPGRADE INDIVIDUAL (PATHS)
# ==========================================
@export var upgrade_ui_scene: PackedScene          # Arraste a cena UpgradeUI.tscn aqui
@export var cena_opcao_button: PackedScene         # Arraste a cena OpcaoUpgradeButton.tscn aqui
var upgrade_ui_instance: Control = null
var torre_atual = null
var label_renda_preview: Label = null
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
	
	# Se certificando que o filtro de mouse não ira impedir o cursor mudar ao dar hover nas construções
	var centro_tela = $InterfacePrincipal/CentroTela
	if centro_tela != null:
		centro_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ele é "Pass" por padrão no filter
	
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
		botao_reroll.custom_minimum_size = Vector2(220, 56)
	if container_cartas != null:
		container_cartas.mouse_filter = Control.MOUSE_FILTER_PASS
	
	atualizar_moedas()
	_criar_label_renda_preview()
	if label_onda:
		label_onda.text = _formatar_texto_onda(GameManager.onda_atual)
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
	if GameManager.has_signal("renda_recolhida"):
		GameManager.renda_recolhida.connect(_mostrar_moedas_flutuante)
	if Global.has_signal("progresso_salvo"):
		Global.progresso_salvo.connect(_mostrar_confirmacao_save)
		
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

	# Painel do conselheiro IA (canto inferior esquerdo)
	if not get_node_or_null("PainelConselheiro"):
		var painel_conselheiro = _ScriptPainelConselheiro.new()
		painel_conselheiro.name = "PainelConselheiro"
		add_child(painel_conselheiro)

	# Menu de pausa (botão + instância)
	_instanciar_menu_pausa()
	_criar_botao_pausa()

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
		# A nossa trava de segurança para quando recarregar o save
		if not GameManager.is_night:
			Engine.time_scale = 1.0      # Garante que o jogo não está acelerado

func mostrar_wave_na_tela(texto: String):
	if label_wave == null: return
	label_wave.text = texto
	var tween = create_tween()
	tween.tween_property(label_wave, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(label_wave, "modulate:a", 0.0, 1.0)

func _criar_label_renda_preview() -> void:
	if label_moedas == null:
		return
	label_renda_preview = Label.new()
	label_renda_preview.add_theme_font_size_override("font_size", 14)
	label_renda_preview.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20, 0.6))
	label_renda_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_renda_preview.size_flags_horizontal = Control.SIZE_SHRINK_END
	label_moedas.get_parent().add_child(label_renda_preview)
	_atualizar_renda_preview()

func _atualizar_renda_preview() -> void:
	if label_renda_preview == null:
		return
	if GameManager.is_night:
		label_renda_preview.hide()
		return
	label_renda_preview.show()
	label_renda_preview.text = "(+%d)" % GameManager.get_renda_preview()

func atualizar_moedas():
	if label_moedas != null:
		label_moedas.text = "🪙 " + str(GameManager.moedas)
	_atualizar_renda_preview()

func animar_bau_abrindo():
	if imagem_bau != null:
		imagem_bau.texture = _TexBauAberto
		var tween := create_tween()
		tween.tween_property(imagem_bau, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(imagem_bau, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(1.0).timeout
		imagem_bau.texture = _TexBauFechado

# ==========================================
# SISTEMA DE UPGRADE POR CARTAS
# ==========================================
func _on_abrir_menu_upgrade(cartas_sorteadas):
	# Durante tutorial o TutorialManager (layer 128) deve ficar acima das cartas
	# para que o fundo_escuro bloqueie cliques acidentais.
	self.layer = 64 if GameManager.is_tutorial_ativo else 128

	for crianca in container_cartas.get_children():
		crianca.queue_free()

	# ESCONDE TUDO QUE PODE BUGAR OU ATRAPALHAR O CURSOR
	if container_direcoes:
		container_direcoes.hide()
	if hud_mobile_completo:
		hud_mobile_completo.hide()

	# Força o baú visível e anima ANTES de abrir o menu
	if margin_direita:
		margin_direita.show()
	await animar_bau_abrindo()

	# Só agora abre o menu com as cartas
	menu_upgrade.show()
	# Aguarda um frame para o layout recalcular antes de adicionar as cartas
	await get_tree().process_frame

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

func _on_info_spawner(id_spawner, direcao, inimigos, posicao_mundo):
	print("HUD recebeu: ", id_spawner)

	# remove indicador antigo
	if containers_por_spawner.has(id_spawner):
		var antigo = containers_por_spawner[id_spawner]

		if is_instance_valid(antigo):
			antigo.queue_free()

		containers_por_spawner.erase(id_spawner)

	# sem inimigos -> remove e sai
	if direcao == "" or inimigos.size() == 0:
		return

	# segurança
	if cena_enemy_icon == null:
		print("ERRO: cena_enemy_icon é null")
		return

	# cria container
	var container_dir = Control.new()
	container_dir.name = "Direcao_" + str(id_spawner)

	container_dir.set_meta("posicao_mundo", posicao_mundo)
	container_dir.set_meta("direcao", direcao)

	container_direcoes.add_child(container_dir)

	# layout
	var tamanho_real = tamanho_container
	var box = null
	
	if direcao in ["Leste", "Oeste", "Nordeste", "Noroeste", "Sudeste", "Sudoeste"]:
		tamanho_real = Vector2(tamanho_container.x, tamanho_container.y)
		box = VBoxContainer.new()
	else:
		box = HBoxContainer.new()

	# posição
	var pos_tela = _calcular_posicao_borda(
		posicao_mundo,
		tamanho_real
	)

	container_dir.position = pos_tela
	container_dir.size = tamanho_real
	container_dir.pivot_offset = tamanho_real * 0.5

	# box
	box.size = tamanho_real
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)

	container_dir.add_child(box)

	# ícones
	for info in inimigos:
		var icon = cena_enemy_icon.instantiate()

		box.add_child(icon)

		if icon.has_method("configurar"):
			icon.configurar(
				info.get("icone"),
				info.get("cor"),
				info.get("qtd", 1),
				info.get("descricao", "")
			)

	# salva
	containers_por_spawner[id_spawner] = container_dir



func _calcular_posicao_borda(posicao_mundo: Vector3, tamanho: Vector2) -> Vector2:
	var cam = get_viewport().get_camera_3d()
	if cam == null: return Vector2.ZERO

	var vp_rect = get_viewport().get_visible_rect()
	var vp_size = vp_rect.size
	var centro = vp_size * 0.5
	
	# Projeta a posição 3D para a tela 2D
	var pos_tela = cam.unproject_position(posicao_mundo)
	var esta_atras = cam.is_position_behind(posicao_mundo)
	
	# Margem de segurança para considerar "fora da tela"
	var margem_interna = 50.0 
	var limite_tela = vp_rect.grow(-margem_interna)

	# SE estiver na frente da câmera E dentro dos limites da tela, retorna a posição real
	if not esta_atras and limite_tela.has_point(pos_tela):
		return pos_tela - (tamanho * 0.5)

	# CASO CONTRÁRIO (está fora ou atrás), aplicamos a lógica de borda
	var dir = (pos_tela - centro).normalized()
	if esta_atras:
		dir = -dir # Inverte se estiver atrás para a seta apontar corretamente

	# Cálculo de intersecção com a borda (retângulo)
	var escala_x = (vp_size.x * 0.5 - margem_borda) / abs(dir.x) if abs(dir.x) > 0.001 else INF
	var escala_y = (vp_size.y * 0.5 - margem_borda) / abs(dir.y) if abs(dir.y) > 0.001 else INF
	var escala = min(escala_x, escala_y)

	var pos_final = centro + dir * escala
	return pos_final - (tamanho * 0.5)

# Atualiza os rótulos de texto, inicia a transição visual e exibe os controles de preparação
# Atualiza os rótulos de texto, inicia a transição visual e exibe os controles de preparação
func _ao_iniciar_dia_hud(onda: int) -> void:
	label_onda.text = _formatar_texto_onda(onda)
	label_turno.text = "DIA"
	_animar_transicao_ampulheta(true)
	
	# SÓ MOSTRA SE O MENU DE UPGRADE NÃO ESTIVER VISÍVEL (Evita o bug na pausa)
	if container_direcoes and not menu_upgrade.visible:
		container_direcoes.show()
	if margin_direita and not menu_upgrade.visible:
		margin_direita.show()
	_atualizar_renda_preview()

# Atualiza os rótulos de texto, inicia a transição visual e oculta os controles de preparação
func _ao_iniciar_noite_hud(onda: int) -> void:
	label_onda.text = _formatar_texto_onda(onda)
	label_turno.text = "NOITE"
	_animar_transicao_ampulheta(false)

	if container_direcoes:
		container_direcoes.hide()
	if margin_direita:
		margin_direita.hide()
	_atualizar_renda_preview()

# Executa a animação de rotação e distorção ("smear") da ampulheta.
# A troca entre as texturas ocorre instantaneamente no meio da rotação para mascarar a mudança.
func _formatar_texto_onda(onda: int) -> String:
	if GameManager.modo_infinito:
		return "ONDA " + str(onda)

	var ultima_onda := Balanceamento.get_int("ultima_onda", 10)
	if GameManager.is_tutorial_ativo:
		ultima_onda = Balanceamento.get_int("tutorial_ultima_onda", 5)
	else:
		var chave_fase := "fase_%d_ultima_onda" % GameManager.fase_atual
		ultima_onda = Balanceamento.get_int(chave_fase, ultima_onda)

	return "ONDA %d/%d" % [onda, ultima_onda]

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

	var centro = get_viewport().get_visible_rect().size / 2.0

	for id_spawner in containers_por_spawner:
		var container = containers_por_spawner[id_spawner]

		if not is_instance_valid(container):
			continue

		if not container.has_meta("posicao_mundo"):
			continue

		var pos_mundo: Vector3 = container.get_meta("posicao_mundo")

		# atualiza posição do indicador
		container.position = _calcular_posicao_borda(
			pos_mundo,
			tamanho_container
		)

		# centro real do indicador
		var pos_indicador = container.position + (tamanho_container * 0.5)

		# direção da seta
		var dir_vetor = (pos_indicador - centro).normalized()

		var angulo = dir_vetor.angle()

		# pega VBox OU HBox
		var box = null

		for child in container.get_children():
			if child is VBoxContainer or child is HBoxContainer:
				box = child
				break

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

# ==========================================
# LABEL FLUTUANTE DE MOEDAS
# ==========================================
func _mostrar_moedas_flutuante(total: int) -> void:
	if label_moedas == null:
		return
	var lbl := Label.new()
	lbl.text = "+%d 🪙" % total
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_pos: Vector2 = label_moedas.get_global_rect().get_center()
	lbl.position = base_pos + Vector2(-30, 0)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 70, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)

# ==========================================
# CONFIRMAÇÃO VISUAL DE SAVE
# ==========================================
func _mostrar_confirmacao_save() -> void:
	var lbl := Label.new()
	lbl.text = "✓ Progresso salvo"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.anchor_left   = 0.5
	lbl.anchor_right  = 0.5
	lbl.anchor_top    = 0.0
	lbl.anchor_bottom = 0.0
	lbl.offset_left   = -100
	lbl.offset_right  = 100
	lbl.offset_top    = 6
	lbl.offset_bottom = 30
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(lbl.queue_free)

# ==========================================
# MENU DE PAUSA
# ==========================================
func _instanciar_menu_pausa():
	_menu_pausa_inst = _CenaMenuPausa.instantiate()
	add_child(_menu_pausa_inst)

func _criar_botao_pausa():
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.text = ""
	btn.icon = _TexBotaoMenu
	btn.expand_icon = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.anchor_left   = 1.0
	btn.anchor_right  = 1.0
	btn.anchor_top    = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left   = -70
	btn.offset_right  = -70
	btn.offset_top    = 14
	btn.offset_bottom = 70

	var st := StyleBoxEmpty.new()
	var st_hover := StyleBoxEmpty.new()

	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st_hover)
	btn.add_theme_stylebox_override("pressed", st)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		if is_instance_valid(_menu_pausa_inst):
			_menu_pausa_inst._abrir()
	)
	add_child(btn)
