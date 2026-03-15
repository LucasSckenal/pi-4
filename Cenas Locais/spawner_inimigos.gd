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
	if GameManager.has_signal("noite_iniciada"):
		GameManager.noite_iniciada.connect(_iniciar_noite)
		print(name, " conectado ao GameManager")
	else:
		print("ERRO: GameManager não tem sinal noite_iniciada")
	
	timer.timeout.connect(_on_timer_timeout)
	emitir_info()

func _iniciar_noite(_n):
	print(name, " recebeu noite_iniciada")
	if onda_atual >= ondas.size():
		print(name, " onda_atual >= ondas.size()")
		return
	if spawning:
		print(name, " já está spawning")
		return
	
	var onda = ondas[onda_atual]
	print(name, " onda atual: ", onda.nome_da_onda, " com ", onda.inimigos.size(), " tipos")
	
	fila_inimigos.clear()
	for config in onda.inimigos:
		for i in range(config.quantidade):
			if config.cena == null:
				print("ERRO: config.cena é null para ", config)
			else:
				fila_inimigos.append(config.cena)
	
	inimigos_restantes = fila_inimigos.size()
	print(name, " fila de inimigos criada com ", inimigos_restantes, " inimigos")
	spawning = true
	timer.start(onda.intervalo)
	print(name, " timer iniciado com intervalo ", onda.intervalo)

func _on_timer_timeout():
	print(name, " timer timeout. inimigos_restantes: ", inimigos_restantes)
	if inimigos_restantes > 0:
		_spawnar_proximo()
	else:
		timer.stop()
		spawning = false
		print(name, " spawn concluído, aguardando limpeza")
		await get_tree().create_timer(0.5).timeout
		while get_tree().get_nodes_in_group("inimigos").size() > 0:
			await get_tree().create_timer(1.0).timeout
			print(name, " aguardando... inimigos restantes: ", get_tree().get_nodes_in_group("inimigos").size())
		
		onda_atual += 1
		print(name, " onda avançada para ", onda_atual)
		GameManager.terminar_onda()
		emitir_info()

func _spawnar_proximo():
	if fila_inimigos.size() == 0:
		print(name, " fila vazia ao tentar spawnar")
		return
	var cena = fila_inimigos.pop_front()
	if cena == null:
		print("ERRO: cena de inimigo é null em ", name)
		return
	var inimigo = cena.instantiate()
	inimigo.global_position = global_position
	get_tree().current_scene.add_child(inimigo)
	print(name, " spawnou inimigo. Restam na fila: ", fila_inimigos.size())

func emitir_info():
	if onda_atual >= ondas.size():
		print(name, " sem mais ondas")
		info_proxima_onda.emit("", [])
		return
	
	var onda = ondas[onda_atual]
	var info = []
	for config in onda.inimigos:
		info.append({
		"icone": config.icone,
		"qtd": config.quantidade,
		"cor": config.cor  # opcional, fallback
		})
	var dir = _calcular_direcao()
	print(name, " emitindo info: dir=", dir, " info=", info)
	info_proxima_onda.emit(dir, info, global_position)

func _calcular_direcao() -> String:
	if not base:
		print(name, " base não encontrada")
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
