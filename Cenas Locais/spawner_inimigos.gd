extends Node3D

@export var lista_waves: Array[WaveData] = []
@export var label_wave: Label 

var wave_atual_idx: int = 0
var inimigos_restantes: int = 0
var spawning_ativa: bool = false

@onready var timer_spawn = $TimerSpawn

func _ready():
	add_to_group("Spawner")
	GameManager.noite_iniciada.connect(_ao_receber_noite)
	atualizar_hud()

func _ao_receber_noite(_n):
	if wave_atual_idx >= lista_waves.size() or spawning_ativa: return
	
	var dados = lista_waves[wave_atual_idx]
	inimigos_restantes = dados.quantidade
	timer_spawn.wait_time = dados.intervalo
	spawning_ativa = true
	
	# Escurece o Sol
	var sol = get_tree().get_first_node_in_group("Sol")
	if sol: sol.mudar_para_noite()
	
	timer_spawn.start()

func _on_timer_spawn_timeout():
	if inimigos_restantes > 0:
		_spawn_orc()
		inimigos_restantes -= 1
	else:
		timer_spawn.stop()
		spawning_ativa = false
		_esperar_limpeza()

func _spawn_orc():
	var dados = lista_waves[wave_atual_idx]
	if dados.inimigo:
		var novo = dados.inimigo.instantiate()
		novo.global_position = global_position
		get_tree().current_scene.add_child(novo)

func _esperar_limpeza():
	# Loop de verificação
	while get_tree().get_nodes_in_group("inimigos").size() > 0:
		await get_tree().create_timer(1.0).timeout
	
	# Amanhecer
	var sol = get_tree().get_first_node_in_group("Sol")
	if sol: sol.mudar_para_dia()
	
	# AVISA O BOSS (GameManager) QUE ACABOU
	# Ele vai dar o dinheiro e mudar para o Dia uma única vez
	wave_atual_idx += 1
	GameManager.terminar_onda()
	atualizar_hud()

func atualizar_hud():
	if label_wave:
		label_wave.text = "Wave: " + str(wave_atual_idx + 1)
