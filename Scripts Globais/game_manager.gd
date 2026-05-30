extends Node

# Para ativar logs de diagnóstico, use Global.DEBUG_MODE = true em Global.gd

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

@warning_ignore("unused_signal")
signal inimigo_morreu  ## Emitido por InimigoBase.morrer() — substitui polling de grupo

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
# DESTAQUE DE UPGRADE
# ==========================================
# Qual construção exibe o indicador completo (seta + anel brilhante).
# As demais exibem apenas o anel apagado. Atualizado a cada 1 s durante o dia.
var construcao_destaque_upgrade: Node = null
var _timer_destaque_upgrade: float = 0.0

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
			2: [preload("res://Builds/mercadinho_egipcio.tscn")]
		}
	},
	3: {
		"moedas_iniciais": 12,
		"nivel_base_inicial": 0,
		"tutorial": false,
		"renda_base_por_onda": 6,
		"construcoes": {
			0: [preload("res://Builds/tower.tscn"), preload("res://Builds/house.tscn"), preload("res://Builds/mill.tscn")],
			1: [preload("res://Builds/mina.tscn"), preload("res://Builds/quartel.tscn")],
			2: []
		}
	},
	4: {
		"moedas_iniciais": 15,
		"nivel_base_inicial": 0,
		"tutorial": false,
		"renda_base_por_onda": 7,
		"construcoes": {
			0: [preload("res://Builds/tower.tscn"), preload("res://Builds/house.tscn"), preload("res://Builds/mill.tscn")],
			1: [preload("res://Builds/mina.tscn"), preload("res://Builds/quartel.tscn")],
			2: [ preload("res://Builds/taverna_dos_piratas.tscn")]
		}
	},
	5: {
		"moedas_iniciais": 18,
		"nivel_base_inicial": 0,
		"tutorial": false,
		"renda_base_por_onda": 8,
		"construcoes": {
			0: [preload("res://Builds/tower.tscn"), preload("res://Builds/house.tscn"), preload("res://Builds/mill.tscn")],
			1: [preload("res://Builds/mina.tscn"), preload("res://Builds/quartel.tscn")],
			2: []
		}
	},
	6: {
		"moedas_iniciais": 20,
		"nivel_base_inicial": 0,
		"tutorial": false,
		"renda_base_por_onda": 10,
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
var bonus_alcance: float = 0.0
var bonus_ricochete: int = 0
var dano_inflamavel: int = 0
var bonus_espinho: int = 0
var bonus_dano_chefe: int = 0

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
	preload("res://PowerUps/Precisao.tres"),
	preload("res://PowerUps/Ricochete.tres"),
	preload("res://PowerUps/Inflamavel.tres"),
	preload("res://PowerUps/Espinhosa.tres"),
	preload("res://PowerUps/Cacador.tres"),
]

var reroll_usado: bool = false
var custo_reroll: int = 2
var upgrades_escolhidos: Array = []

# ==========================================
# RASTREAMENTO DE CONQUISTAS
# ==========================================
var _conquistas_cache: Dictionary = {}
var _moedas_ao_inicio_dia: int = 0
var _dias_sem_gastar: int = 0
var _vida_base_ao_iniciar_noite: int = 0

var caminhos_das_fases = {
	1: "res://Maps/tutorial_world.tscn",
	2: "res://Maps/Crimson_Desert.tscn",
	3: "res://Maps/Witch_house.tscn",
	4: "res://Maps/fenda_dos_piratas.tscn",
	5: "res://Maps/planeta_maluco.tscn",
	6: "res://Maps/Covil_Dragon.tscn"
}

var caminhos_das_cutscenes = {
	1: "res://Cenas Locais/Cutscines/cutscene_dinamica.tscn",
	2: "res://Cenas Locais/Cutscines/cutscene_animada_2.tscn",
	3: "res://Cenas Locais/Cutscines/cutscene_animada_3.tscn",
	4: "res://Cenas Locais/Cutscines/cutscene_animada_4.tscn",
	5: "res://Cenas Locais/Cutscines/cutscene_animada_5.tscn",
	6: "res://Cenas Locais/Cutscines/cutscene_animada_6.tscn"
}

# ==========================================
# AUTO-LOAD (INICIA JUNTO COM O JOGO)
# ==========================================
func _ready():
	# Aguarda o Godot terminar de carregar a cena principal
	await get_tree().process_frame

	# Aplica os valores do CSV de balanceamento (sobrescreve banco_de_fases, custo_reroll, etc.)
	_aplicar_balanceamento()
	# Reaplica sempre que o usuário pressionar F5 para hot-reload
	if Balanceamento.recarregado.is_connected(_aplicar_balanceamento) == false:
		Balanceamento.recarregado.connect(_aplicar_balanceamento)

