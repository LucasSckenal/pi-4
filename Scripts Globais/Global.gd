extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save.cfg"
const _SAVE_PATH_ANTIGO = "user://save_game.cfg"
const SETTINGS_PATH = "user://settings.cfg"  # mesmo ficheiro usado por configuracoes.gd

# --- MODO DEBUG ---
## Coloque true durante o desenvolvimento para ver os prints de diagnóstico.
## Mantenha false em builds de produção.
const DEBUG_MODE: bool = false
var _save_count: int = 0  # Contador para throttle do backup (1 backup a cada 5 saves)

# --- VARIÁVEIS DE ESTADO ---
var hud_tematico_ativo: bool = true   # controlado por configuracoes.gd / CheckHUD
var shake_tela_ativo: bool = true     # controlado por configuracoes.gd / CheckShakeTela
var numeros_dano_ativo: bool = true   # controlado por configuracoes.gd / CheckNumerosDano

var personagem_jogado_atualmente : String = "avo_m"
var personagem_escolhido_path: String = ""

# Personagens base disponíveis para seleção
var lista_personagens: Array = [
	"res://Assets/Personagens/personagem_m.tscn",
	"res://Assets/Personagens/personagem_f.tscn"
]

func is_personagem_liberado(_indice: int) -> bool:
	return true  # Avô e avó sempre disponíveis

# --- PROGRESSO DO MAPA ---
var fases_liberadas: int = 1
# Quantos mapas o jogador já viu "revelados" no seletor. Mapas com índice acima
# disto (mas já liberados) aparecem com animação de descoberta na próxima visita.
var mapas_revelados: int = 0
var estrelas_por_fase: Dictionary = {}
var cutscenes_vistas: Array = []

# Progresso do Jogador
var conquistas_desbloqueadas: Array = []
var armas_desbloqueadas: Array = ["arma_katana"]
var chapeus_desbloqueados: Array = ["Nenhum"]
var armadura_darksouls_desbloqueada: bool = false
var armadura_bloodborne_desbloqueada: bool = false
var usando_set_especial: bool = false
var usando_set_bloodborne: bool = false
var armadura_hollow_knight_desbloqueada: bool = false
var usando_set_hollow_knight: bool = false

var armadura_kakashi_desbloqueada: bool = false
var usando_set_kakashi: bool = false

var inimigos_descobertos: Array = []
var cartas_obtidas: Array = []   # ids das cartas que o jogador já pegou em batalha
var construcoes_descobertas: Array = []   # ids das construções que o jogador já ergueu
var total_ondas_completadas: int = 0

# Registra a descoberta de uma construção (ao ser construída/melhorada pela 1ª vez).
func descobrir_construcao(id: String) -> void:
	if id == "" or construcoes_descobertas.has(id):
		return
	construcoes_descobertas.append(id)
	salvar_progresso()

# --- ESTATÍSTICAS (persistentes) ---
var total_inimigos_mortos: int = 0   # acumulado entre todas as partidas
var melhor_onda_infinito: int = 0    # recorde do modo infinito
var tempo_jogado_total: float = 0.0  # segundos totais jogados (em fases)

# O que cada um tem equipado neste momento
var equip_avo_m = { "arma": "arma_katana", "chapeu": "Nenhum" }
var equip_avo_f = { "arma": "arma_katana", "chapeu": "Nenhum" }

# --- SINAL DO POP-UP ---
signal conquista_desbloqueada(nome_conquista, id_item_liberado, icone_conquista)
signal progresso_salvo


func _ready():
	_carregar_preferencias_video()
	carregar_progresso()
	# Save que já tinha todas as conquistas libera o chapéu de 100% ao abrir o jogo
	verificar_100_porcento()


# Lê as preferências de vídeo (toggles) no arranque para valerem já na 1ª fase,
# sem precisar abrir o menu de configurações. configuracoes.gd continua a ser a
# fonte de escrita; aqui só replicamos a leitura das flags puras (sem efeitos colaterais).
func _carregar_preferencias_video() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	hud_tematico_ativo = cfg.get_value("video", "hud_customizado", true)
	shake_tela_ativo   = cfg.get_value("video", "shake_tela", true)
	numeros_dano_ativo = cfg.get_value("video", "numeros_dano", true)


