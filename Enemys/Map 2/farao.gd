extends InimigoBase

# ==========================================
# FARAÓ — ATAQUE ESPECIAL: TORNADO DE AREIA
# ==========================================
# O Faraó gira no lugar enquanto um tornado de areia se expande ao redor,
# causando dano em área a aliados e construções dentro do raio.
# ==========================================

@export_category("Especial — Tornado de Areia")
@export var dano_por_tick: int = 25               ## Dano aplicado a cada pulso de área
@export var raio_tornado: float = 3.5             ## Raio de dano (unidades de mundo)
@export var duracao_tornado: float = 3.5          ## Segundos com o tornado activo
@export var intervalo_dano: float = 0.5           ## Segundos entre pulsos de dano
@export var cooldown_especial: float = 14.0       ## Recarga entre usos
@export var anim_especial: String = "dance"       ## Animação de spin (configurável no editor)

var _especial_em_andamento: bool = false
var _timer_especial: Timer = null
var _tornado_tweens: Array = []                   ## Tweens de loop do VFX, para limpar ao acabar

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	# Resolve modelo_3d se não configurado no editor
	if modelo_3d == null:
		modelo_3d = get_node_or_null(
			"Meshy_AI_Pharaoh_Mummy_Warrior_biped_Meshy_AI_Meshy_Merged_Animations"
		)
	# Resolve animation_player dentro do modelo (busca recursiva)
	if animation_player == null and modelo_3d != null:
		animation_player = modelo_3d.find_child("AnimationPlayer", true, false)

	super._ready()

	# Timer de recarga do especial (one-shot; reiniciado manualmente após cada uso)
	_timer_especial = Timer.new()
	_timer_especial.one_shot = true
	_timer_especial.timeout.connect(_executar_tornado)
	add_child(_timer_especial)
	# Primeiro uso ligeiramente mais cedo que o cooldown completo
	_timer_especial.start(cooldown_especial * 0.4)

# ==========================================
# FÍSICA — PARALISA DURANTE O ESPECIAL
# ==========================================
func _physics_process(delta: float) -> void:
	if esta_morto:
		return
	if _especial_em_andamento:
		# Mantém gravidade mas remove movimento horizontal
		if not is_on_floor():
			velocity.y -= gravity * delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	super._physics_process(delta)

