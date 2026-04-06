extends CharacterBody3D

# --- SONS ---
const SOM_PULO = preload("res://Sons/jump.wav")

# --- CONFIGURAÇÕES DE MOVIMENTO ---
@export var speed = 2.0
@export var jump_velocity = 4.0
@export var gravity = 20.0
@export var rotation_speed = 10.0 

const TEXTURA_CORTE = preload("res://Icons/HalfMoon.png")
const OUTLINE_SHADER = preload("res://Shaders/Outline.gdshader")

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
var tween_clique: Tween
var rotation_tween: Tween = null
var materiais_outline: Array[ShaderMaterial] = [] # Cache dos materiais para otimizar o zoom

func _ready():
	add_to_group("Player")
	
	# Configura o Timer de Ataque
	timer_ataque.wait_time = velocidade_ataque
	timer_ataque.one_shot = true
	if not timer_ataque.timeout.is_connected(_on_timer_ataque_timeout):
		timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	if linha_caminho:
		linha_caminho.top_level = true
		linha_caminho.hide()
	
	# --- AQUI ESTÁ A BARREIRA DE SEGURANÇA DE VOLTA ---
	if nav_agent != null:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.1
	
	# Configura o personagem salvo (e anexa a espada)
	# O shader agora é aplicado automaticamente ao final desta função
	_configurar_modelo_escolhido()

