extends Node3D
@export var conquista_fim_Espaco: ConquistaData

# ─── referências ─────────────────────────────────────────────────────────────
var _estrelas_normais: GPUParticles3D
var _planeta: MeshInstance3D
var _atmosfera: MeshInstance3D
var _estrelas_cadentes: GPUParticles3D
var _timer_cadente: Timer

var _luz_solar: DirectionalLight3D = null
var _ambiente: WorldEnvironment = null
var _luzes_plataforma: Array = []
var _energia_solar_original: float = 1.0

const ONDA_BOSS := 6

# ─── Shader da superfície — estilo Terra ─────────────────────────────────────
const SHADER_PLANETA = """
shader_type spatial;
render_mode unshaded, cull_back;

uniform float velocidade : hint_range(0.0, 0.1) = 0.013;

// ── Ruído 3D sem costura ──────────────────────────────────────────────────────
// Usa coordenadas 3D do vértice em vez de UV — elimina a costura polar/lateral.
varying vec3 v_vert;

void vertex() {
	v_vert = VERTEX;
}

float h31(vec3 p) {
	p = fract(p * vec3(127.1, 311.7, 74.7));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}
float sn3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(h31(i),             h31(i+vec3(1,0,0)), f.x),
		    mix(h31(i+vec3(0,1,0)), h31(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(h31(i+vec3(0,0,1)), h31(i+vec3(1,0,1)), f.x),
		    mix(h31(i+vec3(0,1,1)), h31(i+vec3(1,1,1)), f.x), f.y),
		f.z);
}
float fbm3(vec3 p) { return sn3(p)*.5 + sn3(p*2.1)*.25 + sn3(p*4.5)*.125; }

void fragment() {
	// pn = posição normalizada na superfície da esfera (raio=18 → divide por 18)
	vec3 pn = v_vert / 18.0;
	float t  = TIME * velocidade;

	// ── Máscara terra/oceano ──────────────────────────────────────────────
	float terra = fbm3(pn * 3.8 + vec3(t * 0.4, 0.0, 0.0));
	terra = smoothstep(0.44, 0.56, terra);   // 0 = oceano, 1 = terra

	// Oceano: azul profundo com variação de profundidade
	vec3 oceano_raso  = vec3(0.10, 0.45, 0.80);
	vec3 oceano_fundo = vec3(0.04, 0.18, 0.52);
	float prof = fbm3(pn * 6.0 + vec3(-t * 0.6, 0.0, 0.0));
	vec3 col_oceano = mix(oceano_fundo, oceano_raso, prof);

	// Terra: verde floresta + marrom deserto + montanha
	vec3 floresta = vec3(0.13, 0.42, 0.12);
	vec3 deserto  = vec3(0.62, 0.48, 0.22);
	vec3 montanha = vec3(0.42, 0.35, 0.28);
	float bioma = fbm3(pn * 5.5 + vec3(t * 0.2, t * 0.15, 0.0));
	vec3 col_terra = mix(floresta, deserto, smoothstep(0.35, 0.65, bioma));
	col_terra = mix(col_terra, montanha, smoothstep(0.68, 0.80, bioma));

	vec3 col = mix(col_oceano, col_terra, terra);

	// ── Nuvens (camada independente, mais rápida) ─────────────────────────
	float nuvens = fbm3(pn * 5.5 + vec3(-t * 1.8, t * 0.9, 0.0));
	nuvens += fbm3(pn * 9.0 + vec3(t * 1.1, -t * 0.7, 0.0)) * 0.4;
	nuvens = smoothstep(0.58, 0.80, nuvens);
	col = mix(col, vec3(0.95, 0.97, 1.0), nuvens * 0.88);

	// ── Calotas polares (baseado na latitude = componente Y normalizado) ──
	float lat = (pn.y + 1.0) * 0.5;   // 0 = polo sul, 1 = polo norte
	float caps = smoothstep(0.12, 0.0, lat) + smoothstep(0.88, 1.0, lat);
	col = mix(col, vec3(0.92, 0.97, 1.0), caps);

	// ── Limb darkening suave ──────────────────────────────────────────────
	float limb = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	col *= 0.35 + 0.65 * limb;

	ALBEDO = col;
}
"""

