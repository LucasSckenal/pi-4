extends Node3D
@export var conquista_fim_Fenda: ConquistaData
const BolhasFundo = preload("res://Cenas Locais/bolhas_fundo.tscn")

# ─── Referências de iluminação ────────────────────────────────────────────────
var _luz_solar: DirectionalLight3D = null
var _ambiente: WorldEnvironment = null
var _luzes_cais: Array = []
var _energia_solar_original: float = 1.0
var _ambient_energy_original: float = 1.0

func _ready():
	get_tree().paused = false
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.carregar_fase(4)
	MusicaGlobal.tocar_aquatico()
	add_child(BolhasFundo.instantiate())
	GameManager.vitoria.connect(_on_fase_vencida)

	_luz_solar = get_node_or_null("DirectionalLight3D")
	if is_instance_valid(_luz_solar):
		_energia_solar_original = _luz_solar.light_energy
	_ambiente = get_node_or_null("WorldEnvironment")
	if is_instance_valid(_ambiente) and _ambiente.environment:
		_ambient_energy_original = _ambiente.environment.ambient_light_energy
	_criar_luzes_cais()

# ─── Lanternas do cais ────────────────────────────────────────────────────────
func _criar_luzes_cais() -> void:
	# Lanternas estilo pirata — âmbar quente, visíveis no mobile
	var cor := Color(1.0, 0.70, 0.25)

	var aneis := [
		{ "raio": 14.0, "num": 8,  "altura": 2 },  # anel externo (caminho inimigos)
	]
	for anel in aneis:
		var num_anel: int = anel["num"]
		for i in range(num_anel):
			var ang: float = (TAU / num_anel) * i
			var luz := OmniLight3D.new()
			luz.light_color    = cor
			luz.light_energy   = 0.0
			luz.omni_range     = 10.0
			luz.shadow_enabled = false
			add_child(luz)
			luz.position = Vector3(
				cos(ang) * anel["raio"],
				anel["altura"],
				sin(ang) * anel["raio"]
			)
			_luzes_cais.append(luz)

	# Lanterna central
	var central := OmniLight3D.new()
	central.light_color    = cor
	central.light_energy   = 0.0
	central.omni_range     = 10.0
	central.shadow_enabled = false
	add_child(central)
	central.position = Vector3(0.0, 2.0, 0.0)
	_luzes_cais.append(central)

# ─── Animações ────────────────────────────────────────────────────────────────
func _animar_para_noite() -> void:
	var dur := 3.0

	# Sol vira luar — azul-esverdeado como oceano à noite, fica em 22 %
	if is_instance_valid(_luz_solar):
		var tw = create_tween().set_parallel(true)
		tw.tween_property(_luz_solar, "light_energy", _energia_solar_original * 0.22, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(_luz_solar, "light_color", Color(0.50, 0.68, 1.0), dur * 0.7) \
			.set_trans(Tween.TRANS_SINE)

	# Luz ambiente reduz para deixar a noite mais dramática
	if is_instance_valid(_ambiente) and _ambiente.environment:
		var tw_a = create_tween()
		tw_a.tween_property(_ambiente.environment, "ambient_light_energy",
			_ambient_energy_original * 0.30, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Lanternas acendem em cascata
	for i in _luzes_cais.size():
		var luz: OmniLight3D = _luzes_cais[i]
		if not is_instance_valid(luz): continue
		var tw_l = create_tween()
		tw_l.tween_interval(0.08 * i)
		tw_l.tween_property(luz, "light_energy", 3.2, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animar_para_dia() -> void:
	var dur := 2.5

	# Sol volta ao branco original
	if is_instance_valid(_luz_solar):
		var tw = create_tween().set_parallel(true)
		tw.tween_property(_luz_solar, "light_energy", _energia_solar_original, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_luz_solar, "light_color", Color(1.0, 1.0, 1.0), dur) \
			.set_trans(Tween.TRANS_SINE)

	# Luz ambiente volta ao normal
	if is_instance_valid(_ambiente) and _ambiente.environment:
		var tw_a = create_tween()
		tw_a.tween_property(_ambiente.environment, "ambient_light_energy",
			_ambient_energy_original, dur) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Lanternas apagam
	for luz in _luzes_cais:
		if not is_instance_valid(luz): continue
		var tw_l = create_tween()
		tw_l.tween_property(luz, "light_energy", 0.0, dur * 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

# ─── Callbacks ────────────────────────────────────────────────────────────────
func _on_dia_iniciado(_onda_atual: int) -> void:
	_animar_para_dia()

func _on_noite_iniciada(_onda_atual: int) -> void:
	_animar_para_noite()

func _on_fase_vencida():
	if conquista_fim_Fenda != null:
		Global.processar_recompensa(conquista_fim_Fenda)
