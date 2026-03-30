extends Node3D

# --- CONFIGURAÇÕES ---
# ARR_AQUI O CAMINHO DA TUA CENA DO PLAYER (ex: "res://Cenas/Player.tscn")
@export var cena_player_caminho: String = "res://Cenas Locais/player.tscn"

# Pasta onde vais guardar os ícones (.png) com o nome exato dos IDs
const PASTA_ICONES = "res://Icons/"

# --- REFERÊNCIAS DA INTERFACE ---
@onready var manequim_ponto = $PontoPersonagem

# ESTES SÃO OS CAMINHOS NOVOS CORRETOS:
@onready var grid_itens = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/SecaoArmas/ScrollArmas/Margin/GridArmas
@onready var grid_chapeus = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/SecaoChapeus/ScrollChapeus/Margin/GridChapeus
@onready var label_nome_item = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/LabelNomeItem

@onready var btn_avo_m = $UI/Tela/ControlesGenero/BtnAvoM
@onready var btn_avo_f = $UI/Tela/ControlesGenero/BtnAvoF

# --- VARIÁVEIS DE ESTADO ---
var player_instanciado: Node3D = null
var a_arrastar_rato = false
var sensibilidade_rotacao = 0.5

# A lista oficial de IDs (em pt-br)
var todas_as_armas = [
	"arma_katana", "arma_cajado", "arma_lanca", "arma_rolo_massa",
	"arma_baguete", "arma_frigideira", "arma_peixe", "arma_colher_pau",
	"arma_espatula", "arma_faca", "arma_machado",
	"arma_espada_longa", "arma_garfo_gigante", "arma_presunto"
]

var todos_os_chapeus = [
	"Nenhum","Crown", "Witch Hat", "Pirate hat", "Graduation cap", "Cowboy Hat"
]

func _ready():
	_instanciar_personagem()
	_gerar_botoes_armas()
	_gerar_botoes_chapeus()
	_atualizar_botoes_genero()

# --- LÓGICA 3D (Spawning e Rotação) ---

func _instanciar_personagem():
	if is_instance_valid(player_instanciado):
		player_instanciado.queue_free()
		player_instanciado = null
		
	var cena_player = load(cena_player_caminho)
	if not cena_player:
		printerr("[ERRO] Cena do Player não encontrada em: ", cena_player_caminho)
		return
		
	player_instanciado = cena_player.instantiate()
	manequim_ponto.add_child(player_instanciado)
	
	player_instanciado.set_process(false)
	player_instanciado.set_physics_process(false)
	
	if player_instanciado.has_method("_configurar_modelo_escolhido"):
		player_instanciado.call("_configurar_modelo_escolhido")
		

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			a_arrastar_rato = true
		else:
			a_arrastar_rato = false
			
	if event is InputEventMouseMotion and a_arrastar_rato:
		if is_instance_valid(player_instanciado):
			player_instanciado.rotate_y(deg_to_rad(-event.relative.x * sensibilidade_rotacao))

# --- LÓGICA DE INTERFACE (UI em pt-br) ---

func _gerar_botoes_armas():
	for filho in grid_itens.get_children():
		filho.queue_free()
		
	var arma_equipada = Global.equip_avo_m["arma"] if Global.personagem_jogado_atualmente == "avo_m" else Global.equip_avo_f["arma"]
		
	for id in todas_as_armas:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Mantém a cor normal do botão (sem aquele verde radioativo)
		btn.modulate = Color(1, 1, 1)
		
		var caminho_icone = PASTA_ICONES + id + ".png"
		if FileAccess.file_exists(caminho_icone):
			btn.icon = load(caminho_icone)
		else:
			btn.text = id.replace("arma_", "").capitalize()
		
		btn.pressed.connect(func(): _on_arma_selecionada(id))
		
		# --- CRIANDO O ESTILO DA BORDA BRANCA ---
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.2, 0.2, 0.22, 1) # Cor de fundo dark mode
		estilo.set_corner_radius_all(8) # Deixa os cantos arredondados
		
		if id == arma_equipada:
			# Se a arma estiver selecionada, coloca a borda branca!
			estilo.set_border_width_all(4)
			estilo.border_color = Color(1.0, 1.0, 1.0, 1.0)
			label_nome_item.text = _obter_nome_formatado(id)
		else:
			# Se não estiver selecionada, bota uma bordinha sutil escura
			estilo.set_border_width_all(2)
			estilo.border_color = Color(0.1, 0.1, 0.12, 1)
			
		# Aplica o estilo visual ao botão
		btn.add_theme_stylebox_override("normal", estilo)
		btn.add_theme_stylebox_override("hover", estilo)
		btn.add_theme_stylebox_override("pressed", estilo)
		btn.add_theme_stylebox_override("focus", estilo)
			
		grid_itens.add_child(btn)

