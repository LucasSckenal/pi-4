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

# Guarda Real (upgrade do quartel): quando true, o soldado luta de espada (corpo a corpo) em vez de atirar flechas.
# Definido pelo quartel ANTES do add_child (portanto antes do _ready).
var modo_espada: bool = false

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
	# Aplica balanceamento centralizado (CSV) antes de inicializar a vida
	_aplicar_balanceamento()
	# Guarda Real (upgrade do quartel): converte o soldado para combate corpo a corpo (espada)
	if modo_espada:
		_configurar_modo_espada()
	vida_atual = vida_maxima

	# Soldado não bloqueia fisicamente o jogador nem os inimigos.
	# collision_layer = 0  → nenhum outro corpo "bate" nele
	# collision_mask inalterada → soldado ainda detecta chão/paredes para mover_and_slide
	collision_layer = 0
	
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
			if Global.DEBUG_MODE:
				print("Aviso: animação 'idle' não encontrada em ", name)
	else:
		if Global.DEBUG_MODE:
			print("Erro: AnimationPlayer não encontrado em ", name)
	
	# Timer de ataque
	timer_ataque.wait_time = tempo_entre_ataques
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)

func _process(_delta):
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
			
			# Olha para o inimigo (de frente)
			var pos_alvo = Vector3(alvo_atual.global_position.x, global_position.y, alvo_atual.global_position.z)
			_encarar(pos_alvo)
			
			# CHAMA A FUNÇÃO CERTA QUE TOCA A ANIMAÇÃO DE MIRAR E ATIRAR!
			if pode_atacar and not esta_atacando:
				_iniciar_ataque() 
				
		else:
			# ESTÁ LONGE: Corre até o alvo
			if not esta_atacando: 
				navigation_agent.target_position = alvo_atual.global_position
				var proxima_posicao = navigation_agent.get_next_path_position()
				var direcao = global_position.direction_to(proxima_posicao)
				
				velocity.x = direcao.x * velocidade
				velocity.z = direcao.z * velocidade
				
				# TOCA A ANIMAÇÃO DE ANDAR AQUI
				if animation_player and animation_player.has_animation("walk"):
					animation_player.play("walk")
				elif animation_player and animation_player.has_animation("run"):
					animation_player.play("run") # Fallback caso você use "run"
				
				# Olha para o caminho onde está indo (de frente)
				var pos_olhar = Vector3(proxima_posicao.x, global_position.y, proxima_posicao.z)
				_encarar(pos_olhar)
	else:
		# SE NÃO TEM ALVO: Fica parado e descansa
		velocity.x = 0
		velocity.z = 0
		if animation_player and animation_player.has_animation("idle") and not esta_atacando:
			animation_player.play("idle")
			
	# 3. Mágica do CharacterBody3D que aplica a velocidade na física do jogo
	move_and_slide()
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
			
			# Olha para o inimigo (de frente)
			_encarar(Vector3(alvo_atual.global_position.x, global_position.y, alvo_atual.global_position.z))
			
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
				
				# Olha para o caminho onde está indo (de frente)
				_encarar(Vector3(proxima_posicao.x, global_position.y, proxima_posicao.z))
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

# Vira o soldado para ENCARAR o ponto de frente.
# O look_at do Godot aponta o -Z ao alvo, mas o modelo encara +Z — por isso o flip de 180°.
func _encarar(pos: Vector3) -> void:
	if global_position.distance_to(pos) <= 0.05:
		return
	look_at(pos, Vector3.UP)
	rotate_y(PI)

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

	# Guarda Real (upgrade do quartel): golpe corpo a corpo em vez de flecha
	if modo_espada:
		_golpe_espada()
		_iniciar_recarga()
		return

	# Toca animação de disparo
	if animation_player and animation_player.has_animation("holding-left-shoot"):
		animation_player.play("holding-left-shoot")

	# Instancia a flecha
	if cena_flecha and ponto_tiro:
		var flecha = cena_flecha.instantiate()
		get_tree().root.add_child(flecha)
		flecha.global_position = ponto_tiro.global_position
		flecha.dano = int(round((dano + GameManager.bonus_dano_soldado) * GameManager.fator_buff_bardo(global_position)))  # SOLDADO_FORTE + buff bardo
		flecha.alvo = alvo_atual

	# Inicia o timer de recarga (cadência acelerada se houver bardo no raio)
	_iniciar_recarga()

# Inicia a recarga aplicando o buff de cadência do bardo (se houver).
func _iniciar_recarga() -> void:
	timer_ataque.wait_time = max(0.2, tempo_entre_ataques / GameManager.fator_buff_bardo(global_position))
	timer_ataque.start()

