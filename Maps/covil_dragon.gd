extends Node3D
@export var conquista_fim: ConquistaData

# ─── Referências de iluminação ────────────────────────────────────────────────
var _luz_solar: DirectionalLight3D = null
var _luz_caldera: SpotLight3D = null
var _ambiente: WorldEnvironment = null
var _luzes_lava: Array = []
var _tweens_lava: Array = []

var _energia_solar_original: float   = 2.0
var _energia_caldera_original: float = 1.0
var _ambient_energy_original: float  = 2.5
var _ambient_color_original: Color   = Color(1.0, 1.0, 1.0, 1.0)
var _brightness_original: float      = 0.8
var _contrast_original: float        = 1.2

func _ready():
	get_tree().paused = false
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.total_spawners = 3
	GameManager.carregar_fase(6)
	MusicaGlobal.tocar_covil()
	GameManager.vitoria.connect(_on_fase_vencida)

	_luz_solar   = get_node_or_null("DirectionalLight3D")
	_luz_caldera = get_node_or_null("DirectionalLight3D3")
	_ambiente    = get_node_or_null("WorldEnvironment")

	if is_instance_valid(_luz_solar):
		_energia_solar_original = _luz_solar.light_energy
	if is_instance_valid(_luz_caldera):
		_energia_caldera_original = _luz_caldera.light_energy
	if is_instance_valid(_ambiente) and _ambiente.environment:
		_ambiente.environment      = _ambiente.environment.duplicate()
		_ambient_energy_original   = _ambiente.environment.ambient_light_energy
		_ambient_color_original    = _ambiente.environment.ambient_light_color
		_brightness_original       = _ambiente.environment.adjustment_brightness
		_contrast_original         = _ambiente.environment.adjustment_contrast

	_criar_luzes_lava()
	_criar_luz_direita()

# ─── Luz permanente lado direito ─────────────────────────────────────────────
func _criar_luz_direita() -> void:
	# Lava do lado +X sempre existe — esta luz fica acesa o tempo todo
	# Duas luzes em alturas diferentes para cobrir parede e chão
	var posicoes := [
		Vector3(10.0, 3.0,  0.0),   # alta — ilumina parede lateral da plataforma
		Vector3( 8.0, 0.8, -2.5),   # baixa-fundo
		Vector3( 8.0, 0.8,  3.0),   # baixa-frente
	]
	for pos in posicoes:
		var luz := OmniLight3D.new()
		luz.light_color    = Color(1.0, 0.32, 0.05)
		luz.light_energy   = 2.2
		luz.omni_range     = 14.0
		luz.shadow_enabled = false
		add_child(luz)
		luz.position = pos

# ─── Luzes de lava ────────────────────────────────────────────────────────────
func _criar_luzes_lava() -> void:
	# Layout: centro + anel 4 pontos + reforço direita (+X) a altura maior
	# altura y=1.5 → ilumina paredes laterais da plataforma, não só o chão
	var pontos := [
		# Anel principal
		Vector3(-7.0, 1.5, -4.0),   # esquerda-fundo
		Vector3(-7.0, 1.5,  3.0),   # esquerda-frente
		Vector3( 0.0, 1.5,  8.0),   # frente-centro
		Vector3( 0.0, 1.5, -7.0),   # fundo-centro
		# Direita — duas luzes dedicadas, maior altura para alcançar a parede
		Vector3( 8.5, 2.0, -3.0),   # direita-fundo
		Vector3( 8.5, 2.0,  3.0),   # direita-frente
		# Extra direita a nível do chão (glow de lava no piso)
		Vector3( 6.5, 0.5,  0.0),   # direita-meio (rés-do-chão)
	]
	for pos in pontos:
		var luz := OmniLight3D.new()
		luz.light_color    = Color(1.0, 0.28, 0.04)
		luz.light_energy   = 0.0
		luz.omni_range     = 10.0
		luz.shadow_enabled = false
		add_child(luz)
		luz.position = pos
		_luzes_lava.append(luz)

func _iniciar_pulso_lava() -> void:
	_parar_tweens_lava()
	for i in _luzes_lava.size():
		var luz: OmniLight3D = _luzes_lava[i]
		if not is_instance_valid(luz): continue
		var tw := create_tween().set_loops()
		tw.tween_property(luz, "light_energy", 3.2, 1.8 + i * 0.11) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(luz, "light_energy", 1.5, 1.6 + i * 0.09) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tweens_lava.append(tw)

func _parar_tweens_lava() -> void:
	for tw in _tweens_lava:
		tw.kill()
	_tweens_lava.clear()

func _apagar_luzes_lava() -> void:
	_parar_tweens_lava()
	for luz in _luzes_lava:
		if not is_instance_valid(luz): continue
		var tw := create_tween()
		tw.tween_property(luz, "light_energy", 0.0, 1.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# ─── Callbacks ────────────────────────────────────────────────────────────────
func _on_dia_iniciado(_onda_atual: int) -> void:
	if Global.DEBUG_MODE:
		print("Dia iniciado!!!!")
	_iniciar_pulso_lava()

	if is_instance_valid(_luz_solar):
		var tw := create_tween()
		tw.tween_property(_luz_solar, "light_energy", 0.15, 3.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if is_instance_valid(_luz_caldera):
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_luz_caldera, "light_energy", _energia_caldera_original * 1.8, 3.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(_luz_caldera, "light_color", Color(1.0, 0.15, 0.02), 3.0) \
			.set_trans(Tween.TRANS_SINE)

	if is_instance_valid(_ambiente) and _ambiente.environment:
		var tw_a := create_tween().set_parallel(true)
		tw_a.tween_property(_ambiente.environment, "ambient_light_energy",
			1.6, 3.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw_a.tween_property(_ambiente.environment, "ambient_light_color",
			Color(1.0, 0.28, 0.04), 3.0) \
			.set_trans(Tween.TRANS_SINE)
		tw_a.tween_property(_ambiente.environment, "adjustment_brightness",
			0.70, 3.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw_a.tween_property(_ambiente.environment, "adjustment_contrast",
			1.35, 3.0) \
			.set_trans(Tween.TRANS_SINE)

func _on_noite_iniciada(_onda_atual: int) -> void:
	_apagar_luzes_lava()

	if is_instance_valid(_luz_solar):
		var tw := create_tween()
		tw.tween_property(_luz_solar, "light_energy", _energia_solar_original, 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if is_instance_valid(_luz_caldera):
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_luz_caldera, "light_energy", _energia_caldera_original, 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_luz_caldera, "light_color", Color(1.0, 0.55, 0.28), 2.5) \
			.set_trans(Tween.TRANS_SINE)

	if is_instance_valid(_ambiente) and _ambiente.environment:
		var tw_a := create_tween().set_parallel(true)
		tw_a.tween_property(_ambiente.environment, "ambient_light_energy",
			_ambient_energy_original, 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw_a.tween_property(_ambiente.environment, "ambient_light_color",
			_ambient_color_original, 2.5) \
			.set_trans(Tween.TRANS_SINE)
		tw_a.tween_property(_ambiente.environment, "adjustment_brightness",
			_brightness_original, 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw_a.tween_property(_ambiente.environment, "adjustment_contrast",
			_contrast_original, 2.5) \
			.set_trans(Tween.TRANS_SINE)

func _on_fase_vencida():
	if conquista_fim != null:
		Global.processar_recompensa(conquista_fim)
