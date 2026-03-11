extends CharacterBody3D

@export var speed = 2.0
@export var jump_velocity = 4.0 # <-- NOVA: A força do pulo
@export var gravity = 20.0
@export var rotation_speed = 10.0 

@onready var anim_player = $"character-male-f2/AnimationPlayer"
@onready var nav_agent = $NavigationAgent3D

# Captura o clique do mouse para definir o destino do pathfinding
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var ray_origin = camera.project_ray_origin(event.position)
			var ray_target = ray_origin + camera.project_ray_normal(event.position) * 1000.0
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(query)
			if result:
				nav_agent.target_position = result.position

func _physics_process(delta):
	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. O PULO (AUTOMÁTICO) E NAVEGAÇÃO
	var direction = Vector3.ZERO
	
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var current_pos = global_position
		direction = (next_path_pos - current_pos)
		direction.y = 0
		direction = direction.normalized()
		
		# Pulo automático ao detectar obstáculo frontal durante a navegação
		if is_on_floor() and is_on_wall():
			velocity.y = jump_velocity

	# 3. Movimento (Navegação)
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
	
	# Configurações de distância do NavigationAgent para evitar paradas prematuras
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	# ---------------------------------------------------------
	# SISTEMA DE TROCA DE PERSONAGEM
	# ---------------------------------------------------------
	# Verifica se tem algum caminho salvo lá no Global
	if Global.personagem_escolhido_path != "":
		
		var modelo_antigo = get_node_or_null("character-male-f2")
		
		if modelo_antigo:
			# 1. Carrega o boneco que o jogador escolheu no menu
			var cena_novo_modelo = load(Global.personagem_escolhido_path)
			var modelo_novo = cena_novo_modelo.instantiate()
			
			# 2. Renomeia o novo para o nome padrão (mantém a árvore organizada)
			modelo_novo.name = "character-male-f2"
			
			# 3. Adiciona o novo boneco na cena do Player
			add_child(modelo_novo)
			modelo_novo.scale = Vector3(0.3, 0.3, 0.3)
			# 4. O PULO DO GATO: Atualiza a variável de animação para o novo boneco!
			# Se não fizermos isso, o jogo quebra ao tentar andar.
			var novo_anim_player = modelo_novo.get_node_or_null("AnimationPlayer")
			if novo_anim_player:
				anim_player = novo_anim_player
				
				# Força as animações principais a ficarem em loop (opcional, mas recomendado)
				if anim_player.has_animation("idle"): anim_player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
				if anim_player.has_animation("walk"): anim_player.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
			
			# 5. Agora que o novo já está pronto, renomeamos e deletamos o antigo
			modelo_antigo.name = "Boneco_Deletado"
			modelo_antigo.queue_free()

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
