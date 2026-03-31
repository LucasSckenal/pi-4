extends Node3D

@export var conquista_sobreviver_onda: ConquistaData
@export var conquista_fim_tutorial: ConquistaData

@onready var tutorial = $TutorialManager
@onready var anim_player = $DayNightAnimator

# Referências dos slots (todas as quatro construções)
@onready var slot_torre_1 = $BuildSlots/BuildSlot
@onready var slot_torre_2 = $BuildSlots/BuildSlot2
@onready var slot_casa_1 = $BuildSlots/BuildSlot11   # casa da frente (não usada no tutorial)
@onready var slot_casa_2 = $BuildSlots/BuildSlot12    # casa segura (atrás)
@onready var castelo = $"NavigationRegion3D/building-castle2"
@onready var slot_quartel = $BuildSlots/BuildSlot24
@onready var ponto_defesa = $PontoDefesaPlayer   # Pode ser Marker3D

# Referências das construções que serão criadas
var torre_1: Node3D = null
var torre_2: Node3D = null
var casa_2: Node3D = null
var quartel: Node3D = null

func _ready():
	get_tree().paused = false
	
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	
	await get_tree().process_frame
	
	GameManager.carregar_fase(1)
	if GameManager.is_tutorial_ativo:
		iniciar_sequencia_tutorial()

func iniciar_sequencia_tutorial():
	# ------------------------------------------------------------
	# DIA 1 – Chegada e primeiras construções
	# ------------------------------------------------------------
	
	await tutorial.mostrar_dialogo("Afonso: Minhas costas... Berta, onde viemos parar?! Levaram nossos netos pra dentro desse jogo!")
	await tutorial.mostrar_dialogo("Berta: Calma, Afonso. Olha aqueles ícones ali embaixo. De noite, monstros verdes vão sair dali e vão tentar destruir tudo até chegar no nosso Castelo.")
	
	torre_1 = await passo_construcao(slot_torre_1, 0, "Berta: Afonso, constrói a primeira Torre aqui!")
	torre_2 = await passo_construcao(slot_torre_2, 0, "Berta: Outra torre para reforçar a entrada.")
	
	await tutorial.mostrar_dialogo("Afonso: Legal, mas olha esse menu! Dá pra fazer uma Casa por só 2 moedas. O tabuleiro diz que ela gera ouro todo dia. Eu adoro um bom investimento!")
	await tutorial.mostrar_dialogo("Berta: Tá bom, mas não coloca na frente! Aqueles bichos destroem as casas. Constrói lá atrás, perto do Castelo, onde é seguro!")
	
	casa_2 = await passo_construcao(slot_casa_2, 1, "Afonso: Vou fazer uma Casa aqui para ganhar ouro.")
	
	# Botão "Iniciar Noite"
	var btn_noite = get_tree().get_first_node_in_group("BotaoIniciarNoite")
	while btn_noite == null:
		if not GameManager.is_tutorial_ativo: break
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(btn_noite, "Berta: Tudo pronto! Clica aqui para começar!")
	
	# ------------------------------------------------------------
	# NOITE 1 – Foco no ponto de defesa
	# ------------------------------------------------------------
	tutorial.visible = true
	tutorial.fundo_escuro.visible = true
	tutorial.alvo_3d_atual = ponto_defesa
	tutorial.configurar_dialogo("Afonso: Vou lutar ali com a minha espada onde as torres não chegam!")
	
	# Encontra o jogador (grupo "Player")
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_tree().root.find_child("Player", true, false)
	
	await get_tree().create_timer(1.5).timeout  # tempo para ver a seta
	
	var player_chegou = false
	var tempo_espera = 0.0
	var raio_chegada = 5.0
	
	while not player_chegou and tempo_espera < 15.0:
		if not GameManager.is_tutorial_ativo: break
		if player and player.global_position.distance_to(ponto_defesa.global_position) < raio_chegada:
			player_chegou = true
			print("Jogador chegou ao ponto de defesa!")
		await get_tree().create_timer(0.1).timeout
		tempo_espera += 0.1
	
	tutorial.esconder()
	
	# Aguarda o fim da noite
	await GameManager.dia_iniciado
	
	# ------------------------------------------------------------
	# DIA 2 – Carta, Upgrade do Castelo e Quartel
	# ------------------------------------------------------------
	await tutorial.mostrar_dialogo("Afonso: Sobrevivemos! E olha o dinheiro entrando! Agora já posso construir o Quartel pra chamar soldados!")
	await tutorial.mostrar_dialogo("Berta: Ainda não. O Quartel é Nível 1. Nosso Castelo é Nível 0. Precisamos gastar 5 moedas pra evoluir ele primeiro.")
	
	var carta = get_tree().root.find_child("CartaTutorial0", true, false)
	while carta == null:
		if not GameManager.is_tutorial_ativo: break
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(carta, "Escolha esta carta de ajuda.")
	
	# Upgrade do Castelo usando passo_upgrade (mais confiável)
	await passo_upgrade(castelo, "Afonso: Toca no Castelo para melhorá-lo.")
	
	await tutorial.mostrar_dialogo("Berta: Pronto! Agora a escolha é sua, Afonso. Posiciona o Quartel e vamos salvar nossos netos!")
	
	quartel = await passo_construcao(slot_quartel, 4, "Constrói o Quartel neste novo lote!")
	
	# ------------------------------------------------------------
	# NOITE 2 – (aguarda outra noite para preparar upgrades)
	# ------------------------------------------------------------
	await tutorial.mostrar_dialogo("Agora que temos um exército, precisamos fortalecer nossas defesas para a próxima noite.")
	
	var btn_noite2 = get_tree().get_first_node_in_group("BotaoIniciarNoite")
	while btn_noite2 == null:
		if not GameManager.is_tutorial_ativo: break
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(btn_noite2, "Clique para iniciar a próxima noite.")
	
	# Aguarda o fim da noite
	await GameManager.dia_iniciado
	
	# ------------------------------------------------------------
	# DIA 3 – Upgrades (Torre com paths, Casa linear)
	# ------------------------------------------------------------
	await tutorial.mostrar_dialogo("Chegou o dia! Agora podemos melhorar nossas construções.")
	
	# Upgrade na torre (dois paths)
	await passo_upgrade(torre_1, "Clique na torre para abrir o menu de upgrade. Ela tem dois caminhos: escolha um!")
	
	# Upgrade na casa (linear)
	await passo_upgrade(casa_2, "Agora clique na casa. Ela tem apenas um upgrade linear.")
	
	# Final do tutorial
	GameManager.is_tutorial_ativo = false
	print("✅ Tutorial Completo")
	if conquista_fim_tutorial:
		Global.processar_recompensa(conquista_fim_tutorial)

