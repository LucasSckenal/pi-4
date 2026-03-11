extends CharacterBody3D

@export var speed = 2.0
@export var jump_velocity = 4.0
@export var gravity = 20.0
@export var rotation_speed = 10.0 

@onready var anim_player = $"character-male-f2/AnimationPlayer"
@onready var nav_agent = $NavigationAgent3D
@onready var linha_caminho = $LinhaCaminho

# Captura o clique do mouse para definir o destino do pathfinding
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Cenas locais/main_menu.tscn")
	
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
			
		# Renderiza o caminho visual se o nó existir e for do tipo adequado
		if linha_caminho and linha_caminho.mesh is ImmediateMesh:
			var caminho_atual = nav_agent.get_current_navigation_path()
			_desenhar_caminho(caminho_atual)

	else:
		# Limpa o caminho da tela quando o jogador chega ao destino
		if linha_caminho and linha_caminho.mesh is ImmediateMesh:
			linha_caminho.mesh.clear_surfaces()

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

	# 4. GERENCIADOR DE ANIMAÇÕES
	if not is_on_floor():
		# Se ele NÃO está no chão (está caindo ou pulando), toca o pulo.
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
	
	# Desvincula a linha do transform local do Player para que ela fique estática no mundo
	if linha_caminho:
		linha_caminho.top_level = true
	
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
			# 4. Atualiza a variável de animação para o novo boneco
			var novo_anim_player = modelo_novo.get_node_or_null("AnimationPlayer")
			if novo_anim_player:
				anim_player = novo_anim_player
				
				# Força as animações principais a ficarem em loop
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
		printerr("ERRO VISUAL: O script do Player não está achando o Nó do texto! Verifique se o nome é exatamente TextoMoedas e se ele é filho direto do Player.")

# ---------------------------------------------------------
# FUNÇÃO PARA DESENHAR O CAMINHO VISUAL DO NAVMESH
# ---------------------------------------------------------
# ---------------------------------------------------------
# FUNÇÃO PARA DESENHAR O CAMINHO VISUAL DO NAVMESH E MARCADOR DE DESTINO
# ---------------------------------------------------------
func _desenhar_caminho(caminho: PackedVector3Array):
	var mesh = linha_caminho.mesh as ImmediateMesh
	mesh.clear_surfaces()
	
	if caminho.size() < 2:
		return
		
	# Variáveis de controle do visual do tracejado
	var espessura = 0.05
	var tamanho_traco = 0.2
	var espaco_traco = 0.15
	var passo_total = tamanho_traco + espaco_traco
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Desenha os segmentos tracejados do caminho
	for i in range(caminho.size() - 1):
		# Converte as coordenadas globais do navmesh para as coordenadas locais da linha
		var p1_local = linha_caminho.to_local(caminho[i])
		var p2_local = linha_caminho.to_local(caminho[i+1])
		
		# Define a altura exata da linha. Sinta-se à vontade para ajustar esse número se precisar subir ou descer um pouco mais.
		p1_local.y += 0.05
		p2_local.y += 0.05
		
		var direcao = (p2_local - p1_local).normalized()
		var distancia = p1_local.distance_to(p2_local)
		
		# Calcula o vetor lateral para dar a largura da fita geométrica
		var direita = direcao.cross(Vector3.UP).normalized() * espessura
		
		var distancia_percorrida = 0.0
		while distancia_percorrida < distancia:
			var inicio_traco = p1_local + direcao * distancia_percorrida
			# Garante que o traço não passe do ponto final do segmento atual
			var fim_traco = p1_local + direcao * min(distancia_percorrida + tamanho_traco, distancia)
			
			# Define os quatro cantos do retângulo para o traço atual
			var v1 = inicio_traco - direita
			var v2 = inicio_traco + direita
			var v3 = fim_traco - direita
			var v4 = fim_traco + direita
			
			# Monta o retângulo (face primária)
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v3)
			mesh.surface_add_vertex(v2)
			
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v3)
			mesh.surface_add_vertex(v4)
			
			# Monta o retângulo (face secundária para garantir visibilidade contra o culling)
			mesh.surface_add_vertex(v1)
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v3)
			
			mesh.surface_add_vertex(v2)
			mesh.surface_add_vertex(v4)
			mesh.surface_add_vertex(v3)
			
			distancia_percorrida += passo_total

	# Desenha um 'X' marcando o destino final
	var ponto_final = linha_caminho.to_local(caminho[caminho.size() - 1])
	ponto_final.y += 0.05
	
	var tamanho_x = 0.15
	var espessura_x = 0.04
	
	# Primeira perna do X (Diagonal 1)
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
	
	# Segunda perna do X (Diagonal 2)
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
