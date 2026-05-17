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
@export var max_tentaculos_vivos: int = 3
## Quantidade total de tentáculos que o Kraken invoca ao longo do combate.
## Ao matar todos eles o boss morre (dano = vida_maxima / total_tentaculos por kill)
@export var total_tentaculos: int = 9
## Intervalo entre invocações (em segundos)
@export var intervalo_invocacao: float = 4.0
## Dano no Kraken por tentáculo morto — calculado em _ready() a partir de vida_maxima
var dano_por_tentaculo_morto: int = 0
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
var _tentaculos_invocados: int = 0
var _timer_invocacao: float = 0.0
var _telegrafando: bool = false

# Fases de raiva (0 = normal · 1 = 50 % HP · 2 = 25 % HP)
var _fase_atual: int = 0
var _intervalo_original: float = 0.0

# Efeito de vazio no chão
var _vazio_portal: GPUParticles3D = null

# Silhueta sólida que bloqueia as estrelas atrás do boss
var _corpo_sombrio: MeshInstance3D = null

# Shader do corpo — quase preto, ondula devagar para parecer orgânico
const SHADER_CORPO_SOMBRIO = """
shader_type spatial;
render_mode unshaded, cull_back;

void vertex() {
	// Respiração muito lenta — contorno pulsante como tecido vivo
	float onda = sin(TIME * 0.35 + VERTEX.x * 0.28 + VERTEX.z * 0.28) * 0.10
	           + sin(TIME * 0.22 + VERTEX.y * 0.40) * 0.06;
	VERTEX += NORMAL * onda;
}

void fragment() {
	// Quase preto com leve toque roxo — distingue do fundo puro
	ALBEDO = vec3(0.014, 0.0, 0.028);
}
"""

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

	# Pega refs aos olhos no ModeloAnchor — começam APAGADOS para a intro dramática
	_olho_esquerdo = get_node_or_null("ModeloAnchor/OlhoEsquerdo")
	_olho_direito  = get_node_or_null("ModeloAnchor/OlhoDireito")
	if _olho_esquerdo:
		_olho_esquerdo.light_color  = cor_olhos
		_olho_esquerdo.light_energy = 0.0
	if _olho_direito:
		_olho_direito.light_color  = cor_olhos
		_olho_direito.light_energy = 0.0

	super._ready()

	# Dano por tentáculo = vida_maxima distribuída igualmente entre o total.
	# ceil() garante que arredondamentos sempre cubram 100% da vida.
	dano_por_tentaculo_morto = ceili(float(vida_maxima) / float(max(1, total_tentaculos)))

	# Kraken NÃO conta como "inimigo restante" da wave. Ele é apenas um "hazard"
	# que abre caminho via tentáculos — a wave finaliza quando os inimigos normais
	# (Flamingo/Alexa/Linigena/Sapão) e os tentáculos ativos forem todos derrotados.
	remove_from_group("inimigos")
	add_to_group("Chefe")

	# Posiciona embaixo da base (uma frame depois pra garantir base existindo)
	call_deferred("_posicionar_sob_base")

	# Piscadas dramáticas de spawn — coroutine independente, não bloqueia _ready
	_intro_olhos()

	# Pequeno delay teatral antes da primeira invocação
	_timer_invocacao = 1.5
	_intervalo_original = intervalo_invocacao

func _posicionar_sob_base() -> void:
	var base = get_tree().get_first_node_in_group("Castelo")
	if not base:
		base = get_tree().get_first_node_in_group("Base")
	if not is_instance_valid(base):
		return
	global_position  = base.global_position + Vector3(0, offset_y_sob_base, 0)
	posicao_de_spawn = global_position

	# Posiciona os olhos perto dos BuildSlot7 e BuildSlot8.
	var slot7: Node3D = null
	var slot8: Node3D = null
	for slot in get_tree().get_nodes_in_group("BuildSlots"):
		if slot.name == "BuildSlot7":
			slot7 = slot
		elif slot.name == "BuildSlot8":
			slot8 = slot

	if slot7 and slot8:
		# Olho do slot7 vai para a direita do slot, olho do slot8 vai para a esquerda.
		# "Lado" é perpendicular à direção base→slot no plano XZ.
		var centro: Vector3 = base.global_position
		var dir_e := (slot7.global_position - centro)
		dir_e.y = 0.0
		dir_e = dir_e.normalized()
		var lado_dir_e := Vector3(dir_e.z, 0.0, -dir_e.x)   # 90° horário = direita

		var dir_d := (slot8.global_position - centro)
		dir_d.y = 0.0
		dir_d = dir_d.normalized()
		var lado_esq_d := Vector3(-dir_d.z, 0.0, dir_d.x)   # 90° anti-horário = esquerda

		var pos_e: Vector3 = to_local(slot7.global_position + lado_dir_e * 2.0)
		var pos_d: Vector3 = to_local(slot8.global_position + lado_esq_d * 2.0)
		pos_e.y = 0.5
		pos_d.y = 0.5
		if _olho_esquerdo:
			_olho_esquerdo.position = pos_e
			_olho_esquerdo.omni_range = 3.5
		if _olho_direito:
			_olho_direito.position = pos_d
			_olho_direito.omni_range = 3.5
	else:
		push_warning("CosmicKraken: BuildSlot7/8 não encontrados, usando posição padrão")
		var y_borda: float = abs(offset_y_sob_base) - 1.0
		if _olho_esquerdo:
			_olho_esquerdo.position = Vector3(-4.5, y_borda, 0.0)
			_olho_esquerdo.omni_range = 3.0
		if _olho_direito:
			_olho_direito.position = Vector3(4.5, y_borda, 0.0)
			_olho_direito.omni_range = 3.0
	_criar_corpo_sombrio()
	_criar_malha_olhos()
	_criar_vazio_portal()

