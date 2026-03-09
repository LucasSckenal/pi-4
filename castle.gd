extends Node3D

@export var vida_maxima: int = 100
var vida_atual: int

func _ready():
	vida_atual = vida_maxima
	add_to_group("Castelo") # Garante que ele tem o crachá!

func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print("O Castelo sofreu dano! Vida: ", vida_atual)
	
	if vida_atual <= 0:
		destruir_castelo()

func destruir_castelo():
	print("GAME OVER! O Castelo caiu!")
	# Aqui você pode recarregar a fase:
	get_tree().reload_current_scene()
