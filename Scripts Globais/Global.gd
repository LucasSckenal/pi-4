extends Node

# --- CONFIGURAÇÕES DE CAMINHO ---
const SAVE_PATH = "user://save_game.cfg"

# --- SISTEMA DE PERSONAGENS ---
var personagem_escolhido_path : String = ""

# Lista com 12 personagens. O index 0 (Feminino A) e 6 (Masculino A) são livres.
var lista_personagens = [
	"res://Personagens/character-female-c.glb", # Index 0: Livre
	"res://Personagens/character-female-b.glb", # Index 1: Trancado
	"res://Personagens/character-female-a.glb", # Index 2: Trancado
	"res://Personagens/character-female-d.glb", # Index 3: Trancado
	"res://Personagens/character-female-e.glb", # Index 4: Trancado
	"res://Personagens/character-female-f.glb", # Index 5: Trancado
	
	"res://Personagens/character-male-b.glb",   # Index 6: Livre
	"res://Personagens/character-male-a.glb",   # Index 7: Trancado
	"res://Personagens/character-male-c.glb",   # Index 8: Trancado
	"res://Personagens/character-male-d.glb",   # Index 9: Trancado
	"res://Personagens/character-male-e.glb",   # Index 10: Trancado
	"res://Personagens/character-male-f.glb"    # Index 11: Trancado
]

# --- SISTEMA DE CONQUISTAS (RESOURCES) ---
signal conquista_desbloqueada(nome_conquista, index_liberado, icone_conquista)

# 1. Carregamos os arquivos visuais (Resources) que você criou na pasta
var banco_conquistas: Array = [
	preload("res://Conquistas/engenheiro.tres"),     # O seu arquivo antigo da torre
	preload("res://Conquistas/vitoria_1.tres"),      # O seu arquivo antigo rico/vitoria
	preload("res://Conquistas/economia.tres"),       # <-- AQUI ESTÁ O NOVO!
	preload("res://Conquistas/defesa_perfeita.tres"),
	preload("res://Conquistas/mao_na_massa.tres"),
	preload("res://Conquistas/sobrevivente.tres"),
	preload("res://Conquistas/muralhas.tres"),
	preload("res://Conquistas/general.tres"),
	preload("res://Conquistas/matar_boss.tres"),
	preload("res://Conquistas/zerar_jogo.tres")
]

# 2. Esse dicionário vai guardar APENAS o status (true/false) na memória para o Save
var status_conquistas: Dictionary = {}

func _ready():
	# Prepara o dicionário de status dinamicamente baseado nos arquivos .tres
	for conquista in banco_conquistas:
		if conquista != null:
			status_conquistas[conquista.id] = false
		
	carregar_progresso()
	print("--- DEBUG GLOBAL ---")
	print("Lista de personagens: ", lista_personagens.size())
	print("Banco de conquistas carregado com sucesso.")

# --- LÓGICA DE DESBLOQUEIO E VERIFICAÇÃO ---

func desbloquear_conquista(id_procurado: String):
	# Busca a conquista no nosso banco de dados
	var conquista_encontrada = null
	for c in banco_conquistas:
		if c != null and c.id == id_procurado:
			conquista_encontrada = c
			break
			
	if conquista_encontrada == null:
		print("[ERRO] Conquista não encontrada no banco: ", id_procurado)
		return
		
	# Verifica se já não foi liberada
	if status_conquistas.has(id_procurado) and status_conquistas[id_procurado] == false:
		status_conquistas[id_procurado] = true # Muda para verdadeiro!
		
		var nome = conquista_encontrada.nome
		var index = conquista_encontrada.libera_personagem_index
		var icone = conquista_encontrada.icone # NOVO: Pega a imagem do arquivo .tres!
		
		# Dispara o sinal para o Popup UI (agora com 3 informações)
		emit_signal("conquista_desbloqueada", nome, index, icone)
		salvar_progresso()
		
		print("[SUCESSO] Conquista Liberada e Salva: ", nome)
	else:
		print("[INFO] A conquista '", conquista_encontrada.nome, "' já estava liberada.")

# Essa função a Tela de Personagens vai usar para saber se mostra o cadeado
func is_personagem_liberado(index: int) -> bool:
	# 1. Os personagens 0 e 6 já nascem liberados
	if index == 0 or index == 6:
		return true
		
	# 2. Procura se tem alguma conquista atrelada a este personagem
	for conquista in banco_conquistas:
		if conquista != null and conquista.libera_personagem_index == index:
			# Retorna true se já tem no save, false se não tem
			if status_conquistas.has(conquista.id):
				return status_conquistas[conquista.id]
			
	# 3. Se não achou nenhuma conquista que libere ele, tranca por segurança
	return false

# --- SISTEMA DE SAVE / LOAD ---

func salvar_progresso():
	var config = ConfigFile.new()
	for id in status_conquistas.keys():
		config.set_value("conquistas", id, status_conquistas[id])
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		print("[ERRO] Falha ao salvar arquivo: ", err)

func carregar_progresso():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		print("[INFO] Nenhum save encontrado. Iniciando do zero.")
		return
	
	for id in status_conquistas.keys():
		var status_salvo = config.get_value("conquistas", id, false)
		status_conquistas[id] = status_salvo

# --- SISTEMA DE DEBUG (TESTE COM TECLADO) ---

func _input(event):
	if event is InputEventKey and event.pressed:
		
		# Tecla J: APAGA O SAVE E ZERA TUDO
		if event.keycode == KEY_J:
			resetar_tudo()

		# Tecla K: TENTA DESBLOQUEAR A CONQUISTA
		if event.keycode == KEY_K:
			print("\n[DEBUG] Testando desbloqueio via tecla K...")
			desbloquear_conquista("mestre_economia")
			
		# Tecla L: LISTA O STATUS NO CONSOLE
		if event.keycode == KEY_L:
			print("\n--- STATUS DAS CONQUISTAS NO SAVE ---")
			for id in status_conquistas:
				print("- ", id, " [", status_conquistas[id], "]")
			print("-------------------------------------")

func resetar_tudo():
	print("\n[DEBUG] Resetando progresso...")
	var dir = DirAccess.open("user://")
	if dir.file_exists("save_game.cfg"):
		dir.remove("save_game.cfg")
		print("[DEBUG] Arquivo 'save_game.cfg' removido.")
	
	for id in status_conquistas.keys():
		status_conquistas[id] = false
	
	salvar_progresso()
	print("[DEBUG] Save limpo! Personagens trancados novamente.")
