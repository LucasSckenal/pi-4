extends Node

signal dia_iniciado(onda_atual)
signal noite_iniciada(onda_atual)
signal onda_terminada

enum EstadoJogo { DIA, NOITE }
var estado_atual = EstadoJogo.DIA

# --- SISTEMA DE ECONOMIA ---
var moedas: int = 3 # Começa com 3 moedas como você pediu
var onda_atual: int = 1
var is_night: bool = false

func _process(_delta):
	if Input.is_action_just_pressed("passar_onda"): 
		if estado_atual == EstadoJogo.DIA:
			iniciar_noite()

func iniciar_dia():
	estado_atual = EstadoJogo.DIA
	is_night = false
	dia_iniciado.emit(onda_atual)

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	is_night = true
	noite_iniciada.emit(onda_atual)

func terminar_onda():
	if estado_atual == EstadoJogo.DIA: return 
	
	estado_atual = EstadoJogo.DIA
	is_night = false
	
	# --- NOVA LÓGICA DE DINHEIRO ---
	# Exemplo: Ganha 5 moedas base + 2 por cada onda que passou
	var bonus_vitoria = 3 + (onda_atual * 2) 
	
	# Se você quiser que seja APENAS o que as construções dão:
	# var bonus_vitoria = 0 (Aí você ganha só o das Minas/Casas)
	
	moedas += bonus_vitoria
	
	print("Onda ", onda_atual, " vencida! Bônus de vitória: ", bonus_vitoria)
	
	# O sinal abaixo faz as construções (Minas/Moinhos) pagarem o extra delas
	onda_terminada.emit() 
	
	onda_atual += 1
	iniciar_dia()
	
	# Atualiza o visual do Player
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("atualizar_hud"):
		player.atualizar_hud()
