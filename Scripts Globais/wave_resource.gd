extends Resource
class_name WaveData # Isso faz a mágica aparecer no Inspetor!

@export var nome_da_onda: String = "Onda"
@export var quantidade: int = 5
@export var intervalo: float = 2.0
@export var inimigo: PackedScene
