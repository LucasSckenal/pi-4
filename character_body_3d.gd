extends CharacterBody3D

@export var speed = 2.0
@export var jump_velocity = 4.0 # <-- NOVA: A força do pulo
@export var gravity = 20.0
@export var rotation_speed = 10.0 

@onready var anim_player = $"character-male-f2/AnimationPlayer"

func _physics_process(delta):
	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. O PULO (NOVO)
	# "ui_accept" é a Barra de Espaço (ou Enter) por padrão no Godot
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Movimento (Input)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Rotação suave do corpo
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# 4. NOVO GERENCIADOR DE ANIMAÇÕES
	if not is_on_floor():
		# Se ele NÃO está no chão (está caindo ou pulando), toca o pulo.
		# IMPORTANTE: Mude "jump" para o nome exato da sua animação!
		if anim_player.current_animation != "jump":
			anim_player.play("jump")
	else:
		# Se ele ESTÁ no chão, decide se anda ou fica parado
		if direction.length() > 0:
			if anim_player.current_animation != "walk":
				anim_player.play("walk")
		else:
			if anim_player.current_animation != "idle":
				anim_player.play("idle")

	# 5. Executar a física
	move_and_slide()
	
# ---------------------------------------------------------
# SISTEMA DE MOEDAS E INTERFACE (HUD)
# ---------------------------------------------------------
@export var moedas: int = 50
@onready var texto_moedas = $TextoMoedas

func _ready():
	add_to_group("Player")
	atualizar_hud()

# ---------------------------------------------------------
# FUNÇÃO PARA ATUALIZAR O TEXTO NO ECRÃ
# ---------------------------------------------------------
func atualizar_hud():
	# 1. Este print vai nos provar se a mina conseguiu avisar o Player
	print("O Player foi avisado! Moedas na conta: ", moedas)
	
	# 2. Tenta atualizar o texto
	if texto_moedas != null:
		texto_moedas.text = "Moedas: " + str(moedas)
	else:
		# Se o texto não mudar, este erro vermelho vai aparecer na tela!
		printerr("ERRO VISUAL: O script do Player não está achando o Nó do texto! Verifique se o nome é exatamente TextoMoedas e se ele é filho direto do Player.")
