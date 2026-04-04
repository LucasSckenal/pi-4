extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save_game.cfg"

# --- VARIÁVEIS DE ESTADO ---
var personagem_jogado_atualmente : String = "avo_m"

# Progresso do Jogador
var conquistas_desbloqueadas: Array = [] 
var armas_desbloqueadas: Array = ["arma_katana"]
var chapeus_desbloqueados: Array = ["Nenhum"]
var armadura_darksouls_desbloqueada: bool = true # Mude de false para true para testar
var usando_set_especial: bool = false

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
	var id_do_item_ganho = "" # Vamos guardar o ID para enviar para o pop-up
	
	# 1. Regista que a conquista foi ganha
	if not conquista.id in conquistas_desbloqueadas:
		conquistas_desbloqueadas.append(conquista.id)
		precisa_salvar = true
		
	# 2. Verifica se essa conquista dá uma ARMA
	if conquista.libera_arma_id != "":
		if not conquista.libera_arma_id in armas_desbloqueadas:
			armas_desbloqueadas.append(conquista.libera_arma_id)
			id_do_item_ganho = conquista.libera_arma_id
			precisa_salvar = true
			
	# 3. Verifica se essa conquista dá um CHAPÉU
	if conquista.libera_chapeu_id != "":
		if not conquista.libera_chapeu_id in chapeus_desbloqueados:
			chapeus_desbloqueados.append(conquista.libera_chapeu_id)
			id_do_item_ganho = conquista.libera_chapeu_id
			precisa_salvar = true
			
	# 4. Só salva e avisa a interface se tiver ganho algo novo (ou se for a primeira vez que ganha a conquista)
	if precisa_salvar:
		salvar_progresso()
		_atualizar_interface_customizacao()
		
		# --- A MÁGICA ACONTECE AQUI ---
		# Dispara o sinal que o seu `popup_conquista.gd` está à escuta!
		conquista_desbloqueada.emit(conquista.nome, id_do_item_ganho, conquista.icone)


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
	var config = ConfigFile.new()
	
	config.set_value("progresso", "conquistas", conquistas_desbloqueadas)
	config.set_value("inventario", "armas_ganhas", armas_desbloqueadas)
	config.set_value("inventario", "chapeus_ganhos", chapeus_desbloqueados)
	config.set_value("equipamentos", "avo_m", equip_avo_m)
	config.set_value("equipamentos", "avo_f", equip_avo_f)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		print("[ERRO] Falha ao guardar ficheiro: ", err)


func carregar_progresso():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		return
	
	conquistas_desbloqueadas = config.get_value("progresso", "conquistas", [])
	armas_desbloqueadas = config.get_value("inventario", "armas_ganhas", ["arma_katana"])
	chapeus_desbloqueados = config.get_value("inventario", "chapeus_ganhos", ["Nenhum"])
	equip_avo_m = config.get_value("equipamentos", "avo_m", {"arma": "arma_katana", "chapeu": "Nenhum"})
	equip_avo_f = config.get_value("equipamentos", "avo_f", {"arma": "arma_katana", "chapeu": "Nenhum"})


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
	conquistas_desbloqueadas = []
	armas_desbloqueadas = ["arma_katana"]
	chapeus_desbloqueados = ["Nenhum"]
	equip_avo_m = {"arma": "arma_katana", "chapeu": "Nenhum"}
	equip_avo_f = {"arma": "arma_katana", "chapeu": "Nenhum"}
	salvar_progresso()
