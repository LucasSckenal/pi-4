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

# ADICIONADO O "Set Dark Souls" NA LISTA
var todos_os_chapeus = [
	"Nenhum","Crown", "Witch Hat", "Pirate hat", "Graduation cap", "Cowboy Hat", "Hard hat", "Set Dark Souls", "Set Bloodborne"
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
	# 1. Detecta quando o jogador TOCA ou SOLTA a tela (Mobile) ou clica com o mouse (PC)
	if event is InputEventScreenTouch:
		a_arrastar_rato = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		a_arrastar_rato = event.pressed

	# 2. Detecta o movimento de ARRASTAR o dedo na tela (Mobile) ou mover o mouse (PC)
	if a_arrastar_rato:
		if event is InputEventScreenDrag:
			manequim_ponto.rotate_y(deg_to_rad(-event.relative.x * sensibilidade_rotacao))
		elif event is InputEventMouseMotion:
			manequim_ponto.rotate_y(deg_to_rad(-event.relative.x * sensibilidade_rotacao))

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
		btn.custom_minimum_size = Vector2(115, 115) # Tamanho ideal para mobile
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# --- VERIFICAÇÃO DE DESBLOQUEIO ---
		var esta_desbloqueada = id in Global.armas_desbloqueadas 
		
		# --- ESTILO ---
		var estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.2, 0.2, 0.22, 1)
		estilo.set_corner_radius_all(8)
		
		if esta_desbloqueada:
			# Carrega ícone se existir, senão usa texto
			var caminho_icone = PASTA_ICONES + id + ".png"
			if FileAccess.file_exists(caminho_icone):
				btn.icon = load(caminho_icone)
			else:
				btn.text = _obter_nome_formatado(id)
				
			btn.pressed.connect(func(): _on_arma_selecionada(id))
			btn.modulate = Color(1, 1, 1) # Cor normal
			
			if id == arma_equipada:
				estilo.set_border_width_all(6) 
				estilo.border_color = Color.GOLD # Destaque dourado para arma equipada
		else:
			# Se estiver bloqueada, o botão fica escuro e não clica
			btn.modulate = Color(0.2, 0.2, 0.2, 0.8) 
			btn.disabled = true 
			var cadeado = load("res://Icons/cadeado.png")
			if cadeado: btn.icon = cadeado

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
	
	if is_instance_valid(player_instanciado) and player_instanciado.has_method("_atualizar_arma_visivel"):
		player_instanciado.call("_atualizar_arma_visivel")
		
	_gerar_botoes_armas()

func _gerar_botoes_chapeus():
	# Limpa os atuais
	for filho in grid_chapeus.get_children():
		filho.queue_free()
		
	for id in todos_os_chapeus:
		# Regra do Dark Souls
		if id == "Set Dark Souls" and not Global.armadura_darksouls_desbloqueada:
			continue
			
		# Regra do Bloodborne
		if id == "Set Bloodborne" and not Global.armadura_bloodborne_desbloqueada:
			continue
			
		# Cria o botão visualmente
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		
		# Tenta carregar o ícone
		var caminho_icone = PASTA_ICONES + id + ".png"
		if ResourceLoader.exists(caminho_icone):
			btn.icon = load(caminho_icone)
		else:
			btn.text = id
			
		# Conecta o clique do botão
		btn.pressed.connect(_on_chapeu_selecionado.bind(id))
		grid_chapeus.add_child(btn)


func _on_chapeu_selecionado(id_chapeu):
	# --- LÓGICA DOS EASTER EGGS ---
	if id_chapeu == "Set Dark Souls":
		Global.usando_set_especial = true
		Global.usando_set_bloodborne = false
	elif id_chapeu == "Set Bloodborne":
		Global.usando_set_bloodborne = true
		Global.usando_set_especial = false
	else:
		# Se for normal, desliga Easter Eggs
		Global.usando_set_especial = false
		Global.usando_set_bloodborne = false
		
		if Global.personagem_jogado_atualmente == "avo_m":
			Global.equip_avo_m["chapeu"] = id_chapeu
		else:
			Global.equip_avo_f["chapeu"] = id_chapeu
			
	Global.salvar_progresso()
	label_nome_item.text = _obter_nome_formatado(id_chapeu)
	
	# --- ATUALIZAR BONECO DO JOGO (Se já existir) ---
	if is_instance_valid(player_instanciado):
		if player_instanciado.has_method("_configurar_modelo_escolhido"):
			player_instanciado.call("_configurar_modelo_escolhido")
			
		# Só atualiza chapéus normais se não for Easter Egg
		if not Global.usando_set_especial and not Global.usando_set_bloodborne:
			if player_instanciado.has_method("_atualizar_chapeu_visivel"):
				player_instanciado.call("_atualizar_chapeu_visivel")
				
	_gerar_botoes_chapeus()
	
# --- LÓGICA VISUAL EXCLUSIVA DO MENU ---
	var modelo_normal = find_child("character-male-f2", true, false) 
	var modelo_bb = find_child("ModeloBloodborneMenu", true, false)
	
	if Global.usando_set_bloodborne:
		if modelo_normal:
			modelo_normal.visible = false
			
		if not modelo_bb:
			var cena_bb = load("res://Assets/Personagens/blood_borne_male.tscn") 
			modelo_bb = cena_bb.instantiate()
			modelo_bb.name = "ModeloBloodborneMenu"
			
			# --- CORREÇÃO 1: TAMANHO DO BONECO NO MENU ---
			# (Usa o mesmo valor que escolheste lá no Player.gd para não ficar gigante)
			modelo_bb.scale = Vector3(0.33, 0.33, 0.33) 
			
			if modelo_normal:
				modelo_normal.get_parent().add_child(modelo_bb)
				modelo_bb.global_position = modelo_normal.global_position
				modelo_bb.rotation = modelo_normal.rotation
				
			# --- CORREÇÃO 2: ATIVAR A ANIMAÇÃO "IDLE" NO MENU ---
			var anim_player_menu = modelo_bb.find_child("AnimationPlayer", true)
			if anim_player_menu:
				if anim_player_menu.has_animation("Idle"):
					anim_player_menu.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
					anim_player_menu.play("Idle")
				
		modelo_bb.visible = true
		
		var osso_arma_menu = modelo_bb.find_child("BoneAttachment3D", true, false)
		if osso_arma_menu: osso_arma_menu.visible = false
		var osso_chapeu_menu = modelo_bb.find_child("BoneAttachment3D_Cabeca", true, false)
		if osso_chapeu_menu: osso_chapeu_menu.visible = false
		
	else:
		if modelo_normal:
			modelo_normal.visible = true
		if modelo_bb:
			modelo_bb.visible = false

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
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
