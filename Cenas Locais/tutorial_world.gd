extends Node3D

@onready var tutorial = $TutorialManager

# Referências dos slots
@onready var slot_torre_1 = $BuildSlots/BuildSlot12
@onready var slot_torre_2 = $BuildSlots/BuildSlot
@onready var slot_casa_1 = $BuildSlots/BuildSlot11
@onready var slot_casa_2 = $BuildSlots/BuildSlot7
@onready var castelo = $"NavigationRegion3D/building-castle2"
@onready var slot_quartel = $BuildSlots/BuildSlot24
@onready var ponto_defesa = $PontoDefesaPlayer   # Pode ser Marker3D

func _ready():
	GameManager.carregar_fase(1)
	if GameManager.is_tutorial_ativo:
		iniciar_sequencia_tutorial()

func iniciar_sequencia_tutorial():
	# DIA 1
	await tutorial.mostrar_dialogo("Afonso: Minhas costas... Berta, onde viemos parar?! Levaram nossos netos pra dentro desse jogo!")
	await tutorial.mostrar_dialogo("Berta: Calma, Afonso. Olha aqueles ícones ali embaixo. De noite, monstros verdes vão sair dali e vão tentar destruir tudo até chegar no nosso Castelo.")
	
	await passo_construcao(slot_torre_1, 0, "Berta: Afonso, constrói a primeira Torre aqui!")
	await passo_construcao(slot_torre_2, 0, "Berta: Outra torre para reforçar a entrada.")
	
	await tutorial.mostrar_dialogo("Afonso: Legal, mas olha esse menu! Dá pra fazer uma Casa por só 2 moedas. O tabuleiro diz que ela gera ouro todo dia. Eu adoro um bom investimento!")
	await tutorial.mostrar_dialogo("Berta: Tá bom, mas não coloca na frente! Aqueles bichos destroem as casas. Constrói lá atrás, perto do Castelo, onde é seguro!")
	
	await passo_construcao(slot_casa_2, 1, "Afonso: Vou fazer uma Casa aqui para ganhar ouro.")
	
	var btn_noite = get_tree().get_first_node_in_group("BotaoIniciarNoite")
	while btn_noite == null:
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(btn_noite, "Berta: Tudo pronto! Clica aqui para começar!")
	
	# NOITE
	tutorial.visible = true
	tutorial.fundo_escuro.visible = true
	tutorial.alvo_3d_atual = ponto_defesa
	tutorial.configurar_dialogo("Afonso: Vou lutar ali com a minha espada onde as torres não chegam!")
	
	# Encontra o jogador
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_tree().root.find_child("Player", true, false)
	
	# Aguarda 1.5 segundos para o jogador ver a seta antes de começar a verificar
	await get_tree().create_timer(1.5).timeout
	
	var player_chegou = false
	var tempo_espera = 0.0
	var raio_chegada = 5.0
	
	while not player_chegou and tempo_espera < 15.0:
		if player and player.global_position.distance_to(ponto_defesa.global_position) < raio_chegada:
			player_chegou = true
			print("Jogador chegou ao ponto de defesa!")
		await get_tree().create_timer(0.1).timeout
		tempo_espera += 0.1
	
	tutorial.esconder()
	
	# Aguarda o fim da noite
	await GameManager.dia_iniciado
	
	# DIA 2
	await tutorial.mostrar_dialogo("Afonso: Sobrevivemos! E olha o dinheiro entrando! Agora já posso construir o Quartel pra chamar soldados!")
	await tutorial.mostrar_dialogo("Berta: Ainda não. O Quartel é Nível 1. Nosso Castelo é Nível 0. Precisamos gastar 5 moedas pra evoluir ele primeiro.")
	
	var carta = get_tree().root.find_child("CartaTutorial0", true, false)
	while carta == null:
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(carta, "Escolha esta carta de ajuda.")
	
	await tutorial.focar_em_slot_3d(castelo, "Afonso: Toca no Castelo para melhorá-lo.")
	var btn_up = get_tree().root.find_child("Upgrade", true, false)
	while btn_up == null:
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(btn_up, "Clica em Upgrade!")
	
	await tutorial.mostrar_dialogo("Berta: Pronto! Agora a escolha é sua, Afonso. Posiciona o Quartel e vamos salvar nossos netos!")
	
	await tutorial.focar_em_slot_3d(slot_quartel, "Constrói o Quartel neste novo lote!")
	while slot_quartel.get("ui_atual") == null:
		await get_tree().create_timer(0.01).timeout
	var btn_quartel = slot_quartel.ui_atual._botoes_ativos[4]
	await tutorial.focar_em_ui_2d(btn_quartel, "O Quartel vai dar-nos soldados!")
	
	GameManager.is_tutorial_ativo = false
	print("✅ Tutorial Completo")

func passo_construcao(slot, indice_botao, texto):
	await tutorial.focar_em_slot_3d(slot, texto)
	while slot.get("ui_atual") == null:
		await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(slot.ui_atual._botoes_ativos[indice_botao], "Escolha a construção.")
