extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save_game.cfg"

# --- NOVO SISTEMA DE CUSTOMIZAÇÃO ---
# Qual personagem o jogador escolheu para jogar na fase atual (ex: "avo_m" ou "avo_f")
var personagem_jogado_atualmente : String = "avo_m"

# O nosso inventário de armas partilhado (A Katana já vem de fábrica!)
# CHEAT: Todas as armas desbloqueadas para teste!
var armas_desbloqueadas: Array = [
	"arma_cajado", 
	"arma_lanca", 
	"arma_rolo_massa", 
	"arma_baguete", 
	"arma_baguete2", 
	"arma_peixe", 
	"arma_colher_pau", 
	"arma_espatula", 
	"arma_faca", 
	"arma_machado", 
	"arma_katana", 
	"arma_espada_longa", 
	"arma_garfo_gigante", 
	"arma_presunto"
]

# O que cada um tem equipado neste momento
var equip_avo_m = {
	"arma": "arma_katana"
}

var equip_avo_f = {
	"arma": "arma_katana"
}

# --- SISTEMA DE CONQUISTAS (RESOURCES) ---
# O sinal agora envia o id da arma em vez do index do personagem
signal conquista_desbloqueada(nome_conquista, id_arma_liberada, icone_conquista)

var banco_conquistas: Array = [
	preload("res://Conquistas/acumula_1000_moedas.tres"),
	preload("res://Conquistas/chega_fase_final.tres"),
	preload("res://Conquistas/completa_fase_4.tres"),
	preload("res://Conquistas/defesa_perfeita.tres"),
	preload("res://Conquistas/derrota_boss_sem_dano_base.tres"),
	preload("res://Conquistas/fuga_piramide.tres"),
	preload("res://Conquistas/guarda_dinheiro_ondas.tres"),
	preload("res://Conquistas/inicio_aventura.tres"),
	preload("res://Conquistas/pagamento_20_ondas.tres"),
	preload("res://Conquistas/poder_espacial.tres"),
	preload("res://Conquistas/primeira_compra.tres"),
	preload("res://Conquistas/primeiros_passos.tres"),
	preload("res://Conquistas/Querida_Encolhi_os_Avos.tres")
]

# Esse dicionário vai guardar o status (true/false) na memória para o Save [cite: 4]
var status_conquistas: Dictionary = {}

func _ready():
	for conquista in banco_conquistas:
		if conquista != null:
			status_conquistas[conquista.id] = false
		
	carregar_progresso()
	print("--- DEBUG GLOBAL ---")
	print("Armas desbloqueadas no inventário: ", armas_desbloqueadas)

# --- LÓGICA DE DESBLOQUEIO E VERIFICAÇÃO ---

func desbloquear_conquista(id_procurado: String):
	var conquista_encontrada = null
	for c in banco_conquistas:
		if c != null and c.id == id_procurado:
			conquista_encontrada = c
			break
			
	if conquista_encontrada == null:
		return
		
	if status_conquistas.has(id_procurado) and status_conquistas[id_procurado] == false:
		status_conquistas[id_procurado] = true
		
		var nome = conquista_encontrada.nome
		# ATENÇÃO: O teu arquivo de conquistas (.tres) agora deve ter a variável 'libera_arma_id' em vez de 'libera_personagem_index' [cite: 5]
		var arma_id = conquista_encontrada.libera_arma_id 
		var icone = conquista_encontrada.icone 
		
		# Se a conquista der uma arma e ela ainda não estiver no inventário, adiciona!
		if arma_id != "" and not armas_desbloqueadas.has(arma_id):
			armas_desbloqueadas.append(arma_id)
			print("[INVENTÁRIO] Nova arma ganha: ", arma_id)
		
		emit_signal("conquista_desbloqueada", nome, arma_id, icone) 
		salvar_progresso()
	else:
		print("[INFO] A conquista '", conquista_encontrada.nome, "' já estava liberada.")

# A UI vai usar isto para saber se desenha o cadeado ou a arma colorida
func is_arma_liberada(id_arma: String) -> bool:
	return armas_desbloqueadas.has(id_arma)

# Função para quando o jogador clica numa arma na tela de customização
func equipar_arma(personagem: String, id_arma: String):
	if personagem == "avo_m":
		equip_avo_m["arma"] = id_arma
	elif personagem == "avo_f":
		equip_avo_f["arma"] = id_arma
	
	salvar_progresso()
	print("[EQUIPAMENTO] ", personagem, " agora está a usar: ", id_arma)

# --- SISTEMA DE SAVE / LOAD ---

func salvar_progresso():
	var config = ConfigFile.new()
	
	# 1. Salva as conquistas
	for id in status_conquistas.keys():
		config.set_value("conquistas", id, status_conquistas[id])
		
	# 2. Salva o Inventário e os Equipamentos
	config.set_value("inventario", "armas_ganhas", armas_desbloqueadas)
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
		
	# Carrega Inventário e Equipamentos (Se não existir no save, devolve a Katana por defeito)
	armas_desbloqueadas = config.get_value("inventario", "armas_ganhas", ["arma_katana"])
	equip_avo_m = config.get_value("equipamentos", "avo_m", {"arma": "arma_katana"})
	equip_avo_f = config.get_value("equipamentos", "avo_f", {"arma": "arma_katana"})

# --- SISTEMA DE DEBUG (TESTE COM TECLADO) ---

func _input(event):
	if event is InputEventKey and event.pressed:
		
		if event.keycode == KEY_J:
			resetar_tudo()

		if event.keycode == KEY_L:
			print("\n--- STATUS DO SAVE ---")
			print("Armas Desbloqueadas: ", armas_desbloqueadas)
			print("Equip Avô: ", equip_avo_m)
			print("Equip Avó: ", equip_avo_f)
			print("----------------------")

func resetar_tudo():
	var dir = DirAccess.open("user://")
	if dir.file_exists("save_game.cfg"):
		dir.remove("save_game.cfg")
	
	for id in status_conquistas.keys():
		status_conquistas[id] = false
		
	armas_desbloqueadas = ["arma_katana"]
	equip_avo_m = {"arma": "arma_katana"}
	equip_avo_f = {"arma": "arma_katana"}
	
	salvar_progresso()
	print("[DEBUG] Save limpo! Inventário resetado.") 
