extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save_game.cfg"

# --- VARIÁVEIS DE ESTADO ---
var personagem_jogado_atualmente : String = "avo_m"

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

# --- SINAL DO POP-UP (O seu popup_conquista.gd precisa disto!) ---
signal conquista_desbloqueada(nome_conquista, id_item_liberado, icone_conquista)


func _ready():
	carregar_progresso()


# --- SISTEMA DE RECOMPENSAS E CONQUISTAS ---
# Chame esta função passando o Resource da conquista sempre que o jogador ganhar uma!
func processar_recompensa(conquista: ConquistaData):
	var precisa_salvar = false
	var itens_ganhos: Array = [] # <--- AGORA É UMA LISTA!
	
	# 1. Regista que a conquista foi ganha
	if not conquista.id in conquistas_desbloqueadas:
		conquistas_desbloqueadas.append(conquista.id)
		precisa_salvar = true
		
	# 2. Verifica se essa conquista dá uma ARMA
	if conquista.libera_arma_id != "":
		if not conquista.libera_arma_id in armas_desbloqueadas:
			armas_desbloqueadas.append(conquista.libera_arma_id)
			itens_ganhos.append(conquista.libera_arma_id) # Adiciona à lista
			precisa_salvar = true
			
	# 3. Verifica se essa conquista dá um CHAPÉU
	if conquista.libera_chapeu_id != "":
		if not conquista.libera_chapeu_id in chapeus_desbloqueados:
			chapeus_desbloqueados.append(conquista.libera_chapeu_id)
			itens_ganhos.append(conquista.libera_chapeu_id) # Adiciona à lista
			precisa_salvar = true
			
	# 4. Só salva e avisa a interface se tiver ganho algo novo
	if precisa_salvar:
		salvar_progresso()
		_atualizar_interface_customizacao()
		
		# Envia a LISTA de itens para o Pop-up!
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
	
	# Adicione estas duas linhas para salvar o mapa
	config.set_value("mapa", "fases_liberadas", fases_liberadas)
	config.set_value("mapa", "estrelas_por_fase", estrelas_por_fase)
	config.set_value("progresso", "inimigos", inimigos_descobertos)
	# Mantenha o resto que já tem 
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
		print("[ERRO] Falha ao guardar ficheiro: ", err)


func carregar_progresso():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		return
	
	fases_liberadas = config.get_value("mapa", "fases_liberadas", 1)
	estrelas_por_fase = config.get_value("mapa", "estrelas_por_fase", {})
	inimigos_descobertos = config.get_value("progresso", "inimigos", [])
	conquistas_desbloqueadas = config.get_value("progresso", "conquistas", [])
	armas_desbloqueadas = config.get_value("inventario", "armas_ganhas", ["arma_katana"])
	chapeus_desbloqueados = config.get_value("inventario", "chapeus_ganhos", ["Nenhum"])
	equip_avo_m = config.get_value("equipamentos", "avo_m", {"arma": "arma_katana", "chapeu": "Nenhum"})
	equip_avo_f = config.get_value("equipamentos", "avo_f", {"arma": "arma_katana", "chapeu": "Nenhum"})
	armadura_darksouls_desbloqueada = config.get_value("sets_especiais", "darksouls", false)
	armadura_bloodborne_desbloqueada = config.get_value("sets_especiais", "bloodborne", false)
	armadura_hollow_knight_desbloqueada = config.get_value("sets_especiais", "hollow", false)
	armadura_kakashi_desbloqueada = config.get_value("sets_especiais", "kakashi", false)
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
	# --- RESET DO MAPA E ESTRELAS ---
	fases_liberadas = 1
	estrelas_por_fase = {}
	
	# --- RESET DO QUE JÁ TINHAS ---
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
	# MUITO IMPORTANTE: Salvar após o reset para limpar o ficheiro no PC
	salvar_progresso()
	
	print("Progresso total resetado com sucesso!")
	
func obter_total_estrelas() -> int:
	var total = 0
	for qtd in estrelas_por_fase.values():
		total += qtd
	return total

func verificar_desbloqueios_por_estrelas():
	var total = obter_total_estrelas()
	
	# 1º: Hollow Knight (Fácil - 3 estrelas)
	if total >= 3: 
		armadura_hollow_knight_desbloqueada = true
		
	# 2º: Kakashi (Médio - 8 estrelas)
	if total >= 8: 
		armadura_kakashi_desbloqueada = true
		
	# 3º: Bloodborne (Difícil - 13 estrelas)
	if total >= 13: 
		armadura_bloodborne_desbloqueada = true
		
	# 4º: Dark Souls (Mestre - 18 estrelas - 100% do jogo)
	if total >= 18: 
		armadura_darksouls_desbloqueada = true