# ==========================================
# BALANCEAMENTO CENTRALIZADO (CSV)
# Sobrescreve valores numéricos das fases, custo de reroll, etc.
# ==========================================
func _aplicar_balanceamento() -> void:
	# Fases 1 a 6
	for n in range(1, 7):
		if banco_de_fases.has(n):
			banco_de_fases[n]["moedas_iniciais"]   = Balanceamento.get_int(
				"fase_%d_moedas_iniciais" % n, banco_de_fases[n]["moedas_iniciais"])
			banco_de_fases[n]["renda_base_por_onda"] = Balanceamento.get_int(
				"fase_%d_renda_onda" % n, banco_de_fases[n]["renda_base_por_onda"])
			banco_de_fases[n]["nivel_base_inicial"]  = Balanceamento.get_int(
				"fase_%d_nivel_base_inicial" % n, banco_de_fases[n]["nivel_base_inicial"])

	# Economia geral
	custo_reroll = Balanceamento.get_int("custo_reroll", custo_reroll)
	# (Caldeirão, Mercado, Taverna e Tesla lêem diretamente do Balanceamento em seus scripts)

# Tabela de IDs de carta → chaves do CSV (para sobrescrever PowerUps)
const _MAPA_UPGRADES: Dictionary = {
	"1": "upgrade_balistica_pesada",
	"2": "upgrade_imposto_guerra",
	"3": "upgrade_muralhas_reforcadas",
	"4": "upgrade_frequencia_critica",
	"5": "upgrade_engenharia_eficiente",
	"6": "upgrade_furia_dano",
	"7": "upgrade_ganancia_moedas",
	"8": "upgrade_gelo_lentidao",
	"9": "upgrade_precisao_alcance",
	"10": "upgrade_ricochete",
	"11": "upgrade_inflamavel",
	"12": "upgrade_espinhosa",
	"13": "upgrade_cacador_chefe",
}
const _MAPA_DEBUFFS: Dictionary = {
	"6": "upgrade_furia_debuff_vida",
	"7": "upgrade_ganancia_horda",
}

# Processa o carregamento do save e transição de cena, acionado por interface
func carregar_jogo_salvo_manual() -> bool:
	if not tem_jogo_salvo():
		return false

	if carregar_jogo():
		if caminhos_das_fases.has(fase_atual):
			var caminho_cena = caminhos_das_fases[fase_atual]
			var erro = get_tree().change_scene_to_file(caminho_cena)
			if erro != OK:
				push_error("[GameManager] Erro ao mudar de cena para: %s (código %d)" % [caminho_cena, erro])
				return false

			await get_tree().tree_changed
			await get_tree().process_frame

			recarregando_save = true
			carregar_fase(fase_atual)

			await get_tree().process_frame  # Barreira de cena — sem timer cria menos objects

			if dados_construcoes_pendentes.size() > 0:
				await _restaurar_construcoes(dados_construcoes_pendentes)
				dados_construcoes_pendentes.clear()

			dia_iniciado.emit(onda_atual)
			get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))
			get_tree().call_group("Spawner", "restaurar_onda_do_save")

			match fase_atual:
				1: MusicaGlobal.tocar_tutorial()
				2: MusicaGlobal.tocar_deserto()
				3: MusicaGlobal.tocar_bruxa()
				4: MusicaGlobal.tocar_aquatico()
				5: MusicaGlobal.tocar_scifi()
				6: MusicaGlobal.tocar_covil()
				_: MusicaGlobal.tocar_menu()

			recarregando_save = false
			return true
		else:
			push_error("[GameManager] Fase %d não existe em caminhos_das_fases!" % fase_atual)
			return false
	return false

# ==========================================
# INPUTS GERAIS
# ==========================================
func _process(delta):
	if Input.is_action_just_pressed("passar_onda"):
		if estado_atual == EstadoJogo.DIA and not is_tutorial_ativo:
			iniciar_noite()

	if Input.is_physical_key_pressed(KEY_F2) and not modo_dev:
		modo_dev = true
		moedas += 10000
		get_tree().call_group("Interface", "atualizar_moedas")

	# Atualiza o destaque de upgrade — fallback a cada 3 s durante o dia.
	# O update imediato é disparado por gastar_moedas() e aplicar_upgrade(),
	# portanto o timer serve apenas como garantia de sincronização residual.
	if not is_night:
		_timer_destaque_upgrade -= delta
		if _timer_destaque_upgrade <= 0.0:
			_timer_destaque_upgrade = 3.0
			_atualizar_destaque_upgrade()

# ==========================================
# INICIALIZAÇÃO DE FASE E CONSTRUÇÕES
# ==========================================
func carregar_fase(numero_fase: int):
	fase_atual = numero_fase
	var config = banco_de_fases[numero_fase]

	construcoes_permitidas_na_fase = config["construcoes"]

	if not recarregando_save:
		moedas = config["moedas_iniciais"]
		if modo_infinito:
			moedas += Balanceamento.get_int("modo_infinito_bonus_moedas_iniciais", 10)
		_set_nivel_base(config["nivel_base_inicial"])
		is_tutorial_ativo = config["tutorial"] and not modo_infinito
		onda_atual = 1
		# Descarta qualquer construção pendente de uma sessão anterior
		dados_construcoes_pendentes.clear()
		# Reset dos contadores de conquista por sessão
		_dias_sem_gastar = 0
		_moedas_ao_inicio_dia = moedas
		_vida_base_ao_iniciar_noite = 0
		# Corrige o ícone da base: _ready() das construções corre antes deste ponto,
		# por isso fase_atual ainda era o valor antigo quando _resolver_icone_construcao()
		# foi chamado. Forçamos a re-resolução agora que fase_atual está correcto.
		get_tree().call_group("Base", "_atualizar_icone_base")
		get_tree().call_group("Interface", "aplicar_tema_hud")
		# Conquista: chegou à fase final
		if numero_fase == 6:
			_tentar_conquista("res://Conquistas/chega_fase_final.tres")
		iniciar_dia(true)
	# Se for save, os dados já foram carregados — não sobrescrevemos

	get_tree().call_group("Interface", "atualizar_moedas")

