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
signal vitoria

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
var recarregando_save: bool = false

# ==========================================
# MODO INFINITO
# ==========================================
var modo_infinito: bool = false

# ==========================================
# BANCO DE DADOS DAS FASES
# ==========================================
var construcoes_permitidas_na_fase: Dictionary = {}

var vida_base_atual: int = 0
var vida_base_maxima: int = 0
# ==========================================
# CONTROLO DOS SPAWNERS
# ==========================================
var total_spawners: int = 3 
var spawners_concluidos: int = 0

var banco_de_fases: Dictionary = {
	1: {
		"moedas_iniciais": 10,
		"nivel_base_inicial": 0,
		"tutorial": true,
		"renda_base_por_onda": 5, 
		"construcoes": {
			0: [preload("res://Builds/tower.tscn"), preload("res://Builds/house.tscn"), preload("res://Builds/mill.tscn")],
			1: [preload("res://Builds/mina.tscn"), preload("res://Builds/quartel.tscn")],
			2: []
		}
	},
	2: {
		"moedas_iniciais": 10,
		"nivel_base_inicial": 0,
		"tutorial": false,
		"renda_base_por_onda": 5, 
		"construcoes": {
			0: [preload("res://Builds/tower.tscn"), preload("res://Builds/house.tscn"), preload("res://Builds/mill.tscn")],
			1: [preload("res://Builds/mina.tscn"), preload("res://Builds/quartel.tscn")],
			2: []
		}
	}
}

# ==========================================
# UPGRADES E MODIFICADORES
# ==========================================
var bonus_dano: int = 0 
var bonus_moedas_onda: int = 0
var recomendacao_conselheiro: String = ""
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
	preload("res://PowerUps/Fúria.tres"),
	preload("res://PowerUps/Gelo.tres"),
]

var reroll_usado: bool = false
var custo_reroll: int = 2

var caminhos_das_fases = {
	1: "res://Maps/tutorial_world.tscn",
	2: "res://Maps/Crimson_Desert.tscn",
	3: "res://Maps/Witch_house.tscn",
	4: "res://Maps/fenda_dos_piratas.tscn",
	5: "res://Maps/Covil_Dragon.tscn"
}

# ==========================================
# AUTO-LOAD (INICIA JUNTO COM O JOGO)
# ==========================================
func _ready():
	# Aguarda o Godot terminar de carregar a cena principal
	await get_tree().process_frame

