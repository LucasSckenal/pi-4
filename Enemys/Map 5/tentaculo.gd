extends InimigoBase
class_name Tentaculo

# ============================================================================
# TENTÁCULO CÓSMICO — Invocação do Cosmic Kraken
# ============================================================================
# Surge fixo perto de uma construção (build slot ocupado) ou perto da base
# se não houver mais construções. NÃO se move. Ataca a construção mais
# próxima dentro do alcance. Quando morre, dá dano fixo no Kraken pai.
# ============================================================================

@export_category("Tentáculo")
## Quanto o tentáculo emerge do chão na animação de surgimento (em metros)
@export var altura_emergencia: float = 2.5
## Duração da animação de emergência (em segundos)
@export var duracao_emergencia: float = 1.2
## Tempo (s) sem alvo até o tentáculo se auto-destruir
## (evita travar o fim da wave caso todas as construções já tenham caído)
@export var timeout_sem_alvo: float = 12.0

# Referência ao boss que invocou este tentáculo
var kraken_pai: Node = null

# Quanto tempo está sem alvo
var _tempo_sem_alvo: float = 0.0

# ============================================================================
# READY
# ============================================================================
func _ready() -> void:
	# Configurações forçadas (sobrescreve o que vier do .tscn)
	nome_inimigo         = "Tentáculo Cósmico"
	prioriza_construcoes = true
	eh_kamikaze          = false
	eh_necromancer       = false
	velocidade           = 0.0  # NUNCA se move

	super._ready()

	# Animação dramática: tentáculo emerge do chão
	_animar_emergencia()

func _animar_emergencia() -> void:
	var alvo_y: float = global_position.y
	global_position.y = alvo_y - altura_emergencia
	var tw = create_tween()
	tw.tween_property(self, "global_position:y", alvo_y, duracao_emergencia)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ============================================================================
# FÍSICA — Sobrescreve completamente. Tentáculo é ESTÁTICO:
# • Sem navegação / sem path-finding (não precisa do NavigationAgent)
# • Sem pulos automáticos / sem rotação por velocidade
# • Aplica gravidade só pra grudar no chão
# • Vira pra encarar o alvo (rotação horizontal)
# • Ataca quando alvo está dentro de distancia_ataque
# • Auto-destrói se ficar sem alvo por timeout_sem_alvo segundos
# ============================================================================
func _physics_process(delta: float) -> void:
	if esta_morto:
		return

	# Gravidade — só pra encostar no chão e travar
	if not is_on_floor():
		velocity.y -= gravity * delta
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

	# Renova o alvo se inválido / destruído
	var alvo_invalido: bool = (alvo_atual == null) or (not is_instance_valid(alvo_atual)) \
		or (alvo_atual.get("esta_destruida") == true) \
		or ("vida_atual" in alvo_atual and alvo_atual.vida_atual <= 0)

	if alvo_invalido:
		alvo_atual = procurar_novo_alvo()
		if alvo_atual == null:
			_tempo_sem_alvo += delta
			if _tempo_sem_alvo >= timeout_sem_alvo:
				morrer()
			return
		_tempo_sem_alvo = 0.0

	# Vira pra encarar a construção (rotação horizontal apenas)
	var alvo_pos: Vector3 = alvo_atual.global_position
	alvo_pos.y = global_position.y
	if not global_position.is_equal_approx(alvo_pos):
		look_at(alvo_pos, Vector3.UP, true)

	# Ataca se em alcance
	var dist_xz: float = Vector2(
		global_position.x - alvo_atual.global_position.x,
		global_position.z - alvo_atual.global_position.z
	).length()
	if dist_xz <= distancia_ataque:
		atacar()

# ============================================================================
# ALVO — Apenas construções (ignora a base e outros tentáculos)
# ============================================================================
func procurar_novo_alvo():
	var construcoes = get_tree().get_nodes_in_group("Construcao")
	var melhor_alvo = null
	var menor_dist: float = raio_visao_construcao + 0.001

	for c in construcoes:
		if not is_instance_valid(c):
			continue
		# Ignora a própria base — tentáculo só ataca construções
		if c.is_in_group("Castelo") or c.is_in_group("Base"):
			continue
		if "esta_destruida" in c and c.esta_destruida:
			continue
		if "vida_atual" in c and c.vida_atual <= 0:
			continue
		var d: float = global_position.distance_to(c.global_position)
		if d < menor_dist:
			menor_dist = d
			melhor_alvo = c

	return melhor_alvo

# ============================================================================
# MORTE — Notifica o Kraken pai antes de seguir o fluxo padrão
# ============================================================================
func morrer() -> void:
	if esta_morto:
		return
	if is_instance_valid(kraken_pai) and kraken_pai.has_method("notificar_tentaculo_morto"):
		kraken_pai.notificar_tentaculo_morto()
	super.morrer()
