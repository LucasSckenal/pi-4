extends Node3D
# Controlador do barco do boss (anexado ao "ship-ghost2").
# Animações do AnimationPlayer da CENA (posição FIXA no dock):
#   ShipArrival = Aparecendo | Ship = Aparecido (idle) | ShipVanish = Sumindo | ShipLess = Ausente
# Fluxo:
#   • 1ª wave do boss: Aparecendo → idle (no dock).
#   • Teleporte (boss troca de rota): vai por TWEEN até o Marker3D mais próximo
#     (grupo "MarcaBarco"), assumindo a ROTAÇÃO do mark, emergindo das profundezas.
#   • Derrota: no dock usa Sumindo; se estiver num mark, afunda no lugar.

@export var anim_entrada: String = "ShipArrival"   # Aparecendo
@export var anim_idle: String = "Ship"             # Aparecido (loop)
@export var anim_sumir: String = "ShipVanish"      # Sumindo (derrota no dock)
@export var anim_ausente: String = "ShipLess"      # Ausente (escondido)
## Profundidade da emersão/afundamento quando está num mark
@export var profundidade: float = 8.0
## Tempo da emersão no mark
@export var duracao_surgir: float = 3.0

var _ap: AnimationPlayer = null
var _tw: Tween = null
var _em_mark: bool = false

func _ready() -> void:
	add_to_group("BarcoBoss")
	_ap = _achar_ap()
	if _ap and _ap.has_animation(anim_ausente):
		_ap.play(anim_ausente)
	else:
		visible = false

# 1ª aparição (no dock): animação de entrada → idle.
func aparecer(_boss_pos: Vector3 = Vector3.ZERO) -> void:
	_em_mark = false
	visible = true
	if _ap == null:
		_ap = _achar_ap()
	if _ap and _ap.has_animation(anim_entrada):
		if not _ap.animation_finished.is_connected(_ao_terminar):
			_ap.animation_finished.connect(_ao_terminar)
		_ap.play(anim_entrada)

func _ao_terminar(nome: StringName) -> void:
	if String(nome) == anim_entrada and not _em_mark and _ap and _ap.has_animation(anim_idle):
		_ap.play(anim_idle)

# Teleporte: TWEEN até o mark mais próximo do boss, com a rotação do mark, emergindo.
func ir_para(boss_pos: Vector3) -> void:
	_em_mark = true
	_parar_ap()   # tira o AnimationPlayer do controle (ele é fixo no dock)
	visible = true
	var mark := _mark_mais_proximo(boss_pos)
	var destino := global_position
	if mark != null:
		destino = mark.global_position
		global_rotation = mark.global_rotation   # gira igual ao Marker3D
	if _tw and _tw.is_valid():
		_tw.kill()
	global_position = destino - Vector3(0, profundidade, 0)
	_tw = create_tween()
	_tw.tween_property(self, "global_position", destino, duracao_surgir).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Derrota do chefe.
func derrota() -> void:
	if _em_mark:
		# Num mark: afunda no lugar (a animação ShipVanish é fixa no dock).
		_parar_ap()
		if _tw and _tw.is_valid():
			_tw.kill()
		_tw = create_tween()
		_tw.tween_property(self, "global_position", global_position - Vector3(0, profundidade, 0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tw.tween_callback(func(): visible = false)
	elif _ap and _ap.has_animation(anim_sumir):
		_ap.play(anim_sumir)   # No dock: usa a animação Sumindo

func _parar_ap() -> void:
	if _ap and _ap.is_playing():
		_ap.stop()

func _mark_mais_proximo(boss_pos: Vector3) -> Node3D:
	var melhor: Node3D = null
	var menor := INF
	for m in get_tree().get_nodes_in_group("MarcaBarco"):
		if m is Node3D:
			var d: float = (m as Node3D).global_position.distance_to(boss_pos)
			if d < menor:
				menor = d
				melhor = m as Node3D
	print("[BarcoBoss] mark mais próximo: %s" % (melhor.name if melhor else "(nenhum)"))
	return melhor

func _achar_ap() -> AnimationPlayer:
	var raiz := get_tree().current_scene
	if raiz == null:
		return null
	for n in raiz.find_children("*", "AnimationPlayer", true, false):
		var a := n as AnimationPlayer
		if a != null and a.has_animation(anim_entrada):
			return a
	return null
