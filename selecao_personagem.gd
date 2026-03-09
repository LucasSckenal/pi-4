extends Control

var slot_cena = preload("res://slot_personagem.tscn")

@onready var grid = $HBoxContainer/ScrollContainer/GridContainer
@onready var ponto_spawn = get_node_or_null("HBoxContainer/SubViewportContainer/SubViewport/PontoSpawn")

# VARIÁVEL TEMPORÁRIA: Guarda quem você clicou, mas ainda não confirmou
var personagem_temporario = ""

func _ready():
	# Limpa a grade
	for child in grid.get_children():
		child.queue_free()
	
	# Cria os slots
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
	# 1. VISUALIZAR: Salva APENAS no temporário por enquanto!
	personagem_temporario = caminho

	if ponto_spawn:
		# Deleta quem estava lá na tela grande
		for n in ponto_spawn.get_children():
			n.queue_free()
		
		# Spawna o personagem grande
		var grande = load(caminho).instantiate()
		ponto_spawn.add_child(grande)
		grande.scale = Vector3(0.3, 0.3, 0.3) # Tamanho 0.3 como você pediu!
		
		# Toca a animação em Loop
		var anim = grande.get_node_or_null("AnimationPlayer")
		if anim: 
			var animacao_idle = anim.get_animation("idle")
			if animacao_idle:
				animacao_idle.loop_mode = Animation.LOOP_LINEAR
			anim.play("idle")


# ---------------------------------------------------------
# BOTÃO DE VOLTAR (Apenas sai da tela)
# ---------------------------------------------------------
func _on_btn_back_pressed() -> void:
	print("Voltando para o menu principal...")
	get_tree().change_scene_to_file("res://main_menu.tscn")


# ---------------------------------------------------------
# BOTÃO DE SELECIONAR (Salva no Global e fica na tela)
# ---------------------------------------------------------
func _on_btn_select_pressed() -> void:
	# Verifica se tem alguém no temporário (se você clicou em alguma miniatura)
	if personagem_temporario == "":
		print("Aviso: Você precisa clicar em um personagem primeiro!")
		return 
		
	# AGORA SIM! O jogador confirmou. Passamos do temporário para o Global!
	Global.personagem_escolhido_path = personagem_temporario
	print("Personagem salvo com sucesso para o jogo: ", Global.personagem_escolhido_path)