# --- SISTEMA DE RECOMPENSAS E CONQUISTAS ---
func processar_recompensa(conquista: ConquistaData):
	var precisa_salvar = false
	var itens_ganhos: Array = []

	if not conquista.id in conquistas_desbloqueadas:
		conquistas_desbloqueadas.append(conquista.id)
		precisa_salvar = true

	if conquista.libera_arma_id != "":
		if not conquista.libera_arma_id in armas_desbloqueadas:
			armas_desbloqueadas.append(conquista.libera_arma_id)
			itens_ganhos.append(conquista.libera_arma_id)
			precisa_salvar = true

	if conquista.libera_chapeu_id != "":
		if not conquista.libera_chapeu_id in chapeus_desbloqueados:
			chapeus_desbloqueados.append(conquista.libera_chapeu_id)
			itens_ganhos.append(conquista.libera_chapeu_id)
			precisa_salvar = true

	if precisa_salvar:
		salvar_progresso()
		_atualizar_interface_customizacao()
		conquista_desbloqueada.emit(conquista.nome, itens_ganhos, conquista.icone)

	# Após qualquer conquista, verifica se o jogo chegou a 100% (libera o chapéu do Ash).
	# Guard: não re-checa ao conceder a PRÓPRIA conquista de 100% (evita recursão).
	if conquista.id != CONQUISTA_100_ID:
		verificar_100_porcento()

# ==========================================
# CONQUISTA DE 100% — desbloqueia ao ter TODAS as outras conquistas
# ==========================================
const CONQUISTA_100_ID := "colecionador_supremo"
const CONQUISTA_100_PATH := "res://Conquistas/colecionador_supremo.tres"

func verificar_100_porcento() -> void:
	if CONQUISTA_100_ID in conquistas_desbloqueadas:
		return
	var dir = DirAccess.open("res://Conquistas/")
	if not dir:
		return
	dir.list_dir_begin()
	var arq = dir.get_next()
	while arq != "":
		var limpo = arq.trim_suffix(".remap")
		if limpo.ends_with(".tres") or limpo.ends_with(".res"):
			var c = load("res://Conquistas/" + limpo)
			if c is ConquistaData and c.id != CONQUISTA_100_ID:
				if not c.id in conquistas_desbloqueadas:
					return  # ainda falta alguma conquista → não está 100%
		arq = dir.get_next()
	# Todas as outras estão desbloqueadas → concede a de 100% (libera o chapéu)
	var c100 = load(CONQUISTA_100_PATH)
	if c100 is ConquistaData:
		processar_recompensa(c100)


func _atualizar_interface_customizacao():
	get_tree().call_group("MenuCustomizacao", "_gerar_botoes_armas")
	get_tree().call_group("MenuCustomizacao", "_gerar_botoes_chapeus")


# --- FUNÇÕES DE EQUIPAMENTO ---
func equipar_arma(personagem: String, id_arma: String):
	if personagem == "avo_m":
		equip_avo_m["arma"] = id_arma
	elif personagem == "avo_f":
		equip_avo_f["arma"] = id_arma
	salvar_progresso()


