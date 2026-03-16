extends CharacterBody3D

# ==========================================
# EXPORTS (configuráveis no inspetor)
# ==========================================
@export var velocidade: float = 3.0
@export var alcance_ataque: float = 10.0
@export var tempo_entre_ataques: float = 1.5
@export var dano: int = 20
@export var vida_maxima: int = 50
@export var cena_flecha: PackedScene
@export var alcance_deteccao: float = 15.0

# ==========================================
# REFERÊNCIAS DOS NÓS
# ==========================================
@onready var animation_player: AnimationPlayer = $"character-soldier2/AnimationPlayer"
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer_ataque: Timer = $Timer
@onready var area_atk: Area3D = $AreaAtk
@onready var hitbox: Area3D = $Hitbox
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ponto_tiro: Node3D = $PontoDeTiro

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var inimigos_no_alcance: Array[Node3D] = []  # Inicializado como array vazio
var alvo_atual: Node3D = null
var pode_atacar: bool = true
var esta_atacando: bool = false
var vida_atual: int
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")

signal morreu(aliado: Node)

func _ready():
	add_to_group("aliados")
	vida_atual = vida_maxima
	
	# --- ADICIONE ESTE BLOCO ---
	if area_atk.has_node("CollisionShape3D"):
		var shape_node = area_atk.get_node("CollisionShape3D")
		if shape_node.shape is SphereShape3D:
			var novo_shape = shape_node.shape.duplicate() # Evita alterar todas as instâncias
			novo_shape.radius = alcance_deteccao
			shape_node.shape = novo_shape
	# ---------------------------
	
	# Conecta sinais
	area_atk.body_entered.connect(_on_inimigo_entrou)
	area_atk.body_exited.connect(_on_inimigo_saiu)
	hitbox.body_entered.connect(_on_hitbox_entered)
	
	# Configura o NavigationAgent
	navigation_agent.target_desired_distance = 1.0
	navigation_agent.path_desired_distance = 0.5
	
	# Inicia com animação idle (verifica se o AnimationPlayer existe)
	if animation_player:
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
		else:
			print("Aviso: animação 'idle' não encontrada em ", name)
	else:
		print("Erro: AnimationPlayer não encontrado em ", name)
	
	# Timer de ataque
	timer_ataque.wait_time = tempo_entre_ataques
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)

func _process(delta):
	# A _process agora serve APENAS para atualizar os alvos a cada frame da tela.
	# Atualiza lista de inimigos válidos (remove os que morreram)
	inimigos_no_alcance = inimigos_no_alcance.filter(func(inimigo): return is_instance_valid(inimigo))
	
	# Escolhe o alvo mais próximo
	alvo_atual = _encontrar_alvo_mais_proximo()

func _physics_process(delta):
	# 1. Aplica a gravidade se o soldado estiver no ar
	if not is_on_floor():
		velocity.y -= gravidade * delta
		
	# 2. Lógica de perseguir e atacar o inimigo
	if alvo_atual and is_instance_valid(alvo_atual):
		var distancia = global_position.distance_to(alvo_atual.global_position)
		
		if distancia <= alcance_ataque:
			# CHEGOU PERTO: Para de andar e ataca
			velocity.x = 0
			velocity.z = 0
			
			# Olha para o inimigo
			look_at(Vector3(alvo_atual.global_position.x, global_position.y, alvo_atual.global_position.z), Vector3.UP)
			
			if pode_atacar and not esta_atacando:
				esta_atacando = true
				pode_atacar = false
				_atirar_flecha()
				
		else:
			# ESTÁ LONGE: Corre até o alvo
			if not esta_atacando: 
				navigation_agent.target_position = alvo_atual.global_position
				var proxima_posicao = navigation_agent.get_next_path_position()
				var direcao = global_position.direction_to(proxima_posicao)
				
				velocity.x = direcao.x * velocidade
				velocity.z = direcao.z * velocidade
				
				if animation_player.has_animation("run"):
					animation_player.play("run")
				
				# Olha para o caminho onde está indo
				look_at(Vector3(proxima_posicao.x, global_position.y, proxima_posicao.z), Vector3.UP)
	else:
		# SE NÃO TEM ALVO: Fica parado e zera a velocidade horizontal
		velocity.x = 0
		velocity.z = 0
		if animation_player and animation_player.has_animation("idle") and not esta_atacando:
			animation_player.play("idle")
			
	# 3. Mágica do CharacterBody3D que aplica a velocidade na física do jogo
	move_and_slide()