# Carrega a próxima fase com mudança de cena.
# Chamado pela tela de vitória. Roda no singleton (AutoLoad) para sobreviver
# ao change_scene_to_file que destrói a cena atual.
func ir_para_proxima_fase() -> void:
	get_tree().paused = false
	var proxima := fase_atual + 1
	if not caminhos_das_fases.has(proxima):
		# Sem próxima fase — volta ao menu principal
		limpar_estado_sessao()
		get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
		return
	# Limpa perks, upgrades e nivel_base ANTES de carregar a nova fase
	limpar_estado_sessao()
	get_tree().change_scene_to_file(obter_cena_entrada_fase(proxima))
	await get_tree().tree_changed
	await get_tree().process_frame
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == caminhos_das_fases[proxima]:
		carregar_fase(proxima)
	match proxima:
		1: MusicaGlobal.tocar_tutorial()
		2: MusicaGlobal.tocar_deserto()
		3: MusicaGlobal.tocar_bruxa()
		4: MusicaGlobal.tocar_aquatico()
		5: MusicaGlobal.tocar_scifi()
		6: MusicaGlobal.tocar_covil()
		_: MusicaGlobal.tocar_menu()

func obter_cena_entrada_fase(numero_fase: int) -> String:
	var caminho_fase: String = caminhos_das_fases.get(numero_fase, "")
	var caminho_cutscene: String = caminhos_das_cutscenes.get(numero_fase, "")
	if caminho_cutscene != "" and not Global.cutscene_ja_vista(numero_fase):
		return caminho_cutscene
	return caminho_fase

func _set_nivel_base(valor):
	nivel_base = valor
	upgrade_base_aplicado.emit()

# Tenta desbloquear uma conquista pelo caminho do .tres.
# Carrega lazy (uma vez) e ignora silenciosamente se já desbloqueada.
func _tentar_conquista(caminho: String) -> void:
	var id := caminho.get_file().get_basename()
	if id in Global.conquistas_desbloqueadas:
		return
	if not _conquistas_cache.has(caminho):
		_conquistas_cache[caminho] = load(caminho)
	var c = _conquistas_cache.get(caminho)
	if c:
		Global.processar_recompensa(c)

func get_construcoes_disponiveis() -> Array:
	var disponiveis = []
	for nivel in construcoes_permitidas_na_fase:
		if nivel <= nivel_base:
			disponiveis += construcoes_permitidas_na_fase[nivel]
	return disponiveis

func get_todas_construcoes_da_fase() -> Array:
	var resultado = []
	for nivel in construcoes_permitidas_na_fase:
		for cena in construcoes_permitidas_na_fase[nivel]:
			if cena == null: continue
			resultado.append({
				"cena": cena,
				"nivel_necessario": nivel,
				"bloqueado": nivel > nivel_base
			})
	return resultado

## Cache de nomes por resource_path — evita instantiate+free repetido
var _cache_nomes_cenas: Dictionary = {}

## Devolve o nome de exibição de uma cena de construção.
## Usa nome_construcao se definido (e diferente do default "Construção");
## caso contrário, infere pelo caminho do ficheiro.
## Usado pelo menu radial e pelo conselheiro para garantir nomes consistentes.
func nome_para_cena(cena: PackedScene) -> String:
	var path: String = cena.resource_path
	if _cache_nomes_cenas.has(path):
		return _cache_nomes_cenas[path]
	var inst = cena.instantiate()
	var raw: String = str(inst.get("nome_construcao")) if "nome_construcao" in inst else ""
	inst.free()
	var resultado: String
	if raw != "" and raw != "Construção":
		resultado = raw
	else:
		resultado = _nome_por_path(path)
	_cache_nomes_cenas[path] = resultado
	return resultado

## Infere o tipo inteiro (0-5) de uma cena pelo caminho do recurso.
## Centraliza a lógica que antes estava duplicada em ConselheiroIA e aqui.
## Retorna -1 se não reconhecido.
func tipo_por_cena(cena: PackedScene) -> int:
	return _tipo_por_path(cena.resource_path.to_lower())

func _tipo_por_path(p: String) -> int:
	if "tower" in p or "torre" in p or "morteiro" in p or "sniper" in p: return 0
	if "mina" in p: return 1
	if "house" in p or "casa" in p: return 2
	if "mill" in p or "moinho" in p: return 3
	if "quartel" in p: return 4
	return -1

func _nome_por_path(path: String) -> String:
	var p := path.to_lower()
	if "tower" in p or "torre" in p or "morteiro" in p or "sniper" in p: return "Torre"
	if "mina" in p: return "Mina"
	if "house" in p or "casa" in p: return "Casa"
	if "mill" in p or "moinho" in p: return "Moinho"
	if "quartel" in p: return "Quartel"
	return path.get_file().get_basename().capitalize()

