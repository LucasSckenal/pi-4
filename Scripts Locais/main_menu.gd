extends Control

@onready var ponto_lobby = $CenarioFundo/Camera3D/PontoLobby

# Referências para a interface
@onready var menu_botoes = $CanvasLayer/MarginContainer/VBoxContainer
@onready var cena_configuracoes = $CanvasLayer/MarginContainer/Configuracoes
@onready var btn_continuar = $CanvasLayer/MarginContainer/VBoxContainer/BtnContinuar

func _ready():
	MusicaGlobal.tocar_menu()
	
	# Oculta e desativa o botão de continuar caso não exista um arquivo de save válido
	if btn_continuar:
		var existe_save = FileAccess.file_exists(GameManager.SAVE_PATH)
		btn_continuar.disabled = not existe_save
		btn_continuar.visible = existe_save
		
	# 1. Configurações iniciais de interface 
	if cena_configuracoes:
		cena_configuracoes.hide()
		cena_configuracoes.fechar_configuracoes.connect(_voltar_para_menu)
	
	# 2. Instancia o Player no Menu (Estilo Minecraft)
	_instanciar_player_no_menu()
	_animar_entrada_botoes()

func _instanciar_player_no_menu():
	# Carrega a cena do Player 
	# AJUSTE O CAMINHO ABAIXO para o caminho real da sua cena .tscn
	var cena_p = load("res://Cenas Locais/player.tscn")
	
	if cena_p and ponto_lobby:
		var player_instancia = cena_p.instantiate()
		ponto_lobby.add_child(player_instancia)
		
		# POSICIONAMENTO
		player_instancia.global_position = ponto_lobby.global_position
		
		# ESCALA ORIGINAL: Revertido para (1, 1, 1) para usar o tamanho real da cena
		player_instancia.scale = Vector3(1, 1, 1)
		
		# TRAVA DE SEGURANÇA PARA MENU: 
		# Desativa física e scripts de movimento para ele ficar estático 
		player_instancia.set_physics_process(false)
		player_instancia.set_process(false)
		
		if player_instancia is CharacterBody3D:
			player_instancia.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		
		# Aplica o visual salvo (Avô/Avó) chamando a função do Player.gd 
		if player_instancia.has_method("_configurar_modelo_escolhido"):
			player_instancia._configurar_modelo_escolhido()
			
		call_deferred("_atualizar_estado_cabeca", player_instancia)
			
		# Aplica o outline automático em todas as malhas
		_aplicar_outline_automatico(player_instancia)

# Processa a visibilidade da malha da cabeca base garantindo o estado visual apos instanciar o modelo
func _atualizar_estado_cabeca(player_instancia: Node):
	if is_instance_valid(player_instancia):
		var todos_os_nos = player_instancia.find_children("*", "", true, false)
		for no in todos_os_nos:
			if "head-mesh" in no.name.to_lower():
				no.visible = not Global.usando_set_hollow_knight

# ---------------------------------------------------------
# BOTÕES DO MENU (Lógica original de animações restaurada)
# ---------------------------------------------------------

func _animar_entrada_botoes() -> void:
	for i in menu_botoes.get_child_count():
		var btn = menu_botoes.get_child(i)
		btn.modulate.a = 0.0
		var delay := i * 0.09
		var tw := create_tween().set_parallel(true)
		tw.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_btn_continuar_pressed():
	if btn_continuar:
		btn_continuar.disabled = true
	var sucesso = await GameManager.carregar_jogo_salvo_manual()
	if not sucesso and btn_continuar:
		btn_continuar.disabled = false

func _on_btn_jogar_pressed():
	get_tree().change_scene_to_file("res://UI/Menus/seletor_fases.tscn")

func _on_btn_conquistas_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/tela_conquistas.tscn")

func _on_btn_sair_pressed() -> void:
	get_tree().quit()

func _on_btn_configuracoes_pressed():
	if not is_instance_valid(cena_configuracoes):
		return
	menu_botoes.hide()
	cena_configuracoes.show()
	
	cena_configuracoes.pivot_offset = cena_configuracoes.size / 2
	cena_configuracoes.scale = Vector2(0.8, 0.8)
	cena_configuracoes.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(cena_configuracoes, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cena_configuracoes, "modulate:a", 1.0, 0.2)

func _voltar_para_menu():
	cena_configuracoes.hide()
	menu_botoes.show()

func _voltar_para_menu_do_seletor():
	menu_botoes.show()

# ---------------------------------------------------------
# SHADER DE OUTLINE (Lógica original de varredura)
# ---------------------------------------------------------
const OUTLINE_SHADER = preload("res://Shaders/Outline.gdshader")

func _aplicar_outline_automatico(no_raiz: Node):
	var mat_outline = ShaderMaterial.new()
	if OUTLINE_SHADER:
		mat_outline.shader = OUTLINE_SHADER
		mat_outline.set_shader_parameter("scale", 2.0)
		mat_outline.set_shader_parameter("outline_spread", 5.0)
		mat_outline.set_shader_parameter("_Color", Color(0, 0, 0, 1))
		mat_outline.set_shader_parameter("_DepthNormalThreshold", 0.1)
		mat_outline.set_shader_parameter("_DepthNormalThresholdScale", 3.0)
		mat_outline.set_shader_parameter("_DepthThreshold", 1.5)
		mat_outline.set_shader_parameter("_NormalThreshold", 2.0)
		_varrer_malhas_e_aplicar(no_raiz, mat_outline)

func _varrer_malhas_e_aplicar(no_atual: Node, material_shader: ShaderMaterial):
	if no_atual is MeshInstance3D:
		no_atual.material_overlay = material_shader
	for filho in no_atual.get_children():
		_varrer_malhas_e_aplicar(filho, material_shader)

func _on_btn_personagem_invisivel_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/menu_customizacao.tscn")
