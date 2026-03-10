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
	get_tree().change_scene_to_file("res://World.tscn")

func _on_btn_customizar_pressed():
	print("Mudar para a tela de Customização!")
	get_tree().change_scene_to_file("res://selecao_personagem.tscn")

func _on_btn_configuracoes_pressed():
	print("Mudar para a tela de Configurações!")
	get_tree().change_scene_to_file("res://configuracoes.tscn")

func _on_btn_sair_pressed() -> void:
	print("Fechando o jogo...")
	get_tree().quit()
