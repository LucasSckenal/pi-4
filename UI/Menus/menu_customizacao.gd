extends Node3D

# --- CONFIGURAÇÕES ---
@export var cena_player_caminho: String = "res://Cenas Locais/player.tscn"

# Pasta onde vais guardar os ícones (.png) com o nome exato dos IDs
const PASTA_ICONES = "res://Icons/"

# --- REFERÊNCIAS DA INTERFACE ---
@onready var manequim_ponto = $PontoPersonagem

@onready var grid_itens = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/SecaoArmas/Margin/GridArmas
@onready var grid_chapeus = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/SecaoChapeus/Margin/GridChapeus
@onready var label_nome_item = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/LabelNomeItem
@onready var label_estrelas = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/HBoxTitulo/LabelEstrelas
@onready var secao_chapeus = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/SecaoChapeus
@onready var secao_armas = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/SecaoArmas
@onready var btn_tab_chapeus = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/TabBar/BtnTabChapeus
@onready var btn_tab_armas = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/TabBar/BtnTabArmas
@onready var btn_avo_m = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/BotoesGenero/BtnAvoM
@onready var btn_avo_f = $UI/Tela/QuadroPrincipal/MarginContainer/VBox/BotoesGenero/BtnAvoF

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

# ADICIONADO O "Set Dark Souls" NA LISTA
var todos_os_chapeus = [
	"Nenhum","Crown", "Witch Hat", "Pirate hat", "Graduation cap", "Cowboy Hat", "Hard hat", "HollowKnight Head", "Set Kakashi", "Set Bloodborne" ,"Set Dark Souls"
]

func _ready():
	add_to_group("MenuCustomizacao")
	_instanciar_personagem()
	_gerar_botoes_armas()
	_gerar_botoes_chapeus()
	_atualizar_botoes_genero()
	atualizar_info_estrelas()
func atualizar_info_estrelas():
	var total = Global.obter_total_estrelas()
	if label_estrelas:
		label_estrelas.text = "⭐ %d/18" % total

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
		
	call_deferred("_atualizar_estado_cabeca")
		

func _input(event):
	# 1. Detecta quando o jogador TOCA ou SOLTA a tela (Mobile) ou clica com o mouse (PC)
	if event is InputEventScreenTouch:
		a_arrastar_rato = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		a_arrastar_rato = event.pressed

	# 2. Detecta o movimento de ARRASTAR o dedo na tela (Mobile) ou mover o mouse (PC)
	if a_arrastar_rato:
		if event is InputEventScreenDrag:
			manequim_ponto.rotate_y(-deg_to_rad(-event.relative.x * sensibilidade_rotacao))
		elif event is InputEventMouseMotion:
			manequim_ponto.rotate_y(-deg_to_rad(-event.relative.x * sensibilidade_rotacao))

# --- LÓGICA DE INTERFACE (UI em pt-br) ---