# ==========================================
# CICLO DIA / NOITE E ECONOMIA
# ==========================================
func iniciar_dia(primeiro_dia: bool = false):
	estado_atual = EstadoJogo.DIA
	is_night = false
	dia_iniciado.emit(onda_atual)

	if not primeiro_dia:
		calcular_e_recolher_renda()
	_moedas_ao_inicio_dia = moedas   # snapshot APÓS a renda para detectar gasto

	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Torres", "curar_totalmente")

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	spawners_concluidos = 0
	is_night = true
	construcao_destaque_upgrade = null   # Limpa o destaque ao entrar na noite
	_vida_base_ao_iniciar_noite = vida_base_atual

	# Salva ANTES da noite começar — garante que todas as construções
	# do jogador estão no arquivo. Assim ao carregar/reiniciar a noite
	# elas são restauradas corretamente, mesmo que sejam destruídas.
	salvar_jogo()

	noite_iniciada.emit(onda_atual)
	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))

func registrar_spawner_concluido():

	spawners_concluidos += 1
	if spawners_concluidos >= total_spawners:
		terminar_onda()

func terminar_onda():
	if estado_atual == EstadoJogo.DIA: return

	var ultima_onda := Balanceamento.get_int("ultima_onda", 10)
	# Tutorial usa sempre 5 ondas, independente do valor global
	if is_tutorial_ativo:
		ultima_onda = Balanceamento.get_int("tutorial_ultima_onda", 5)
	# Cada fase pode ter um limite próprio de ondas (ex: fase_1_ultima_onda = 5)
	var chave_fase := "fase_%d_ultima_onda" % fase_atual
	if Balanceamento.tem(chave_fase):
		ultima_onda = Balanceamento.get_int(chave_fase, ultima_onda)

	if not modo_infinito and onda_atual >= ultima_onda:
		acionar_vitoria()
		return

	estado_atual = EstadoJogo.DIA
	is_night = false
	onda_terminada.emit()

	# ── Conquistas por onda ──────────────────────────────────────────
	# Sobreviveu a primeira onda
	if onda_atual == 1:
		_tentar_conquista("res://Conquistas/inicio_aventura.tres")
	# Dias consecutivos sem gastar moedas
	if moedas >= _moedas_ao_inicio_dia:
		_dias_sem_gastar += 1
		if _dias_sem_gastar >= 3:
			_tentar_conquista("res://Conquistas/guarda_dinheiro_ondas.tres")
	else:
		_dias_sem_gastar = 0
	# Total acumulado de ondas (persiste entre sessões)
	Global.total_ondas_completadas += 1
	if Global.total_ondas_completadas >= 20:
		_tentar_conquista("res://Conquistas/pagamento_20_ondas.tres")
	# ────────────────────────────────────────────────────────────────

	if onda_atual % 2 != 0:
		sortear_cartas()

	onda_atual += 1
	iniciar_dia()

func get_renda_preview() -> int:
	var config_fase = banco_de_fases.get(fase_atual, {})
	var total: int = config_fase.get("renda_base_por_onda", 0) + bonus_moedas_onda
	if modo_infinito:
		total += Balanceamento.get_int("modo_infinito_bonus_renda", 3)
	var bonus_onda = max(1, 6 - onda_atual)
	# Usa grupo "Economia" (apenas construções de renda) em vez de iterar tudo
	for construcao in get_tree().get_nodes_in_group("Economia"):
		if not is_instance_valid(construcao): continue
		if construcao.get("is_fantasma"): continue
		if construcao.get("esta_destruida"): continue
		if "moedas_por_onda_atual" in construcao:
			total += construcao.moedas_por_onda_atual + bonus_onda
		elif "moedas_por_onda" in construcao:
			total += construcao.moedas_por_onda
	return total

func calcular_e_recolher_renda():
	var config_fase = banco_de_fases[fase_atual]
	var total_renda = config_fase["renda_base_por_onda"] + bonus_moedas_onda
	if modo_infinito:
		total_renda += Balanceamento.get_int("modo_infinito_bonus_renda", 3)

	var construcoes_economia = get_tree().get_nodes_in_group("Economia")
	for construcao in construcoes_economia:
		if construcao.has_method("gerar_renda"):
			total_renda += construcao.gerar_renda()

	moedas += total_renda
	renda_recolhida.emit(total_renda)
	get_tree().call_group("Interface", "atualizar_moedas")
	# Conquista: acumular 1000 moedas ao mesmo tempo
	if moedas >= 1000:
		_tentar_conquista("res://Conquistas/acumula_1000_moedas.tres")

# ==========================================
# SISTEMA DE UPGRADES E CARTAS
# ==========================================
func _baralho_filtrado() -> Array:
	var disponiveis = baralho_upgrades.filter(func(u): return not upgrades_escolhidos.has(u))
	if disponiveis.size() < 3:
		# Fallback: se restam menos de 3, completa com as já escolhidas
		var extras = baralho_upgrades.duplicate()
		extras.shuffle()
		for u in extras:
			if not disponiveis.has(u):
				disponiveis.append(u)
			if disponiveis.size() >= 3:
				break
	disponiveis.shuffle()
	return disponiveis

func sortear_cartas():
	if baralho_upgrades.size() == 0:
		push_error("[GameManager] O baralho de upgrades está vazio no Inspetor!")
		return

	reroll_usado = false

	var copia = _baralho_filtrado()
	var escolhidas = []
	for i in range(3):
		if i < copia.size():
			escolhidas.append(copia[i])

	if is_tutorial_ativo and onda_atual == 1:
		escolhidas[0] = baralho_upgrades[0]

	mostrar_menu_upgrade.emit(escolhidas)

