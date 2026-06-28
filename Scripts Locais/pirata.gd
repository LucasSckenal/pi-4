extends CharacterBody3D
# ==========================================
# PIRATA — aliado TANQUE corpo a corpo (caminho "Taverna" do quartel).
# Muita vida, ataca de perto com dano de torre padrão. Substitui os soldados
# junto com o Bardo quando o quartel é melhorado para a Taverna dos Piratas.
# ==========================================

@export var velocidade: float = 2.6
@export var alcance_ataque: float = 1.9
@export var tempo_entre_ataques: float = 1.4
@export var dano: int = 30                 # dano de uma torre padrão
@export var vida_maxima: int = 320         # tanque: aguenta muito
@export var alcance_deteccao: float = 6.0  # só engaja inimigos PERTO (não corre o mapa todo)

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var timer_ataque: Timer = $Timer
@onready var area_atk: Area3D = $AreaAtk
@onready var hitbox: Area3D = $Hitbox

var animation_player: AnimationPlayer
var anim_idle: String = ""
var anim_walk: String = ""
var anim_atk: String = ""

var inimigos_no_alcance: Array[Node3D] = []
var alvo_atual: Node3D = null
var pode_atacar: bool = true
var esta_atacando: bool = false
var vida_atual: int
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")

signal morreu(aliado: Node)

func _ready():
	add_to_group("aliados")
	add_to_group("piratas")  # o bardo segue este grupo
	vida_atual = vida_maxima
	# Não bloqueia fisicamente jogador/inimigos (igual ao soldado).
	collision_layer = 0

	animation_player = find_child("AnimationPlayer", true, false)
	if animation_player:
		anim_idle = _achar_anim("idle")
		anim_walk = _achar_anim("walk")
		anim_atk = _achar_anim("sword")
		if anim_atk == "":
			anim_atk = _achar_anim("punch")
		if anim_idle != "":
			animation_player.play(anim_idle)

	# Ajusta o raio da área de detecção
	var cs = area_atk.get_node_or_null("CollisionShape3D")
	if cs and cs.shape is SphereShape3D:
		var s = cs.shape.duplicate()
		s.radius = alcance_deteccao
		cs.shape = s

	area_atk.body_entered.connect(_on_inimigo_entrou)
	area_atk.body_exited.connect(_on_inimigo_saiu)
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	navigation_agent.target_desired_distance = 1.0
	navigation_agent.path_desired_distance = 0.5

	timer_ataque.wait_time = tempo_entre_ataques
	timer_ataque.one_shot = true
	timer_ataque.timeout.connect(_on_timer_timeout)

func _achar_anim(sub: String) -> String:
	if animation_player == null:
		return ""
	for a in animation_player.get_animation_list():
		if sub.to_lower() in a.to_lower():
			return a
	return ""

func _process(_delta):
	inimigos_no_alcance = inimigos_no_alcance.filter(func(i): return is_instance_valid(i))
	alvo_atual = _mais_proximo()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravidade * delta

	if alvo_atual and is_instance_valid(alvo_atual):
		var distancia = global_position.distance_to(alvo_atual.global_position)
		if distancia <= alcance_ataque:
			velocity.x = 0
			velocity.z = 0
			_encarar(Vector3(alvo_atual.global_position.x, global_position.y, alvo_atual.global_position.z))
			if pode_atacar and not esta_atacando:
				_atacar()
		elif not esta_atacando:
			navigation_agent.target_position = alvo_atual.global_position
			var proxima = navigation_agent.get_next_path_position()
			var direcao = global_position.direction_to(proxima)
			velocity.x = direcao.x * velocidade
			velocity.z = direcao.z * velocidade
			if anim_walk != "":
				animation_player.play(anim_walk)
			_encarar(Vector3(proxima.x, global_position.y, proxima.z))
	else:
		velocity.x = 0
		velocity.z = 0
		if not esta_atacando and anim_idle != "":
			animation_player.play(anim_idle)

	move_and_slide()

func _atacar():
	esta_atacando = true
	pode_atacar = false
	if anim_atk != "":
		animation_player.play(anim_atk)
	# Pequeno atraso para o golpe casar com a animação
	await get_tree().create_timer(0.25).timeout
	if not is_instance_valid(self):
		return
	if alvo_atual and is_instance_valid(alvo_atual) and global_position.distance_to(alvo_atual.global_position) <= alcance_ataque + 0.7:
		if alvo_atual.has_method("receber_dano"):
			var fator := GameManager.fator_buff_bardo(global_position)
			var dano_total := int(round((dano + GameManager.bonus_dano_soldado) * fator))
			var foi_critico := false
			if GameManager.chance_critico > 0.0 and randf() < GameManager.chance_critico:
				dano_total *= 2
				foi_critico = true
			alvo_atual.receber_dano(dano_total, "torre", foi_critico)
			if GameManager.dano_veneno > 0 and alvo_atual.has_method("iniciar_veneno"):
				alvo_atual.iniciar_veneno(GameManager.dano_veneno)
	# Cadência acelerada se houver bardo no raio
	timer_ataque.wait_time = max(0.2, tempo_entre_ataques / GameManager.fator_buff_bardo(global_position))
	timer_ataque.start()

func _on_timer_timeout():
	pode_atacar = true
	esta_atacando = false

# Vira o pirata para encarar o ponto (o modelo Quaternius encara +Z, por isso o flip de 180°).
func _encarar(pos: Vector3) -> void:
	if global_position.distance_to(pos) <= 0.05:
		return
	look_at(pos, Vector3.UP)
	rotate_y(PI)

func _mais_proximo() -> Node3D:
	var melhor: Node3D = null
	var menor = INF
	for inimigo in inimigos_no_alcance:
		if not is_instance_valid(inimigo):
			continue
		var d = global_position.distance_squared_to(inimigo.global_position)
		if d < menor:
			menor = d
			melhor = inimigo
	return melhor

func _on_inimigo_entrou(body: Node):
	if body.is_in_group("inimigos") and body not in inimigos_no_alcance:
		inimigos_no_alcance.append(body)

func _on_inimigo_saiu(body: Node):
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

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

# Mapas maiores escalam as construções; o aliado nasce na raiz da cena com escala 1.
func aplicar_escala_mapa(fator: float) -> void:
	if fator <= 0.0 or is_equal_approx(fator, 1.0):
		return
	scale = Vector3.ONE * fator
	velocidade *= fator
	alcance_ataque *= fator
