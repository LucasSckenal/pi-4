extends Node

signal onda_terminada

func _process(_delta):
	if Input.is_action_just_pressed("passar_onda"): 
		terminar_onda()

func terminar_onda():
	print("A onda terminou! A distribuir os lucros...")
	onda_terminada.emit()
