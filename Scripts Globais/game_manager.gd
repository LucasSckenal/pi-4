extends Node

# ==========================================
# SINAIS
# ==========================================
signal dia_iniciado(onda_atual)
signal noite_iniciada(onda_atual)
signal onda_terminada
signal mostrar_menu_upgrade(cartas_sorteadas)
signal upgrade_aplicado
signal upgrade_base_aplicado
signal renda_recolhida(total_ganho) # Para a UI mostrar "+X Moedas" de manhã
signal game_over

# ==========================================
# ESTADO GLOBAL DO JOGO
# ==========================================
enum EstadoJogo { DIA, NOITE }
var estado_atual = EstadoJogo.DIA
var is_night: bool = false

var fase_atual: int = 1
var is_tutorial_ativo: bool = false

var moedas: int = 0
var onda_atual: int = 1
var nivel_base: int = 0 : set = _set_nivel_base

var modo_dev: bool = false

# ==========================================
# BANCO DE DADOS DAS FASES
# ==========================================
var construcoes_permitidas_na_fase: Dictionary = {}

var banco_de_fases: Dictionary = {
	1: {
		"moedas_iniciais": 10,
		"nivel_base_inicial": 0,
		"tutorial": true,
		"renda_base_por_onda": 5, # Ouro garantido só por sobreviver à noite
		"construcoes": {
			0: [preload("res://Builds/tower.tscn"), preload("res://Builds/house.tscn"), preload("res://Builds/mill.tscn")],
			1: [preload("res://Builds/mina.tscn"), preload("res://Builds/quartel.tscn")],
			2: []
		}
	}
	# Pode adicionar a Fase 2 aqui futuramente!
}

# ==========================================
# UPGRADES E MODIFICADORES
# ==========================================
var bonus_dano: int = 0 
var bonus_moedas_onda: int = 0
var bonus_velocidade_ataque: float = 0.0
var desconto_construcao: int = 0
var multiplicador_horda: float = 1.0
var multiplicador_velocidade_inimigo: float = 1.0

# ==========================================
# BARALHO DE UPGRADES
# ==========================================
var baralho_upgrades: Array = [
	preload("res://PowerUps/EngenhariaEficiente.tres"),
	preload("res://PowerUps/BalisticaPesada.tres"),
	preload("res://PowerUps/FrequenciaCritica.tres"),
	preload("res://PowerUps/ImpostoGuerra.tres"),
	preload("res://PowerUps/MuralhasReforçadas.tres"),
	preload("res://PowerUps/TFRICO.tres"),
]

var reroll_usado: bool = false
var custo_reroll: int = 2

# ==========================================
# INPUTS GERAIS
# ==========================================
func _process(_delta):
	# Permite passar a onda com um botão, mas bloqueia se o tutorial estiver a forçar uma ação
	if Input.is_action_just_pressed("passar_onda"): 
		if estado_atual == EstadoJogo.DIA and not is_tutorial_ativo:
			iniciar_noite()

	# Ativa o modo de desenvolvedor para testes e recursos adicionais
	if Input.is_physical_key_pressed(KEY_F2) and not modo_dev:
		modo_dev = true
		moedas += 10000
		get_tree().call_group("Interface", "atualizar_moedas")
		print("Modo Dev ativado: Moedas concedidas e restrições de movimento removidas.")

# ==========================================
# INICIALIZAÇÃO DE FASE E CONSTRUÇÕES
# ==========================================
func carregar_fase(numero_fase: int):
	fase_atual = numero_fase
	var config = banco_de_fases[numero_fase]
	
	moedas = config["moedas_iniciais"]
	_set_nivel_base(config["nivel_base_inicial"])
	is_tutorial_ativo = config["tutorial"]
	construcoes_permitidas_na_fase = config["construcoes"]
	onda_atual = 1
	
	iniciar_dia(true) # True significa que é o 1º dia (não recolhe renda ainda)
	get_tree().call_group("Interface", "atualizar_moedas")
	print("Fase ", fase_atual, " carregada com sucesso!")

func _set_nivel_base(valor):
	nivel_base = valor
	upgrade_base_aplicado.emit()
	print("Nível da base agora é: ", nivel_base)

func get_construcoes_disponiveis() -> Array:
	var disponiveis = []
	for nivel in construcoes_permitidas_na_fase:
		if nivel <= nivel_base:
			disponiveis += construcoes_permitidas_na_fase[nivel]
	return disponiveis

# ==========================================
# CICLO DIA / NOITE E ECONOMIA
# ==========================================
func iniciar_dia(primeiro_dia: bool = false):
	estado_atual = EstadoJogo.DIA
	is_night = false
	dia_iniciado.emit(onda_atual)
	
	if not primeiro_dia:
		calcular_e_recolher_renda()
	
	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Torres", "curar_totalmente")

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	is_night = true
	noite_iniciada.emit(onda_atual)
	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))

func terminar_onda():
	if estado_atual == EstadoJogo.DIA: return 
	
	estado_atual = EstadoJogo.DIA
	is_night = false
	
	onda_terminada.emit() 
	
	if onda_atual % 2 != 0: # Se impar? Receba carta (se fosse par quebraria o tutorial)
		sortear_cartas()
	
	onda_atual += 1
	iniciar_dia() # Isto vai acionar automaticamente a recolha de renda!

