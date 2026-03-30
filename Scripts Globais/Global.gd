extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save_game.cfg"

# --- NOVO SISTEMA DE CUSTOMIZAÇÃO ---
# Qual personagem o jogador escolheu para jogar na fase atual (ex: "avo_m" ou "avo_f")
var personagem_jogado_atualmente : String = "avo_m"

# Inventário inicial (Agora começa só com a Katana e o Nenhum)
var armas_desbloqueadas: Array = ["arma_katana"]
var chapeus_desbloqueados: Array = ["Nenhum"]

# O que cada um tem equipado neste momento
var equip_avo_m = {
	"arma": "arma_katana",
	"chapeu": "Nenhum" 
}

var equip_avo_f = {
	"arma": "arma_katana",
	"chapeu": "Nenhum" 
}

# --- SISTEMA DE CONQUISTAS E RECOMPENSAS ---
signal conquista_desbloqueada(nome_conquista, id_arma_liberada, icone_path)

# Status atual das conquistas
var status_conquistas = {
	"conquista_10_inimigos": false,
	"conquista_50_inimigos": false,
	"conquista_boss_1": false,
	"conquista_100_moedas": false,
	"conquista_sem_dano": false,
	"conquista_secreta": false
}

# Aqui você liga o ID da conquista ao ID do Item que ela libera!
# (Altere os nomes das armas/chapéus aqui de acordo com os IDs reais do seu jogo)
var recompensas_armas = {
	"conquista_10_inimigos": "arma_faca",
	"conquista_50_inimigos": "arma_machado",
	"conquista_boss_1": "arma_espada_longa"
}

var recompensas_chapeus = {
	"conquista_100_moedas": "Cowboy Hat",
	"conquista_sem_dano": "Crown",
	"conquista_secreta": "Pirate hat"
}

func _ready():
	carregar_progresso()
	conquista_desbloqueada.connect(_receber_recompensa_conquista)
# --- FUNÇÃO PRINCIPAL DE DESBLOQUEIO ---
# Chame esta função nos scripts do jogo quando o jogador fizer algo importante!
func completar_conquista(id_conquista: String):
	if status_conquistas.has(id_conquista) and not status_conquistas[id_conquista]:
		status_conquistas[id_conquista] = true
		
		# Verifica se essa conquista dá uma arma de prêmio
		if recompensas_armas.has(id_conquista):
			var nova_arma = recompensas_armas[id_conquista]
			if not nova_arma in armas_desbloqueadas:
				armas_desbloqueadas.append(nova_arma)
				
		# Verifica se essa conquista dá um chapéu de prêmio
		if recompensas_chapeus.has(id_conquista):
			var novo_chapeu = recompensas_chapeus[id_conquista]
			if not novo_chapeu in chapeus_desbloqueados:
				chapeus_desbloqueados.append(novo_chapeu)
		
		salvar_progresso()
		# Aqui você pode emitir o sinal para aparecer aquele pop-up na tela!

func _receber_recompensa_conquista(nome_conquista, id_item_liberado, icone_path):
	# Se a recompensa não for vazia
	if id_item_liberado != "":
		
		# Se começar com "arma_", guarda na lista de armas
		if id_item_liberado.begins_with("arma_"):
			if not id_item_liberado in armas_desbloqueadas:
				armas_desbloqueadas.append(id_item_liberado)
				print("[GLOBAL] Nova arma desbloqueada: ", id_item_liberado)
				
		# Se não começar com "arma_", é um chapéu!
		else:
			if not id_item_liberado in chapeus_desbloqueados:
				chapeus_desbloqueados.append(id_item_liberado)
				print("[GLOBAL] Novo chapéu desbloqueado: ", id_item_liberado)
				
		# Salva o jogo com o novo item!
		salvar_progresso()
		
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
	
	# Salva conquistas
	for id in status_conquistas.keys():
		config.set_value("conquistas", id, status_conquistas[id])
		
	# Salva Inventário
	config.set_value("inventario", "armas_ganhas", armas_desbloqueadas)
	config.set_value("inventario", "chapeus_ganhos", chapeus_desbloqueados)
	
	# Salva Equipamentos Atuais
	config.set_value("equipamentos", "avo_m", equip_avo_m)
	config.set_value("equipamentos", "avo_f", equip_avo_f)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		print("[ERRO] Falha ao salvar arquivo: ", err)

func carregar_progresso():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		print("[INFO] Nenhum save encontrado. Iniciando do zero.") 
		return
	
	# Carrega conquistas
	for id in status_conquistas.keys():
		status_conquistas[id] = config.get_value("conquistas", id, false)
		
	# Carrega Inventário
	armas_desbloqueadas = config.get_value("inventario", "armas_ganhas", ["arma_katana"])
	chapeus_desbloqueados = config.get_value("inventario", "chapeus_ganhos", ["Nenhum"])
	
	# Carrega Equipamentos
	equip_avo_m = config.get_value("equipamentos", "avo_m", {"arma": "arma_katana", "chapeu": "Nenhum"})
	equip_avo_f = config.get_value("equipamentos", "avo_f", {"arma": "arma_katana", "chapeu": "Nenhum"})

# --- SISTEMA DE DEBUG (TESTE COM TECLADO) ---
func _input(event):
	if event is InputEventKey and event.pressed:
		
		if event.keycode == KEY_J:
			resetar_tudo()

		if event.keycode == KEY_L:
			print("\n--- STATUS DO SAVE ---")
			print("Armas Desbloqueadas: ", armas_desbloqueadas)
			print("Chapéus Desbloqueados: ", chapeus_desbloqueados)
			print("Equip Avô: ", equip_avo_m)
			print("Equip Avó: ", equip_avo_f)
			print("----------------------")
			
		# Tecla de CHEAT: Aperte 'C' para ganhar a conquista de 10 inimigos e testar o desbloqueio!
		if event.keycode == KEY_C:
			completar_conquista("conquista_10_inimigos")
			print("CHEAT: Conquista de 10 inimigos ativada! Arma deve ter sido liberada.")

func resetar_tudo():
	# Reseta as conquistas
	for id in status_conquistas.keys():
		status_conquistas[id] = false
		
	# Reseta inventário e equipamentos
	armas_desbloqueadas = ["arma_katana"]
	chapeus_desbloqueados = ["Nenhum"]
	equip_avo_m = {"arma": "arma_katana", "chapeu": "Nenhum"}
	equip_avo_f = {"arma": "arma_katana", "chapeu": "Nenhum"}
	
	salvar_progresso()
	print("[INFO] Progresso resetado completamente!")