# --- SISTEMA DE SAVE ---
func salvar_progresso():
	verificar_desbloqueios_por_estrelas()
	var config = ConfigFile.new()
	# Carrega dados existentes para não apagar a sessão do GameManager
	config.load(SAVE_PATH)

	config.set_value("progresso", "fases_liberadas", fases_liberadas)
	config.set_value("progresso", "mapas_revelados", mapas_revelados)
	config.set_value("progresso", "estrelas_por_fase", estrelas_por_fase)
	config.set_value("progresso", "cutscenes_vistas", cutscenes_vistas)
	config.set_value("progresso", "inimigos", inimigos_descobertos)
	config.set_value("progresso", "cartas_obtidas", cartas_obtidas)
	config.set_value("progresso", "construcoes_descobertas", construcoes_descobertas)
	config.set_value("progresso", "conquistas", conquistas_desbloqueadas)
	config.set_value("progresso", "total_ondas_completadas", total_ondas_completadas)
	config.set_value("estatisticas", "inimigos_mortos", total_inimigos_mortos)
	config.set_value("estatisticas", "melhor_onda_infinito", melhor_onda_infinito)
	config.set_value("estatisticas", "tempo_jogado", tempo_jogado_total)
	config.set_value("inventario", "armas_ganhas", armas_desbloqueadas)
	config.set_value("inventario", "chapeus_ganhos", chapeus_desbloqueados)
	config.set_value("equipamentos", "avo_m", equip_avo_m)
	config.set_value("equipamentos", "avo_f", equip_avo_f)
	config.set_value("sets_especiais", "darksouls", armadura_darksouls_desbloqueada)
	config.set_value("sets_especiais", "bloodborne", armadura_bloodborne_desbloqueada)
	config.set_value("sets_especiais", "hollow", armadura_hollow_knight_desbloqueada)
	config.set_value("sets_especiais", "kakashi", armadura_kakashi_desbloqueada)

	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("[Global] Falha ao guardar progresso: %d" % err)
	else:
		# Backup a cada 5 saves para não fazer I/O duplo em cada save trivial
		_save_count += 1
		if _save_count % 5 == 0:
			config.save(SAVE_PATH.replace(".cfg", "_backup.cfg"))
		progresso_salvo.emit()


# Migração: corrige nomes de inimigos renomeados depois que alguns saves já existiam.
# Ex.: o lacaio do deserto se chamava "Desert minion" antes de virar "Servo do Deserto".
func _migrar_nomes_inimigos() -> void:
	var renomeados := {
		"Desert minion": "Servo do Deserto",
		"Tentáculo Cósmico": "Tentáculo",
	}
	var mudou := false
	for antigo in renomeados:
		if inimigos_descobertos.has(antigo):
			inimigos_descobertos.erase(antigo)
			var novo: String = renomeados[antigo]
			if not inimigos_descobertos.has(novo):
				inimigos_descobertos.append(novo)
			mudou = true
	if mudou:
		salvar_progresso()

func carregar_progresso():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)

	# Tenta migrar do formato antigo (save_game.cfg) se o novo ainda não existir
	if err != OK:
		err = config.load(_SAVE_PATH_ANTIGO)
		if err != OK:
			return
		# Converte imediatamente para o novo ficheiro unificado
		salvar_progresso()

	# Suporte à migração da secção "mapa" (formato antigo) para "progresso"
	fases_liberadas   = config.get_value("progresso", "fases_liberadas",
						config.get_value("mapa", "fases_liberadas", 1))
	mapas_revelados   = config.get_value("progresso", "mapas_revelados", 0)
	estrelas_por_fase = config.get_value("progresso", "estrelas_por_fase",
						config.get_value("mapa", "estrelas_por_fase", {}))
	cutscenes_vistas = config.get_value("progresso", "cutscenes_vistas", [])

	inimigos_descobertos         = config.get_value("progresso", "inimigos", [])
	_migrar_nomes_inimigos()  # corrige nomes de inimigos renomeados em saves antigos
	cartas_obtidas               = config.get_value("progresso", "cartas_obtidas", [])
	construcoes_descobertas      = config.get_value("progresso", "construcoes_descobertas", [])
	conquistas_desbloqueadas     = config.get_value("progresso", "conquistas", [])
	total_ondas_completadas      = config.get_value("progresso", "total_ondas_completadas", 0)
	total_inimigos_mortos        = config.get_value("estatisticas", "inimigos_mortos", 0)
	melhor_onda_infinito         = config.get_value("estatisticas", "melhor_onda_infinito", 0)
	tempo_jogado_total           = config.get_value("estatisticas", "tempo_jogado", 0.0)
	armas_desbloqueadas       = config.get_value("inventario", "armas_ganhas", ["arma_katana"])
	chapeus_desbloqueados     = config.get_value("inventario", "chapeus_ganhos", ["Nenhum"])
	equip_avo_m               = config.get_value("equipamentos", "avo_m", {"arma": "arma_katana", "chapeu": "Nenhum"})
	equip_avo_f               = config.get_value("equipamentos", "avo_f", {"arma": "arma_katana", "chapeu": "Nenhum"})
	armadura_darksouls_desbloqueada      = config.get_value("sets_especiais", "darksouls", false)
	armadura_bloodborne_desbloqueada     = config.get_value("sets_especiais", "bloodborne", false)
	armadura_hollow_knight_desbloqueada  = config.get_value("sets_especiais", "hollow", false)
	armadura_kakashi_desbloqueada        = config.get_value("sets_especiais", "kakashi", false)
	verificar_desbloqueios_por_estrelas()