func _gerar_botoes_armas():
	for filho in grid_itens.get_children():
		filho.queue_free()
		
	# --- Ordenar a lista (Desbloqueados primeiro) ---
	var lista_ordenada = todas_as_armas.duplicate()
	lista_ordenada.sort_custom(func(a, b):
		var a_tem = a in Global.armas_desbloqueadas
		var b_tem = b in Global.armas_desbloqueadas
		if a_tem != b_tem:
			return a_tem
		return a < b
	)
		
	var arma_equipada = Global.equip_avo_m["arma"] if Global.personagem_jogado_atualmente == "avo_m" else Global.equip_avo_f["arma"]
		
	for id in lista_ordenada:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 155)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.clip_text = true

		# --- VERIFICAÇÃO DE DESBLOQUEIO ---
		var esta_desbloqueada = id in Global.armas_desbloqueadas

		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.18, 0.18, 0.21, 1)
		estilo.set_corner_radius_all(8)

		var estilo_hover = StyleBoxFlat.new()
		estilo_hover.bg_color = Color(0.26, 0.26, 0.32, 1)
		estilo_hover.set_corner_radius_all(8)
		estilo_hover.set_border_width_all(1)
		estilo_hover.border_color = Color(0.50, 0.46, 0.72, 1)

		if esta_desbloqueada:
			var caminho_icone = PASTA_ICONES + id + ".png"
			if FileAccess.file_exists(caminho_icone):
				btn.icon = load(caminho_icone)
			btn.text = _obter_nome_formatado(id)
			btn.add_theme_font_size_override("font_size", 13)
			btn.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92, 1))
			btn.pressed.connect(func(): _on_arma_selecionada(id))

			if id == arma_equipada:
				estilo.bg_color = Color(0.22, 0.20, 0.10, 1)
				estilo.set_border_width_all(3)
				estilo.border_color = Color(1.0, 0.85, 0.25, 1)
		else:
			btn.modulate = Color(0.25, 0.25, 0.25, 0.9)
			btn.disabled = true
			var cadeado = load("res://Icons/cadeado.png")
			if cadeado: btn.icon = cadeado

		btn.add_theme_stylebox_override("normal", estilo)
		btn.add_theme_stylebox_override("hover", estilo_hover)
		btn.add_theme_stylebox_override("pressed", estilo)
		btn.add_theme_stylebox_override("focus", estilo)
			
		grid_itens.add_child(btn)

func _obter_nome_formatado(id):
	return id.replace("arma_", "").replace("_", " ").capitalize()

func _atualizar_botoes_genero():
	btn_avo_m.disabled = (Global.personagem_jogado_atualmente == "avo_m")
	btn_avo_f.disabled = (Global.personagem_jogado_atualmente == "avo_f")


func _on_arma_selecionada(id_arma):
	# Equipar a mesma arma para ambos os personagens para manter sincronia
	Global.equipar_arma("avo_m", id_arma)
	Global.equipar_arma("avo_f", id_arma)
	label_nome_item.text = _obter_nome_formatado(id_arma)
	
	if is_instance_valid(player_instanciado) and player_instanciado.has_method("_atualizar_arma_visivel"):
		player_instanciado.call("_atualizar_arma_visivel")
		
	_gerar_botoes_armas()

