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
## Tempo (s) com alvo mas fora de alcance antes de se auto-destruir
## (evita travar se o spawn ficou longe demais da construção)
@export var timeout_fora_alcance: float = 20.0

# Referência ao boss que invocou este tentáculo
var kraken_pai: Node = null

# Contador de tempo sem alvo válido
var _tempo_sem_alvo: float = 0.0
# Contador de tempo com alvo mas fora do alcance de ataque
var _tempo_fora_alcance: float = 0.0
# AnimationPlayer encontrado no modelo (pode ser null se o GLB não tiver animações)
var _anim_player: AnimationPlayer = null
# Bloqueio de ataque durante a animação de surgimento (modelo ainda invisível)
var _emergindo: bool = true

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

	# Busca o AnimationPlayer no sub-tree do modelo (GLB pode exportar um)
	_anim_player = _buscar_anim_player(get_node_or_null("ModeloAnchor"))

	# Animação dramática: tentáculo emerge do chão
	_animar_emergencia()

# Percorre recursivamente a sub-árvore em busca do primeiro AnimationPlayer.
func _buscar_anim_player(raiz: Node) -> AnimationPlayer:
	if raiz == null:
		return null
	if raiz is AnimationPlayer:
		return raiz
	for filho in raiz.get_children():
		var encontrado: AnimationPlayer = _buscar_anim_player(filho)
		if encontrado:
			return encontrado
	return null

func _animar_emergencia() -> void:
	var alvo_y: float = global_position.y
	global_position.y = alvo_y - altura_emergencia

	# O modelo começa invisível (escala zero) e expande junto com a subida —
	# cria um efeito de brotamento do chão mais dramático sem tocar no
	# collision shape do CharacterBody3D (usamos o ModeloAnchor como pivot).
	var modelo: Node3D = get_node_or_null("ModeloAnchor")
	if modelo:
		modelo.scale = Vector3.ZERO

	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "global_position:y", alvo_y, duracao_emergencia)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if modelo:
		tw.tween_property(modelo, "scale", Vector3.ONE, duracao_emergencia * 0.75)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func(): _emergindo = false)

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
			_tocar_animacao("idle")
			return
		_tempo_sem_alvo = 0.0
		_tempo_fora_alcance = 0.0

	# Vira pra encarar a construção (rotação horizontal apenas)
	var alvo_pos: Vector3 = alvo_atual.global_position
	alvo_pos.y = global_position.y
	if not global_position.is_equal_approx(alvo_pos):
		look_at(alvo_pos, Vector3.UP, true)

	# Não ataca enquanto ainda está emergindo (modelo invisível)
	if _emergindo:
		return

	# Ataca se em alcance; acumula timeout se ficar preso fora do alcance
	# (timeout desativado quando alvo é a base — é o último recurso)
	var alvo_e_base: bool = alvo_atual.is_in_group("Castelo") or alvo_atual.is_in_group("Base")
	var dist_xz: float = Vector2(
		global_position.x - alvo_atual.global_position.x,
		global_position.z - alvo_atual.global_position.z
	).length()
	if dist_xz <= distancia_ataque:
		_tempo_fora_alcance = 0.0
		_tocar_animacao("attack")
		atacar()
	else:
		if not alvo_e_base:
			_tempo_fora_alcance += delta
			if _tempo_fora_alcance >= timeout_fora_alcance:
				morrer()
		_tocar_animacao("idle")

# ============================================================================
# ANIMAÇÃO — Toca animação pelo nome; cai automaticamente na primeira
#             disponível se o nome exato não existir no GLB
# ============================================================================
func _tocar_animacao(nome: String) -> void:
	if not _anim_player:
		return
	# Já tocando a animação certa? Nada a fazer.
	if _anim_player.current_animation == nome and _anim_player.is_playing():
		return
	if _anim_player.has_animation(nome):
		_anim_player.play(nome)
	elif not _anim_player.is_playing():
		# Fallback: primeira animação disponível (idle genérico do GLB)
		var lista: PackedStringArray = _anim_player.get_animation_list()
		if lista.size() > 0:
			_anim_player.play(lista[0])

# ============================================================================
# ALVO — Apenas construções (ignora a base e outros tentáculos)
# ============================================================================
func procurar_novo_alvo():
	var construcoes = get_tree().get_nodes_in_group("Construcao")

	# Conta quantas construções válidas (não-base) ainda existem na cena inteira.
	# O fallback para a base só ativa se TODAS tiverem sido destruídas.
	var construcoes_vivas: int = 0
	var melhor_alvo = null
	var menor_dist: float = raio_visao_construcao + 0.001

	for c in construcoes:
		if not is_instance_valid(c):
			continue
		if c.is_in_group("Castelo") or c.is_in_group("Base"):
			continue
		if "esta_destruida" in c and c.esta_destruida:
			continue
		if "vida_atual" in c and c.vida_atual <= 0:
			continue
		construcoes_vivas += 1
		var d: float = global_position.distance_to(c.global_position)
		if d < menor_dist:
			menor_dist = d
			melhor_alvo = c

	# Só ataca a base quando não existe NENHUMA construção viva no mapa
	if melhor_alvo == null and construcoes_vivas == 0:
		var base = get_tree().get_first_node_in_group("Castelo")
		if not base:
			base = get_tree().get_first_node_in_group("Base")
		if is_instance_valid(base) \
				and not ("esta_destruida" in base and base.esta_destruida) \
				and not ("vida_atual" in base and base.vida_atual <= 0):
			melhor_alvo = base

	return melhor_alvo

# ============================================================================
# MORTE — Notifica o Kraken pai antes de seguir o fluxo padrão
# ============================================================================
func morrer() -> void:
	if esta_morto:
		return
	# Garante que o modelo está em escala normal mesmo que o tentáculo morra
	# durante a animação de surgimento (onde ModeloAnchor começa em scale zero).
	# Sem isso, o tentáculo ficaria invisível durante a animação de morte.
	var modelo: Node3D = get_node_or_null("ModeloAnchor")
	if modelo:
		modelo.scale = Vector3.ONE
	if is_instance_valid(kraken_pai) and kraken_pai.has_method("notificar_tentaculo_morto"):
		kraken_pai.notificar_tentaculo_morto()
	super.morrer()
