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
	"arma_espada_longa", "arma_garfo_gigante", "arma_presunto", "arma_light_saber"
]

var todos_os_chapeus = [
	"Nenhum","Crown", "Witch Hat", "Pirate hat", "Graduation cap", "Cowboy Hat", "Hard hat"
]

func _ready():
	add_to_group("MenuCustomizacao")
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
		btn.custom_minimum_size = Vector2(120, 120) # Tamanho mobile/idoso [cite: 11]
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# --- VERIFICAÇÃO DE DESBLOQUEIO ---
		var esta_desbloqueada = id in Global.armas_desbloqueadas 
		
		var caminho_icone = PASTA_ICONES + id + ".png"
		if FileAccess.file_exists(caminho_icone):
			btn.icon = load(caminho_icone)
		else:
			btn.text = _obter_nome_formatado(id)
		
		# --- ESTILO E ACESSIBILIDADE ---
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.2, 0.2, 0.22, 1)
		estilo.set_corner_radius_all(8)
		
		if esta_desbloqueada:
			btn.pressed.connect(func(): _on_arma_selecionada(id))
			btn.modulate = Color(1, 1, 1) # Cor normal
			
			if id == arma_equipada:
				estilo.set_border_width_all(6) # Borda mais grossa para idosos [cite: 11]
				estilo.border_color = Color(1.0, 1.0, 1.0, 1.0)
		else:
			# Se estiver bloqueada, o botão fica escuro e não clica
			btn.modulate = Color(0.2, 0.2, 0.2, 0.8) 
			btn.disabled = true 
			# Opcional: colocar um ícone de cadeado aqui 
			btn.icon = load("res://Icons/cadeado.png")
		btn.add_theme_stylebox_override("normal", estilo)
		grid_itens.add_child(btn)
			
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
		
	var chapeu_equipado = Global.equip_avo_m.get("chapeu", "Nenhum") if Global.personagem_jogado_atualmente == "avo_m" else Global.equip_avo_f.get("chapeu", "Nenhum")
		
	for id in todos_os_chapeus:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120) # Tamanho para idosos/mobile
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# --- LÓGICA DE BLOQUEIO ---
		var esta_desbloqueado = id in Global.chapeus_desbloqueados
		
		var caminho_icone = PASTA_ICONES + id + ".png"
		if FileAccess.file_exists(caminho_icone):
			btn.icon = load(caminho_icone)
		else:
			btn.text = id
		
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.15, 0.15, 0.17, 1)
		estilo.set_corner_radius_all(10)
		
		if esta_desbloqueado:
			btn.modulate = Color(1, 1, 1) # Cor normal
			btn.pressed.connect(func(): _on_chapeu_selecionado(id))
			
			if id == chapeu_equipado:
				estilo.set_border_width_all(6)
				estilo.border_color = Color.WHITE
		else:
			# Visual de item bloqueado
			btn.modulate = Color(0.2, 0.2, 0.2, 0.7) # Fica bem escuro
			btn.disabled = true 
			# Se tiver um ícone de cadeado, poderia carregar aqui:
			btn.icon = load("res://Icons/cadeado.png")

		btn.add_theme_stylebox_override("normal", estilo)
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
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