func _gerar_botoes_chapeus():
	for filho in grid_chapeus.get_children():
		filho.queue_free()

	var chapeu_equipado: String = Global.equip_avo_m["chapeu"] if Global.personagem_jogado_atualmente == "avo_m" else Global.equip_avo_f["chapeu"]

	for id in todos_os_chapeus:
		var bloqueado = false
		var texto_bloqueio = ""
		
		# --- REGRA 1: SETS ESPECIAIS (POR ESTRELAS) ---
		if id == "Set Dark Souls" and not Global.armadura_darksouls_desbloqueada:
			bloqueado = true
			texto_bloqueio = "18★"
		elif id == "Set Bloodborne" and not Global.armadura_bloodborne_desbloqueada:
			bloqueado = true
			texto_bloqueio = "13★"
		elif id == "HollowKnight Head" and not Global.armadura_hollow_knight_desbloqueada:
			bloqueado = true
			texto_bloqueio = "3★"
		elif id == "Set Kakashi" and not Global.armadura_kakashi_desbloqueada:
			bloqueado = true
			texto_bloqueio = "8★"
		
		# --- REGRA 2: CHAPÉUS NORMAIS (POR CONQUISTA / LISTA) ---
		# Se não for um dos especiais acima e não for o "Nenhum"
		elif id != "Nenhum" and not (id in Global.chapeus_desbloqueados):
			bloqueado = true

		# --- CRIAÇÃO VISUAL DO BOTÃO ---
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 155)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.clip_text = true
		
		if bloqueado:
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6, 1)
			btn.text = texto_bloqueio
			btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.90, 0.20, 1))
			btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			btn.add_theme_constant_override("outline_size", 4)
			btn.add_theme_font_size_override("font_size", 16)
			
			# Usa a imagem de cadeado
			var caminho_cadeado = "res://Icons/cadeado.png"
			if ResourceLoader.exists(caminho_cadeado):
				btn.icon = load(caminho_cadeado)
			
			# Usa a sua imagem de cadeado para TODOS os itens bloqueados
			
		else:
			var caminho_icone = PASTA_ICONES + id + ".png"
			if ResourceLoader.exists(caminho_icone):
				btn.icon = load(caminho_icone)
			# sempre mostra nome abaixo do ícone
			if id == "Nenhum":
				btn.text = "Nenhum"
			else:
				btn.text = id if id.length() <= 12 else id.left(11) + "…"

			btn.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92, 1))
			btn.add_theme_font_size_override("font_size", 13)
			btn.add_theme_constant_override("outline_size", 0)

			var estilo_c := StyleBoxFlat.new()
			estilo_c.set_corner_radius_all(8)
			var estilo_c_hover := StyleBoxFlat.new()
			estilo_c_hover.set_corner_radius_all(8)
			estilo_c_hover.set_border_width_all(1)
			estilo_c_hover.border_color = Color(0.50, 0.46, 0.72, 1)

			if id == chapeu_equipado:
				estilo_c.bg_color = Color(0.22, 0.20, 0.10, 1)
				estilo_c.set_border_width_all(3)
				estilo_c.border_color = Color(1.0, 0.85, 0.25, 1)
				estilo_c_hover.bg_color = Color(0.28, 0.26, 0.14, 1)
			else:
				estilo_c.bg_color = Color(0.18, 0.18, 0.21, 1)
				estilo_c_hover.bg_color = Color(0.26, 0.26, 0.32, 1)

			btn.add_theme_stylebox_override("normal", estilo_c)
			btn.add_theme_stylebox_override("hover", estilo_c_hover)
			btn.add_theme_stylebox_override("pressed", estilo_c)
			btn.add_theme_stylebox_override("focus", estilo_c)
			btn.pressed.connect(_on_chapeu_selecionado.bind(id))
			
		grid_chapeus.add_child(btn)


func _on_chapeu_selecionado(id_chapeu):
	# 1. Definir as flags de Sets Especiais
	Global.usando_set_especial = (id_chapeu == "Set Dark Souls")
	Global.usando_set_bloodborne = (id_chapeu == "Set Bloodborne")
	Global.usando_set_kakashi = (id_chapeu == "Set Kakashi")
	Global.usando_set_hollow_knight = (id_chapeu == "HollowKnight Head")
	
	# 2. Se for um chapéu normal (ou o Hollow Knight), equipamos no slot de chapéu
	# Nota: Hollow Knight aqui é tratado como um chapéu que esconde a cabeça
	if not (Global.usando_set_especial or Global.usando_set_bloodborne or Global.usando_set_kakashi):
		Global.equip_avo_m["chapeu"] = id_chapeu
		Global.equip_avo_f["chapeu"] = id_chapeu
	else:
		# Se trocou para um set de corpo inteiro (DS, BB, Kakashi), removemos o chapéu normal
		Global.equip_avo_m["chapeu"] = "Nenhum"
		Global.equip_avo_f["chapeu"] = "Nenhum"

	Global.salvar_progresso()
	label_nome_item.text = _obter_nome_formatado(id_chapeu)
	
	# 3. Atualizar visual do Manequim 3D
	if is_instance_valid(player_instanciado):
		# Atualiza as malhas do corpo (esconde/mostra conforme o set)
		if player_instanciado.has_method("_configurar_modelo_escolhido"):
			player_instanciado.call("_configurar_modelo_escolhido")
		
		# IMPORTANTE: Forçar a atualização do chapéu visível
		if player_instanciado.has_method("_atualizar_chapeu_visivel"):
			player_instanciado.call("_atualizar_chapeu_visivel")
		
		# Atualiza se a cabeça deve sumir (Hollow Knight)
		_atualizar_estado_cabeca()
	
	# 4. Lógica de visibilidade dos modelos no Menu
	_atualizar_modelos_menu_especiais()
	
	# 5. Atualiza a lista de botões (para mostrar quem está selecionado, se quiser)
	_gerar_botoes_chapeus()