# ============================================================================
# FÍSICA — Sobrescreve o _physics_process do InimigoBase
# Kraken NÃO se move, NÃO procura alvo, NÃO ataca por contato.
# Apenas controla a invocação de tentáculos.
# ============================================================================
func _physics_process(delta: float) -> void:
	if esta_morto:
		return

	velocity = Vector3.ZERO  # Trava completa

	# Limpa lista de tentáculos mortos/inválidos (loop reverso — sem alocação)
	for i in range(_tentaculos_ativos.size() - 1, -1, -1):
		var t = _tentaculos_ativos[i]
		if not is_instance_valid(t) or t.get("esta_morto"):
			_tentaculos_ativos.remove_at(i)

	# Invoca novo tentáculo se houver espaço e o timer permitir.
	# Para de invocar quando só restam tentáculos vivos (wave em fase de limpeza),
	# senão o spawner ficaria preso esperando uma corrente infinita de tentáculos.
	_timer_invocacao -= delta

	var pode_invocar := _tentaculos_ativos.size() < max_tentaculos_vivos \
			and _tentaculos_invocados < total_tentaculos

	# Telegraf visual: acende os olhos quando falta <tempo_telegraf> para invocar
	if _timer_invocacao <= tempo_telegraf \
			and _timer_invocacao > 0.0 \
			and not _telegrafando \
			and pode_invocar:
		_telegrafando = true
		_pulso_telegraf()

	if _timer_invocacao <= 0.0 and pode_invocar:
		_telegrafando = false
		_invocar_tentaculo()
		_timer_invocacao = intervalo_invocacao

	_verificar_fases()

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
	_tentaculos_invocados += 1
	_screen_shake(0.12, 0.28)

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
	# Explosão cósmica de morte — flash branco + burst de partículas roxas
	_screen_shake(0.35, 0.6)
	# Flash nos olhos ao máximo antes de apagar
	if _olho_esquerdo:
		_olho_esquerdo.light_energy = intensidade_olhos * 10.0
	if _olho_direito:
		_olho_direito.light_energy = intensidade_olhos * 10.0
	# Burst de partículas no ponto de cada olho
	for olho in [_olho_esquerdo, _olho_direito]:
		if not olho: continue
		var burst := GPUParticles3D.new()
		burst.one_shot     = true
		burst.emitting     = true
		burst.amount       = 40
		burst.lifetime     = 1.2
		burst.explosiveness = 0.95
		burst.visibility_aabb = AABB(Vector3(-10,-10,-10), Vector3(20,20,20))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.2
		pm.direction = Vector3(0, 1, 0)
		pm.spread    = 180.0
		pm.initial_velocity_min = 4.0
		pm.initial_velocity_max = 9.0
		pm.gravity = Vector3.ZERO
		pm.scale_min = 0.06
		pm.scale_max = 0.18
		pm.color = Color(0.7, 0.0, 1.0, 1.0)
		burst.process_material = burst.process_material  # placeholder
		burst.process_material = pm
		var mat_b := StandardMaterial3D.new()
		mat_b.shading_mode            = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_b.albedo_color            = Color(0.8, 0.2, 1.0)
		mat_b.emission_enabled        = true
		mat_b.emission                = Color(0.7, 0.0, 1.0)
		mat_b.emission_energy_multiplier = 5.0
		var esf := SphereMesh.new()
		esf.material = mat_b
		esf.radius = 0.1
		esf.height = 0.2
		burst.draw_pass_1 = esf
		get_parent().add_child(burst)
		burst.global_position = olho.global_position
		# Auto-destrói após as partículas acabarem
		get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(burst): burst.queue_free())

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

	# Apaga os olhos lentamente (pupilas permanecem visíveis até sumir com o fade)
	_set_visibilidade_pupilas(true)
	if _olho_esquerdo:
		var tw_l = create_tween()
		tw_l.tween_property(_olho_esquerdo, "light_energy", 0.0, 1.5)
	if _olho_direito:
		var tw_r = create_tween()
		tw_r.tween_property(_olho_direito, "light_energy", 0.0, 1.5)

	super.morrer()