# ==========================================
# FUNÇÕES AUXILIARES
# ==========================================

# Aguarda a construção aparecer no slot e retorna sua referência
func aguardar_construcao_no_slot(slot: Node3D, timeout: float = 5.0) -> Node3D:
	var tempo = 0.0
	while tempo < timeout:
		if not GameManager.is_tutorial_ativo: return null
		var c = get_construcao_no_slot(slot)
		if c:
			return c
		await get_tree().create_timer(0.1).timeout
		tempo += 0.1
	push_error("Timeout aguardando construção no slot: ", slot.name)
	return null

# Retorna a construção que está na posição do slot (procurando no grupo "Construcao")
func get_construcao_no_slot(slot: Node3D) -> Node3D:
	var construcoes = get_tree().get_nodes_in_group("Construcao")
	for c in construcoes:
		if c.global_position.distance_to(slot.global_position) < 1.0:
			return c
	return null

# Passo de construção: foca no slot, clica no botão e retorna a construção criada
func passo_construcao(slot, indice_botao, texto) -> Node3D:
	if not GameManager.is_tutorial_ativo: return null
	await tutorial.focar_em_slot_3d(slot, texto)
	while slot.get("ui_atual") == null:
		if not GameManager.is_tutorial_ativo: return null
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(slot.ui_atual._botoes_ativos[indice_botao], "Escolha a construção.")
	var construcao = await aguardar_construcao_no_slot(slot)
	return construcao

# Passo de upgrade: foca na construção, aguarda a UI abrir e o upgrade ser concluído
func passo_upgrade(construcao: Node3D, texto: String):
	if not GameManager.is_tutorial_ativo: return
	var hud = get_tree().get_first_node_in_group("Interface")
	if not hud:
		push_error("HUD não encontrada")
		return
	
	# Acessa a instância da UI de upgrade diretamente da HUD (variável pública)
	var upgrade_ui = hud.upgrade_ui_instance
	if not upgrade_ui:
		push_error("UI de upgrade não encontrada na HUD")
		return
	
	var upgrade_feito = false
	var tentativas = 0
	while not upgrade_feito and tentativas < 3:
		tentativas += 1
		print("Tentativa ", tentativas, " de upgrade para ", construcao.name)
		
		# Foca na construção e aguarda o clique
		await tutorial.focar_em_slot_3d(construcao, texto)
		var nivel_antes = construcao.nivel_atual
		print("Nível antes: ", nivel_antes)
		
		# Aguarda a UI ficar visível (com timeout)
		var tempo_ui = 0.0
		while not upgrade_ui.visible and tempo_ui < 5.0:
			if not GameManager.is_tutorial_ativo: return
			await get_tree().create_timer(0.1).timeout
			tempo_ui += 0.1
		
		if not upgrade_ui.visible:
			print("UI de upgrade não apareceu. Tentando novamente.")
			continue
		
		# Aguarda o sinal de fechamento da UI (resposta imediata)
		await upgrade_ui.fechado
		print("Sinal fechado recebido")
		
		# Verifica se o nível aumentou
		print("Nível depois: ", construcao.nivel_atual)
		if construcao.nivel_atual > nivel_antes:
			upgrade_feito = true
			print("Upgrade realizado com sucesso!")
		else:
			print("Upgrade não realizado. Tentativa ", tentativas, " de 3.")
			if tentativas < 3:
				await tutorial.mostrar_dialogo("Você precisa escolher um upgrade! Tente novamente.")
	
	if not upgrade_feito:
		push_warning("Jogador não conseguiu fazer o upgrade após várias tentativas. Prosseguindo.")

# Executa a transição de iluminação e ambiente para o ciclo do dia
func _on_dia_iniciado(_onda_atual: int) -> void:
	print("Dia iniciado!!!!")
	if anim_player and anim_player.has_animation("transicao_para_dia"):
		anim_player.play("transicao_para_dia")
		
	if _onda_atual == 2 and conquista_sobreviver_onda:
		Global.processar_recompensa(conquista_sobreviver_onda)

# Executa a transição de iluminação e ambiente para o ciclo da noite
func _on_noite_iniciada(_onda_atual: int) -> void:
	print("Noite iniciada!!!!")
	if anim_player and anim_player.has_animation("transicao_para_noite"):
		anim_player.play("transicao_para_noite")