func aplicar_upgrade(dados):
	if not upgrades_escolhidos.has(dados):
		upgrades_escolhidos.append(dados)
	# Sobrescreve valores das cartas com o que estiver no CSV (se houver)
	var valor_bonus_final = dados.valor_bonus
	var id_carta = str(dados.id) if "id" in dados else ""
	if id_carta in _MAPA_UPGRADES:
		var chave = _MAPA_UPGRADES[id_carta]
		if Balanceamento.tem(chave):
			valor_bonus_final = Balanceamento.get_float(chave, dados.valor_bonus)

	_processar_efeito(dados.tipo_bonus, valor_bonus_final)

	if dados.valor_debuff != 0:
		var valor_debuff_final = dados.valor_debuff
		if id_carta in _MAPA_DEBUFFS:
			var chave_d = _MAPA_DEBUFFS[id_carta]
			if Balanceamento.tem(chave_d):
				valor_debuff_final = Balanceamento.get_float(chave_d, dados.valor_debuff)
		_processar_efeito(dados.tipo_debuff, valor_debuff_final)

	upgrade_aplicado.emit()
	get_tree().call_group("Torres", "atualizar_status")
	# Upgrade aplicado — construções podem ter ficado mais baratas; atualiza destaque
	if not is_night:
		_atualizar_destaque_upgrade()
		_timer_destaque_upgrade = 3.0

func _processar_efeito(tipo_efeito, valor):
	match tipo_efeito:
		0: # DANO
			bonus_dano += int(valor)
		1: # MOEDA
			bonus_moedas_onda += int(valor)
		2: # VIDA
			var delta: int = int(valor) if abs(valor) >= 1.0 else int(vida_base_maxima * valor)
			vida_base_maxima = max(1, vida_base_maxima + delta)
			vida_base_atual  = clamp(vida_base_atual + max(0, delta), 1, vida_base_maxima)
			get_tree().call_group("Base", "_aplicar_bonus_vida", delta)
		3: # VELOCIDADE_ATAQUE
			bonus_velocidade_ataque += float(valor)
		4: # VELOCIDADE_INIMIGO
			multiplicador_velocidade_inimigo = max(0.1, multiplicador_velocidade_inimigo + float(valor))
		5: # CUSTO_CONSTRUCAO
			desconto_construcao += int(valor)
		6: # QUANTIDADE_INIMIGOS
			multiplicador_horda = max(0.1, multiplicador_horda + float(valor) / 100.0)
		7: # ALCANCE
			bonus_alcance += float(valor)
		8: # RICOCHETE
			bonus_ricochete += int(valor)
		9: # INFLAMAVEL
			dano_inflamavel += int(valor)
		10: # ESPINHO
			bonus_espinho += int(valor)
		11: # DANO_CHEFE
			bonus_dano_chefe += int(valor)

func rerolar_cartas():
	if reroll_usado:
		return
	if moedas < custo_reroll:
		return
	if baralho_upgrades.size() == 0:
		push_error("[GameManager] O baralho de upgrades está vazio!")
		return

	moedas -= custo_reroll
	get_tree().call_group("Interface", "atualizar_moedas")

	var copia = _baralho_filtrado()
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
		# Moedas mudaram — recalcula destaque imediatamente (construções antes inacessíveis
		# podem ter ficado acessíveis ou vice-versa) e reseta o timer de fallback
		if not is_night:
			_atualizar_destaque_upgrade()
			_timer_destaque_upgrade = 3.0
		return true
	return false

func obter_custo_com_desconto(custo_base: int) -> int:
	return max(1, custo_base - desconto_construcao)


# ==========================================
# SISTEMA DE GAME OVER E REINÍCIO
# ==========================================
func acionar_game_over():
	game_over.emit()
	get_tree().paused = true

func acionar_vitoria():
	var estrelas_ganhas = 1

	if vida_base_maxima > 0:
		var porcentagem = (float(vida_base_atual) / float(vida_base_maxima)) * 100.0
		if porcentagem >= 75.0:
			estrelas_ganhas = 3
		elif porcentagem >= 50.0:
			estrelas_ganhas = 2

	if fase_atual >= Global.fases_liberadas:
		Global.fases_liberadas = fase_atual + 1

	var estrelas_antigas = Global.estrelas_por_fase.get(str(fase_atual), 0)
	if estrelas_ganhas > estrelas_antigas:
		Global.estrelas_por_fase[str(fase_atual)] = estrelas_ganhas

	Global.salvar_progresso()

	# ── Conquistas por vitória ───────────────────────────────────────
	# Fase concluída sem nenhum dano na base
	if vida_base_atual == vida_base_maxima and vida_base_maxima > 0:
		_tentar_conquista("res://Conquistas/defesa_perfeita.tres")
	# Última onda (boss) concluída sem dano na base
	if _vida_base_ao_iniciar_noite == vida_base_atual and vida_base_maxima > 0:
		_tentar_conquista("res://Conquistas/derrota_boss_sem_dano_base.tres")
	# Concluiu o tutorial (fase 1)
	if fase_atual == 1:
		_tentar_conquista("res://Conquistas/primeiros_passos.tres")
	# ────────────────────────────────────────────────────────────────

	vitoria.emit()
	get_tree().paused = true

