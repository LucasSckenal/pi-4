extends Node3D

@export var vida_maxima: int = 100
var vida_atual: int

func _ready():
	# Aplica balanceamento centralizado (CSV)
	vida_maxima = Balanceamento.get_int("castelo_vida", vida_maxima)
	vida_atual = vida_maxima
	add_to_group("Castelo") # Garante que ele tem o crachá!

func recarregar_balanceamento() -> void:
	# Hot-reload F5: ajusta vida máxima sem matar o castelo
	var nova_vida = Balanceamento.get_int("castelo_vida", vida_maxima)
	if nova_vida != vida_maxima:
		var diff = nova_vida - vida_maxima
		vida_maxima = nova_vida
		vida_atual = clamp(vida_atual + diff, 1, vida_maxima)

func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print("O Castelo sofreu dano! Vida: ", vida_atual)
	
	if vida_atual <= 0:
		destruir_castelo()

func destruir_castelo():
	print("GAME OVER! O Castelo caiu!")
	# Aqui você pode recarregar a fase:
	get_tree().reload_current_scene()
