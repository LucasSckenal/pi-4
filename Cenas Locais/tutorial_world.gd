extends Node3D

@onready var tutorial = $TutorialManager

# REFERENCIAS
@onready var slot_torre_1 = $BuildSlots/BuildSlot12
@onready var slot_torre_2 = $BuildSlots/BuildSlot
@onready var slot_casa_1 = $BuildSlots/BuildSlot11  
@onready var slot_casa_2 = $BuildSlots/BuildSlot7  
@onready var castelo = $"NavigationRegion3D/building-castle2"      
@onready var slot_quartel = $BuildSlots/BuildSlot24
@onready var ponto_defesa_player = $PontoDefesaPlayer 

func _ready():
	GameManager.carregar_fase(1)
	if GameManager.is_tutorial_ativo:
		iniciar_sequencia_tutorial()

func iniciar_sequencia_tutorial():
	# --- DIA 1: CONSTRUÇÕES ---
	await passo_construcao(slot_torre_1, 0, "Avó Berta: Afonso, constrói a primeira Torre aqui!")
	await passo_construcao(slot_torre_2, 0, "Avó Berta: Outra torre para reforçar a entrada.")
	await passo_construcao(slot_casa_1, 1, "Afonso: Vou fazer uma Casa aqui para ganhar ouro.")
	await passo_construcao(slot_casa_2, 1, "Afonso: Mais uma casa para a nossa economia crescer!")

	# --- INICIAR NOITE ---
	var btn_noite = get_tree().get_first_node_in_group("BotaoIniciarNoite")
	while btn_noite == null: await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(btn_noite, "Avó Berta: Tudo pronto! Clica aqui para começar!")

	# --- COMBATE (INSTANTÂNEO APÓS CLIQUE) ---
	get_tree().paused = true
	# Aqui o Manager vai usar o efeito de fundo escuro por 4 segundos
	await tutorial.focar_em_slot_3d(ponto_defesa_player, "Afonso: Vou lutar ali com a minha espada onde as torres não chegam!")
	get_tree().paused = false
	
	await GameManager.dia_iniciado # Espera amanhecer

	# --- DIA 2: CARTAS E UPGRADE ---
	var carta = get_tree().root.find_child("CartaTutorial0", true, false)
	while carta == null: await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(carta, "Escolha esta carta de ajuda.")
	
	await tutorial.focar_em_slot_3d(castelo, "Afonso: Toca no Castelo para melhorá-lo.")
	var btn_up = get_tree().root.find_child("Upgrade", true, false)
	while btn_up == null: await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(btn_up, "Clica em Upgrade!")
	
	get_tree().paused = false 
	await get_tree().create_timer(0.3).timeout

	# --- QUARTEL (ÍNDICE 4) ---
	await tutorial.focar_em_slot_3d(slot_quartel, "Constrói o Quartel neste novo lote!")
	while slot_quartel.get("ui_atual") == null: await get_tree().create_timer(0.01).timeout
	
	var btn_quartel = slot_quartel.ui_atual._botoes_ativos[4]
	await tutorial.focar_em_ui_2d(btn_quartel, "O Quartel vai dar-nos soldados!")

	# FINAL
	GameManager.is_tutorial_ativo = false
	print("✅ Tutorial Completo")

# Função para simplificar as construções repetidas
func passo_construcao(slot, indice, texto):
	await tutorial.focar_em_slot_3d(slot, texto)
	while slot.get("ui_atual") == null: await get_tree().create_timer(0.01).timeout
	await tutorial.focar_em_ui_2d(slot.ui_atual._botoes_ativos[indice], "Escolha a construção.")