func calcular_e_recolher_renda():
	var config_fase = banco_de_fases[fase_atual]
	var total_renda = config_fase["renda_base_por_onda"] + bonus_moedas_onda
	
	# Recolhe o dinheiro das casas e moinhos
	var construcoes_economia = get_tree().get_nodes_in_group("Economia")
	for construcao in construcoes_economia:
		if construcao.has_method("gerar_renda"):
			total_renda += construcao.gerar_renda()
	
	moedas += total_renda
	renda_recolhida.emit(total_renda)
	get_tree().call_group("Interface", "atualizar_moedas")
	print("Manhã da Onda ", onda_atual, " | Renda recolhida: ", total_renda)

# ==========================================
# SISTEMA DE UPGRADES E CARTAS
# ==========================================
func sortear_cartas():
	if baralho_upgrades.size() == 0:
		print("ERRO: O baralho está vazio no Inspetor!")
		return

	reroll_usado = false

	var copia = baralho_upgrades.duplicate()
	copia.shuffle()
	
	var escolhidas = []
	for i in range(3):
		if i < copia.size():
			escolhidas.append(copia[i])
			
	# ==========================================
	# MÁGICA DO TUTORIAL: FORÇAR A PRIMEIRA CARTA
	# ==========================================
	if is_tutorial_ativo and onda_atual == 1:
		# Pega a carta que está na posição 0 da tua lista original (podes mudar o número)
		escolhidas[0] = baralho_upgrades[0] 
		print("Tutorial Ativo: Forçando a primeira carta do baralho!")
	# ==========================================
	
	mostrar_menu_upgrade.emit(escolhidas)
	get_tree().paused = true

func aplicar_upgrade(dados): # Substitua "dados: CartaUpgrade" se tiver o tipo definido
	_processar_efeito(dados.tipo_bonus, dados.valor_bonus)
	
	if dados.valor_debuff != 0:
		_processar_efeito(dados.tipo_debuff, dados.valor_debuff)

	print("Upgrade '", dados.titulo, "' aplicado com sucesso!")
	
	upgrade_aplicado.emit()
	get_tree().call_group("Torres", "atualizar_status")

func _processar_efeito(tipo_efeito, valor):
	# Assumindo que o enum TipoUpgrade está dentro de CartaUpgrade
	# Se necessário, ajuste o caminho do Enum conforme o seu projeto
	match tipo_efeito:
		0: # DANO
			bonus_dano += int(valor)
			print("Novo Bônus de Dano: ", bonus_dano)
		1: # MOEDA
			bonus_moedas_onda += int(valor)
			print("Novo Bônus de Moedas: ", bonus_moedas_onda)
		2: # VELOCIDADE_ATAQUE
			bonus_velocidade_ataque += float(valor)
			print("Novo Bônus de Velocidade: ", bonus_velocidade_ataque)
		3: # CUSTO_CONSTRUCAO
			desconto_construcao += int(valor) 
			print("Desconto fixo aplicado! Torres custam -", desconto_construcao, " moedas.")
		4: # QUANTIDADE_INIMIGOS
			multiplicador_horda *= float(valor)
			print("Novo Multiplicador de Horda: ", multiplicador_horda)
		5: # VELOCIDADE_INIMIGO
			multiplicador_velocidade_inimigo *= float(valor)
			print("Velocidade dos Inimigos alterada: ", multiplicador_velocidade_inimigo)
		6: # VIDA
			print("Vida aumentada em: ", valor)

func rerolar_cartas():
	if reroll_usado:
		print("Reroll já foi usado nesta oportunidade.")
		return
	if moedas < custo_reroll:
		print("Moedas insuficientes para reroll.")
		return
	if baralho_upgrades.size() == 0:
		print("ERRO: O baralho está vazio!")
		return

	moedas -= custo_reroll
	get_tree().call_group("Interface", "atualizar_moedas")

	var copia = baralho_upgrades.duplicate()
	copia.shuffle()
	var escolhidas = []
	for i in range(3):
		if i < copia.size():
			escolhidas.append(copia[i])

	reroll_usado = true
	mostrar_menu_upgrade.emit(escolhidas)

# ==========================================
# SISTEMA DE COMPRAS
# ==========================================
func gastar_moedas(valor_custo: int) -> bool:
	if moedas >= valor_custo:
		moedas -= valor_custo
		get_tree().call_group("Interface", "atualizar_moedas")
		get_tree().call_group("Interface", "animar_bau_abrindo")
		return true
	return false

func obter_custo_com_desconto(custo_base: int) -> int:
	return max(1, custo_base - desconto_construcao)
	
	
# ==========================================
# SISTEMA DE GAME OVER E REINÍCIO
# ==========================================
func acionar_game_over():
	print("Game Over acionado!")
	game_over.emit() # Dispara o sinal para a HUD abrir a tela
	get_tree().paused = true # Pausa o jogo (inimigos, tempo, torres)

func reiniciar_partida():
	print("Reiniciando a partida...")
	# 1. Tira o jogo da pausa
	get_tree().paused = false
	
	# 2. Reseta a onda e as moedas para os valores iniciais da fase 1
	onda_atual = 1
	moedas = banco_de_fases[1]["moedas_iniciais"] # Volta para 10 moedas
	nivel_base = banco_de_fases[1]["nivel_base_inicial"]
	
	# 3. Limpa todos os bônus das cartas (Para não recomeçar roubado!)
	bonus_dano = 0 
	bonus_moedas_onda = 0
	bonus_velocidade_ataque = 0.0
	desconto_construcao = 0
	multiplicador_horda = 1.0
	multiplicador_velocidade_inimigo = 1.0
	
	# 4. Recarrega o mapa do zero
	get_tree().reload_current_scene()
	
func adicionar_moedas(quantidade: int):
	moedas += quantidade
	# É esta linha mágica que avisa a HUD para mudar o texto na tela!
	get_tree().call_group("Interface", "atualizar_moedas")