# ─── Shader da atmosfera — halo azul-celeste ─────────────────────────────────
const SHADER_ATMOSFERA = """
shader_type spatial;
render_mode unshaded, cull_back, blend_add, depth_draw_never;

void fragment() {
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// Duas camadas: halo amplo suave + anel fino brilhante na borda
	float halo  = pow(rim, 3.2) * 0.55;
	float borda = pow(rim, 7.5) * 1.20;
	float total = halo + borda;
	// Cor: azul-celeste no halo, quase branco na borda
	vec3 cor = mix(vec3(0.20, 0.52, 1.0), vec3(0.75, 0.90, 1.0), pow(rim, 5.0));
	ALBEDO = cor * total;
	ALPHA  = clamp(total, 0.0, 1.0);
}
"""

# ─────────────────────────────────────────────────────────────────────────────
func _ready():
	get_tree().paused = false
	GameManager.total_spawners = 4
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.carregar_fase(5)
	MusicaGlobal.tocar_scifi()
	GameManager.vitoria.connect(_on_fase_vencida)

	_estrelas_normais = get_node_or_null("Estrelas")
	_criar_estrelas_cadentes()
	# Aguarda mais um frame para a Camera3D estar registada no viewport
	await get_tree().process_frame
	_criar_planeta()
	_luz_solar = get_node_or_null("LuzSolar")
	_ambiente = get_node_or_null("AmbienteEspacial")
	if is_instance_valid(_luz_solar):
		_energia_solar_original = _luz_solar.light_energy
	# Dobra o amount das estrelas — amount_ratio 0.5 mantém o visual de dia,
	# à noite tweenamos para 1.0 dobrando as estrelas visivelmente.
	if is_instance_valid(_estrelas_normais):
		_estrelas_normais.amount = _estrelas_normais.amount * 2
		_estrelas_normais.amount_ratio = 0.5
	_criar_luzes_plataforma()

# ─── Planeta ─────────────────────────────────────────────────────────────────
func _criar_planeta() -> void:
	# Superfície
	_planeta = MeshInstance3D.new()
	_planeta.name = "PlanetaFundo"

	var esfera := SphereMesh.new()
	esfera.radius          = 18.0
	esfera.height          = 36.0
	esfera.radial_segments = 48
	esfera.rings           = 24
	_planeta.mesh = esfera

	var mat_p := ShaderMaterial.new()
	mat_p.shader      = Shader.new()
	mat_p.shader.code = SHADER_PLANETA
	_planeta.material_override = mat_p
	_planeta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Atmosfera (rim glow — filho do planeta)
	_atmosfera = MeshInstance3D.new()
	_atmosfera.name = "Atmosfera"

	var esfera_atm := SphereMesh.new()
	esfera_atm.radius          = 19.6   # ~9 % maior
	esfera_atm.height          = 39.2
	esfera_atm.radial_segments = 32
	esfera_atm.rings           = 16
	_atmosfera.mesh = esfera_atm

	var mat_a := ShaderMaterial.new()
	mat_a.shader      = Shader.new()
	mat_a.shader.code = SHADER_ATMOSFERA
	_atmosfera.material_override = mat_a
	_atmosfera.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_planeta.add_child(_atmosfera)   # atmosfera segue posição do planeta

	# ── Pareneia o planeta à Camera3D ────────────────────────────────────
	# Assim as coordenadas são locais à câmera:
	#   +X = direita do ecrã   +Y = cima do ecrã   -Z = à frente da câmera
	# Independente do ângulo ou posição da câmera no mundo.
	var cam := get_viewport().get_camera_3d()
	if is_instance_valid(cam):
		cam.add_child(_planeta)
		# Direita, acima do centro (céu de fundo), longe
		_planeta.position = Vector3(22.0, 110.0, -220.0)
	else:
		add_child(_planeta)
		_planeta.position = Vector3(0.0, 0.0, 80.0)