# Função auxiliar para limpar a bagunça dos modelos especiais no menu
func _atualizar_modelos_menu_especiais():
	var modelo_normal = find_child("character-male-f2", true, false) 
	var modelo_bb = find_child("ModeloBloodborneMenu", true, false)
	var modelo_kak = find_child("ModeloKakashiMenu", true, false)
	
	# Esconde todos primeiro para evitar sobreposição
	if modelo_normal: modelo_normal.visible = false
	if modelo_bb: modelo_bb.visible = false
	if modelo_kak: modelo_kak.visible = false
	
	if Global.usando_set_bloodborne:
		if not modelo_bb:
			var cena = load("res://Assets/Personagens/blood_borne_male.tscn") 
			modelo_bb = _instanciar_easter_egg_menu(cena, "ModeloBloodborneMenu", modelo_normal)
		modelo_bb.visible = true
	elif Global.usando_set_kakashi:
		if not modelo_kak:
			var cena = load("res://Assets/Personagens/kakashi.tscn") 
			modelo_kak = _instanciar_easter_egg_menu(cena, "ModeloKakashiMenu", modelo_normal)
		modelo_kak.visible = true
	else:
		# Se for chapéu normal ou Hollow Knight, volta para o modelo base
		if modelo_normal: 
			modelo_normal.visible = true


# Processa a visibilidade da malha da cabeca base garantindo o estado visual apos qualquer configuracao interna do personagem
func _atualizar_estado_cabeca():
	if is_instance_valid(player_instanciado):
		var todos_os_nos = player_instanciado.find_children("*", "", true, false)
		for no in todos_os_nos:
			if "head-mesh" in no.name.to_lower():
				no.visible = not Global.usando_set_hollow_knight


# --- FUNÇÃO AUXILIAR PARA NÃO REPETIR CÓDIGO ---
func _instanciar_easter_egg_menu(cena_carregada, nome_node, modelo_referencia) -> Node3D:
	var modelo = cena_carregada.instantiate()
	modelo.name = nome_node
	modelo.scale = Vector3(0.33, 0.33, 0.33) 
	
	if modelo_referencia:
		modelo_referencia.get_parent().add_child(modelo)
		modelo.global_position = modelo_referencia.global_position
		modelo.rotation = modelo_referencia.rotation
		
	var anim_player_menu = modelo.find_child("AnimationPlayer", true)
	if anim_player_menu and anim_player_menu.has_animation("Idle"):
		anim_player_menu.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		anim_player_menu.play("Idle")
		
	var osso_arma = modelo.find_child("BoneAttachment3D", true, false)
	if osso_arma: osso_arma.visible = false
	var osso_chapeu = modelo.find_child("BoneAttachment3D_Cabeca", true, false)
	if osso_chapeu: osso_chapeu.visible = false
	
	return modelo

# --- SINAIS DO EDITOR ---
func _on_btn_avo_m_pressed():
	Global.personagem_jogado_atualmente = "avo_m"
	_instanciar_personagem()
	_atualizar_botoes_genero()
	_gerar_botoes_armas()
	_gerar_botoes_chapeus()

func _on_btn_avo_f_pressed():
	Global.personagem_jogado_atualmente = "avo_f"
	_instanciar_personagem()
	_atualizar_botoes_genero()
	_gerar_botoes_armas()
	_gerar_botoes_chapeus()

func _on_btn_voltar_pressed():
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")

func _on_btn_tab_chapeus_pressed():
	secao_chapeus.visible = true
	secao_armas.visible = false
	btn_tab_chapeus.disabled = true
	btn_tab_armas.disabled = false

func _on_btn_tab_armas_pressed():
	secao_chapeus.visible = false
	secao_armas.visible = true
	btn_tab_chapeus.disabled = false
	btn_tab_armas.disabled = true
