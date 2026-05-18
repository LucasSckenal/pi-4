extends Node3D
@export var conquista_fim_Bruxa: ConquistaData

@onready var anim_player = $DayNightAnimator

var _luz_tocha: OmniLight3D = null
var _chama_tocha: MeshInstance3D = null   # malha de chama (ShaderMaterial)
var _luz_dia: DirectionalLight3D = null
var _ambiente: WorldEnvironment = null
var _ambient_energy_dia: float = 1.0

func _ready():
	get_tree().paused = false
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.carregar_fase(3)
	MusicaGlobal.tocar_bruxa()
	GameManager.vitoria.connect(_on_fase_vencida)

	# ── Tocha ─────────────────────────────────────────────────────────────────
	var tocha := get_node_or_null("Tocha")
	if tocha:
		_luz_tocha   = _buscar_omni(tocha)
		_chama_tocha = _buscar_chama(tocha)   # só a malha com ShaderMaterial

	# Começa apagada durante o dia (modelo da tocha continua visível)
	if is_instance_valid(_luz_tocha):
		_luz_tocha.light_energy = 0.0
	if is_instance_valid(_chama_tocha):
		_chama_tocha.visible = false

	# ── Luz solar (criada aqui pois o mapa não tem DirectionalLight3D) ─────────
	_luz_dia = DirectionalLight3D.new()
	_luz_dia.light_color    = Color(1.0, 0.94, 0.82)
	_luz_dia.light_energy   = 1.5               # dia bem iluminado
	_luz_dia.shadow_enabled = false
	_luz_dia.rotation_degrees = Vector3(-50.0, 40.0, 0.0)
	add_child(_luz_dia)

	# ── WorldEnvironment (duplicado para não afetar outros mapas) ─────────────
	_ambiente = get_node_or_null("WorldEnvironment")
	if is_instance_valid(_ambiente) and _ambiente.environment:
		_ambiente.environment = _ambiente.environment.duplicate()
		_ambient_energy_dia = _ambiente.environment.ambient_light_energy

# ─── Buscadores recursivos ────────────────────────────────────────────────────
func _buscar_omni(no: Node) -> OmniLight3D:
	if no is OmniLight3D:
		return no
	for filho in no.get_children():
		var r := _buscar_omni(filho)
		if r: return r
	return null

func _buscar_chama(no: Node) -> MeshInstance3D:
	# Ignora malhas com StandardMaterial3D (corpo da tocha)
	# Retorna apenas a malha com ShaderMaterial (a chama em si)
	if no is MeshInstance3D:
		var mat = (no as MeshInstance3D).get_active_material(0)
		if mat is ShaderMaterial:
			return no
	for filho in no.get_children():
		var r := _buscar_chama(filho)
		if r: return r
	return null

# ─── Acender / apagar ─────────────────────────────────────────────────────────
func _acender_tocha() -> void:
	if is_instance_valid(_chama_tocha):
		_chama_tocha.visible = true
	if is_instance_valid(_luz_tocha):
		var tw := create_tween()
		tw.tween_property(_luz_tocha, "light_energy", 3.5, 1.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _apagar_tocha() -> void:
	if is_instance_valid(_luz_tocha):
		var tw := create_tween()
		tw.tween_property(_luz_tocha, "light_energy", 0.0, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tw.finished
	if is_instance_valid(_chama_tocha):
		_chama_tocha.visible = false

# ─── Callbacks ────────────────────────────────────────────────────────────────
func _on_dia_iniciado(_onda_atual: int) -> void:
	if anim_player and anim_player.has_animation("transicao_para_dia"):
		anim_player.play("transicao_para_dia")
	_apagar_tocha()
	# Sol volta ao brilho total
	if is_instance_valid(_luz_dia):
		var tw := create_tween()
		tw.tween_property(_luz_dia, "light_energy", 1.5, 2.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Ambiente claro de dia
	if is_instance_valid(_ambiente) and _ambiente.environment:
		var tw_a := create_tween()
		tw_a.tween_property(_ambiente.environment, "ambient_light_energy",
			_ambient_energy_dia, 2.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_noite_iniciada(_onda_atual: int) -> void:
	if anim_player and anim_player.has_animation("transicao_para_noite"):
		anim_player.play("transicao_para_noite")
	_acender_tocha()
	# Sol vira luar fraco
	if is_instance_valid(_luz_dia):
		var tw := create_tween()
		tw.tween_property(_luz_dia, "light_energy", 0.12, 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Ambiente bem escuro de noite (fora da câmera fica quase preto)
	if is_instance_valid(_ambiente) and _ambiente.environment:
		var tw_a := create_tween()
		tw_a.tween_property(_ambiente.environment, "ambient_light_energy",
			_ambient_energy_dia * 0.15, 2.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_fase_vencida():
	if conquista_fim_Bruxa != null:
		Global.processar_recompensa(conquista_fim_Bruxa)
