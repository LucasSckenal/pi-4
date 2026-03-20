extends Control

# Variáveis sempre no topo!
@onready var ponto_lobby = $CenarioFundo/Camera3D/PontoLobby

func _ready():
	# 1. Pega o caminho do Global
	var caminho = Global.personagem_escolhido_path
	
	# 2. Se for a primeira vez abrindo o jogo (caminho vazio), escolhemos um padrão!
	if caminho == "":
		caminho = "res://Personagens/character-male-b.glb" 
		# (Opcional: já salvar no Global para ele jogar com esse se não mudar)
		Global.personagem_escolhido_path = caminho

	# 3. Carrega o modelo (agora a variável "caminho" nunca vai estar vazia)
	var modelo = load(caminho).instantiate()
	
	# 4. Coloca no menu, ajusta tamanho e tira da Pose de T
	ponto_lobby.add_child(modelo)
	_aplicar_outline_automatico(modelo)
	modelo.scale = Vector3(0.3, 0.3, 0.3)
	
	var anim = modelo.get_node_or_null("AnimationPlayer")
	if anim:
		if anim.has_animation("idle"):
			anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			anim.play("idle")


# ---------------------------------------------------------
# BOTÕES DO MENU
# ---------------------------------------------------------

func _on_btn_jogar_pressed():
	get_tree().change_scene_to_file("res://Cenas Locais/tutorial_world.tscn")

func _on_btn_customizar_pressed():
	print("Mudar para a tela de Customização!")
	get_tree().change_scene_to_file("res://Cenas Locais/selecao_personagem.tscn")

func _on_btn_configuracoes_pressed():
	print("Mudar para a tela de Configurações!")
	get_tree().change_scene_to_file("res://Cenas Locais/configuracoes.tscn")

func _on_btn_sair_pressed() -> void:
	print("Fechando o jogo...")
	get_tree().quit()


func _on_btn_conquistas_pressed() -> void:
	print("Mudar para a tela de Conquistas!")
	get_tree().change_scene_to_file("res://Cenas Locais/tela_conquistas.tscn")
	
# ==========================================
# AUTOMAÇÃO DE SHADER DE OUTLINE
# ==========================================
const OUTLINE_SHADER = preload("res://Shaders/Outline.gdshader")

func _aplicar_outline_automatico(no_raiz: Node):
	var mat_outline = ShaderMaterial.new()
	if OUTLINE_SHADER:
		mat_outline.shader = OUTLINE_SHADER
		mat_outline.set_shader_parameter("scale", 2.0) # Escala fixa agradável para o menu
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
