extends Node

signal dia_iniciado(onda_atual)
signal noite_iniciada(onda_atual)
signal onda_terminada

enum EstadoJogo { DIA, NOITE }

var estado_atual = EstadoJogo.DIA
var onda_atual = 1
var is_night: bool = false # Resolve o erro de atribuição

func _process(_delta):
	if Input.is_action_just_pressed("passar_onda"): 
		if estado_atual == EstadoJogo.DIA:
			iniciar_noite()
		else:
			# Opcional: permitir pular a noite manualmente
			terminar_onda()

func iniciar_dia():
	estado_atual = EstadoJogo.DIA
	is_night = false
	print("--- DIA ", onda_atual, " ---")
	dia_iniciado.emit(onda_atual)

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	is_night = true
	print("--- NOITE ", onda_atual, " ---")
	noite_iniciada.emit(onda_atual)

func terminar_onda():
	print("Onda terminada! Distribuindo lucros...")
	onda_terminada.emit()
	onda_atual += 1
	iniciar_dia()