func _obter_nome_formatado(id):
	return id.replace("arma_", "").replace("_", " ").capitalize()

func _atualizar_botoes_genero():
	btn_avo_m.disabled = (Global.personagem_jogado_atualmente == "avo_m")
	btn_avo_f.disabled = (Global.personagem_jogado_atualmente == "avo_f")

func _on_arma_selecionada(id_arma):
	# Salva a arma no Global
	Global.equipar_arma(Global.personagem_jogado_atualmente, id_arma)
	label_nome_item.text = _obter_nome_formatado(id_arma)
	
	# ERRO ESTAVA AQUI: Estava chamando _configurar_modelo_escolhido (que gera um corpo novo)
	# SOLUÇÃO: Chamar APENAS _atualizar_arma_visivel (que só liga/desliga a malha da arma)
	if is_instance_valid(player_instanciado) and player_instanciado.has_method("_atualizar_arma_visivel"):
		player_instanciado.call("_atualizar_arma_visivel")
		
	_gerar_botoes_armas()

func _gerar_botoes_chapeus():
	for filho in grid_chapeus.get_children():
		filho.queue_free()
		
	# Pega o chapéu atual salvo no Global (Usando .get caso você ainda não tenha criado a chave "chapeu")
	var chapeu_equipado = Global.equip_avo_m.get("chapeu", "") if Global.personagem_jogado_atualmente == "avo_m" else Global.equip_avo_f.get("chapeu", "")
		
	for id in todos_os_chapeus:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.modulate = Color(1, 1, 1)
		
		# Procura o ícone do chapéu na mesma pasta
		var caminho_icone = PASTA_ICONES + id + ".png"
		if FileAccess.file_exists(caminho_icone):
			btn.icon = load(caminho_icone)
		else:
			btn.text = id # Como os nomes já estão bonitos (ex: Cowboy Hat), usamos direto
		
		btn.pressed.connect(func(): _on_chapeu_selecionado(id))
		
		# --- ESTILO DA BORDA BRANCA ---
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.2, 0.2, 0.22, 1)
		estilo.set_corner_radius_all(8)
		
		if id == chapeu_equipado:
			estilo.set_border_width_all(4)
			estilo.border_color = Color(1.0, 1.0, 1.0, 1.0)
			label_nome_item.text = id
		else:
			estilo.set_border_width_all(2)
			estilo.border_color = Color(0.1, 0.1, 0.12, 1)
			
		btn.add_theme_stylebox_override("normal", estilo)
		btn.add_theme_stylebox_override("hover", estilo)
		btn.add_theme_stylebox_override("pressed", estilo)
		btn.add_theme_stylebox_override("focus", estilo)
			
		grid_chapeus.add_child(btn)

func _on_chapeu_selecionado(id_chapeu):
	# Salva o chapéu no dicionário Global
	if Global.personagem_jogado_atualmente == "avo_m":
		Global.equip_avo_m["chapeu"] = id_chapeu
	else:
		Global.equip_avo_f["chapeu"] = id_chapeu
		
	label_nome_item.text = id_chapeu
	
	# Chama uma função no player para atualizar o 3D (igual fizemos com a arma)
	if is_instance_valid(player_instanciado) and player_instanciado.has_method("_atualizar_chapeu_visivel"):
		player_instanciado.call("_atualizar_chapeu_visivel")
		
	_gerar_botoes_chapeus()

# --- SINAIS DO EDITOR ---
func _on_btn_avo_m_pressed():
	Global.personagem_jogado_atualmente = "avo_m"
	_instanciar_personagem()
	_atualizar_botoes_genero()
	_gerar_botoes_armas()
	_gerar_botoes_chapeus() # <-- ADICIONE AQUI

func _on_btn_avo_f_pressed():
	Global.personagem_jogado_atualmente = "avo_f"
	_instanciar_personagem()
	_atualizar_botoes_genero()
	_gerar_botoes_armas()
	_gerar_botoes_chapeus()

func _on_btn_voltar_pressed():
	print("[INFO] Botão Voltar clicado")
