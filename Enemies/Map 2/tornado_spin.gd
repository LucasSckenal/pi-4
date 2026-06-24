extends Node3D
## Gira o tornado continuamente (efeito de rodopio do Genio).
## O modelo do tornado já vem do Blender; aqui só aplicamos a rotação infinita.

## Velocidade de giro em graus por segundo.
@export var velocidade_giro: float = 220.0

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(velocidade_giro) * delta)