# Processa o carregamento do save e transição de cena, acionado por interface
func carregar_jogo_salvo_manual() -> bool:
	print("🔍 Verificando se existe save para carregamento...")
	
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ Nenhum ficheiro de save encontrado em: ", SAVE_PATH)
		return false

	if carregar_jogo():
		print("💾 Save lido com sucesso! Fase encontrada no save: ", fase_atual)
		
		if caminhos_das_fases.has(fase_atual):
			var caminho_cena = caminhos_das_fases[fase_atual]
			print("🚀 Mudando para a cena: ", caminho_cena)
			
			var erro = get_tree().change_scene_to_file(caminho_cena)
			if erro != OK:
				print("❌ Erro ao tentar mudar de cena! Código: ", erro)
				return false

			await get_tree().tree_changed
			await get_tree().process_frame
			
			print("🎬 Nova cena carregada. Iniciando restauração de torres...")
			
			recarregando_save = true
			carregar_fase(fase_atual)
			
			await get_tree().create_timer(0.1).timeout
			
			# NOVA LINHA: Instanciamos as torres fisicamente no mundo apenas agora.
			if dados_construcoes_pendentes.size() > 0:
				await _restaurar_construcoes(dados_construcoes_pendentes)
				dados_construcoes_pendentes.clear()
			
			dia_iniciado.emit(onda_atual)
			get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))
			get_tree().call_group("Spawner", "restaurar_onda_do_save")
			
			# Sincroniza o ambiente musical com a fase carregada
			match fase_atual:
				1:
					MusicaGlobal.tocar_tutorial()
				3:
					MusicaGlobal.tocar_bruxa()
				5:
					MusicaGlobal.tocar_covil()
				_:
					MusicaGlobal.tocar_menu()
			
			recarregando_save = false
			print("✅ Carregamento concluído com sucesso!")
			return true
		else:
			print("⚠️ Erro: A fase ", fase_atual, " não existe no dicionário caminhos_das_fases!")
			return false
	return false

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
	
	# 1. Carrega as regras base da fase (Sempre necessário)
	construcoes_permitidas_na_fase = config["construcoes"]
	
	# 2. Se NÃO for um carregamento de save, aplicamos os valores iniciais de "Novo Jogo"
	if not recarregando_save:
		moedas = config["moedas_iniciais"]
		if modo_infinito:
			moedas += 10  # Bônus de entrada no modo infinito
		_set_nivel_base(config["nivel_base_inicial"])
		is_tutorial_ativo = config["tutorial"] and not modo_infinito
		onda_atual = 1 # Só resetamos a onda se for um jogo novo
		iniciar_dia(true)
		print("Fase ", fase_atual, " iniciada do zero!", " [INFINITO]" if modo_infinito else "")
	else:
		# Se for save, apenas confirmamos que os dados já foram carregados
		print("Fase ", fase_atual, " restaurada na onda: ", onda_atual)
		# IMPORTANTE: Não chamamos iniciar_dia(true) aqui para não salvar por cima
	
	get_tree().call_group("Interface", "atualizar_moedas")

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
	
	# ADICIONE ESTA LINHA: Salva o jogo sempre que o dia começa em segurança
	# (o modo infinito é uma sessão única, não persiste mid-run)
	if not modo_infinito:
		salvar_jogo()

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	spawners_concluidos = 0
	is_night = true
	noite_iniciada.emit(onda_atual)
	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))

func registrar_spawner_concluido():
	spawners_concluidos += 1
	print("Spawner concluído! Total: ", spawners_concluidos, "/", total_spawners)
	
	# Só termina a onda quando os 3 terminarem!
	if spawners_concluidos >= total_spawners:
		terminar_onda()
		
func terminar_onda():
	if estado_atual == EstadoJogo.DIA: return 
	
	# Verifica se era a última onda da fase (Ex: fase 1 tem 5 ondas)
	# Você pode definir esse valor no seu banco_de_fases [cite: 2]
	var ultima_onda = 5

	# No modo infinito nunca aciona vitória — só termina com game over (base destruída)
	if not modo_infinito and onda_atual >= ultima_onda:
		acionar_vitoria()
		return

	estado_atual = EstadoJogo.DIA
	is_night = false
	onda_terminada.emit() 
	
	if onda_atual % 2 != 0: 
		sortear_cartas()
	
	onda_atual += 1
	iniciar_dia() # Isto vai acionar automaticamente a recolha de renda!

