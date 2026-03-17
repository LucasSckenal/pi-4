extends Node3D

@onready var tutorial = $TutorialManager

# ==========================================
# NÓS DO TUTORIAL
# ==========================================
@onready var slot_torre_1 = $BuildSlots/BuildSlot12
@onready var slot_torre_2 = $BuildSlots/BuildSlot
@onready var slot_casa_1 = $BuildSlots/BuildSlot11  
@onready var slot_casa_2 = $BuildSlots/BuildSlot7  

@onready var castelo = $"NavigationRegion3D/building-castle2"      
@onready var slot_quartel = $BuildSlots/BuildSlot24

# ==========================================
# INÍCIO DO JOGO
# ==========================================
func _ready():
	GameManager.carregar_fase(1)
	
	if GameManager.is_tutorial_ativo:
		iniciar_sequencia_tutorial()

# ==========================================
# O GUIÃO DO TUTORIAL
# ==========================================
func iniciar_sequencia_tutorial():
	print("🎬 INICIANDO O TUTORIAL - DIA 1")
	
	# --- DIA 1: CONSTRUINDO AS TORRES ---
	await tutorial.focar_em_slot_3d(slot_torre_1, "Avó Berta: Afonso, esses monstros vão atacar à noite! Toca neste lote para construir uma Torre.")
	await get_tree().create_timer(0.2).timeout # Aguarda o menu abrir
	
	# Procura o botão no menu radial pelo nome ou pela lista ativa
	var botao_torre1 = slot_torre_1.ui_atual._botoes_ativos[0] if slot_torre_1.ui_atual else null
	if botao_torre1:
		await tutorial.focar_em_ui_2d(botao_torre1, "Avó Berta: Escolhe a Torre de Defesa. Ela vai segurar o avanço deles!")
	await get_tree().create_timer(0.5).timeout
	
	await tutorial.focar_em_slot_3d(slot_torre_2, "Avó Berta: Precisamos de mais proteção. Constrói outra Torre neste lote ao lado.")
	await get_tree().create_timer(0.2).timeout 
	var botao_torre2 = slot_torre_2.ui_atual._botoes_ativos[0] if slot_torre_2.ui_atual else null
	if botao_torre2:
		await tutorial.focar_em_ui_2d(botao_torre2, "Avó Berta: Escolhe a Torre de Defesa novamente.")
	await get_tree().create_timer(0.5).timeout


	# --- DIA 1: CONSTRUINDO AS CASAS (ECONOMIA) ---
	await tutorial.focar_em_slot_3d(slot_casa_1, "Afonso: E o nosso dinheiro? Precisamos investir! Vou construir uma Casa aqui atrás.")
	await get_tree().create_timer(0.2).timeout
	var botao_casa1 = slot_casa_1.ui_atual._botoes_ativos[1] if slot_casa_1.ui_atual else null
	if botao_casa1:
		await tutorial.focar_em_ui_2d(botao_casa1, "Afonso: As Casas geram dinheiro todas as manhãs!")
	await get_tree().create_timer(0.5).timeout

	await tutorial.focar_em_slot_3d(slot_casa_2, "Afonso: Vou fazer mais uma Casa aqui para garantir a reforma!")
	await get_tree().create_timer(0.2).timeout
	var botao_casa2 = slot_casa_2.ui_atual._botoes_ativos[1] if slot_casa_2.ui_atual else null
	if botao_casa2:
		await tutorial.focar_em_ui_2d(botao_casa2, "Afonso: Excelente. Ouro garantido para o pequeno-almoço.")
	await get_tree().create_timer(1.0).timeout


	# --- DIA 1: INICIAR A NOITE (BUSCANDO PELO GRUPO) ---
	print("🔍 Procurando o botão de iniciar a noite pelo Grupo...")
	
	var botao_iniciar_noite = get_tree().get_first_node_in_group("BotaoIniciarNoite")
	
	# MÁGICA DE SEGURANÇA: Se o botão ainda não estiver pronto na tela, o Godot espera!
	while botao_iniciar_noite == null:
		await get_tree().create_timer(0.1).timeout
		botao_iniciar_noite = get_tree().get_first_node_in_group("BotaoIniciarNoite")
		
	print("✅ Botão da Noite ENCONTRADO com sucesso!")
	
	await tutorial.focar_em_ui_2d(botao_iniciar_noite, "Avó Berta: Tudo pronto! Clica aqui para chamar a noite, e usa a tua espada para defender as Torres!")
	
	print("⚔️ JOGADOR ESTÁ A LUTAR NA NOITE 1...")
	
	# O CÓDIGO PAUSA AQUI ATÉ QUE A NOITE ACABE E O NOVO DIA NASÇA!
	await GameManager.dia_iniciado
	
	# O CÓDIGO PAUSA AQUI ATÉ QUE A NOITE ACABE E O NOVO DIA NASÇA!
	await GameManager.dia_iniciado
	
	
	# --- DIA 2: O SOL NASCE (CASTELO E QUARTEL) ---
	print("☀️ INICIANDO O TUTORIAL - DIA 2")
	await get_tree().create_timer(1.5).timeout # Tempo para a animação das moedas ganhas
	
	await tutorial.focar_em_slot_3d(castelo, "Afonso: Sobrevivemos! E olha o dinheiro das rendas! Toca no nosso Castelo para o evoluir.")
	await get_tree().create_timer(0.2).timeout
	
	if castelo.ui_atual:
		var botao_upgrade_castelo = castelo.ui_atual.get_node_or_null("Upgrade") 
		if botao_upgrade_castelo:
			await tutorial.focar_em_ui_2d(botao_upgrade_castelo, "Avó Berta: Evolui o Castelo. Isso vai libertar novas opções no tabuleiro!")
	await get_tree().create_timer(1.0).timeout
	
	await tutorial.focar_em_slot_3d(slot_quartel, "Avó Berta: Repara! Novos lotes surgiram porque melhorámos o Castelo. Toca aqui.")
	await get_tree().create_timer(0.2).timeout
	
	if slot_quartel.ui_atual:
		var botao_quartel = slot_quartel.ui_atual.get_node_or_null("Quartel") 
		if botao_quartel:
			await tutorial.focar_em_ui_2d(botao_quartel, "Afonso: Perfeito! Vou construir o Quartel para chamar soldados para lutarem por nós.")
	await get_tree().create_timer(1.0).timeout


	# --- FIM DO TUTORIAL ---
	# Procura o botão de iniciar a noite novamente (pode ter sido recriado se o HUD mudar de dia/noite)
	botao_iniciar_noite = get_tree().get_first_node_in_group("BotaoIniciarNoite")
	if botao_iniciar_noite:
		await tutorial.focar_em_ui_2d(botao_iniciar_noite, "Avó Berta: Agora estás no controlo, Afonso. Posiciona os soldados e inicia a Noite 2!")
	
	GameManager.is_tutorial_ativo = false
	print("✅ TUTORIAL CONCLUÍDO COM SUCESSO!")
