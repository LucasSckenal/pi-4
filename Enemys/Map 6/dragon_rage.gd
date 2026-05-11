extends InimigoBase
class_name DragonRage

@export_category("Rage")
@export_range(0.05, 0.95, 0.05) var rage_hp_gatilho: float = 0.5
@export var rage_velocidade_mult: float = 1.7
@export var rage_dano_mult: float = 1.2
@export var rage_animacao: String = ""
@export var rage_anim_andar: String = ""
@export var rage_duracao_preparacao: float = 1.0
@export var rage_pausar_movimento: bool = true

var rage_ativado: bool = false
var _velocidade_base: float = 0.0
var _dano_base: int = 0
var _anim_andar_base: String = ""
var _preparando_rage: bool = false

func _ready() -> void:
	super._ready()
	_velocidade_base = velocidade
	_dano_base = forca_dano
	_anim_andar_base = anim_andar

func receber_dano(qtd, origem = "torre") -> void:
	super.receber_dano(qtd, origem)
	if rage_ativado or esta_morto:
		return
	if vida_maxima <= 0:
		return

	var porcentagem_vida: float = float(vida_atual) / float(vida_maxima)
	if porcentagem_vida <= rage_hp_gatilho:
		_ativar_rage()

func _physics_process(delta: float) -> void:
	if _preparando_rage:
		if not is_on_floor():
			velocity.y -= gravity * delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	super._physics_process(delta)

func _ativar_rage() -> void:
	if rage_ativado:
		return

	rage_ativado = true
	call_deferred("_executar_rage")

func _executar_rage() -> void:
	if esta_morto:
		return

	var podia_atacar: bool = pode_atacar
	if rage_pausar_movimento:
		_preparando_rage = true
		pode_atacar = false
		velocity = Vector3.ZERO

	var anim_preparacao: String = rage_animacao if rage_animacao != "" else anim_atacar
	if animation_player and animation_player.has_animation(anim_preparacao):
		animation_player.play(anim_preparacao)

	if rage_duracao_preparacao > 0.0:
		await get_tree().create_timer(rage_duracao_preparacao).timeout

	if esta_morto:
		_preparando_rage = false
		return

	velocidade = _velocidade_base * rage_velocidade_mult
	forca_dano = max(1, int(round(float(_dano_base) * rage_dano_mult)))

	if rage_anim_andar != "":
		anim_andar = rage_anim_andar
	elif _anim_andar_base != "":
		anim_andar = _anim_andar_base

	if animation_player and animation_player.has_animation(anim_andar):
		animation_player.play(anim_andar)

	if rage_pausar_movimento:
		_preparando_rage = false
		pode_atacar = podia_atacar