func calcular_e_recolher_renda():
	var config_fase = banco_de_fases[fase_atual]
	var total_renda = config_fase["renda_base_por_onda"] + bonus_moedas_onda
	if modo_infinito:
		total_renda += 3  # Renda extra facilitada no modo infinito
	
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
	# Enum CartaUpgrade.TipoUpgrade: DANO=0, MOEDA=1, VIDA=2, VELOCIDADE_ATAQUE=3,
	#                                VELOCIDADE_INIMIGO=4, CUSTO_CONSTRUCAO=5, QUANTIDADE_INIMIGOS=6
	match tipo_efeito:
		0: # DANO
			bonus_dano += int(valor)
			print("Bônus de Dano: ", bonus_dano)
		1: # MOEDA
			bonus_moedas_onda += int(valor)
			print("Bônus de Moedas por Onda: ", bonus_moedas_onda)
		2: # VIDA — aplica ao castelo (flat se |valor|>=1, percentual se |valor|<1)
			var delta: int = int(valor) if abs(valor) >= 1.0 else int(vida_base_maxima * valor)
			vida_base_maxima = max(1, vida_base_maxima + delta)
			vida_base_atual  = clamp(vida_base_atual + max(0, delta), 1, vida_base_maxima)
			get_tree().call_group("Base", "_aplicar_bonus_vida", delta)
			print("Vida do castelo: ", vida_base_atual, "/", vida_base_maxima)
		3: # VELOCIDADE_ATAQUE
			bonus_velocidade_ataque += float(valor)
			print("Bônus de Velocidade de Ataque: ", bonus_velocidade_ataque)
		4: # VELOCIDADE_INIMIGO (aditivo: -0.3 = inimigos 30% mais lentos)
			multiplicador_velocidade_inimigo = max(0.1, multiplicador_velocidade_inimigo + float(valor))
			print("Multiplicador de Velocidade Inimigo: ", multiplicador_velocidade_inimigo)
		5: # CUSTO_CONSTRUCAO
			desconto_construcao += int(valor)
			print("Desconto de Construção: -", desconto_construcao, " moedas")
		6: # QUANTIDADE_INIMIGOS (valor em %, ex: 20.0 = +20% mais inimigos)
			multiplicador_horda = max(0.1, multiplicador_horda + float(valor) / 100.0)
			print("Multiplicador de Horda: ", multiplicador_horda)

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

# Agora a função recebe as estrelas que o jogador ganhou na partida
func acionar_vitoria(): 
	print("Todas as ondas terminaram! Calculando vitória...")
	
	# ==========================================
	# 1. CÁLCULO DE ESTRELAS
	# ==========================================
	var estrelas_ganhas = 1 # O padrão é 1 (sobreviveu)
	
	# Previne erro caso a vida máxima não tenha sido carregada
	if vida_base_maxima > 0:
		var porcentagem = (float(vida_base_atual) / float(vida_base_maxima)) * 100.0
		if porcentagem >= 75.0:
			estrelas_ganhas = 3
		elif porcentagem >= 50.0:
			estrelas_ganhas = 2
			
	print("A base terminou com ", vida_base_atual, " de vida. O jogador ganhou ", estrelas_ganhas, " estrelas!")

	# ==========================================
	# 2. SALVAR NO GLOBAL (Como fizemos antes)
	# ==========================================
	if fase_atual >= Global.fases_liberadas:
		Global.fases_liberadas = fase_atual + 1
	
	var estrelas_antigas = Global.estrelas_por_fase.get(str(fase_atual), 0)
	if estrelas_ganhas > estrelas_antigas:
		Global.estrelas_por_fase[str(fase_atual)] = estrelas_ganhas
	
	Global.salvar_progresso()
	
	# ==========================================
	# 3. FINALIZAR
	# ==========================================
	vitoria.emit() 
	get_tree().paused = true

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

# ==========================================
# SISTEMA DE SAVE / LOAD E REINÍCIO DE NOITE
# ==========================================
const SAVE_PATH = "user://save_jogo.json"
var dados_construcoes_pendentes: Array = []

