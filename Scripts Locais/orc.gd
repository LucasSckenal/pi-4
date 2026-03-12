extends CharacterBody3D

# --- CONFIGURAÇÕES DE MOVIMENTO ---
@export var velocidade: float = 0.5
@export var jump_velocity: float = 4.5
@export var gravity: float = 20.0
@export var rotation_speed: float = 10.0

# --- CONFIGURAÇÕES DE COMBATE ---
@export var distancia_de_ataque: float = 0.7
@export var forca_do_ataque: int = 10
@export var cadencia_ataque: float = 1.5
@export var vida_maxima: int = 100

var vida_atual: int = 100
var alvo_atual: Node3D = null
var pode_atacar: bool = true
var esta_morto: bool = false
var escala_original: Vector3 # Guarda o tamanho certo dele

# --- REFERÊNCIAS ---
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $"character-orc2/AnimationPlayer" 
@onready var modelo_visual = $"character-orc2"
@onready var timer_ataque = Timer.new()

func _ready():
	vida_atual = vida_maxima
	escala_original = modelo_visual.scale # Salva o tamanho que ele tem no editor
	add_to_group("inimigos")
	
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	add_child(timer_ataque)
	timer_ataque.wait_time = cadencia_ataque
	timer_ataque.one_shot = true
	timer_ataque.timeout.connect(func(): pode_atacar = true)

func _physics_process(delta):
	if esta_morto: return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if alvo_atual == null or not is_instance_valid(alvo_atual):
		alvo_atual = procurar_novo_alvo()

	var direction = Vector3.ZERO

	if alvo_atual != null:
		nav_agent.target_position = alvo_atual.global_position
		var distancia = global_position.distance_to(alvo_atual.global_position)
		
		if distancia > distancia_de_ataque:
			if not nav_agent.is_navigation_finished():
				var proximo_passo = nav_agent.get_next_path_position()
				direction = (proximo_passo - global_position)
				direction.y = 0
				direction = direction.normalized()
				
				# PULO AUTOMÁTICO (Igual ao teu Player)
				if is_on_floor() and is_on_wall():
					velocity.y = jump_velocity
				
				if direction.length() > 0.01:
					var target_angle = atan2(direction.x, direction.z)
					rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
					velocity.x = direction.x * velocidade
					velocity.z = direction.z * velocidade
					if is_on_floor(): _tocar_animacao("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, velocidade)
			velocity.z = move_toward(velocity.z, 0, velocidade)
			tentar_atacar_alvo()
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade)
		velocity.z = move_toward(velocity.z, 0, velocidade)
		if is_on_floor(): _tocar_animacao("idle")

	if not is_on_floor() and not esta_morto:
		_tocar_animacao("jump")

	move_and_slide()

# --- FUNÇÕES DE LÓGICA ---

func _tocar_animacao(anim_name: String):
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func procurar_novo_alvo() -> Node3D:
	var construcoes = get_tree().get_nodes_in_group("Construcao")
	var alvo_proximo = null
	var menor_dist = 9999.0
	for c in construcoes:
		if "is_fantasma" in c and c.is_fantasma: continue
		var d = global_position.distance_to(c.global_position)
		if d < menor_dist:
			menor_dist = d
			alvo_proximo = c
	if alvo_proximo: return alvo_proximo
	return get_tree().get_first_node_in_group("Castelo")

func tentar_atacar_alvo():
	if pode_atacar and is_instance_valid(alvo_atual):
		if alvo_atual.has_method("receber_dano"):
			pode_atacar = false
			_tocar_animacao("attack-melee-right")
			alvo_atual.receber_dano(forca_do_ataque)
			timer_ataque.start()

func receber_dano(dano_sofrido: int):
	if esta_morto: return
	vida_atual -= dano_sofrido
	
	# CORREÇÃO DO GIGANTE: Usa a escala_original
	var tween = create_tween()
	tween.tween_property(modelo_visual, "scale", escala_original * 1.2, 0.05)
	tween.tween_property(modelo_visual, "scale", escala_original, 0.1)
	
	if vida_atual <= 0: morrer()

func morrer():
	esta_morto = true
	$CollisionShape3D.set_deferred("disabled", true)
	_tocar_animacao("sit")
	
	var tween_morte = create_tween()
	tween_morte.tween_interval(1.0) 
	tween_morte.tween_property(self, "scale", Vector3.ZERO, 1.5).set_trans(Tween.TRANS_SINE)
	tween_morte.finished.connect(queue_free)
