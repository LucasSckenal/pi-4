extends Node3D

@export var lista_waves: Array[WaveData] = []
@export var label_wave: Label 
@export var bonus_vitoria: int = 50

var wave_atual_idx: int = 0
var inimigos_restantes: int = 0
var spawning_ativa: bool = false

@onready var timer_spawn = $TimerSpawn

func _ready():
	add_to_group("Spawner")
	atualizar_hud()
	# CONEXÃO: Quando o GameManager avisar que é noite, o Spawner começa
	GameManager.noite_iniciada.connect(_ao_receber_noite)

func _ao_receber_noite(_numero_onda):
	iniciar_horda()

func iniciar_horda():
	if wave_atual_idx >= lista_waves.size(): return
	
	var dados = lista_waves[wave_atual_idx]
	inimigos_restantes = dados.quantidade
	timer_spawn.wait_time = dados.intervalo
	spawning_ativa = true
	
	# Avisa o Sol (DirectionalLight3D)
	var sol = get_tree().get_first_node_in_group("Sol")
	if sol: sol.mudar_para_noite()
	
	timer_spawn.start()
	atualizar_hud()

func _on_timer_spawn_timeout():
	if inimigos_restantes > 0:
		var dados = lista_waves[wave_atual_idx]
		if dados.inimigo:
			var novo = dados.inimigo.instantiate()
			novo.global_position = global_position
			get_tree().current_scene.add_child(novo)
		inimigos_restantes -= 1
	else:
		timer_spawn.stop()
		spawning_ativa = false
		_checar_limpeza_do_mapa()

func _checar_limpeza_do_mapa():
	# Espera os inimigos morrerem
	while get_tree().get_nodes_in_group("inimigos").size() > 0:
		await get_tree().create_timer(1.0).timeout
	
	# Amanhecer
	var sol = get_tree().get_first_node_in_group("Sol")
	if sol: sol.mudar_para_dia()
	
	# Bônus ao Player
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.moedas += bonus_vitoria
		if player.has_method("atualizar_hud"): player.atualizar_hud()
	
	wave_atual_idx += 1
	# Avisa o GameManager para voltar ao estado de DIA
	GameManager.terminar_onda()

func atualizar_hud():
	if label_wave:
		label_wave.text = "Wave: " + str(wave_atual_idx + 1) + " / " + str(lista_waves.size())