# ============================================================================
# ANIMAÇÃO DOS OLHOS — intro dramática + pulso lento de cosmic horror
# ============================================================================

# Adiciona esferas emissivas aos nós dos olhos para torná-los visíveis como objetos.
# Chamado em _posicionar_sob_base após reposicionar os olhos.
func _criar_malha_olhos() -> void:
	var shader_olho: Shader = load("res://Shaders/kraken_eye.gdshader")
	for olho in [_olho_esquerdo, _olho_direito]:
		if not olho or olho.get_node_or_null("Pupila") != null:
			continue
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Pupila"
		# QuadMesh billboard (2:1) — shader cuida da forma oval e da névoa
		var quad := QuadMesh.new()
		quad.size = Vector2(1.5, 0.75)
		mesh_inst.mesh = quad
		var mat := ShaderMaterial.new()
		mat.shader = shader_olho
		mat.set_shader_parameter("cor_olho", cor_olhos)
		mat.set_shader_parameter("intensidade", 2.5)
		mesh_inst.material_override = mat
		olho.add_child(mesh_inst)

# Sequência de spawn: olhos piscam do nada, 2 vezes, depois entram no loop.
func _intro_olhos() -> void:
	if not _olho_esquerdo and not _olho_direito:
		return
	# Esferas invisíveis durante a pausa inicial
	_set_visibilidade_pupilas(false)

	# Pausa inicial — o boss acabou de aparecer embaixo da base
	await get_tree().create_timer(1.0).timeout
	if esta_morto: return

	# 1ª piscada: flash muito forte (susto)
	_set_visibilidade_pupilas(true)
	var tw = create_tween().set_parallel(true)
	if _olho_esquerdo:
		tw.tween_property(_olho_esquerdo, "light_energy", intensidade_olhos * 6.0, 0.08)
	if _olho_direito:
		tw.tween_property(_olho_direito, "light_energy", intensidade_olhos * 6.0, 0.08)
	await get_tree().create_timer(0.12).timeout
	if esta_morto: return

	# Apaga
	_set_visibilidade_pupilas(false)
	tw = create_tween().set_parallel(true)
	if _olho_esquerdo:
		tw.tween_property(_olho_esquerdo, "light_energy", 0.0, 0.2)
	if _olho_direito:
		tw.tween_property(_olho_direito, "light_energy", 0.0, 0.2)
	await get_tree().create_timer(0.4).timeout
	if esta_morto: return

	# 2ª piscada: os olhos "se abrem de verdade" e ficam
	_set_visibilidade_pupilas(true)
	tw = create_tween().set_parallel(true)
	if _olho_esquerdo:
		tw.tween_property(_olho_esquerdo, "light_energy", intensidade_olhos * 4.0, 0.15)
	if _olho_direito:
		tw.tween_property(_olho_direito, "light_energy", intensidade_olhos * 4.0, 0.15)
	await get_tree().create_timer(0.5).timeout
	if esta_morto: return

	# Entra no pulso contínuo
	_iniciar_pulso_olhos()

func _set_visibilidade_pupilas(visivel: bool) -> void:
	for olho in [_olho_esquerdo, _olho_direito]:
		if not olho: continue
		var pupila = olho.get_node_or_null("Pupila")
		if pupila:
			pupila.visible = visivel

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

# ============================================================================
# CORPO SOMBRIO — mesh opaco que bloqueia estrelas revelando a massa do boss
# ============================================================================
func _criar_corpo_sombrio() -> void:
	_corpo_sombrio = MeshInstance3D.new()
	_corpo_sombrio.name = "CorpoSombrio"

	var esfera := SphereMesh.new()
	# Grande o suficiente para cobrir a área da plataforma circular
	esfera.radius          = 13.0
	esfera.height          = 26.0
	esfera.radial_segments = 64   # segmentos suficientes para o vertex shader suavizar
	esfera.rings           = 32
	_corpo_sombrio.mesh = esfera

	var mat := ShaderMaterial.new()
	mat.shader      = Shader.new()
	mat.shader.code = SHADER_CORPO_SOMBRIO
	_corpo_sombrio.material_override = mat
	_corpo_sombrio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(_corpo_sombrio)

	# Achatado para forma de disco. Centro em Y=-3.5 (local) para que o
	# topo do ellipsoide (−3.5 + 13×0.25 = −0.25) fique ligeiramente
	# ABAIXO dos olhos (Y=0.5), sem flutuar acima da plataforma.
	_corpo_sombrio.scale    = Vector3(1.0, 0.25, 1.0)
	_corpo_sombrio.position = Vector3(0.0, -3.5, 0.0)