# Guarda Real (upgrade do quartel): aplica dano direto no alvo (corpo a corpo), respeitando as cartas
func _golpe_espada() -> void:
	if not alvo_atual or not is_instance_valid(alvo_atual):
		return
	# Animação de golpe (usa o que houver disponível no modelo)
	if animation_player:
		for nome_anim in ["attack-melee-left", "attack-melee-right", "interact-left", "holding-left-shoot"]:
			if animation_player.has_animation(nome_anim):
				animation_player.play(nome_anim)
				break
	if not alvo_atual.has_method("receber_dano"):
		return
	var dano_total: int = int(round((dano + GameManager.bonus_dano_soldado) * GameManager.fator_buff_bardo(global_position)))  # SOLDADO_FORTE + buff bardo
	# CRITICO: chance de dobrar o dano
	var foi_critico := false
	if GameManager.chance_critico > 0.0 and randf() < GameManager.chance_critico:
		dano_total *= 2
		foi_critico = true
	alvo_atual.receber_dano(dano_total, "torre", foi_critico)
	# VENENO: aplica dano ao longo do tempo, igual às flechas
	if GameManager.dano_veneno > 0 and alvo_atual.has_method("iniciar_veneno"):
		alvo_atual.iniciar_veneno(GameManager.dano_veneno)

# Guarda Real (upgrade do quartel): transforma o arqueiro num soldado de espada (tanque, corpo a corpo)
func _configurar_modo_espada() -> void:
	# Combate colado: só ataca bem perto do inimigo
	alcance_ataque = 1.8
	# Range curto: só engaja inimigos PERTO (não sai correndo atrás como o arqueiro).
	# Isso é aplicado ao raio da AreaAtk logo depois, no _ready.
	alcance_deteccao = 5.0
	# Tanque de frente: bem mais vida, mais dano, um pouco mais rápido para alcançar o alvo
	vida_maxima = int(round(vida_maxima * 2.6))
	dano = int(round(dano * 1.5))
	velocidade *= 1.15
	_trocar_arco_por_espada()

# --- Ajuste fino da espada na mão (mexa aqui se ficar torta) ---
const ESPADA_ESCALA := 0.45
const ESPADA_POS := Vector3(0.231, 0.026, 0.057)          # posição na palma (mesma referência do arco)
const ESPADA_ROT_GRAUS := Vector3(-90.0, 0.0, 0.0)        # gira a lâmina para frente do soldado

# Troca o visual: esconde o arco/flecha das mãos e encaixa uma espada
func _trocar_arco_por_espada() -> void:
	var base := "character-soldier2/character-soldier/Skeleton3D"
	var mao_dir := get_node_or_null(base + "/MaoDireita")
	var arco_mesh := get_node_or_null(base + "/MaoDireita/bow_A_withString2/bow_A_withString")
	var flecha_mao := get_node_or_null(base + "/MaoEsquerda/arrow_A2")
	# Esconde só a MALHA do arco e a flecha (mantém o nó-pai, que tem a transform da mão)
	if arco_mesh:
		arco_mesh.visible = false
	if flecha_mao:
		flecha_mao.visible = false
	if mao_dir == null or not ResourceLoader.exists("res://Modelos_3D/Arena/weapon-sword.glb"):
		return
	var cena_espada: PackedScene = load("res://Modelos_3D/Arena/weapon-sword.glb")
	if cena_espada == null:
		return
	var espada := cena_espada.instantiate()
	# Encaixa direto na mão (osso) com transform própria — controle total da orientação.
	mao_dir.add_child(espada)
	if espada is Node3D:
		var t := Transform3D.IDENTITY
		t.basis = Basis.from_euler(Vector3(
			deg_to_rad(ESPADA_ROT_GRAUS.x),
			deg_to_rad(ESPADA_ROT_GRAUS.y),
			deg_to_rad(ESPADA_ROT_GRAUS.z)
		)).scaled(Vector3.ONE * ESPADA_ESCALA)
		t.origin = ESPADA_POS
		espada.transform = t

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
	if Global.DEBUG_MODE:
		print("%s recebeu %d de dano. Vida: %d/%d" % [name, quantidade, vida_atual, vida_maxima])
	
	if vida_atual <= 0:
		morrer()

func morrer():
	if Global.DEBUG_MODE:
		print("%s morreu." % name)
	morreu.emit(self)
	queue_free()

# ==========================================
# BALANCEAMENTO (CSV)
# ==========================================
func _aplicar_balanceamento() -> void:
	velocidade           = Balanceamento.get_float("soldado_velocidade", velocidade)
	alcance_ataque       = Balanceamento.get_float("soldado_alcance_ataque", alcance_ataque)
	tempo_entre_ataques  = Balanceamento.get_float("soldado_tempo_entre_ataques", tempo_entre_ataques)
	dano                 = Balanceamento.get_int("soldado_dano", dano)
	vida_maxima          = Balanceamento.get_int("soldado_vida", vida_maxima)
	alcance_deteccao     = Balanceamento.get_float("soldado_alcance_deteccao", alcance_deteccao)

func recarregar_balanceamento() -> void:
	_aplicar_balanceamento()
	if timer_ataque:
		timer_ataque.wait_time = tempo_entre_ataques

# Escala o soldado conforme o tamanho do mapa (mapas maiores => soldados maiores).
# Deve ser chamado DEPOIS do _ready (a AreaAtk de detecção já existe e escala junto com o nó).
func aplicar_escala_mapa(fator: float) -> void:
	if fator <= 0.0 or is_equal_approx(fator, 1.0):
		return
	scale = Vector3.ONE * fator
	# A AreaAtk (detecção) é filha do nó, então o raio já cresce com a escala.
	# Mas velocidade e alcance de ataque são em unidades de mundo no código — precisam escalar.
	velocidade *= fator
	alcance_ataque *= fator
