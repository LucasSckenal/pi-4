extends CharacterBody3D

# --- CONFIGURAÇÕES ---
@export var velocidade: float = 0.5
@export var jump_velocity: float = 4.5
@export var gravity: float = 20.0
@export var distancia_ataque: float = 0.7
@export var forca_dano: int = 5
@export var raio_visao_construcao: float = 2.0
@export var raio_visao_aliados: float = 1.0

var vida: int = 100
var esta_morto: bool = false
var alvo_atual: Node3D = null
var inimigo_focado: Node3D = null
var pode_atacar: bool = true
var escala_original: Vector3

@onready var nav_agent = $NavigationAgent3D
@onready var anim = $"character-orc2/AnimationPlayer"
@onready var modelo = $"character-orc2"

func _ready():
	add_to_group("inimigos")
	escala_original = modelo.scale
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

func _physics_process(delta):
	if esta_morto: return

	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. IA de Alvo
	# Verifica se o alvo atual foi destruído para procurar um novo
	if alvo_atual == null or not is_instance_valid(alvo_atual) or \
	   alvo_atual.is_in_group("Castelo") or (alvo_atual.get("esta_destruida") == true):
		alvo_atual = procurar_novo_alvo()

	if alvo_atual == null or not is_instance_valid(alvo_atual) or esta_morto:
		alvo_atual = procurar_novo_alvo()
		
	# 3. Movimento
	if alvo_atual:
		nav_agent.target_position = alvo_atual.global_position
		var dist = global_position.distance_to(alvo_atual.global_position)
		
		if dist > distancia_ataque:
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var dir = (next_pos - global_position).normalized()
				
				# PULO AUTOMÁTICO
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
				
				velocity.x = dir.x * velocidade
				velocity.z = dir.z * velocidade
				
				# ROTAÇÃO
				var look_dir = Vector2(velocity.z, velocity.x)
				rotation.y = lerp_angle(rotation.y, look_dir.angle(), 10 * delta)
				
				if is_on_floor(): anim.play("walk")
		else:
			# ATACAR
			velocity.x = 0
			velocity.z = 0
			atacar()

	move_and_slide()

func procurar_novo_alvo():
	var aliados = get_tree().get_nodes_in_group("aliados")
	var construcoes = get_tree().get_nodes_in_group("Construcao")
	
	var melhor_alvo = null
	var menor_dist = 1000.0 
	
	# ==========================================
	# 1. PRIORIDADE MÁXIMA: Procurar Aliados
	# ==========================================
	for aliado in aliados:
		if is_instance_valid(aliado):
			if "vida_atual" in aliado and aliado.vida_atual <= 0:
				continue 
			
			var d = global_position.distance_to(aliado.global_position)
			if d <= raio_visao_aliados and d < menor_dist:
				menor_dist = d
				melhor_alvo = aliado
			
	# Se ele achou algum aliado vivo, já escolhe ele como alvo e para de pensar!
	if melhor_alvo: 
		return melhor_alvo
		
	# ==========================================
	# 2. SEGUNDA OPÇÃO: Procurar Construções
	# ==========================================
	menor_dist = 1000.0 # Resetamos a distância para procurar de novo
	
	for c in construcoes:
		if is_instance_valid(c):
			# Pula construções que estão no estado de destruídas
			if "esta_destruida" in c and c.esta_destruida:
				continue
				
			if "vida_atual" in c and c.vida_atual <= 0:
				continue 
				
			var d = global_position.distance_to(c.global_position)
			if d <= raio_visao_construcao and d < menor_dist:
				menor_dist = d
				melhor_alvo = c
			
	if melhor_alvo: 
		return melhor_alvo
		
	# ==========================================
	# 3. ÚLTIMA OPÇÃO: Castelo
	# ==========================================
	return get_tree().get_first_node_in_group("Castelo")

func atacar():
	if pode_atacar and alvo_atual:
		pode_atacar = false
		anim.play("attack-melee-right")
		if alvo_atual.has_method("receber_dano"):
			alvo_atual.receber_dano(forca_dano)
		
		await get_tree().create_timer(1.5).timeout
		pode_atacar = true

func receber_dano(qtd):
	if esta_morto: return
	vida -= qtd
	
	# Feedback de dano (não fica gigante!)
	var tw = create_tween()
	tw.tween_property(modelo, "scale", escala_original * 1.2, 0.1)
	tw.tween_property(modelo, "scale", escala_original, 0.1)
	
	if vida <= 0: morrer()

func morrer():
	esta_morto = true
	remove_from_group("inimigos")
	$CollisionShape3D.set_deferred("disabled", true)
	anim.play("sit")
	
	var tw = create_tween()
	tw.tween_interval(1.5) # Espera sentado
	tw.tween_property(self, "scale", Vector3.ZERO, 1.0)
	tw.finished.connect(queue_free)
