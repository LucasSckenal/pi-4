extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save.cfg"
const _SAVE_PATH_ANTIGO = "user://save_game.cfg"

# --- VARIÁVEIS DE ESTADO ---
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
var estrelas_por_fase: Dictionary = {}

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

# O que cada um tem equipado neste momento
var equip_avo_m = { "arma": "arma_katana", "chapeu": "Nenhum" }
var equip_avo_f = { "arma": "arma_katana", "chapeu": "Nenhum" }

# --- SINAL DO POP-UP ---
signal conquista_desbloqueada(nome_conquista, id_item_liberado, icone_conquista)
signal progresso_salvo


func _ready():
	carregar_progresso()


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
	config.set_value("progresso", "estrelas_por_fase", estrelas_por_fase)
	config.set_value("progresso", "inimigos", inimigos_descobertos)
	config.set_value("progresso", "conquistas", conquistas_desbloqueadas)
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
		config.save(SAVE_PATH.replace(".cfg", "_backup.cfg"))
		progresso_salvo.emit()


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
	estrelas_por_fase = config.get_value("progresso", "estrelas_por_fase",
						config.get_value("mapa", "estrelas_por_fase", {}))

	inimigos_descobertos      = config.get_value("progresso", "inimigos", [])
	conquistas_desbloqueadas  = config.get_value("progresso", "conquistas", [])
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
			print("\n--- STATUS DO SAVE ---")
			print("Conquistas Completas: ", conquistas_desbloqueadas)
			print("Armas Desbloqueadas: ", armas_desbloqueadas)
			print("Chapéus Desbloqueados: ", chapeus_desbloqueados)
			print("Equip Avô: ", equip_avo_m)
			print("Equip Avó: ", equip_avo_f)
			print("----------------------\n")


func resetar_tudo():
	fases_liberadas = 1
	estrelas_por_fase = {}

	conquistas_desbloqueadas = []
	armas_desbloqueadas = ["arma_katana"]
	chapeus_desbloqueados = ["Nenhum"]
	inimigos_descobertos = []
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

func verificar_desbloqueios_por_estrelas():
	var total = obter_total_estrelas()

	if total >= 3:
		armadura_hollow_knight_desbloqueada = true

	if total >= 8:
		armadura_kakashi_desbloqueada = true

	if total >= 13:
		armadura_bloodborne_desbloqueada = true

	if total >= 18:
		armadura_darksouls_desbloqueada = true