# ==========================================
# ESPECIAL — TORNADO
# ==========================================
func _executar_tornado() -> void:
	if esta_morto:
		return
	_especial_em_andamento = true

	# ── Spin visual via Tween (gira o modelo 360° várias vezes) ──────────
	var spin_tween: Tween = null
	if modelo_3d:
		var giros := int(duracao_tornado / 0.55)
		spin_tween = create_tween().set_loops(giros)
		spin_tween.tween_property(
			modelo_3d, "rotation_degrees:y",
			modelo_3d.rotation_degrees.y + 360.0, 0.55
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# ── Animação (se existir no modelo) ──────────────────────────────────
	if animation_player:
		if animation_player.has_animation(anim_especial):
			animation_player.play(anim_especial)
		# Se não existir, o Tween já faz o efeito visual de rotação

	# ── VFX: cria o tornado de areia ─────────────────────────────────────
	var tornado_vfx := _criar_vfx_tornado()

	# ── Pulsos de dano em área ────────────────────────────────────────────
	var ticks := int(duracao_tornado / intervalo_dano)
	for _i in range(ticks):
		await get_tree().create_timer(intervalo_dano).timeout
		if esta_morto:
			_limpar_tornado(spin_tween, tornado_vfx)
			return
		_aplicar_dano_area()

	# ── Encerra o especial ────────────────────────────────────────────────
	_limpar_tornado(spin_tween, tornado_vfx)
	_especial_em_andamento = false
	_timer_especial.start(cooldown_especial)


func _limpar_tornado(spin_tween: Tween, tornado_vfx: Node3D) -> void:
	if spin_tween and spin_tween.is_valid():
		spin_tween.kill()

	# Mata os tweens de loop do VFX
	for tw in _tornado_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_tornado_tweens.clear()

	# Para as partículas antes do fade para não aparecerem novas
	if is_instance_valid(tornado_vfx):
		for partic in tornado_vfx.find_children("*", "CPUParticles3D", true, false):
			partic.emitting = false
		var tw_fade := create_tween()
		tw_fade.tween_property(tornado_vfx, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_SINE)
		tw_fade.tween_callback(tornado_vfx.queue_free)


func _aplicar_dano_area() -> void:
	for grupo in ["aliados", "Construcao", "Castelo", "Base"]:
		for alvo in get_tree().get_nodes_in_group(grupo):
			if not is_instance_valid(alvo):
				continue
			if alvo.get("esta_destruida") == true:
				continue
			var dist := global_position.distance_to(alvo.global_position)
			if dist <= raio_tornado and alvo.has_method("receber_dano"):
				alvo.receber_dano(dano_por_tick)

# ==========================================
# VFX — TORNADO DE AREIA
# ==========================================
func _criar_vfx_tornado() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "TornadoVFX"
	add_child(raiz)  # filho do Faraó → segue junto com o boss

	# ── 1. Anel de partículas de areia ─────────────────────────────────
	var partic := CPUParticles3D.new()
	raiz.add_child(partic)
	partic.amount               = 120
	partic.lifetime             = 1.4
	partic.emitting             = true
	partic.one_shot             = false
	partic.explosiveness        = 0.0
	partic.emission_shape       = CPUParticles3D.EMISSION_SHAPE_RING
	partic.emission_ring_radius     = raio_tornado * 0.72
	partic.emission_ring_height     = 0.05
	partic.emission_ring_axis       = Vector3.UP
	partic.emission_ring_cone_angle = 8.0
	partic.direction            = Vector3(0.0, 1.0, 0.0)
	partic.gravity              = Vector3(0.0, 1.5, 0.0)
	partic.spread               = 28.0
	partic.initial_velocity_min = 1.5
	partic.initial_velocity_max = 3.5
	partic.angular_velocity_min = 180.0
	partic.angular_velocity_max = 360.0
	partic.scale_amount_min     = 0.08
	partic.scale_amount_max     = 0.22
	partic.color                = Color(0.88, 0.72, 0.38, 0.85)

	# Segunda camada: partículas centrais mais densas
	var partic2 := CPUParticles3D.new()
	raiz.add_child(partic2)
	partic2.amount               = 60
	partic2.lifetime             = 0.9
	partic2.emitting             = true
	partic2.one_shot             = false
	partic2.explosiveness        = 0.0
	partic2.emission_shape       = CPUParticles3D.EMISSION_SHAPE_SPHERE
	partic2.emission_sphere_radius = raio_tornado * 0.35
	partic2.direction            = Vector3(0.0, 1.0, 0.0)
	partic2.gravity              = Vector3(0.0, 3.0, 0.0)
	partic2.spread               = 45.0
	partic2.initial_velocity_min = 2.0
	partic2.initial_velocity_max = 5.0
	partic2.scale_amount_min     = 0.05
	partic2.scale_amount_max     = 0.15
	partic2.color                = Color(0.95, 0.85, 0.55, 0.70)

	# ── 2. Luz pontual quente (pulsante) ───────────────────────────────
	var luz := OmniLight3D.new()
	raiz.add_child(luz)
	luz.position     = Vector3(0.0, 1.2, 0.0)
	luz.light_color  = Color(1.0, 0.82, 0.42)
	luz.light_energy = 3.5
	luz.omni_range   = raio_tornado * 1.8

	var tw_luz := create_tween().set_loops()
	tw_luz.tween_property(luz, "light_energy", 5.5, 0.35).set_trans(Tween.TRANS_SINE)
	tw_luz.tween_property(luz, "light_energy", 2.5, 0.35).set_trans(Tween.TRANS_SINE)
	_tornado_tweens.append(tw_luz)

	# ── 3. Anel de chão — indica a área de dano ───────────────────────
	var ring_inst := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius  = raio_tornado - 0.15
	ring_mesh.outer_radius  = raio_tornado + 0.15
	ring_mesh.ring_segments = 64
	ring_inst.mesh = ring_mesh
	ring_inst.position = Vector3(0.0, 0.05, 0.0)

	var mat_ring := StandardMaterial3D.new()
	mat_ring.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ring.albedo_color              = Color(1.0, 0.82, 0.30, 0.65)
	mat_ring.emission_enabled          = true
	mat_ring.emission                  = Color(1.0, 0.70, 0.15)
	mat_ring.emission_energy_multiplier = 2.0
	mat_ring.cull_mode                 = BaseMaterial3D.CULL_DISABLED
	ring_mesh.surface_set_material(0, mat_ring)
	raiz.add_child(ring_inst)

	# Pulsa opacidade
	var tw_ring := create_tween().set_loops()
	tw_ring.tween_property(mat_ring, "albedo_color:a", 0.90, 0.45).set_trans(Tween.TRANS_SINE)
	tw_ring.tween_property(mat_ring, "albedo_color:a", 0.28, 0.45).set_trans(Tween.TRANS_SINE)
	_tornado_tweens.append(tw_ring)

	# Gira o anel (vórtice no chão)
	var tw_giro := create_tween().set_loops()
	tw_giro.tween_property(
		ring_inst, "rotation_degrees:y", 360.0, 1.2
	).from(0.0).set_trans(Tween.TRANS_LINEAR)
	_tornado_tweens.append(tw_giro)

	# ── 4. Colunas de areia orbitando (duas camadas a velocidades diferentes) ─
	for camada in range(2):
		var pivot := Node3D.new()       # Pivot no centro — roda e as colunas orbitam
		raiz.add_child(pivot)

		var num_cols := 4
		var raio_orbita := raio_tornado * (0.40 + camada * 0.28)
		var altura := 1.4 - camada * 0.3
		var vel_giro := 0.9 + camada * 0.35  # segundos por volta

		for i in range(num_cols):
			var col_inst := MeshInstance3D.new()
			var col_mesh := CylinderMesh.new()
			col_mesh.top_radius    = 0.10 - camada * 0.02
			col_mesh.bottom_radius = 0.04
			col_mesh.height        = 2.6 - camada * 0.5
			col_inst.mesh = col_mesh

			var ang := (TAU / num_cols) * i
			col_inst.position = Vector3(
				cos(ang) * raio_orbita, altura, sin(ang) * raio_orbita
			)

			var mat_col := StandardMaterial3D.new()
			mat_col.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat_col.albedo_color              = Color(0.90, 0.76, 0.40, 0.38 - camada * 0.08)
			mat_col.emission_enabled          = true
			mat_col.emission                  = Color(1.0, 0.80, 0.35)
			mat_col.emission_energy_multiplier = 0.8
			col_mesh.surface_set_material(0, mat_col)
			pivot.add_child(col_inst)

		# Gira o pivot → todas as colunas orbitam em conjunto
		var tw_pivot := create_tween().set_loops()
		tw_pivot.tween_property(
			pivot, "rotation_degrees:y", 360.0, vel_giro
		).from(0.0).set_trans(Tween.TRANS_LINEAR)
		_tornado_tweens.append(tw_pivot)

	# ── Fade-in inicial do conjunto ───────────────────────────────────
	raiz.scale = Vector3.ZERO
	create_tween().tween_property(
		raiz, "scale", Vector3.ONE, 0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return raiz
