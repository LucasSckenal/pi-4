extends Camera3D

# Velocidade que a câmera vai girar (ajuste como preferir)
@export var velocidade_giro: float = 0.05

func _process(delta: float) -> void:
	# Faz a câmera girar suavemente no eixo Y (para os lados) sem parar
	rotation.y += velocidade_giro * delta
