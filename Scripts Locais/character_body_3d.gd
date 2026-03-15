extends CharacterBody3D

# --- CONFIGURAÇÕES DE MOVIMENTO ---
@export var speed = 2.0
@export var jump_velocity = 4.0
@export var gravity = 20.0
@export var rotation_speed = 10.0 

# --- CONFIGURAÇÕES DE COMBATE ---
@export var dano_ataque: int = 5
@export var velocidade_ataque: float = 0.8 # Tempo entre os golpes

# --- REFERÊNCIAS ---
@onready var anim_player = $"character-male-f2/AnimationPlayer"
@onready var nav_agent = $NavigationAgent3D
@onready var linha_caminho = $LinhaCaminho
@onready var area_ataque = $AreaAtaque 
@onready var timer_ataque = $TimerAtaque

# --- ESTADOS ---
var pode_atacar: bool = true
var inimigo_focado: Node3D = null

func _ready():
	add_to_group("Player")
	
	# Configura o Timer de Ataque
	timer_ataque.wait_time = velocidade_ataque
	timer_ataque.one_shot = true
	if not timer_ataque.timeout.is_connected(_on_timer_ataque_timeout):
		timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	if linha_caminho:
		linha_caminho.top_level = true
	
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.1
	
	# Configura o personagem salvo (e anexa a espada)
	_configurar_modelo_escolhido()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Cenas locais/main_menu.tscn")
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var ray_origin = camera.project_ray_origin(event.position)
			var ray_target = ray_origin + camera.project_ray_normal(event.position) * 1000.0
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
			var result = get_world_3d().direct_space_state.intersect_ray(query)
			if result:
				nav_agent.target_position = result.position