# --- SISTEMA DE DEBUG ---
func _input(event):
	if event is InputEventKey and event.pressed:

		if event.keycode == KEY_J:
			resetar_tudo()

		if event.keycode == KEY_L:
			if Global.DEBUG_MODE:
				print("\n--- STATUS DO SAVE ---")
				print("Conquistas Completas: ", conquistas_desbloqueadas)
				print("Armas Desbloqueadas: ", armas_desbloqueadas)
				print("Chapéus Desbloqueados: ", chapeus_desbloqueados)
				print("Equip Avô: ", equip_avo_m)
				print("Equip Avó: ", equip_avo_f)
				print("----------------------\n")


func resetar_tudo():
	fases_liberadas = 1
	mapas_revelados = 0
	estrelas_por_fase = {}
	cutscenes_vistas = []

	conquistas_desbloqueadas = []
	armas_desbloqueadas = ["arma_katana"]
	chapeus_desbloqueados = ["Nenhum"]
	inimigos_descobertos = []
	cartas_obtidas = []
	construcoes_descobertas = []
	total_ondas_completadas = 0
	total_inimigos_mortos = 0
	melhor_onda_infinito = 0
	tempo_jogado_total = 0.0
	equip_avo_m = { "arma": "arma_katana", "chapeu": "Nenhum" }
	equip_avo_f = { "arma": "arma_katana", "chapeu": "Nenhum" }
	armadura_darksouls_desbloqueada = false
	armadura_bloodborne_desbloqueada = false
	armadura_hollow_knight_desbloqueada = false
	armadura_kakashi_desbloqueada = false
	salvar_progresso()


func obter_total_estrelas() -> int:
	var total = 0
	for qtd in estrelas_por_fase.values():
		total += qtd
	return total

func formatar_tempo_jogado() -> String:
	var s := int(tempo_jogado_total)
	
	@warning_ignore("integer_division")
	var h := s / 3600
	
	@warning_ignore("integer_division")
	var m := (s % 3600) / 60
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm %ds" % [m, s % 60]

func cutscene_ja_vista(numero_fase: int) -> bool:
	return str(numero_fase) in cutscenes_vistas

func registrar_cutscene_vista(numero_fase: int) -> void:
	var chave := str(numero_fase)
	if chave in cutscenes_vistas:
		return
	cutscenes_vistas.append(chave)
	salvar_progresso()

func verificar_desbloqueios_por_estrelas():
	var total = obter_total_estrelas()
	var houve_novo := false

	if total >= 3 and not armadura_hollow_knight_desbloqueada:
		armadura_hollow_knight_desbloqueada = true
		houve_novo = true
		conquista_desbloqueada.emit("HollowKnight Head", ["HollowKnight Head"], null)

	if total >= 8 and not armadura_kakashi_desbloqueada:
		armadura_kakashi_desbloqueada = true
		houve_novo = true
		conquista_desbloqueada.emit("Set Kakashi", ["Set Kakashi"], null)

	if total >= 13 and not armadura_bloodborne_desbloqueada:
		armadura_bloodborne_desbloqueada = true
		houve_novo = true
		conquista_desbloqueada.emit("Set Bloodborne", ["Set Bloodborne"], null)

	if total >= 18 and not armadura_darksouls_desbloqueada:
		armadura_darksouls_desbloqueada = true
		houve_novo = true
		conquista_desbloqueada.emit("Set Dark Souls", ["Set Dark Souls"], null)

	if houve_novo:
		_atualizar_interface_customizacao()