func _mover_em_direcao_ao_alvo(delta):
	if not alvo_atual:
		return
	
	# Define o alvo da navegação
	navigation_agent.target_position = alvo_atual.global_position
	
	# Move o personagem
	if not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var direcao = (next_pos - global_position).normalized()
		direcao.y = 0
		global_position += direcao * velocidade * delta
		
		# Rotaciona suavemente para a direção do movimento
		if direcao.length() > 0.1:
			var target_rotation = atan2(-direcao.x, -direcao.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)
		
		# Verifica se chegou perto o suficiente para atacar
		var dist = global_position.distance_to(alvo_atual.global_position)
		if dist <= alcance_ataque:
			_iniciar_ataque()

func _apontar_para_alvo():
	if not alvo_atual or esta_atacando:
		return
	
	# Aponta o corpo para o alvo
	var dir_para_alvo = (alvo_atual.global_position - global_position).normalized()
	var target_rotation = atan2(-dir_para_alvo.x, -dir_para_alvo.z)
	rotation.y = target_rotation

func _iniciar_ataque():
	if not pode_atacar or esta_atacando:
		return
	
	esta_atacando = true
	pode_atacar = false
	
	# Toca animação de apontar (holding-left)
	if animation_player and animation_player.has_animation("holding-left"):
		animation_player.play("holding-left")
		# Aguarda um tempo para a animação de atirar (ajuste conforme sua animação)
		await get_tree().create_timer(0.3).timeout
		_atirar_flecha()
	else:
		_atirar_flecha()

func _atirar_flecha():
	if not alvo_atual or not is_instance_valid(alvo_atual):
		esta_atacando = false
		pode_atacar = true
		return
	
	# Toca animação de disparo
	if animation_player and animation_player.has_animation("holding-left-shoot"):
		animation_player.play("holding-left-shoot")
	
	# Instancia a flecha
	if cena_flecha and ponto_tiro:
		var flecha = cena_flecha.instantiate()
		get_tree().root.add_child(flecha)
		flecha.global_position = ponto_tiro.global_position
		flecha.dano = dano
		flecha.alvo = alvo_atual
	
	# Inicia o timer de recarga
	timer_ataque.start()

func _on_timer_ataque_timeout():
	# Fim da recarga
	pode_atacar = true
	esta_atacando = false
	
	# Se ainda houver alvo, volta a apontar
	if alvo_atual and is_instance_valid(alvo_atual):
		if animation_player and animation_player.has_animation("holding-left"):
			animation_player.play("holding-left")
	else:
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")

func _encontrar_alvo_mais_proximo() -> Node3D:
	var mais_proximo: Node3D = null
	var menor_dist = INF
	
	for inimigo in inimigos_no_alcance:
		if not is_instance_valid(inimigo):
			continue
		var dist = global_position.distance_squared_to(inimigo.global_position)
		if dist < menor_dist:
			menor_dist = dist
			mais_proximo = inimigo
	
	return mais_proximo

# ==========================================
# SINAIS DA ÁREA DE DETECÇÃO
# ==========================================
func _on_inimigo_entrou(body: Node):
	if body.is_in_group("inimigos") and body not in inimigos_no_alcance:
		inimigos_no_alcance.append(body)

func _on_inimigo_saiu(body: Node):
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

# ==========================================
# SISTEMA DE VIDA E DANO
# ==========================================
func _on_hitbox_entered(body: Node):
	# Se o corpo que entrou na hitbox é um inimigo e causa dano
	if body.has_method("get_dano"):
		receber_dano(body.get_dano())
	elif body.is_in_group("inimigos") and body.has_method("receber_dano") == false:
		# Se o inimigo tem uma variável dano exposta
		if "dano" in body:
			receber_dano(body.dano)

func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print("%s recebeu %d de dano. Vida: %d/%d" % [name, quantidade, vida_atual, vida_maxima])
	
	if vida_atual <= 0:
		morrer()

func morrer():
	print("%s morreu." % name)
	morreu.emit(self)
	queue_free()
