extends Node3D
# Cena de TESTE do barco fantasma (#15). Roda em loop: emerge → segura → submerge.
# Abra Maps/teste_barco.tscn e dê Play (F6) para ver a animação isolada.

@export var escala: float = 1.0          ## ajuste e rode de novo até o tamanho ficar bom
@export var profundidade: float = 8.0    ## de quão fundo (abaixo da água) ele emerge
@export var altura_paira: float = 1.2    ## quanto ele sobe acima da água
@export var duracao: float = 3.0         ## tempo da emersão (devagar)

var _barco: Node3D = null

func _ready() -> void:
	var cena = load("res://Map4/ship-ghost.glb")
	if cena == null:
		push_error("[TesteBarco] ship-ghost.glb não encontrado")
		return
	_barco = cena.instantiate()
	add_child(_barco)
	_barco.scale = Vector3.ONE * escala

	# Mede o tamanho do GLB (ajuda a saber a escala certa) e enquadra a câmera
	var aabb := _aabb_global(_barco)
	var tam: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if tam <= 0.01:
		tam = 4.0
	print("[TesteBarco] ship-ghost na escala %.2f → tamanho %s (maior lado %.2f)" % [escala, str(aabb.size), tam])

	var alvo := Vector3(0, altura_paira, 0)
	var cam: Camera3D = $Camera3D
	cam.global_position = alvo + Vector3(0, tam * 0.75, tam * 2.4)
	cam.look_at(alvo, Vector3.UP)

	# Balanço fantasmagórico contínuo
	var sway := _barco.create_tween().set_loops()
	sway.tween_property(_barco, "rotation:z", 0.05, 1.4).set_trans(Tween.TRANS_SINE)
	sway.tween_property(_barco, "rotation:z", -0.05, 1.4).set_trans(Tween.TRANS_SINE)

	_loop(alvo)

func _loop(alvo: Vector3) -> void:
	while is_inside_tree() and is_instance_valid(_barco):
		# Emerge das profundezas
		_barco.global_position = alvo - Vector3(0, profundidade, 0)
		var t1 := _barco.create_tween()
		t1.tween_property(_barco, "global_position", alvo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await t1.finished
		await get_tree().create_timer(1.5).timeout
		if not is_instance_valid(_barco):
			return
		# Submerge (simula o teleporte)
		var t2 := _barco.create_tween()
		t2.tween_property(_barco, "global_position", alvo - Vector3(0, profundidade, 0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await t2.finished
		await get_tree().create_timer(0.7).timeout

# União dos AABBs de todas as malhas, em espaço global
func _aabb_global(no: Node) -> AABB:
	var res := AABB()
	var primeiro := true
	for filho in no.find_children("*", "VisualInstance3D", true, false):
		var vi := filho as VisualInstance3D
		var ab: AABB = vi.global_transform * vi.get_aabb()
		if primeiro:
			res = ab
			primeiro = false
		else:
			res = res.merge(ab)
	return res