# ─── Estrelas cadentes ────────────────────────────────────────────────────────
func _criar_estrelas_cadentes() -> void:
	_estrelas_cadentes = GPUParticles3D.new()
	_estrelas_cadentes.name         = "EstrelasCadentes"
	_estrelas_cadentes.amount       = 10
	_estrelas_cadentes.lifetime     = 2.2
	_estrelas_cadentes.one_shot     = true
	_estrelas_cadentes.emitting     = false
	_estrelas_cadentes.explosiveness = 0.18
	_estrelas_cadentes.randomness   = 0.5
	_estrelas_cadentes.trail_enabled  = true
	_estrelas_cadentes.trail_lifetime = 0.5
	_estrelas_cadentes.visibility_aabb = AABB(
		Vector3(-200.0, -200.0, -200.0), Vector3(400.0, 400.0, 400.0))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape        = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents  = Vector3(40.0, 8.0, 2.0)
	pm.direction             = Vector3(-0.85, -0.28, 0.0)
	pm.spread                = 5.0
	pm.initial_velocity_min  = 55.0
	pm.initial_velocity_max  = 80.0
	pm.gravity               = Vector3(0, 0, 0)
	pm.scale_min             = 0.08
	pm.scale_max             = 0.18
	pm.color                 = Color(1.0, 0.95, 0.85, 1.0)
	_estrelas_cadentes.process_material = pm

	var mat_c := StandardMaterial3D.new()
	mat_c.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_c.albedo_color              = Color(1.0, 0.95, 0.85, 1.0)
	mat_c.emission_enabled          = true
	mat_c.emission                  = Color(1.0, 0.95, 0.85)
	mat_c.emission_energy_multiplier = 6.0

	var esfera_c := SphereMesh.new()
	esfera_c.material        = mat_c
	esfera_c.radius          = 0.14
	esfera_c.height          = 0.28
	esfera_c.radial_segments = 6
	esfera_c.rings           = 3
	_estrelas_cadentes.draw_pass_1 = esfera_c

	add_child(_estrelas_cadentes)
	# Emite acima do mapa na direcção de onde a câmera olha (+Z, +X, Y alto)
	_estrelas_cadentes.position = Vector3(20.0, 22.0, 35.0)

	_timer_cadente = Timer.new()
	_timer_cadente.wait_time = randf_range(8.0, 18.0)
	_timer_cadente.one_shot  = true
	_timer_cadente.timeout.connect(_disparar_estrelas_cadentes)
	add_child(_timer_cadente)
	_timer_cadente.start()

func _disparar_estrelas_cadentes() -> void:
	if is_instance_valid(_estrelas_cadentes):
		_estrelas_cadentes.restart()
		_estrelas_cadentes.emitting = true
	if is_instance_valid(_timer_cadente):
		_timer_cadente.wait_time = randf_range(8.0, 22.0)
		_timer_cadente.start()

