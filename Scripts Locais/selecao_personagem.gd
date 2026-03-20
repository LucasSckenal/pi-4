extends Control

var slot_cena = preload("res://Cenas Locais/slot_personagem.tscn")

@onready var grid = $HBoxContainer/ScrollContainer/GridContainer
@onready var ponto_spawn = get_node_or_null("HBoxContainer/SubViewportContainer/SubViewport/PontoSpawn")

# VARIÁVEL TEMPORÁRIA: Guarda quem você clicou, mas ainda não confirmou
var personagem_temporario = ""

func _ready():
	# Cria os slots (USANDO O ÍNDICE 'i' PARA CHECAR O BLOQUEIO)
	for i in range(Global.lista_personagens.size()):
		var caminho = Global.lista_personagens[i]
		
		var novo_slot = slot_cena.instantiate()
		grid.add_child(novo_slot)
		
		# Configura a miniatura
		if novo_slot.has_method("configurar_slot"):
			novo_slot.configurar_slot(caminho) 
		
		var btn = novo_slot.get_node_or_null("Button")
		
		# --- VERIFICAÇÃO DO SISTEMA DE CONQUISTAS ---
		if Global.is_personagem_liberado(i):
			# === DESBLOQUEADO ===
			# Deixa a cor do slot normal (branca/original)
			novo_slot.modulate = Color(1.0, 1.0, 1.0, 1.0) 
			
			if btn:
				btn.disabled = false
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				# Conecta o clique normal
				btn.pressed.connect(_ao_escolher.bind(caminho))
		else:
			# === BLOQUEADO ===
			# Escurece o slot quase todo (RGB em 0.1 deixa bem escuro)
			novo_slot.modulate = Color(0.1, 0.1, 0.1, 1.0) 
			
			if btn:
				btn.disabled = true
				# Não conecta o sinal, assim ele não faz nada se o jogador clicar
				
	# ---> O QUE VOCÊ PEDIU: Mostra o personagem global por padrão <---
	if Global.personagem_escolhido_path != "":
		_ao_escolher(Global.personagem_escolhido_path)


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
		_aplicar_outline_automatico(grande)
		
		# Use a escala que você já ajustou e achou melhor
		grande.scale = Vector3(0.3, 0.3, 0.3) 
		
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
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")


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
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
	print("Personagem salvo com sucesso para o jogo: ", Global.personagem_escolhido_path)


# ==========================================
# AUTOMAÇÃO DE SHADER DE OUTLINE
# ==========================================
const OUTLINE_SHADER = preload("res://Shaders/Outline.gdshader")

func _aplicar_outline_automatico(no_raiz: Node):
	var mat_outline = ShaderMaterial.new()
	if OUTLINE_SHADER:
		mat_outline.shader = OUTLINE_SHADER
		mat_outline.set_shader_parameter("scale", 1.0)
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
