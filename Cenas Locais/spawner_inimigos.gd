extends Node3D

signal informacao_proxima_onda(direcao: String, quantidade: int)

@export var lista_waves: Array[WaveData] = []
@export var label_wave: Label 
@export var direcao_spawn: String = "Norte"  # Ajuste no inspetor

var wave_atual_idx: int = 0
var inimigos_restantes: int = 0
var spawning_ativa: bool = false

@onready var timer_spawn = $TimerSpawn

func _ready():
	add_to_group("Spawner")
	GameManager.noite_iniciada.connect(_ao_receber_noite)
	atualizar_hud()
	_emitir_informacao_proxima_onda()  # Mostra a primeira onda

func _ao_receber_noite(_n):
	if wave_atual_idx >= lista_waves.size() or spawning_ativa: return
	
	var dados = lista_waves[wave_atual_idx]
	inimigos_restantes = dados.quantidade
	timer_spawn.wait_time = dados.intervalo
	spawning_ativa = true
	
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
	while get_tree().get_nodes_in_group("inimigos").size() > 0:
		await get_tree().create_timer(1.0).timeout
	
	var sol = get_tree().get_first_node_in_group("Sol")
	if sol: sol.mudar_para_dia()
	
	wave_atual_idx += 1
	GameManager.terminar_onda()
	atualizar_hud()
	_emitir_informacao_proxima_onda()  # Atualiza para a próxima onda

func atualizar_hud():
	if label_wave:
		label_wave.text = "Wave: " + str(wave_atual_idx + 1)

func _emitir_informacao_proxima_onda():
	var proxima_onda = wave_atual_idx
	if proxima_onda < lista_waves.size():
		var dados = lista_waves[proxima_onda]
		informacao_proxima_onda.emit(direcao_spawn, dados.quantidade)
	else:
		# Se não houver mais ondas, emite 0 para indicar fim
		informacao_proxima_onda.emit(direcao_spawn, 0)