func limpar_estado_sessao() -> void:
	# Reseta bônus e modificadores de sessão sem trocar de cena nem emitir sinais.
	# Chame (com get_tree().paused = false no chamador) antes de change_scene_to_file().
	onda_atual         = 1
	bonus_dano         = 0
	bonus_moedas_onda  = 0
	bonus_velocidade_ataque     = 0.0
	desconto_construcao         = 0
	multiplicador_horda              = 1.0
	multiplicador_velocidade_inimigo = 1.0
	bonus_alcance      = 0.0
	bonus_ricochete    = 0
	dano_inflamavel    = 0
	bonus_espinho      = 0
	bonus_dano_chefe   = 0
	upgrades_escolhidos.clear()
	# Garante que construções de uma sessão antiga nunca vazem para outra
	dados_construcoes_pendentes.clear()
	recarregando_save = false
	# Reseta nivel_base para 0: a base lê esse valor em _ready() ao carregar a cena,
	# então deve estar limpo antes de qualquer change_scene_to_file() para nova partida.
	_set_nivel_base(0)

func reiniciar_partida():
	get_tree().paused = false
	var cfg = banco_de_fases.get(fase_atual, banco_de_fases[1])
	moedas      = cfg["moedas_iniciais"]
	nivel_base  = cfg["nivel_base_inicial"]
	limpar_estado_sessao()
	get_tree().reload_current_scene()

func adicionar_moedas(quantidade: int):
	moedas += quantidade
	get_tree().call_group("Interface", "atualizar_moedas")

# ==========================================
# SISTEMA DE SAVE / LOAD E REINÍCIO DE NOITE
# ==========================================
const SAVE_PATH = "user://save.cfg"
const _SAVE_PATH_JSON_ANTIGO = "user://save_jogo.json"
var dados_construcoes_pendentes: Array = []

# Retorna true se existe uma sessão de jogo guardada
func tem_jogo_salvo() -> bool:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return config.has_section("sessao")

func salvar_jogo():
	var config = ConfigFile.new()
	# Carrega dados existentes para não apagar o progresso do Global
	config.load(SAVE_PATH)

	config.set_value("sessao", "fase_atual", fase_atual)
	config.set_value("sessao", "moedas", moedas)
	config.set_value("sessao", "onda_atual", onda_atual)
	config.set_value("sessao", "nivel_base", nivel_base)
	config.set_value("sessao", "is_tutorial_ativo", is_tutorial_ativo)
	config.set_value("sessao", "bonus_dano", bonus_dano)
	config.set_value("sessao", "bonus_moedas_onda", bonus_moedas_onda)
	config.set_value("sessao", "bonus_velocidade_ataque", bonus_velocidade_ataque)
	config.set_value("sessao", "desconto_construcao", desconto_construcao)
	config.set_value("sessao", "multiplicador_horda", multiplicador_horda)
	config.set_value("sessao", "multiplicador_velocidade_inimigo", multiplicador_velocidade_inimigo)
	config.set_value("sessao", "bonus_alcance", bonus_alcance)
	config.set_value("sessao", "bonus_ricochete", bonus_ricochete)
	config.set_value("sessao", "dano_inflamavel", dano_inflamavel)
	config.set_value("sessao", "bonus_espinho", bonus_espinho)
	config.set_value("sessao", "bonus_dano_chefe", bonus_dano_chefe)
	config.set_value("sessao", "modo_infinito", modo_infinito)

	# Salva os upgrades já escolhidos pelos caminhos de recurso para restaurar o baralho filtrado
	var paths_upgrades: Array = upgrades_escolhidos.map(func(u): return u.resource_path)
	config.set_value("sessao", "upgrades_escolhidos_paths", paths_upgrades)

	# Recolhe todas as construções do grupo canônico "Construcao"
	var lista_construcoes: Array = []
	for construcao in get_tree().get_nodes_in_group("Construcao"):
		if construcao.is_in_group("Base"): continue
		lista_construcoes.append(_dados_construcao(construcao))

	config.set_value("construcoes", "lista", lista_construcoes)

	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("[GameManager] Falha ao salvar jogo: %d" % err)

func _dados_construcao(construcao: Node) -> Dictionary:
	return {
		"caminho_cena": construcao.scene_file_path,
		"pos_x": construcao.global_position.x,
		"pos_y": construcao.global_position.y,
		"pos_z": construcao.global_position.z,
		"nivel_atual": construcao.nivel_atual if "nivel_atual" in construcao else 0,
		"caminho_atual": construcao.caminho_atual if "caminho_atual" in construcao else -1
	}

