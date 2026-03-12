extends Node3D

@export var lista_waves: Array[WaveData] = []
@export var label_wave: Label 

var wave_atual_idx: int = 0
var inimigos_restantes: int = 0
@onready var timer_spawn = $TimerSpawn

func _ready():
	atualizar_hud()
	await get_tree().create_timer(3.0).timeout
	iniciar_wave()

func iniciar_wave():
	if wave_atual_idx < lista_waves.size():
		var dados = lista_waves[wave_atual_idx]
		inimigos_restantes = dados.quantidade
		timer_spawn.wait_time = dados.intervalo
		atualizar_hud()
		timer_spawn.start()
	else:
		if label_wave: label_wave.text = "VITÓRIA!"

func _on_timer_spawn_timeout():
	if inimigos_restantes > 0:
		var dados = lista_waves[wave_atual_idx]
		var novo = dados.inimigo.instantiate()
		novo.global_position = global_position
		get_tree().current_scene.add_child(novo)
		inimigos_restantes -= 1
	else:
		timer_spawn.stop()
		_checar_limpeza()

func _checar_limpeza():
	while get_tree().get_nodes_in_group(&"inimigos").size() > 0:
		await get_tree().create_timer(1.0).timeout
	
	wave_atual_idx += 1
	if wave_atual_idx < lista_waves.size():
		if label_wave: label_wave.text = "PRÓXIMA ONDA EM 10s"
		await get_tree().create_timer(10.0).timeout
		iniciar_wave()

func atualizar_hud():
	if label_wave:
		label_wave.text = "Wave: " + str(wave_atual_idx + 1) + "/" + str(lista_waves.size())