func salvar_jogo():
	var dados_save = {
		"fase_atual": fase_atual,
		"moedas": moedas,
		"onda_atual": onda_atual,
		"nivel_base": nivel_base,
		"is_tutorial_ativo": is_tutorial_ativo,
		"bonus_dano": bonus_dano,
		"bonus_moedas_onda": bonus_moedas_onda,
		"bonus_velocidade_ataque": bonus_velocidade_ataque,
		"desconto_construcao": desconto_construcao,
		"multiplicador_horda": multiplicador_horda,
		"multiplicador_velocidade_inimigo": multiplicador_velocidade_inimigo,
		"construcoes": []
	}
	# Salva todas as construções que estiverem no grupo "Construcoes" (1º Loop)
	var construcoes_no_mapa = get_tree().get_nodes_in_group("Construcao")
	print("Encontrei ", construcoes_no_mapa.size(), " construções para salvar.") 
	
	for construcao in construcoes_no_mapa:
		if construcao.is_in_group("Base"): 
			continue
			
		var dados_construcao = {
			"caminho_cena": construcao.scene_file_path, 
			"pos_x": construcao.global_position.x,
			"pos_y": construcao.global_position.y,
			"pos_z": construcao.global_position.z,
			"nivel_atual": construcao.nivel_atual if "nivel_atual" in construcao else 0,
			"caminho_atual": construcao.caminho_atual if "caminho_atual" in construcao else -1
		}
		dados_save["construcoes"].append(dados_construcao)
	
	# Salva todas as construções que estiverem no grupo "Construcoes" (2º Loop)
	var construcoes = get_tree().get_nodes_in_group("Construcoes")
	for construcao in construcoes:
		var dados_construcao = {
			"caminho_cena": construcao.scene_file_path, 
			"pos_x": construcao.global_position.x,
			"pos_y": construcao.global_position.y,
			"pos_z": construcao.global_position.z,
			"nivel_atual": construcao.nivel_atual if "nivel_atual" in construcao else 0,
			"caminho_atual": construcao.caminho_atual if "caminho_atual" in construcao else -1
		}
		dados_save["construcoes"].append(dados_construcao)
		
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados_save))
	print("Jogo salvo com sucesso no início da onda ", onda_atual)

func carregar_jogo() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false # Não existe save prévio
		
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var dados_save = JSON.parse_string(arquivo.get_as_text())
	
	if dados_save:
		fase_atual = dados_save["fase_atual"]
		moedas = dados_save["moedas"]
		onda_atual = dados_save["onda_atual"]
		_set_nivel_base(dados_save["nivel_base"])
		is_tutorial_ativo = dados_save["is_tutorial_ativo"]
		iniciar_dia()
		# Restaurar Bônus
		bonus_dano = dados_save["bonus_dano"]
		bonus_moedas_onda = dados_save["bonus_moedas_onda"]
		bonus_velocidade_ataque = dados_save["bonus_velocidade_ataque"]
		desconto_construcao = dados_save["desconto_construcao"]
		multiplicador_horda = dados_save["multiplicador_horda"]
		multiplicador_velocidade_inimigo = dados_save["multiplicador_velocidade_inimigo"]
		
		# ARMAZENA AS CONSTRUÇÕES PARA RECRIAR DEPOIS DO MAPA CARREGAR
		if dados_save.has("construcoes"):
			dados_construcoes_pendentes = dados_save["construcoes"]
		else:
			dados_construcoes_pendentes = []
		
		get_tree().call_group("Interface", "atualizar_moedas")
		return true
		
	return false

