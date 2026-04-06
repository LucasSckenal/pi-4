extends Node3D

signal info_proxima_onda(direcao: String, inimigos: Array, posicao: Vector3)

@export var ondas: Array[WaveData] = []
@export var label_wave: Label

var onda_atual: int = 0
var fila_inimigos: Array[PackedScene] = []
var inimigos_restantes: int = 0
var spawning: bool = false

@onready var timer = $TimerSpawn
@onready var base = get_tree().get_first_node_in_group("Base")

func _ready():
	add_to_group("Spawner")
	GameManager.noite_iniciada.connect(_iniciar_noite)
	timer.timeout.connect(_on_timer_timeout)
	emitir_info()

func _iniciar_noite(_n):
	if onda_atual >= ondas.size() or spawning:
		return
	
	var onda = ondas[onda_atual]
	if onda == null:
		print("ERRO: Onda ", onda_atual, " é null em ", name)
		return
	
	fila_inimigos.clear()
	for config in onda.inimigos:
		if config == null:
			print("ERRO: Config de inimigo null na onda ", onda_atual)
			continue
		for i in range(config.quantidade):
			fila_inimigos.append(config.cena)
	
	inimigos_restantes = fila_inimigos.size()
	print(name, " iniciando noite com ", inimigos_restantes, " inimigos")
	
	if inimigos_restantes == 0:
		_finalizar_onda()
		return
	
	spawning = true
	timer.start(onda.intervalo)

func _on_timer_timeout():
	if not spawning:
		return
	
	if inimigos_restantes > 0:
		_spawnar_proximo()
	else:
		timer.stop()
		spawning = false
		await get_tree().create_timer(0.5).timeout
		_esperar_limpeza()

func _spawnar_proximo():
	if fila_inimigos.size() == 0:
		return
	
	var cena = fila_inimigos.pop_front()
	if cena == null:
		print("ERRO: cena de inimigo null em ", name)
		return
	
	if not is_inside_tree():
		print("Spawner ", name, " não está na árvore. Cancelando spawn.")
		return
	
	var inimigo = cena.instantiate()
	get_tree().current_scene.add_child(inimigo)
	inimigo.global_position = global_position
	inimigos_restantes -= 1
	print(name, " spawnou inimigo. Restam na fila: ", fila_inimigos.size())

func _esperar_limpeza():
	while get_tree().get_nodes_in_group("inimigos").size() > 0:
		await get_tree().create_timer(1.0).timeout
	_finalizar_onda()

func _finalizar_onda():
	print(name, " finalizando onda. Próxima onda: ", onda_atual + 1)
	onda_atual += 1
	
	# EM VEZ DE: GameManager.terminar_onda()
	# AGORA USAMOS A NOVA FUNÇÃO:
	GameManager.registrar_spawner_concluido()
	
	emitir_info()

func emitir_info():
	if onda_atual >= ondas.size():
		info_proxima_onda.emit("", [], global_position)
		return
	
	var onda = ondas[onda_atual]
	if onda == null:
		info_proxima_onda.emit("", [], global_position)
		return
	
	var info = []
	for config in onda.inimigos:
		if config == null:
			continue
		info.append({
			"icone": config.icone,
			"cor": config.cor,
			"qtd": config.quantidade
		})
	var dir = _calcular_direcao()
	info_proxima_onda.emit(dir, info, global_position)

func _calcular_direcao() -> String:
	if not base:
		return "?"
	var diff = global_position - base.global_position
	var ang = atan2(diff.x, diff.z)
	if abs(ang) < 0.785:
		return "Norte"
	elif ang >= 0.785 and ang < 2.356:
		return "Leste"
	elif ang <= -0.785 and ang > -2.356:
		return "Oeste"
	else:
		return "Sul"