func _unhandled_input(event):
	# Adiciona trava para ignorar input se o tutorial estiver com diálogo aberto
	var tutorial = get_tree().get_first_node_in_group("TutorialManager")
	if tutorial and tutorial.visible and tutorial.alvo_2d_atual == null:
		return

	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Cenas locais/main_menu.tscn")
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Bloqueia clique de andar durante o dia (fase de construção)
			if not GameManager.is_night and not GameManager.modo_dev:
				return
				
			var camera = get_viewport().get_camera_3d()
			if camera:
				var ray_origin = camera.project_ray_origin(event.position)
				var ray_target = ray_origin + camera.project_ray_normal(event.position) * 1000.0
				
				# MÁSCARA DE COLISÃO: Definida para 1 (Chão), ignorando torres (Layer 3)
				var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target, 1) 
				var result = get_world_3d().direct_space_state.intersect_ray(query)
				if result:
					nav_agent.target_position = result.position
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var camera = get_viewport().get_camera_3d()
			if camera:
				var ray_origin = camera.project_ray_origin(event.position)
				var ray_target = ray_origin + camera.project_ray_normal(event.position) * 1000.0
				var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
				var result = get_world_3d().direct_space_state.intersect_ray(query)
				if result:
					nav_agent.target_position = result.position
					
					# Feedback visual do clique no destino com animação de pulso
					if linha_caminho:
						# Mostrando após primeiro clique
						linha_caminho.show()
						
						#GERENCIA A ROTAÇÃO CONTÍNUA E LEVE
						if rotation_tween:
							rotation_tween.kill() # Mata a rotação anterior antes de começar a nova
						
						# Cria um novo Tween infinito
						rotation_tween = create_tween().set_loops() 
						
						# Anima a rotação Y (para girar no chão) de 0 até 360 graus
						# A duração de 5.0 segundos define a velocidade; aumente para girar mais devagar.
						# O método set_trans(Tween.TRANS_LINEAR) garante que a velocidade seja constante.
						rotation_tween.tween_property(linha_caminho, "rotation:y", deg_to_rad(360.0), 5.0).from(0.0).set_trans(Tween.TRANS_LINEAR)
						
						
						# Interrompe a animação anterior caso haja múltiplos cliques em sequência
						if tween_clique and tween_clique.is_valid():
							tween_clique.kill()
							
						linha_caminho.global_position = result.position
						linha_caminho.scale = Vector3.ZERO
						
						tween_clique = create_tween()
						tween_clique.set_parallel(true)
						tween_clique.tween_property(linha_caminho, "scale", Vector3(1, 1, 1), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
						
						# Suaviza a transparência assumindo que o nó seja um Sprite3D ou Decal
						if "modulate" in linha_caminho:
							linha_caminho.modulate.a = 1.0
							tween_clique.tween_property(linha_caminho, "modulate:a", 0.0, 0.5).set_delay(0.2)
						elif "albedo_mix" in linha_caminho:
							linha_caminho.albedo_mix = 1.0
							tween_clique.tween_property(linha_caminho, "albedo_mix", 0.0, 0.5).set_delay(0.2)
		
		# Sistema de Zoom da Câmera e ajuste dinâmico do Outline
		# Bloqueia Zoom durante diálogos do tutorial
		var camera_zoom = get_viewport().get_camera_3d()
		if camera_zoom and event.pressed:
			if tutorial and tutorial.visible: return
			
			if get_tree().current_scene and get_tree().current_scene.name.to_lower().contains("menu"):
				return
			
			var mudou_zoom = false
			
			# Precisa acrescentar uma função que usa o NOVO estilo de zoom aqui, com os 4 níveis
			var hud_mobile = get_tree().root.find_child("HudMobileCompleto", true, false)
			
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if hud_mobile and hud_mobile.has_method("_zoom_aproximar"):
					hud_mobile._zoom_aproximar()
					mudou_zoom = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if hud_mobile and hud_mobile.has_method("_zoom_afastar"):
					hud_mobile._zoom_afastar()
					mudou_zoom = true
				
			if mudou_zoom:
				var parametro_zoom = camera_zoom.fov if camera_zoom.projection == Camera3D.PROJECTION_PERSPECTIVE else camera_zoom.size
				_atualizar_escala_outline(parametro_zoom)

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
					var eh_barreira: bool = false
					for i in get_slide_collision_count():
						var colisao = get_slide_collision(i)
						var colisor = colisao.get_collider()
						
						# Verifica se a parede colidida pertence ao grupo de barreiras de limite do mapa
						if colisor and colisor.is_in_group("Barreiras"):
							eh_barreira = true
							break
					
					if not eh_barreira:
						velocity.y = jump_velocity
						var player_som = AudioStreamPlayer3D.new()
						player_som.stream = SOM_PULO
						player_som.volume_db = -25
						player_som.bus = "SFX" # Use um barramento de áudio para controle de volume
						add_child(player_som)
						player_som.play()
						player_som.finished.connect(player_som.queue_free)

	# 2.5 Se a navegação terminou, esconde o feedback visual e para a rotação
	if nav_agent.is_navigation_finished() and linha_caminho.visible:
		linha_caminho.hide()
		if rotation_tween:
			rotation_tween.kill()

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

		# Limpa o caminho visual ao cair
		if linha_caminho:
			linha_caminho.hide()
			if rotation_tween:
				rotation_tween.kill()

# ==========================================
# LÓGICA DE COMBATE
# ==========================================

func _verificar_ataque_automatico():
	if not pode_atacar: return
	
	var inimigos = area_ataque.get_overlapping_bodies()
	var alvos_validos = []
	
	for corpo in inimigos:
		if corpo.is_in_group("inimigos"):
			alvos_validos.append(corpo)
			
	# Se houver inimigos na área, ataca todos de uma vez
	if alvos_validos.size() > 0:
		_executar_ataque_area(alvos_validos)

func _executar_ataque_area(inimigos: Array):
	pode_atacar = false
	inimigo_focado = inimigos[0] # Salva o primeiro inimigo para o personagem virar para ele
	timer_ataque.start()
	
	# --- TRADUTOR DO ATAQUE ---
	var anim_ataque = "Triple_Combo_Attack" if Global.usando_set_bloodborne else "attack-melee-left"
	
	if anim_player.has_animation(anim_ataque):
		anim_player.play(anim_ataque)
		
	# --- EFEITO DE ESCALA DINÂMICA NA ARMA ---
	var ponto_arma = find_child("BoneAttachment3D", true, false)
	if ponto_arma:
		for arma in ponto_arma.get_children():
			if arma.visible:
				var escala_original = arma.scale
				var escala_alvo = escala_original
				escala_alvo *= 1.3 # Aumenta o comprimento em 30%
				
				await get_tree().create_timer(0.2).timeout
				var tw_escala = create_tween()
				# Estica a arma rapidamente
				tw_escala.tween_property(arma, "scale", escala_alvo, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				# Retorna ao tamanho original logo em seguida
				tw_escala.tween_property(arma, "scale", escala_original, 0.2).set_delay(0.05)
		
	_criar_efeito_visual_corte()
	
	# Aplica dano em todos os inimigos capturados na área de ataque
	for inimigo in inimigos:
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(dano_ataque)

func _criar_efeito_visual_corte():
	# Cria uma malha simples para o rastro da espada
	var efeito = MeshInstance3D.new()
	var malha = PlaneMesh.new()
	malha.size = Vector2(1.0, 1.0) # Aumentado para acomodar o rastro circular
	efeito.mesh = malha
	
	# Shader adaptada para Spatial (3D) baseada na lógica fornecida
	var shader = Shader.new()
	shader.code = """
        shader_type spatial;
        render_mode unshaded, cull_disabled;

        uniform sampler2D tex_albedo;
        uniform float inner_radius : hint_range(0.0, 1.0) = 0.2;
        uniform float outer_radius : hint_range(0.0, 1.0) = 0.5;
        uniform float lead_angle : hint_range(0.0, 2.0) = 0.0;
        uniform float tail_angle : hint_range(0.0, 2.0) = 0.5;
        uniform vec4 slash_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
        // Define a espessura minima das pontas do rastro
        uniform float tips_thickness : hint_range(0.0, 1.0) = 0.0;

        void fragment() {
            vec2 pos = UV - 0.5;
            float dist = length(pos);
            float angle = (atan(pos.y, pos.x) + PI) / TAU; 
            
            float angle_mask = step(angle, lead_angle);
            float inner_mask = step(inner_radius, dist);
            
            float alpha_fade = smoothstep(lead_angle - tail_angle, lead_angle, angle);
            
            // Calcula a curva de espessura (0 nas pontas, 1 no centro do rastro)
            float thickness_curve = sin(alpha_fade * PI);
            
            // Interpola o raio externo entre o limite das pontas e o raio maximo do corte
            float current_outer_radius = mix(inner_radius + tips_thickness, outer_radius, thickness_curve);
            float outer_mask = step(dist, current_outer_radius);
            
            ALBEDO = slash_color.rgb;
            ALPHA = slash_color.a * inner_mask * outer_mask * angle_mask * alpha_fade;
        }
    """
	
	var material = ShaderMaterial.new()
	material.shader = shader
	# Configurações iniciais
	material.set_shader_parameter("inner_radius", 0.3)
	material.set_shader_parameter("outer_radius", 0.4)
	material.set_shader_parameter("lead_angle", 0.0)
	material.set_shader_parameter("slash_color", Color(1.0, 1.0, 1.0, 0.8))
	
	efeito.material_override = material
	add_child(efeito)
	
	# Posicionamento e rotação (ajustado para horizontal à frente do player)
	efeito.position = Vector3(0.0, 0.15, 0.0)
	efeito.rotation_degrees = Vector3(180, 0, 0)
	
	# Animação do "lead_angle" para fazer o corte aparecer circulando
	var tween = create_tween()
	tween.set_parallel(true)
	# O corte "gira" de 0 a 0.8 (quase meio círculo)
	tween.tween_property(material, "shader_parameter/lead_angle", 0.5, 0.1).set_ease(Tween.EASE_OUT)
	# Desvanece a opacidade
	tween.tween_property(material, "shader_parameter/slash_color:a", 0.0, 0.25).set_delay(0.1)
	
	tween.chain().tween_callback(efeito.queue_free)
	
func _on_timer_ataque_timeout():
	pode_atacar = true
	inimigo_focado = null # Limpa o alvo quando termina o golpe


# ==========================================
# SISTEMAS AUXILIARES E ANIMAÇÕES
# ==========================================

func _gerenciar_animacoes(direction):
	if not anim_player: return # Proteção caso ainda não tenha carregado
	
	# 1. Define os nomes corretos dependendo se é o Bloodborne ou o Avô/Avó
	var anim_ataque = "Triple_Combo_Attack" if Global.usando_set_bloodborne else "attack-melee-left"
	var anim_andar = "Walking" if Global.usando_set_bloodborne else "walk"
	var anim_parado = "Idle" if Global.usando_set_bloodborne else "idle"
	var anim_pulo = "jump"
	
	# 2. Se estiver a atacar, não interrompe com a animação de andar/parado
	if anim_player.current_animation == anim_ataque and anim_player.is_playing():
		return
		
	# 3. Dá play na animação correta com o nome traduzido
	if not is_on_floor():
		if anim_player.has_animation(anim_pulo) and anim_player.current_animation != anim_pulo: 
			anim_player.play(anim_pulo)
	elif direction.length() > 0:
		if anim_player.has_animation(anim_andar) and anim_player.current_animation != anim_andar: 
			anim_player.play(anim_andar)
	else:
		if anim_player.has_animation(anim_parado) and anim_player.current_animation != anim_parado: 
			anim_player.play(anim_parado)

# ==========================================
# TROCA DE PERSONAGEM E ARMA (POR CÓDIGO)
# ==========================================

func _configurar_modelo_escolhido():
	var modelo_antigo = get_node_or_null("character-male-f2")
	var ossos_salvos = []
	
	# --- 1. SALVAR AS PEÇAS ATUAIS ANTES DE APAGAR O BONECO ---
	if modelo_antigo:
		var todos_os_ossos = modelo_antigo.find_children("*", "BoneAttachment3D", true, false)
		for osso in todos_os_ossos:
			var ancora = osso.bone_name
			ossos_salvos.append({"node": osso, "ancora": ancora})
			if osso.get_parent():
				osso.get_parent().remove_child(osso)

	# --- 2. O GODOT DECIDE QUAL CENA CARREGAR AQUI ---
	var caminho_novo_modelo = ""
	
	if Global.usando_set_bloodborne:
		# ATENÇÃO: Coloca aqui o caminho real da cena do teu Hunter!
		caminho_novo_modelo = "res://Assets/Personagens/blood_borne_male.tscn" 
	elif Global.personagem_jogado_atualmente == "avo_m":
		caminho_novo_modelo = "res://Assets/Personagens/personagem_m.tscn"
	else:
		caminho_novo_modelo = "res://Assets/Personagens/personagem_f.tscn"

	var modelo_novo = load(caminho_novo_modelo).instantiate()
	
	# --- 3. TROCAR O BONECO VELHO PELO NOVO ---
	if modelo_antigo:
		modelo_novo.scale = modelo_antigo.scale
		modelo_antigo.name = "modelo_a_ser_apagado"
		modelo_antigo.queue_free()
	else:
		modelo_novo.scale = Vector3(1, 1, 1)
		
	modelo_novo.name = "character-male-f2"
	add_child(modelo_novo)
	
	# Restaurar Animações
	var novo_anim_player = modelo_novo.find_child("AnimationPlayer", true)
	if novo_anim_player:
		if "anim_player" in self: self.anim_player = novo_anim_player
		
		# Define quais animações devem ficar em repetição contínua (Loop)
		for anim_name in ["idle", "walk", "Idle", "Walking"]:
			if novo_anim_player.has_animation(anim_name):
				novo_anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
				
		# Tenta dar play na animação de ficar parado inicial
		if novo_anim_player.has_animation("idle"):
			novo_anim_player.play("idle")
		elif novo_anim_player.has_animation("Idle"):
			novo_anim_player.play("Idle")
		
	# --- 4. DEVOLVER AS PEÇAS SALVAS AO ESQUELETO NOVO ---
	var novo_skeleton = modelo_novo.find_child("Skeleton3D", true)
	if novo_skeleton:
		for dado in ossos_salvos:
			var osso_node = dado["node"]
			var nome_ancora = dado["ancora"]
			
			var lixo = novo_skeleton.find_child(osso_node.name, true, false)
			if lixo:
				lixo.name = "lixo_" + osso_node.name
				lixo.free()
				
			novo_skeleton.add_child(osso_node)
			osso_node.bone_name = nome_ancora
			
			if osso_node.bone_name == "":
				if osso_node.name == "BoneAttachment3D_Cabeca": osso_node.bone_name = "head"
				elif osso_node.name == "BoneAttachment3D": osso_node.bone_name = "arm-left"

	# Atualiza o visual base
	_atualizar_arma_visivel()
	_atualizar_chapeu_visivel()
	
	# Aplica as regras do Dark Souls
	call_deferred("_forcar_visual_darksouls")
	
	# --- 5. LÓGICA FINAL DO BLOODBORNE (Esconder armas) ---
	if Global.usando_set_bloodborne:
		var osso_arma = find_child("BoneAttachment3D", true, false)
		if osso_arma:
			osso_arma.visible = false
			
		var osso_chapeu = find_child("BoneAttachment3D_Cabeca", true, false)
		if osso_chapeu:
			osso_chapeu.visible = false

# --- NOVA FUNÇÃO (Copia também isto) ---
func _forcar_visual_darksouls():
	var modelo = get_node_or_null("character-male-f2")
	if not modelo: return
	
	var is_darksouls = Global.armadura_darksouls_desbloqueada and Global.usando_set_especial
	
	# Pega ABSOLUTAMENTE TODOS os nós do personagem, não importa a profundidade
	var todos_nos = modelo.find_children("*", "", true, false)
	
	for no in todos_nos:
		var nome_min = no.name.to_lower()
		
		# 1. ESCONDE A CABEÇA NORMAL
		if "head-mesh" in nome_min or "headmesh" in nome_min:
			if "visible" in no:
				no.visible = not (is_darksouls or Global.usando_set_hollow_knight)
				
		if "body-mesh" in nome_min or "bodymesh" in nome_min:
			if "visible" in no:
				no.visible = not is_darksouls
		
		# 2. ENCONTRA A ARMADURA (Procura por qualquer pedaço do nome)
		var eh_armadura = ("darks" in nome_min) or ("torso" in nome_min) or ("leg" in nome_min) or ("boneattachment3d2" in nome_min)
		
		if eh_armadura:
			if "visible" in no:
				no.visible = is_darksouls
			
			# A MÁGICA FINAL: Se a armadura deve aparecer, obriga todos os pais dela a aparecerem também!
			# Isso impede que o Torso fique escondido porque o osso acima dele estava desligado.
			if is_darksouls:
				var pai = no.get_parent()
				# Sobe na árvore de nós ligando tudo até chegar ao topo do personagem
				while pai != null and pai != get_parent():
					if "visible" in pai:
						pai.visible = true
					pai = pai.get_parent()

func _atualizar_arma_visivel():
	# Lembra de procurar por BoneAttachment3D aqui também!
	var ponto_arma = find_child("BoneAttachment3D", true, false)
	if not ponto_arma: return 
	
	var id_arma = "Nenhuma"
	if Global.personagem_jogado_atualmente == "avo_m":
		id_arma = Global.equip_avo_m["arma"]
	else:
		id_arma = Global.equip_avo_f["arma"]
		
	for arma in ponto_arma.get_children():
		if arma.name == id_arma:
			arma.show()
		else:
			arma.hide()

func _atualizar_chapeu_visivel():
	# 1. Procura a pasta que segura os chapéus na cabeça do personagem
	var ponto_chapeu = find_child("BoneAttachment3D_Cabeca", true, false)
	if not ponto_chapeu: return 
	
	var id_chapeu = "Nenhum"
	
	# Verifica se é o Easter Egg para forçar o capacete a aparecer
	if Global.armadura_darksouls_desbloqueada and Global.usando_set_especial:
		id_chapeu = "Set Dark Souls"
	elif Global.personagem_jogado_atualmente == "avo_m":
		id_chapeu = Global.equip_avo_m.get("chapeu", "Nenhum")
	else:
		id_chapeu = Global.equip_avo_f.get("chapeu", "Nenhum")
		
	# A CORREÇÃO ESTÁ AQUI: Sincroniza a flag global para garantir que o jogo saiba 
	# que está usando o Hollow Knight mesmo ao carregar o save logo que abre o jogo
	Global.usando_set_hollow_knight = (id_chapeu == "HollowKnight Head")
		
	# Passa por todos os chapéus e só mostra o escolhido (Capacete Dark Souls ou chapéu normal)
	for chapeu in ponto_chapeu.get_children():
		if chapeu.name == id_chapeu and id_chapeu != "Nenhum" and id_chapeu != "":
			chapeu.show()
		else:
			chapeu.hide()
			
	# --- 2. LIGA/DESLIGA AS OUTRAS PEÇAS DA ARMADURA (O SEGREDO ESTÁ AQUI) ---
	var is_darksouls = Global.armadura_darksouls_desbloqueada and Global.usando_set_especial
	
	# Esconde ou mostra a cabeça careca do personagem
	var head_mesh = find_child("head-mesh", true, false)
	if not head_mesh: head_mesh = find_child("HeadMesh", true, false)
	if head_mesh:
		head_mesh.visible = not (is_darksouls or Global.usando_set_hollow_knight)
		
	# Procura os ossos do corpo onde a armadura está guardada
	var ossos_armadura = [
		find_child("BoneAttachment3D_torso", true, false),
		find_child("BoneAttachment3D_leg_left", true, false),
		find_child("BoneAttachment3D_leg_right", true, false),
		find_child("BoneAttachment3D2", true, false)
	]
	
	# Liga ou desliga tudo
	for osso in ossos_armadura:
		if osso:
			osso.visible = is_darksouls
			# Garante que as tuas malhas DarkS dentro do osso também obedeçam
			for filho in osso.get_children():
				if "visible" in filho:
					filho.visible = is_darksouls
					
# ==========================================
# EFEITOS VISUAIS E SHADERS
# ==========================================

func _configurar_shader_outline(modelo_alvo: Node):
	if not modelo_alvo: return
	
	materiais_outline.clear()
	
	# Cria uma única instância do material de outline de forma totalmente automatizada via código
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
		
		materiais_outline.append(mat_outline)
		_percorrer_e_ajustar_materiais(modelo_alvo, mat_outline)
	
	# Configura a escala inicial baseada na posição atual da câmera
	var camera = get_viewport().get_camera_3d()
	if camera:
		var parametro_zoom = camera.fov if camera.projection == Camera3D.PROJECTION_PERSPECTIVE else camera.size
		_atualizar_escala_outline(parametro_zoom)

func _atualizar_escala_outline(valor_zoom: float):
	# Mapeia o zoom para a escala do outline dependendo do tipo da câmera
	var nova_escala = 1.0
	var camera = get_viewport().get_camera_3d()
	if camera:
		if camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
			nova_escala = remap(valor_zoom, 20.0, 90.0, 1.0, 4.5)
		else:
			nova_escala = remap(valor_zoom, 5.0, 30.0, 1.0, 4.5)
			
	for mat in materiais_outline:
		if is_instance_valid(mat):
			mat.set_shader_parameter("scale", nova_escala)

func _percorrer_e_ajustar_materiais(no_atual: Node, mat_outline: ShaderMaterial = null):
	# Aplica o overlay do shader em todas as partes do personagem que são malhas visíveis
	if no_atual is MeshInstance3D and mat_outline != null:
		no_atual.material_overlay = mat_outline
			
	for filho in no_atual.get_children():
		_percorrer_e_ajustar_materiais(filho, mat_outline)

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
		
		p1_local.y -= 0.25
		p2_local.y -= 0.25
		
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