# ============================================================================
# PORTAL DO VAZIO — anel de partículas no chão mostrando o Kraken embaixo
# ============================================================================
func _criar_vazio_portal() -> void:
	_vazio_portal = GPUParticles3D.new()
	_vazio_portal.name        = "VazioPortal"
	_vazio_portal.amount      = 80
	_vazio_portal.lifetime    = 2.5
	_vazio_portal.emitting    = true
	_vazio_portal.explosiveness = 0.0
	_vazio_portal.randomness  = 0.4
	_vazio_portal.visibility_aabb = AABB(Vector3(-12,-4,-12), Vector3(24,8,24))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius   = 3.8
	pm.emission_ring_inner_radius = 2.8
	pm.emission_ring_height   = 0.05
	pm.emission_ring_axis     = Vector3(0, 1, 0)
	pm.direction   = Vector3(0, 1, 0)
	pm.spread      = 18.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.8
	pm.gravity     = Vector3(0, -0.4, 0)
	pm.scale_min   = 0.05
	pm.scale_max   = 0.14
	# Começa roxo, fica transparente ao subir
	var grad := Gradient.new()
	grad.set_color(0, Color(0.6, 0.0, 1.0, 1.0))
	grad.set_color(1, Color(0.2, 0.0, 0.5, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pm.color_ramp = grad_tex
	_vazio_portal.process_material = pm

	var mat_v := StandardMaterial3D.new()
	mat_v.shading_mode            = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_v.albedo_color            = Color(0.7, 0.0, 1.0, 1.0)
	mat_v.emission_enabled        = true
	mat_v.emission                = Color(0.5, 0.0, 0.9)
	mat_v.emission_energy_multiplier = 3.5
	var esf_v := SphereMesh.new()
	esf_v.material = mat_v
	esf_v.radius   = 0.08
	esf_v.height   = 0.16
	_vazio_portal.draw_pass_1 = esf_v

	add_child(_vazio_portal)
	# Posiciona na superfície da plataforma (y=abs(offset) acima do Kraken)
	_vazio_portal.position = Vector3(0, abs(offset_y_sob_base) - 0.2, 0)

# ============================================================================
# FASES DE RAIVA
# ============================================================================
func _verificar_fases() -> void:
	if esta_morto or vida_maxima <= 0:
		return
	var ratio := float(vida_atual) / float(vida_maxima)
	if ratio <= 0.25 and _fase_atual < 2:
		_entrar_fase(2)
	elif ratio <= 0.50 and _fase_atual < 1:
		_entrar_fase(1)

func _entrar_fase(fase: int) -> void:
	_fase_atual = fase
	_screen_shake(0.25, 0.5)

	match fase:
		1:  # 50 % — Irritado
			intervalo_invocacao = _intervalo_original * 0.70
			cor_olhos = Color(1.0, 0.45, 0.0, 1.0)   # laranja
			if is_instance_valid(_vazio_portal):
				_vazio_portal.amount = 110
		2:  # 25 % — Fúria total
			intervalo_invocacao = _intervalo_original * 0.45
			cor_olhos = Color(1.0, 0.05, 0.05, 1.0)  # vermelho sangue
			if is_instance_valid(_vazio_portal):
				_vazio_portal.amount = 150

	# Aplica nova cor aos olhos
	for olho in [_olho_esquerdo, _olho_direito]:
		if not olho: continue
		olho.light_color = cor_olhos
		var pupila = olho.get_node_or_null("Pupila")
		if pupila and pupila.material_override is ShaderMaterial:
			pupila.material_override.set_shader_parameter("cor_olho", cor_olhos)

	# Flash dramático de transição
	var tw = create_tween().set_parallel(true)
	for olho in [_olho_esquerdo, _olho_direito]:
		if not olho: continue
		tw.tween_property(olho, "light_energy", intensidade_olhos * 8.0, 0.12)
		tw.chain().tween_property(olho, "light_energy", intensidade_olhos * 1.5, 0.4)

# ============================================================================
# SCREEN SHAKE — oscila h_offset / v_offset da câmera (não conflita com follow)
# ============================================================================
func _screen_shake(intensidade: float, duracao: float) -> void:
	if not Global.shake_tela_ativo:
		return
	var cam := get_viewport().get_camera_3d()
	if not is_instance_valid(cam):
		return
	var tw = create_tween()
	var passos: int = max(4, int(duracao / 0.05))
	for i in range(passos):
		var f := float(passos - i) / float(passos)
		tw.tween_callback(func():
			cam.h_offset = randf_range(-intensidade, intensidade) * f
			cam.v_offset = randf_range(-intensidade * 0.5, intensidade * 0.5) * f
		)
		tw.tween_interval(duracao / passos)
	tw.tween_callback(func():
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	)
