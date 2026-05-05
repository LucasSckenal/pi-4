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
## Distância mínima entre dois tentáculos (evita stack na mesma construção)
@export var distancia_minima_entre_tentaculos: float = 3.0
## Offset lateral do tentáculo em relação à construção que ele ataca
@export var offset_da_construcao: float = 1.8
## Raio em torno da base usado quando todas as construções foram destruídas
@export var raio_fallback_base: float = 4.5
## Intensidade base da luz dos olhos (energia)
@export var intensidade_olhos: float = 4.0
## Cor dos olhos (roxo cósmico)
@export var cor_olhos: Color = Color(0.7, 0.0, 1.0, 1.0)
## Quantos segundos antes de invocar os olhos se acendem (telegraf visual)
@export var tempo_telegraf: float = 1.5

# Referências internas
var _olho_esquerdo: OmniLight3D = null
var _olho_direito: OmniLight3D = null
var _tentaculos_ativos: Array = []
var _timer_invocacao: float = 0.0
var _telegrafando: bool = false

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

	# Kraken NÃO conta como "inimigo restante" da wave. Ele é apenas um "hazard"
	# que abre caminho via tentáculos — a wave finaliza quando os inimigos normais
	# (Flamingo/Alexa/Linigena/Sapão) e os tentáculos ativos forem todos derrotados.
	remove_from_group("inimigos")

	# Posiciona embaixo da base (uma frame depois pra garantir base existindo)
	call_deferred("_posicionar_sob_base")

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

	# Invoca novo tentáculo se houver espaço e o timer permitir.
	# Para de invocar quando só restam tentáculos vivos (wave em fase de limpeza),
	# senão o spawner ficaria preso esperando uma corrente infinita de tentáculos.
	_timer_invocacao -= delta

	# Telegraf visual: acende os olhos quando falta <tempo_telegraf> para invocar
	if _timer_invocacao <= tempo_telegraf \
			and _timer_invocacao > 0.0 \
			and not _telegrafando \
			and _tentaculos_ativos.size() < max_tentaculos_vivos \
			and not _wave_em_limpeza():
		_telegrafando = true
		_pulso_telegraf()

	if _timer_invocacao <= 0.0 and _tentaculos_ativos.size() < max_tentaculos_vivos:
		_telegrafando = false
		if _wave_em_limpeza():
			return
		_invocar_tentaculo()
		_timer_invocacao = intervalo_invocacao

# Retorna true se não há mais inimigos "normais" vivos — só tentáculos (ou nada).
# Usado para parar invocações no fim da wave e deixar o spawner finalizar.
func _wave_em_limpeza() -> bool:
	for i in get_tree().get_nodes_in_group("inimigos"):
		if not is_instance_valid(i):
			continue
		if i is Tentaculo:
			continue
		# Achou um inimigo normal vivo → wave ainda em curso
		return false
	return true

# ============================================================================
# INVOCAÇÃO DE TENTÁCULOS
# ----------------------------------------------------------------------------
# Estratégia:
#   1) Procura uma construção VIVA do jogador que ainda não tenha tentáculo
#      próximo. Spawna o tentáculo a uma curta distância dela → tentáculo
#      ataca essa construção (build slot ocupado).
#   2) Se TODAS as construções caíram, faz fallback: spawn em volta da base
#      em ângulo aleatório (raio_fallback_base) — o Kraken muda de tática e
#      passa a atacar diretamente perto do portal.
# ============================================================================
func _invocar_tentaculo() -> void:
	if cena_tentaculo == null:
		push_warning("Cosmic Kraken: cena_tentaculo não configurada")
		return

	var pos_spawn = _escolher_posicao_invocacao()
	if pos_spawn == null:
		return

	var tentaculo = cena_tentaculo.instantiate()
	get_parent().add_child(tentaculo)
	tentaculo.global_position = pos_spawn
	if "kraken_pai" in tentaculo:
		tentaculo.kraken_pai = self
	_tentaculos_ativos.append(tentaculo)

