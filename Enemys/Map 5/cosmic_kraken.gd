extends InimigoBase
class_name CosmicKraken

# ============================================================================
# COSMIC KRAKEN — Boss único do Mapa 5
# ============================================================================
# Diferente dos demais bosses: NÃO se move pelos paths, NÃO persegue a base.
# Manifesta-se EMBAIXO da base como uma criatura cósmica que "sempre esteve
# lá" — só agora se revela. Apenas dois pontos roxos brilhantes (olhos)
# permanecem visíveis; o corpo continua oculto. (Cosmic horror.)
#
# MECÂNICA
# ────────
# • Não se move e o corpo é praticamente invulnerável a ataques diretos.
# • Invoca tentáculos pelos paths em intervalos regulares, com limite vivos.
# • Cada tentáculo tem vida própria e ataca CONSTRUÇÕES (não a base).
# • Quando um tentáculo morre, dá dano fixo no Kraken.
# • Boss morre quando a soma dos danos por tentáculos mortos == vida_maxima.
# ============================================================================

@export_category("Cosmic Kraken")
## Cena do tentáculo invocado
@export var cena_tentaculo: PackedScene
## Quantos tentáculos podem estar vivos simultaneamente
@export var max_tentaculos_vivos: int = 4
## Intervalo entre invocações (em segundos)
@export var intervalo_invocacao: float = 4.0
## Dano causado no Kraken quando um tentáculo é destruído
@export var dano_por_tentaculo_morto: int = 100
## Quanto o Kraken se enterra abaixo da base
@export var offset_y_sob_base: float = -2.5
## Intensidade base da luz dos olhos (energia)
@export var intensidade_olhos: float = 4.0
## Cor dos olhos (roxo cósmico)
@export var cor_olhos: Color = Color(0.7, 0.0, 1.0, 1.0)

# Referências internas
var _olho_esquerdo: OmniLight3D = null
var _olho_direito: OmniLight3D = null
var _tentaculos_ativos: Array = []
var _timer_invocacao: float = 0.0
var _spawners_ref: Array = []

# ============================================================================
# READY
# ============================================================================
func _ready() -> void:
	# Configurações forçadas (sobrescreve o que vier do .tscn / inspector)
	tipo_inimigo = Categoria.BOSS
	nome_inimigo = "Cosmic Kraken"
	velocidade   = 0.0
	forca_dano   = 0
	eh_aereo     = false

	# Pega refs aos olhos no ModeloAnchor — ajusta cor/intensidade iniciais
	_olho_esquerdo = get_node_or_null("ModeloAnchor/OlhoEsquerdo")
	_olho_direito  = get_node_or_null("ModeloAnchor/OlhoDireito")
	if _olho_esquerdo:
		_olho_esquerdo.light_color  = cor_olhos
		_olho_esquerdo.light_energy = intensidade_olhos
	if _olho_direito:
		_olho_direito.light_color  = cor_olhos
		_olho_direito.light_energy = intensidade_olhos

	super._ready()

	# Posiciona embaixo da base (uma frame depois pra garantir base existindo)
	call_deferred("_posicionar_sob_base")

	# Coleta refs aos spawners (paths)
	await get_tree().process_frame
	_spawners_ref = get_tree().get_nodes_in_group("Spawner")

	# Animação de pulso dos olhos — loop infinito
	_iniciar_pulso_olhos()

	# Pequeno delay teatral antes da primeira invocação
	_timer_invocacao = 1.5

func _posicionar_sob_base() -> void:
	var base = get_tree().get_first_node_in_group("Castelo")
	if not base:
		base = get_tree().get_first_node_in_group("Base")
	if not is_instance_valid(base):
		return
	global_position  = base.global_position + Vector3(0, offset_y_sob_base, 0)
	posicao_de_spawn = global_position

# ============================================================================
# FÍSICA — Sobrescreve o _physics_process do InimigoBase
# Kraken NÃO se move, NÃO procura alvo, NÃO ataca por contato.
# Apenas controla a invocação de tentáculos.
# ============================================================================
func _physics_process(delta: float) -> void:
	if esta_morto:
		return

	velocity = Vector3.ZERO  # Trava completa

	# Limpa lista de tentáculos mortos/inválidos
	_tentaculos_ativos = _tentaculos_ativos.filter(func(t):
		return is_instance_valid(t) and not t.get("esta_morto"))

	# Invoca novo tentáculo se houver espaço e o timer permitir
	_timer_invocacao -= delta
	if _timer_invocacao <= 0.0 and _tentaculos_ativos.size() < max_tentaculos_vivos:
		_invocar_tentaculo()
		_timer_invocacao = intervalo_invocacao

