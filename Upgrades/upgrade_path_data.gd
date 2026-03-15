extends Resource
class_name UpgradePathData

# Nome do caminho (ex: "Caminho de Fogo")
@export var nome: String = "Caminho"

# Ícone que aparecerá no botão de escolha
@export var icone: Texture2D

# Arrays de melhorias por nível (índice 0 = nível 1, índice 1 = nível 2, etc.)
@export var custos: Array[int] = []
@export var dano_por_nivel: Array[int] = []
@export var moedas_por_nivel: Array[int] = []
@export var aliados_por_nivel: Array[int] = []
@export var velocidade_por_nivel: Array[float] = []  # Redução no tempo de ataque
@export var alcance_por_nivel: Array[float] = []
@export var vida_por_nivel: Array[int] = []
@export var modelos_por_nivel: Array[PackedScene] = []  # Modelos 3D para cada nível