# Devolve um Vector3 (posição) ou null se nenhum spot for viável.
func _escolher_posicao_invocacao():
	# 1. Procura construções vivas sem tentáculo nearby
	var candidatas: Array = []
	for c in get_tree().get_nodes_in_group("Construcao"):
		if not is_instance_valid(c):
			continue
		# Ignora a base (Castelo / Base) — tentáculo só vai de torres/casas/etc
		if c.is_in_group("Castelo") or c.is_in_group("Base"):
			continue
		if "esta_destruida" in c and c.esta_destruida:
			continue
		if "vida_atual" in c and c.vida_atual <= 0:
			continue
		# Pula se já há tentáculo grudado nessa construção
		var ja_ocupada: bool = false
		for t in _tentaculos_ativos:
			if is_instance_valid(t) and \
			   t.global_position.distance_to(c.global_position) < distancia_minima_entre_tentaculos:
				ja_ocupada = true
				break
		if not ja_ocupada:
			candidatas.append(c)

	if candidatas.size() > 0:
		var alvo: Node3D = candidatas[randi() % candidatas.size()]
		# Offset lateral aleatório para o tentáculo emergir AO LADO da construção
		var ang: float = randf() * TAU
		var off: Vector3 = Vector3(cos(ang), 0.0, sin(ang)) * offset_da_construcao
		var pos: Vector3 = alvo.global_position + off
		pos.y = alvo.global_position.y  # mesma altura da construção
		return pos

	# 2. FALLBACK: nenhuma construção viva — spawn em volta da base
	var base = get_tree().get_first_node_in_group("Castelo")
	if not base:
		base = get_tree().get_first_node_in_group("Base")
	if not is_instance_valid(base):
		return null

	# Tenta achar um spot com distância mínima dos outros tentáculos
	for tentativa in range(8):
		var ang: float = randf() * TAU
		var pos: Vector3 = base.global_position + Vector3(
			cos(ang) * raio_fallback_base, 0.0, sin(ang) * raio_fallback_base
		)
		var ok: bool = true
		for t in _tentaculos_ativos:
			if is_instance_valid(t) and \
			   t.global_position.distance_to(pos) < distancia_minima_entre_tentaculos:
				ok = false
				break
		if ok:
			return pos

	# Último recurso: aceita qualquer ângulo
	var ang_final: float = randf() * TAU
	return base.global_position + Vector3(
		cos(ang_final) * raio_fallback_base, 0.0, sin(ang_final) * raio_fallback_base
	)

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

# Telegraf: acende forte antes de invocar tentáculo — avisa o jogador
func _pulso_telegraf() -> void:
	if not _olho_esquerdo and not _olho_direito:
		return
	var tw = create_tween().set_parallel(true)
	if _olho_esquerdo:
		tw.tween_property(_olho_esquerdo, "light_energy", intensidade_olhos * 4.0, 0.2)
		tw.chain().tween_property(_olho_esquerdo, "light_energy", intensidade_olhos * 2.0, 0.5)
	if _olho_direito:
		tw.tween_property(_olho_direito, "light_energy", intensidade_olhos * 4.0, 0.2)
		tw.chain().tween_property(_olho_direito, "light_energy", intensidade_olhos * 2.0, 0.5)

# ============================================================================
# MORTE — Mata tentáculos restantes e finaliza com fade dramático
# ============================================================================
func morrer() -> void:
	if esta_morto:
		return
	# IMPORTANTE: marcar morto AGORA bloqueia a recursão.
	# Sem isso, ao matar os tentáculos abaixo, cada um chamaria
	# notificar_tentaculo_morto() → receber_dano() → morrer() de novo
	# (esta_morto ainda seria false até super.morrer() rodar) → stack overflow.
	esta_morto = true

	# Esconde a barra de vida imediatamente — evita que o jogador veja a barra
	# zerada no intervalo entre a morte do boss e a tela de vitória aparecer.
	if canvas_boss:
		canvas_boss.hide()

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