# ============================================================================
# INVOCAÇÃO DE TENTÁCULOS
# ============================================================================
func _invocar_tentaculo() -> void:
	if cena_tentaculo == null:
		push_warning("Cosmic Kraken: cena_tentaculo não configurada")
		return
	if _spawners_ref.size() == 0:
		_spawners_ref = get_tree().get_nodes_in_group("Spawner")
		if _spawners_ref.size() == 0:
			return

	# Prefere spawners que ainda não têm tentáculo próximo (1 por path)
	var disponiveis: Array = _spawners_ref.duplicate()
	disponiveis.shuffle()

	var escolhido: Node3D = null
	for s in disponiveis:
		if not is_instance_valid(s):
			continue
		var ja_ocupado: bool = false
		for t in _tentaculos_ativos:
			if is_instance_valid(t) and t.global_position.distance_to(s.global_position) < 3.0:
				ja_ocupado = true
				break
		if not ja_ocupado:
			escolhido = s
			break

	# Fallback: aceita qualquer spawner se todos estiverem "ocupados"
	if not is_instance_valid(escolhido) and disponiveis.size() > 0:
		escolhido = disponiveis[0]
	if not is_instance_valid(escolhido):
		return

	var tentaculo = cena_tentaculo.instantiate()
	get_parent().add_child(tentaculo)
	tentaculo.global_position = escolhido.global_position
	if "kraken_pai" in tentaculo:
		tentaculo.kraken_pai = self
	_tentaculos_ativos.append(tentaculo)

# Chamado pelos tentáculos quando morrem — fonte ÚNICA de dano no Kraken.
func notificar_tentaculo_morto() -> void:
	if esta_morto:
		return
	receber_dano(dano_por_tentaculo_morto, "tentaculo")

# ============================================================================
# SOBRESCRITAS — Kraken não tem alvo, não ataca, não explode
# ============================================================================
func procurar_novo_alvo():
	return null

func atacar() -> void:
	pass

func _explodir() -> void:
	pass

# Bloqueia dano direto vindo de torres — apenas tentáculos podem ferir.
# Player toca dano via tentáculo → este chama notificar_tentaculo_morto().
func receber_dano(qtd, origem = "torre") -> void:
	if origem != "tentaculo":
		# Pequeno feedback visual de "imune" — pulso vermelho rápido nos olhos
		_pulso_imunidade()
		return
	super.receber_dano(qtd, origem)

func _pulso_imunidade() -> void:
	if not _olho_esquerdo and not _olho_direito:
		return
	var tw = create_tween().set_parallel(true)
	if _olho_esquerdo:
		var cor_orig = _olho_esquerdo.light_color
		tw.tween_property(_olho_esquerdo, "light_color", Color(1, 0.1, 0.1), 0.08)
		tw.chain().tween_property(_olho_esquerdo, "light_color", cor_orig, 0.25)
	if _olho_direito:
		var cor_orig = _olho_direito.light_color
		tw.tween_property(_olho_direito, "light_color", Color(1, 0.1, 0.1), 0.08)
		tw.chain().tween_property(_olho_direito, "light_color", cor_orig, 0.25)

# ============================================================================
# MORTE — Mata tentáculos restantes e finaliza com fade dramático
# ============================================================================
func morrer() -> void:
	if esta_morto:
		return

	# Mata todos os tentáculos vivos para a wave conseguir terminar
	for t in _tentaculos_ativos:
		if is_instance_valid(t) and t.has_method("receber_dano"):
			t.receber_dano(99999, "kraken_morte")

	# Apaga os olhos lentamente
	if _olho_esquerdo:
		var tw_l = create_tween()
		tw_l.tween_property(_olho_esquerdo, "light_energy", 0.0, 1.5)
	if _olho_direito:
		var tw_r = create_tween()
		tw_r.tween_property(_olho_direito, "light_energy", 0.0, 1.5)

	super.morrer()

# ============================================================================
# ANIMAÇÃO DOS OLHOS — pulso lento de cosmic horror
# ============================================================================
func _iniciar_pulso_olhos() -> void:
	if not _olho_esquerdo and not _olho_direito:
		return
	var energia_min: float = intensidade_olhos * 0.4
	var energia_max: float = intensidade_olhos * 1.2
	# Olho esquerdo
	if _olho_esquerdo:
		var tw_l = create_tween().set_loops()
		tw_l.tween_property(_olho_esquerdo, "light_energy", energia_max, 1.4)\
			.set_trans(Tween.TRANS_SINE)
		tw_l.tween_property(_olho_esquerdo, "light_energy", energia_min, 1.4)\
			.set_trans(Tween.TRANS_SINE)
	# Olho direito (defasado em 0.2s pra parecer mais orgânico)
	if _olho_direito:
		var tw_r = create_tween().set_loops()
		tw_r.tween_interval(0.2)
		tw_r.tween_property(_olho_direito, "light_energy", energia_max, 1.4)\
			.set_trans(Tween.TRANS_SINE)
		tw_r.tween_property(_olho_direito, "light_energy", energia_min, 1.4)\
			.set_trans(Tween.TRANS_SINE)
