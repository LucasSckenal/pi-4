extends Camera3D

@export var player: Node3D
var offset: Vector3

func _ready():
	# Salva a distância exata entre a câmera e o player no momento que o jogo abre
	if player:
		offset = global_position - player.global_position

func _process(delta):
	# Copia a posição do player e cola na câmera, mantendo a distância
	if player:
		global_position = player.global_position + offset
