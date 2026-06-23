extends Node3D
# Controlador do barco do boss — anexado ao "ship-ghost2" no mapa do pirata.
# Fica ESCONDIDO até a wave do boss.
#  • 1ª aparição: CHEGA NAVEGANDO (desliza pela água) e PARA na posição inicial
#    do barco no mapa (onde você o deixou no editor).
#  • Teleportes (boss troca de rota): SURGE das profundezas no Marker3D
#    (grupo "MarcaBarco") mais próximo do boss. Sem marcadores → perto do boss.

## Tempo da navegação da 1ª chegada
@export var duracao_navegacao: float = 4.0
## De onde ele começa a navegar na 1ª chegada (offset da posição inicial do barco).
## Ajuste para ele vir da água aberta / fora da tela e deslizar até o ponto.
@export var offset_chegada: Vector3 = Vector3(0, 0, 20)
## De quão fundo (abaixo) ele emerge nos teleportes
@export var profundidade: float = 8.0
## Tempo da emersão (teleportes)
@export var duracao_surgir: float = 3.0

var _pos_base: Vector3
var _tw: Tween = null

func _ready() -> void:
	add_to_group("BarcoBoss")
	_pos_base = global_position
	visible = false   # só aparece quando o boss chama aparecer()

# 1ª aparição: começa no ponto de partida e NAVEGA até a posição inicial do barco.
# Ponto de partida = Marker3D no grupo "InicioBarco" (arraste no editor). Sem ele, usa offset_chegada.
func aparecer(_boss_pos: Vector3) -> void:
	var inicio := _pos_base + offset_chegada
	var pontos := get_tree().get_nodes_in_group("InicioBarco")
	if pontos.size() > 0 and pontos[0] is Node3D:
		inicio = (pontos[0] as Node3D).global_position
	global_position = inicio
	visible = true
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "global_position", _pos_base, duracao_navegacao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Teleportes: SURGE das profundezas no mark mais próximo do boss.
func ir_para(boss_pos: Vector3) -> void:
	var destino := _destino_para(boss_pos)
	visible = true
	if _tw and _tw.is_valid():
		_tw.kill()
	global_position = destino - Vector3(0, profundidade, 0)
	_tw = create_tween()
	_tw.tween_property(self, "global_position", destino, duracao_surgir).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Marker3D (grupo "MarcaBarco") mais próximo do boss; senão, perto do boss no nível do barco.
func _destino_para(boss_pos: Vector3) -> Vector3:
	var marcas := get_tree().get_nodes_in_group("MarcaBarco")
	var melhor := Vector3(boss_pos.x, _pos_base.y, boss_pos.z)
	var menor := INF
	for m in marcas:
		if m is Node3D:
			var d: float = (m as Node3D).global_position.distance_to(boss_pos)
			if d < menor:
				menor = d
				melhor = (m as Node3D).global_position
	print("[BarcoBoss] marcas no grupo 'MarcaBarco': %d | destino do barco: %s" % [marcas.size(), str(melhor)])
	return melhor
