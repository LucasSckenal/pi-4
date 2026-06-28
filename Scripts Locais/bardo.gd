extends CharacterBody3D
# ==========================================
# BARDO — aliado de SUPORTE (caminho "Taverna" do quartel).
# Não ataca. ACOMPANHA o pirata (anda atrás dele) e emite uma AURA que aumenta o
# dano E a cadência de ataque de torres, aliados e do jogador no raio (raio_buff).
# A aura é "puxada": cada entidade consulta GameManager.fator_buff_bardo() na hora de
# atacar, então NÃO acumula (vários bardos = mesmo bônus).
# ==========================================

@export var vida_maxima: int = 160
@export var raio_buff: float = 2.5     # raio médio; lido por GameManager.fator_buff_bardo()
@export var velocidade: float = 2.8    # um tico mais rápido que o pirata, para acompanhá-lo
@export var distancia_seguir: float = 1.4  # mantém-se a esta distância do pirata

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hitbox: Area3D = $Hitbox
@onready var anel_aura: MeshInstance3D = get_node_or_null("AnelAura")

var animation_player: AnimationPlayer
var anim_idle: String = ""
var anim_walk: String = ""
var vida_atual: int
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _t: float = 0.0

signal morreu(aliado: Node)

func _ready():
	add_to_group("aliados")
	add_to_group("bardos")  # GameManager.fator_buff_bardo() procura por este grupo
	vida_atual = vida_maxima
	collision_layer = 0

	animation_player = find_child("AnimationPlayer", true, false)
	if animation_player:
		anim_idle = _achar_anim("idle")
		anim_walk = _achar_anim("walk")
		if anim_idle != "":
			animation_player.play(anim_idle)

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	navigation_agent.target_desired_distance = distancia_seguir
	navigation_agent.path_desired_distance = 0.4

	# Dimensiona o anel visual da aura conforme o raio
	if anel_aura and anel_aura.mesh is TorusMesh:
		var t := anel_aura.mesh as TorusMesh
		t.outer_radius = raio_buff
		t.inner_radius = raio_buff - 0.15

func _achar_anim(sub: String) -> String:
	if animation_player == null:
		return ""
	for a in animation_player.get_animation_list():
		if sub.to_lower() in a.to_lower():
			return a
	return ""

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravidade * delta

	var alvo := _pirata_mais_proximo()
	if alvo and is_instance_valid(alvo):
		var distancia := global_position.distance_to(alvo.global_position)
		if distancia > distancia_seguir:
			# Anda atrás do pirata
			navigation_agent.target_position = alvo.global_position
			var proxima := navigation_agent.get_next_path_position()
			var direcao := global_position.direction_to(proxima)
			velocity.x = direcao.x * velocidade
			velocity.z = direcao.z * velocidade
			if anim_walk != "":
				animation_player.play(anim_walk)
			_encarar(Vector3(proxima.x, global_position.y, proxima.z))
		else:
			# Já está perto: para e fica tocando, virado para o pirata
			velocity.x = 0
			velocity.z = 0
			if anim_idle != "":
				animation_player.play(anim_idle)
			_encarar(Vector3(alvo.global_position.x, global_position.y, alvo.global_position.z))
	else:
		# Sem pirata vivo: fica parado tocando
		velocity.x = 0
		velocity.z = 0
		if anim_idle != "":
			animation_player.play(anim_idle)

	move_and_slide()

	# Pulsa suavemente o anel da aura para indicar que está ativo
	if anel_aura:
		_t += delta
		var p := 1.0 + 0.05 * sin(_t * 3.0)
		anel_aura.scale = Vector3(p, 1.0, p)

# O modelo Quaternius encara +Z, por isso o flip de 180°.
func _encarar(pos: Vector3) -> void:
	if global_position.distance_to(pos) <= 0.05:
		return
	look_at(pos, Vector3.UP)
	rotate_y(PI)

func _pirata_mais_proximo() -> Node3D:
	var melhor: Node3D = null
	var menor = INF
	for pirata in get_tree().get_nodes_in_group("piratas"):
		if not is_instance_valid(pirata):
			continue
		var d = global_position.distance_squared_to(pirata.global_position)
		if d < menor:
			menor = d
			melhor = pirata
	return melhor

func _on_hitbox_entered(body: Node):
	if body.has_method("get_dano"):
		receber_dano(body.get_dano())
	elif body.is_in_group("inimigos") and "dano" in body:
		receber_dano(body.dano)

func receber_dano(quantidade: int):
	vida_atual -= quantidade
	if vida_atual <= 0:
		morrer()

func morrer():
	morreu.emit(self)
	queue_free()

func aplicar_escala_mapa(fator: float) -> void:
	if fator <= 0.0 or is_equal_approx(fator, 1.0):
		return
	scale = Vector3.ONE * fator
	# O raio de buff e a velocidade acompanham a escala do mapa.
	raio_buff *= fator
	velocidade *= fator
