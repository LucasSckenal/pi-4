extends Control

var slot_cena = preload("res://slot_personagem.tscn")

@onready var grid = $HBoxContainer/ScrollContainer/GridContainer
@onready var ponto_spawn = get_node_or_null("HBoxContainer/SubViewportContainer/SubViewport/PontoSpawn")

func _ready():
	# 1. Limpa a grade
	for child in grid.get_children():
		child.queue_free()
	
	# 2. Cria os slots (Apenas UMA vez agora)
	for caminho in Global.lista_personagens:
		var novo_slot = slot_cena.instantiate()
		grid.add_child(novo_slot)
		
		# Configura a miniatura
		if novo_slot.has_method("configurar_slot"):
			novo_slot.configurar_slot(caminho) 
		
		# Conecta o clique no slot
		var btn = novo_slot.get_node_or_null("Button")
		if btn:
			btn.pressed.connect(_ao_escolher.bind(caminho))

func _ao_escolher(caminho):
	# MUITO IMPORTANTE: Salva a escolha do jogador no Global!
	# É isso que o botão "Selecionar" vai conferir depois.
	Global.personagem_escolhido_path = caminho

	if ponto_spawn:
		# Deleta quem estava lá
		for n in ponto_spawn.get_children():
			n.queue_free()
		
		# Spawna o personagem grande
		var grande = load(caminho).instantiate()
		ponto_spawn.add_child(grande)
		grande.scale = Vector3(0.8, 0.8, 0.8)
		
		# Toca a animação (com o Loop infinito que fizemos antes)
		var anim = grande.get_node_or_null("AnimationPlayer")
		if anim: 
			var animacao_idle = anim.get_animation("idle")
			if animacao_idle:
				animacao_idle.loop_mode = Animation.LOOP_LINEAR
			anim.play("idle")


# ---------------------------------------------------------
# BOTÕES DE AÇÃO
# ---------------------------------------------------------

func _on_btn_back_pressed() -> void:
	# Se ele cancelou, limpamos a escolha para não bugar
	Global.personagem_escolhido_path = ""
	# Volta pro menu principal
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_btn_select_pressed() -> void:
	# 1. Verifica se ele realmente clicou em um boneco antes de selecionar
	if Global.personagem_escolhido_path == "":
		print("Você precisa clicar em um personagem primeiro!")
		# DICA: Aqui você pode colocar um Label na tela avisando o erro
		return # Interrompe a função aqui
		
	# 2. Se tudo deu certo, volta pro menu com o personagem salvo!
	print("Personagem salvo: ", Global.personagem_escolhido_path)
	get_tree().change_scene_to_file("res://main_menu.tscn")