# ─── Luzes da plataforma ──────────────────────────────────────────────────────
func _criar_luzes_plataforma() -> void:
	# Três anéis de luzes rasas no chão + uma central — garantem boa
	# visibilidade para público idoso em telas de celular.
	# Cor branco-âmbar quente: excelente contraste sem cansar os olhos.
	var cor := Color(1.0, 0.93, 0.72)

	var aneis := [
		{ "raio": 16.5, "num": 8,  "altura": 0.35 },  # anel externo (caminho dos inimigos)
		{ "raio": 9.5,  "num": 7,  "altura": 0.35 },  # anel médio  (slots de construção)
		{ "raio": 4.0,  "num": 5,  "altura": 0.35 },  # anel interno (perto da base)
	]
	for anel in aneis:
		var num_anel: int = anel["num"]
		for i in range(num_anel):
			var ang: float = (TAU / num_anel) * i
			var luz := OmniLight3D.new()
			luz.light_color    = cor
			luz.light_energy   = 0.0   # apagada durante o dia
			luz.omni_range     = 11.0  # raio amplo cobre toda a área entre anéis
			luz.shadow_enabled = false
			add_child(luz)
			luz.position = Vector3(
				cos(ang) * anel["raio"],
				anel["altura"],
				sin(ang) * anel["raio"]
			)
			_luzes_plataforma.append(luz)

	# Luz central — ilumina o centro da base
	var central := OmniLight3D.new()
	central.light_color    = cor
	central.light_energy   = 1.0
	central.omni_range     = 10.0
	central.shadow_enabled = true
	add_child(central)
	central.position = Vector3(0.0, 1.5, 0.0)
	_luzes_plataforma.append(central)

func _animar_para_noite() -> void:
	var dur := 3.0

	# Sol fica em 25 % — escurece sem ficar ilegível no celular
	if is_instance_valid(_luz_solar):
		var tw = create_tween().set_parallel(true)
		tw.tween_property(_luz_solar, "light_energy", _energia_solar_original * 0.25, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(_luz_solar, "light_color", Color(0.70, 0.75, 1.0), dur * 0.7) \
			.set_trans(Tween.TRANS_SINE)   # azul-luar suave

	# Luzes do chão acendem em cascata
	for i in _luzes_plataforma.size():
		var luz: OmniLight3D = _luzes_plataforma[i]
		if not is_instance_valid(luz): continue
		var tw_l = create_tween()
		tw_l.tween_interval(0.07 * i)          # cascata rápida
		tw_l.tween_property(luz, "light_energy", 1.5, 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Mais estrelas visíveis (tween suave via amount_ratio)
	if is_instance_valid(_estrelas_normais) and _estrelas_normais.emitting:
		var tw_s = create_tween()
		tw_s.tween_interval(1.0)               # espera o sol apagar primeiro
		tw_s.tween_property(_estrelas_normais, "amount_ratio", 1.0, 1.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animar_para_dia() -> void:
	var dur := 2.5

	# Sol volta
	if is_instance_valid(_luz_solar):
		var tw = create_tween().set_parallel(true)
		tw.tween_property(_luz_solar, "light_energy", _energia_solar_original, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_luz_solar, "light_color", Color(1.0, 1.0, 1.0), dur) \
			.set_trans(Tween.TRANS_SINE)

	# Luzes da plataforma apagam
	for luz in _luzes_plataforma:
		if not is_instance_valid(luz): continue
		var tw_l = create_tween()
		tw_l.tween_property(luz, "light_energy", 0.0, dur * 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Estrelas voltam ao nível de dia
	if is_instance_valid(_estrelas_normais):
		var tw_s = create_tween()
		tw_s.tween_property(_estrelas_normais, "amount_ratio", 0.5, 1.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


# ─── Loop ─────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if is_instance_valid(_planeta):
		_planeta.rotation.y += delta * 0.010

# ─── Callbacks ────────────────────────────────────────────────────────────────
func _on_dia_iniciado(_onda_atual: int) -> void:
	_animar_para_dia()

func _on_noite_iniciada(_onda_atual: int) -> void:
	_animar_para_noite()
	if _onda_atual >= ONDA_BOSS:
		if is_instance_valid(_estrelas_normais):
			_estrelas_normais.emitting = false
		if is_instance_valid(_estrelas_cadentes):
			_estrelas_cadentes.emitting = false
		if is_instance_valid(_timer_cadente):
			_timer_cadente.stop()

func _on_fase_vencida():
	if conquista_fim_Espaco != null:
		Global.processar_recompensa(conquista_fim_Espaco)
