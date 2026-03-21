extends Control

@onready var ponto_lobby = $CenarioFundo/Camera3D/PontoLobby

# Referências para a interface
@onready var menu_botoes = $CanvasLayer/MarginContainer/VBoxContainer # A tua lista de botões
@onready var cena_configuracoes = $CanvasLayer/MarginContainer/Configuracoes # A cena instanciada (ajusta o caminho se colocaste noutro lugar)

func _ready():
	# 1. Garante que as configs começam invisíveis
	if cena_configuracoes:
		cena_configuracoes.hide()
		# LIGA O SINAL via código: Quando a cena_config emitir "fechar_configuracoes", roda a função "_voltar_para_menu"
		cena_configuracoes.fechar_configuracoes.connect(_voltar_para_menu)
	
	# 2. Lógica do teu Personagem 3D
	var caminho = Global.personagem_escolhido_path
	if caminho == "":
		caminho = "res://Personagens/character-male-b.glb" 
		Global.personagem_escolhido_path = caminho

	var modelo = load(caminho).instantiate()
	
	if ponto_lobby:
		ponto_lobby.add_child(modelo)
		_aplicar_outline_automatico(modelo)
		modelo.scale = Vector3(0.3, 0.3, 0.3)
		var anim = modelo.get_node_or_null("AnimationPlayer")
		if anim and anim.has_animation("idle"):
			anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			anim.play("idle")

# ---------------------------------------------------------
# BOTÕES DO MENU
# ---------------------------------------------------------

func _on_btn_jogar_pressed():
	get_tree().change_scene_to_file("res://Cenas Locais/tutorial_world.tscn")

func _on_btn_conquistas_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas Locais/tela_conquistas.tscn")

func _on_btn_sair_pressed() -> void:
	get_tree().quit()

# Quando clica no botão "Configurações" do menu
func _on_btn_configuracoes_pressed():
	menu_botoes.hide()
	cena_configuracoes.show()
	
	# --- ANIMAÇÃO DE ENTRADA (POP-UP) ---
	# 1. Definir o ponto de origem para o centro da tela
	cena_configuracoes.pivot_offset = cena_configuracoes.size / 2
	
	# 2. Encolher e deixar transparente no frame zero
	cena_configuracoes.scale = Vector2(0.8, 0.8)
	cena_configuracoes.modulate.a = 0.0
	
	# 3. Criar a animação (Tween)
	var tween = create_tween().set_parallel(true)
	# Faz o tamanho ir para (1, 1) com um efeitinho de mola (TRANS_BACK)
	tween.tween_property(cena_configuracoes, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Faz a opacidade ir para 100% (1.0)
	tween.tween_property(cena_configuracoes, "modulate:a", 1.0, 0.2)

# Função que é chamada quando a cena de configurações emite o sinal
func _voltar_para_menu():
	cena_configuracoes.hide() # Esconde as configs
	menu_botoes.show() # Mostra os botões novamente


# ---------------------------------------------------------
# SHADER DE OUTLINE
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