func _restaurar_construcoes(lista_construcoes):
	# 1. Dá um pequeno tempo para os slots entrarem no grupo
	await get_tree().process_frame
	var todos_os_slots = get_tree().get_nodes_in_group("BuildSlots")
	
	print("🛠️ Tentando restaurar ", lista_construcoes.size(), " construções em ", todos_os_slots.size(), " slots encontrados.")

	for dados_c in lista_construcoes:
		if dados_c["caminho_cena"] == "": continue
		
		var cena_construcao = load(dados_c["caminho_cena"])
		if cena_construcao:
			var pos_salva = Vector3(dados_c["pos_x"], dados_c["pos_y"], dados_c.get("pos_z", 0))
			var nova_construcao = cena_construcao.instantiate()
			
			# Aplica as informações de upgrade diretamente na instância antes de acoplá-la à cena
			if "nivel_atual" in nova_construcao and dados_c.has("nivel_atual"):
				nova_construcao.nivel_atual = dados_c["nivel_atual"]
			if "caminho_atual" in nova_construcao and dados_c.has("caminho_atual"):
				nova_construcao.caminho_atual = dados_c["caminho_atual"]
			
			# 2. PROCURA O SLOT (Aumentamos a tolerância para 1.0 unidade)
			var slot_dono = null
			var menor_distancia = 10.0 # Valor alto inicial
			
			for slot in todos_os_slots:
				var dist = slot.global_position.distance_to(pos_salva)
				# Se a distância for pequena e o slot estiver vazio
				if dist < 1.0 and dist < menor_distancia:
					slot_dono = slot
					menor_distancia = dist
			
			# 3. ACOPLAMENTO NO SLOT
			if slot_dono:
				# Importante: Adiciona como FILHO do slot
				slot_dono.add_child(nova_construcao)
				
				# Reseta a posição local para (0,0,0) para alinhar perfeito ao slot
				nova_construcao.position = Vector3.ZERO 
				nova_construcao.is_fantasma = false
				
				# Avisa o slot que ele está ocupado
				if slot_dono.has_method("configurar_como_ocupado"):
					slot_dono.configurar_como_ocupado()
				else:
					# Fallback caso não tenha a função acima
					slot_dono.is_built = true
					if "base_mesh" in slot_dono and slot_dono.base_mesh: slot_dono.base_mesh.hide()
					if "canvas_mobile" in slot_dono and slot_dono.canvas_mobile: slot_dono.canvas_mobile.hide()
				
				# Reconecta o sinal de morte/venda da torre
				if nova_construcao.has_signal("tree_exited"):
					if not nova_construcao.tree_exited.is_connected(slot_dono.reativar_slot):
						nova_construcao.tree_exited.connect(slot_dono.reativar_slot)
				
				print("✅ Torre ", dados_c["caminho_cena"].get_file(), " acoplada ao slot em ", pos_salva)
			else:
				# 4. FALLBACK (Se não achou slot, coloca no mundo)
				print("⚠️ Slot não encontrado perto de ", pos_salva, ". Adicionando ao mundo.")
				get_tree().current_scene.add_child(nova_construcao)
				nova_construcao.global_position = pos_salva
				nova_construcao.is_fantasma = false

# Remove o arquivo de save local para evitar carregamento de instâncias já finalizadas
func apagar_save():
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("save_jogo.json")
			print("Arquivo de save removido com sucesso.")

# Função chamada pelo seu botão em game_over_ui.gd
# Função chamada pelo seu botão em game_over_ui.gd
func reiniciar_noite_atual():
	print("Voltando ao início da onda atual...")
	get_tree().paused = false
	
	if carregar_jogo():
		recarregando_save = true 
		
		get_tree().reload_current_scene()
		
		# Espera a nova cena terminar de carregar totalmente
		await get_tree().tree_changed
		await get_tree().process_frame
		
		carregar_fase(fase_atual)
		
		await get_tree().create_timer(0.1).timeout
		
		if dados_construcoes_pendentes.size() > 0:
			await _restaurar_construcoes(dados_construcoes_pendentes)
			dados_construcoes_pendentes.clear()
		
		# Forçar o estado de volta para o DIA
		estado_atual = EstadoJogo.DIA
		is_night = false
		
		# ==========================================
		# CORREÇÃO: REAPLICAR DADOS NA CENA NOVA
		# ==========================================
		# Chama o setter novamente para forçar a emissão do sinal na nova cena
		_set_nivel_base(nivel_base) 
		
		# Atualiza a HUD da nova cena com as moedas carregadas
		get_tree().call_group("Interface", "atualizar_moedas")
		# ==========================================
		
		dia_iniciado.emit(onda_atual)
		get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))
		
		# Atualiza botões visuais e cura
		get_tree().call_group("Interface", "verificar_estado_dia_noite") 
		get_tree().call_group("Torres", "curar_totalmente") 
		
		get_tree().call_group("Spawner", "restaurar_onda_do_save")
		
		recarregando_save = false
		print("✅ Noite reiniciada e Base restaurada com sucesso!")
	else:
		print("⚠️ Erro: Nenhum save encontrado! Fazendo reload simples.")
		get_tree().reload_current_scene()