func _physics_process(delta):
	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Navegação e Pulo Automático
	var direction = Vector3.ZERO
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		direction = (next_path_pos - global_position)
		direction.y = 0
		direction = direction.normalized()
		
		if is_on_floor() and is_on_wall():
			velocity.y = jump_velocity
			
		if linha_caminho and linha_caminho.mesh is ImmediateMesh:
			_desenhar_caminho(nav_agent.get_current_navigation_path())
	else:
		if linha_caminho and linha_caminho.mesh is ImmediateMesh:
			linha_caminho.mesh.clear_surfaces()

	# 3. Movimento e Rotação Inteligente
	var angulo_destino = rotation.y # Mantém a rotação atual por padrão
	
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		angulo_destino = atan2(direction.x, direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# SE ESTIVER ATACANDO ALGUÉM, IGNORA O CAMINHO E OLHA PARA O INIMIGO
	if is_instance_valid(inimigo_focado) and not pode_atacar:
		var direcao_inimigo = (inimigo_focado.global_position - global_position).normalized()
		angulo_destino = atan2(direcao_inimigo.x, direcao_inimigo.z)
		
	# Gira suavemente o corpo do personagem
	rotation.y = lerp_angle(rotation.y, angulo_destino, rotation_speed * delta)

	# 4. Gerenciador de Animações
	_gerenciar_animacoes(direction)
	
	# 5. Sistema de Auto-Ataque
	_verificar_ataque_automatico()

	move_and_slide()

	# 6. Sistema de Respawn (Prevenção de queda do mapa)
	# Verifica se o personagem caiu abaixo de um limite vertical seguro
	if global_position.y < -50.0:
		# Retorna o jogador para o centro do mapa (um pouco acima do chão para não prender a colisão)
		global_position = Vector3(0, 1.0, 0)
		velocity = Vector3.ZERO # Zera a velocidade acumulada da queda livre
		nav_agent.target_position = global_position # Reseta a rota do NavigationAgent para ele não tentar correr de volta para o buraco

# ==========================================
# LÓGICA DE COMBATE
# ==========================================

func _verificar_ataque_automatico():
	if not pode_atacar: return
	
	var inimigos = area_ataque.get_overlapping_bodies()
	for corpo in inimigos:
		if corpo.is_in_group("inimigos"):
			_executar_ataque(corpo)
			break # Ataca apenas um por vez

func _executar_ataque(inimigo):
	pode_atacar = false
	inimigo_focado = inimigo # Salva quem o personagem deve olhar
	timer_ataque.start()
	
	if anim_player.has_animation("attack-melee-left"):
		anim_player.play("attack-melee-left")
	
	if inimigo.has_method("receber_dano"):
		inimigo.receber_dano(dano_ataque)

func _on_timer_ataque_timeout():
	pode_atacar = true
	inimigo_focado = null # Limpa o alvo quando termina o golpe


# ==========================================
# SISTEMAS AUXILIARES E ANIMAÇÕES
# ==========================================

func _gerenciar_animacoes(direction):
	# Se estiver atacando, não interrompe com a animação de andar/parado
	if anim_player.current_animation == "attack-melee-left" and anim_player.is_playing():
		return
		
	if not is_on_floor():
		if anim_player.current_animation != "jump": anim_player.play("jump")
	elif direction.length() > 0:
		if anim_player.current_animation != "walk": anim_player.play("walk")
	else:
		if anim_player.current_animation != "idle": anim_player.play("idle")




# ==========================================
# TROCA DE PERSONAGEM E ARMA
# ==========================================

func _configurar_modelo_escolhido():
	if Global.personagem_escolhido_path == "": return
	
	var espada = find_child("sword_C2", true, false)
	var modelo_antigo = get_node_or_null("character-male-f2")
	
	if modelo_antigo:
		if espada:
			espada.get_parent().remove_child(espada)
		
		# Instancia o novo modelo
		var cena_novo_modelo = load(Global.personagem_escolhido_path)
		var modelo_novo = cena_novo_modelo.instantiate()
		modelo_novo.name = "character-male-f2"
		add_child(modelo_novo)
		modelo_novo.scale = Vector3(0.3, 0.3, 0.3)
		
		# Atualiza as animações
		var novo_anim_player = modelo_novo.find_child("AnimationPlayer", true)
		if novo_anim_player:
			anim_player = novo_anim_player
			for anim_name in ["idle", "walk"]:
				if anim_player.has_animation(anim_name):
					anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		
		# Re-anexa a espada (sword_C2)
		if espada:
			var novo_skeleton = modelo_novo.find_child("Skeleton3D", true)
			if novo_skeleton:
				var novo_attachment = BoneAttachment3D.new()
				novo_skeleton.add_child(novo_attachment)
				novo_attachment.bone_name = "arm-left" 
				novo_attachment.add_child(espada)
				
				# Seus valores exatos aplicados
				espada.position = Vector3(0.22, 0.012, 0.092)
				espada.rotation_degrees = Vector3(-47.9, 68.2, 93.5)
				espada.scale = Vector3(0.33, 0.33, 0.33)
				
				espada.show() 
		
		modelo_antigo.queue_free()


# ==========================================
# CAMINHO VISUAL (PATHFINDING)
# ==========================================

func _desenhar_caminho(caminho: PackedVector3Array):
	var mesh = linha_caminho.mesh as ImmediateMesh
	mesh.clear_surfaces()
	
	if caminho.size() < 2:
		return
		
	var espessura = 0.05
	var tamanho_traco = 0.2
	var espaco_traco = 0.15
	var passo_total = tamanho_traco + espaco_traco
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(caminho.size() - 1):
		var p1_local = linha_caminho.to_local(caminho[i])
		var p2_local = linha_caminho.to_local(caminho[i+1])
		
		p1_local.y += 0.05
		p2_local.y += 0.05
		
		var direcao = (p2_local - p1_local).normalized()
		var distancia = p1_local.distance_to(p2_local)
		var direita = direcao.cross(Vector3.UP).normalized() * espessura
		
		var distancia_percorrida = 0.0
		while distancia_percorrida < distancia:
			var inicio_traco = p1_local + direcao * distancia_percorrida
			var fim_traco = p1_local + direcao * min(distancia_percorrida + tamanho_traco, distancia)
			
			var v1 = inicio_traco - direita
			var v2 = inicio_traco + direita
			var v3 = fim_traco - direita
			var v4 = fim_traco + direita
			
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v3)
			mesh.surface_add_vertex(v2)
			
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v3)
			mesh.surface_add_vertex(v4)
			
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v3)
			
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v4)
			mesh.surface_add_vertex(v3)
			
			distancia_percorrida += passo_total

	var ponto_final = linha_caminho.to_local(caminho[caminho.size() - 1])
	ponto_final.y += 0.05
	
	var tamanho_x = 0.15
	var espessura_x = 0.04
	
	var dir_x1 = Vector3(1, 0, 1).normalized()
	var lateral_x1 = dir_x1.cross(Vector3.UP).normalized() * espessura_x
	var inicio_x1 = ponto_final - dir_x1 * tamanho_x
	var fim_x1 = ponto_final + dir_x1 * tamanho_x
	
	var v1_x = inicio_x1 - lateral_x1
	var v2_x = inicio_x1 + lateral_x1
	var v3_x = fim_x1 - lateral_x1
	var v4_x = fim_x1 + lateral_x1
	
	mesh.surface_add_vertex(v1_x)
	mesh.surface_add_vertex(v3_x)
	mesh.surface_add_vertex(v2_x)
	mesh.surface_add_vertex(v2_x)
	mesh.surface_add_vertex(v3_x)
	mesh.surface_add_vertex(v4_x)
	
	mesh.surface_add_vertex(v1_x)
	mesh.surface_add_vertex(v2_x)
	mesh.surface_add_vertex(v3_x)
	mesh.surface_add_vertex(v2_x)
	mesh.surface_add_vertex(v4_x)
	mesh.surface_add_vertex(v3_x)
	
	var dir_x2 = Vector3(1, 0, -1).normalized()
	var lateral_x2 = dir_x2.cross(Vector3.UP).normalized() * espessura_x
	var inicio_x2 = ponto_final - dir_x2 * tamanho_x
	var fim_x2 = ponto_final + dir_x2 * tamanho_x
	
	var v5_x = inicio_x2 - lateral_x2
	var v6_x = inicio_x2 + lateral_x2
	var v7_x = fim_x2 - lateral_x2
	var v8_x = fim_x2 + lateral_x2
	
	mesh.surface_add_vertex(v5_x)
	mesh.surface_add_vertex(v7_x)
	mesh.surface_add_vertex(v6_x)
	mesh.surface_add_vertex(v6_x)
	mesh.surface_add_vertex(v7_x)
	mesh.surface_add_vertex(v8_x)
	
	mesh.surface_add_vertex(v5_x)
	mesh.surface_add_vertex(v6_x)
	mesh.surface_add_vertex(v7_x)
	mesh.surface_add_vertex(v6_x)
	mesh.surface_add_vertex(v8_x)
	mesh.surface_add_vertex(v7_x)

	mesh.surface_end()