func carregar_jogo() -> bool:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		# Tenta migrar do formato JSON antigo
		return _migrar_save_json()

	if not config.has_section("sessao"):
		return false

	fase_atual        = config.get_value("sessao", "fase_atual", 1)
	moedas            = config.get_value("sessao", "moedas", 10)
	onda_atual        = config.get_value("sessao", "onda_atual", 1)
	_set_nivel_base(config.get_value("sessao", "nivel_base", 0))
	is_tutorial_ativo = config.get_value("sessao", "is_tutorial_ativo", false)
	# NÃO chama iniciar_dia() aqui — isso adicionaria renda como se fosse um
	# novo dia. Os chamadores (carregar_jogo_salvo_manual / reiniciar_noite_atual)
	# emitem dia_iniciado no momento certo, depois das construções restauradas.
	estado_atual = EstadoJogo.DIA
	is_night     = false

	bonus_dano                    = config.get_value("sessao", "bonus_dano", 0)
	bonus_moedas_onda             = config.get_value("sessao", "bonus_moedas_onda", 0)
	bonus_velocidade_ataque       = config.get_value("sessao", "bonus_velocidade_ataque", 0.0)
	desconto_construcao           = config.get_value("sessao", "desconto_construcao", 0)
	multiplicador_horda           = config.get_value("sessao", "multiplicador_horda", 1.0)
	multiplicador_velocidade_inimigo = config.get_value("sessao", "multiplicador_velocidade_inimigo", 1.0)
	bonus_alcance                 = config.get_value("sessao", "bonus_alcance", 0.0)
	bonus_ricochete               = config.get_value("sessao", "bonus_ricochete", 0)
	dano_inflamavel               = config.get_value("sessao", "dano_inflamavel", 0)
	bonus_espinho                 = config.get_value("sessao", "bonus_espinho", 0)
	bonus_dano_chefe              = config.get_value("sessao", "bonus_dano_chefe", 0)
	modo_infinito                 = config.get_value("sessao", "modo_infinito", false)

	# Restaura upgrades já escolhidos para que o baralho filtrado continue correto
	var paths_ups: Array = config.get_value("sessao", "upgrades_escolhidos_paths", [])
	upgrades_escolhidos.clear()
	for path in paths_ups:
		for u in baralho_upgrades:
			if u.resource_path == path:
				upgrades_escolhidos.append(u)
				break

	dados_construcoes_pendentes = config.get_value("construcoes", "lista", [])

	get_tree().call_group("Interface", "atualizar_moedas")
	return true

# Migração de saves no formato JSON antigo (save_jogo.json)
func _migrar_save_json() -> bool:
	if not FileAccess.file_exists(_SAVE_PATH_JSON_ANTIGO):
		return false
	var arquivo = FileAccess.open(_SAVE_PATH_JSON_ANTIGO, FileAccess.READ)
	var dados_save = JSON.parse_string(arquivo.get_as_text())
	if not dados_save:
		return false

	fase_atual        = dados_save.get("fase_atual", 1)
	moedas            = dados_save.get("moedas", 10)
	onda_atual        = dados_save.get("onda_atual", 1)
	_set_nivel_base(dados_save.get("nivel_base", 0))
	is_tutorial_ativo = dados_save.get("is_tutorial_ativo", false)
	estado_atual = EstadoJogo.DIA
	is_night     = false

	bonus_dano                    = dados_save.get("bonus_dano", 0)
	bonus_moedas_onda             = dados_save.get("bonus_moedas_onda", 0)
	bonus_velocidade_ataque       = dados_save.get("bonus_velocidade_ataque", 0.0)
	desconto_construcao           = dados_save.get("desconto_construcao", 0)
	multiplicador_horda           = dados_save.get("multiplicador_horda", 1.0)
	multiplicador_velocidade_inimigo = dados_save.get("multiplicador_velocidade_inimigo", 1.0)
	bonus_alcance                 = dados_save.get("bonus_alcance", 0.0)
	bonus_ricochete               = dados_save.get("bonus_ricochete", 0)
	dano_inflamavel               = dados_save.get("dano_inflamavel", 0)
	bonus_espinho                 = dados_save.get("bonus_espinho", 0)
	bonus_dano_chefe              = dados_save.get("bonus_dano_chefe", 0)
	modo_infinito                 = dados_save.get("modo_infinito", false)
	dados_construcoes_pendentes   = dados_save.get("construcoes", [])

	get_tree().call_group("Interface", "atualizar_moedas")
	# Converte imediatamente para o novo formato
	salvar_jogo()
	return true

func _restaurar_construcoes(lista_construcoes):
	await get_tree().process_frame
	var todos_os_slots = get_tree().get_nodes_in_group("BuildSlots")

	if Global.DEBUG_MODE:
		print("[GameManager] Restaurando %d construções em %d slots." % [lista_construcoes.size(), todos_os_slots.size()])

	for dados_c in lista_construcoes:
		if dados_c["caminho_cena"] == "": continue

		var cena_construcao = load(dados_c["caminho_cena"])
		if not cena_construcao:
			continue

		var pos_salva = Vector3(dados_c["pos_x"], dados_c["pos_y"], dados_c.get("pos_z", 0))
		var nova_construcao = cena_construcao.instantiate()

		if "nivel_atual" in nova_construcao and dados_c.has("nivel_atual"):
			nova_construcao.nivel_atual = dados_c["nivel_atual"]
		if "caminho_atual" in nova_construcao and dados_c.has("caminho_atual"):
			nova_construcao.caminho_atual = dados_c["caminho_atual"]

		var slot_dono = null
		var menor_distancia = 10.0

		for slot in todos_os_slots:
			var dist = slot.global_position.distance_to(pos_salva)
			if dist < 1.0 and dist < menor_distancia:
				slot_dono = slot
				menor_distancia = dist

		if slot_dono:
			slot_dono.add_child(nova_construcao)
			nova_construcao.position = Vector3.ZERO
			nova_construcao.is_fantasma = false

			if slot_dono.has_method("configurar_como_ocupado"):
				slot_dono.configurar_como_ocupado()
			else:
				slot_dono.is_built = true
				if "base_mesh" in slot_dono and slot_dono.base_mesh: slot_dono.base_mesh.hide()
				if "canvas_mobile" in slot_dono and slot_dono.canvas_mobile: slot_dono.canvas_mobile.hide()

			if nova_construcao.has_signal("tree_exited"):
				if not nova_construcao.tree_exited.is_connected(slot_dono.reativar_slot):
					nova_construcao.tree_exited.connect(slot_dono.reativar_slot)
		else:
			if Global.DEBUG_MODE:
				print("[GameManager] Slot não encontrado perto de %s. Adicionando ao mundo." % str(pos_salva))
			get_tree().current_scene.add_child(nova_construcao)
			nova_construcao.global_position = pos_salva
			nova_construcao.is_fantasma = false

