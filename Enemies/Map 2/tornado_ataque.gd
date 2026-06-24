extends Node3D
class_name TornadoAtaque
# Projétil de tornado do Gênio: gira, viaja até o alvo (torre/base),
# dá dano ao chegar e se dissipa. Se o alvo morrer no caminho, dissipa também.

## Giro visual (graus/seg)
@export var velocidade_giro: float = 240.0
## Distância do alvo para considerar que "chegou" e aplicar o dano
@export var dist_acerto: float = 1.2

var _alvo: Node3D = null
var _dano: int = 0
var _vel: float = 7.0
var _ativo: bool = false


# Chamado pelo Gênio ao lançar.
func iniciar(alvo: Node3D, dano: int, vel: float) -> void:
	_alvo = alvo
	_dano = dano
	_vel = vel
	_ativo = true


func _process(delta: float) -> void:
	# gira sempre (efeito de rodopio)
	rotate_y(deg_to_rad(velocidade_giro) * delta)

	if not _ativo:
		return

	# alvo sumiu/destruído no caminho → dissipa sem dano
	if _alvo == null or not is_instance_valid(_alvo) or (_alvo.get("esta_destruida") == true):
		_dissipar()
		return

	# viaja em direção ao alvo
	var destino: Vector3 = _alvo.global_position
	var dir: Vector3 = global_position.direction_to(destino)
	global_position += dir * _vel * delta

	# chegou perto o suficiente → dano e some
	if global_position.distance_to(destino) <= dist_acerto:
		_acertar()


func _acertar() -> void:
	_ativo = false
	if _alvo and is_instance_valid(_alvo) and _alvo.has_method("receber_dano"):
		_alvo.receber_dano(_dano)
	_dissipar()


# Encolhe e se remove.
func _dissipar() -> void:
	_ativo = false
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(queue_free)