# Apaga apenas os dados de sessão (mantém o progresso do jogador)
func apagar_save():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		config.erase_section("sessao")
		config.erase_section("construcoes")
		config.save(SAVE_PATH)
	# Remove também o JSON antigo, se ainda existir
	if FileAccess.file_exists(_SAVE_PATH_JSON_ANTIGO):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("save_jogo.json")

func reiniciar_noite_atual():
	get_tree().paused = false

	if carregar_jogo():
		recarregando_save = true

		get_tree().reload_current_scene()

		await get_tree().tree_changed
		await get_tree().process_frame

		carregar_fase(fase_atual)

		await get_tree().create_timer(0.1).timeout

		if dados_construcoes_pendentes.size() > 0:
			await _restaurar_construcoes(dados_construcoes_pendentes)
			dados_construcoes_pendentes.clear()

		estado_atual = EstadoJogo.DIA
		is_night = false

		_set_nivel_base(nivel_base)
		get_tree().call_group("Interface", "atualizar_moedas")

		dia_iniciado.emit(onda_atual)
		get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))
		get_tree().call_group("Interface", "verificar_estado_dia_noite")
		get_tree().call_group("Torres", "curar_totalmente")
		get_tree().call_group("Spawner", "restaurar_onda_do_save")

		recarregando_save = false
	else:
		push_warning("[GameManager] Nenhum save encontrado ao reiniciar a noite. Fazendo reload simples.")
		get_tree().reload_current_scene()

# ==========================================
# DESTAQUE DE UPGRADE — lógica de seleção
# ==========================================
# Mesmo critério do ConselheiroIA (prioridade 3):
#   torres têm preferência; em empate, o upgrade mais barato vence.

# Helper: custo candidato para o próximo upgrade.
# Lida com construções de múltiplos caminhos (tem_paths) que ainda não
# escolheram um caminho — nesses casos retorna o menor custo inicial entre
# os paths disponíveis, em vez de -1 (que get_custo_proximo_upgrade retorna).
func _custo_candidato_upgrade(c: Node) -> int:
	var tem_paths_c: bool = c.get("tem_paths") if "tem_paths" in c else false
	var caminho_c: int    = c.get("caminho_atual") if "caminho_atual" in c else -1
	if tem_paths_c and caminho_c == -1:
		var paths = c.get("upgrade_paths")
		if paths == null or paths.size() == 0:
			return -1
		var menor: int = -1
		for path in paths:
			if path == null or path.custos.size() == 0:
				continue
			var cp: int = path.custos[0]
			if menor < 0 or cp < menor:
				menor = cp
		return menor
	if c.has_method("get_custo_proximo_upgrade"):
		return c.get_custo_proximo_upgrade()
	return -1

func _atualizar_destaque_upgrade() -> void:
	if get_tree() == null:
		construcao_destaque_upgrade = null
		return
	var construcoes = get_tree().get_nodes_in_group("Construcao")

	# Conquista: primeira construção colocada (verifica a cada segundo durante o dia)
	for c in construcoes:
		if not is_instance_valid(c): continue
		if c.is_in_group("Base"): continue
		if c.get("is_fantasma"): continue
		if c.get("tipo") == 5: continue  # ignora a própria base
		_tentar_conquista("res://Conquistas/primeira_compra.tres")
		break

	var melhor: Node  = null
	var melhor_custo: int = moedas + 1
	for c in construcoes:
		if not is_instance_valid(c):        continue
		if c.is_in_group("Base"):           continue
		if not ("tipo" in c):               continue
		var est = c.get("esta_destruida")
		if est != null and est:             continue
		var custo_raw: int = _custo_candidato_upgrade(c)
		if custo_raw <= 0:                  continue
		var custo_final: int = obter_custo_com_desconto(custo_raw)
		if custo_final > moedas:            continue
		# Torres têm prioridade; em empate escolhe o mais barato
		var eh_torre: bool       = (c.tipo == 0)
		var melhor_eh_torre: bool = (melhor != null and melhor.tipo == 0)
		if melhor == null \
		   or (eh_torre and not melhor_eh_torre) \
		   or (eh_torre == melhor_eh_torre and custo_final < melhor_custo):
			melhor_custo = custo_final
			melhor       = c
	construcao_destaque_upgrade = melhor
