extends Resource
class_name UpgradePathData

# Nome do caminho (ex: "Caminho de Fogo")
@export var nome: String = "Caminho"

# Ícone que aparecerá no botão de escolha
@export var icone: Texture2D

# Fase mínima para esta opção aparecer (0 = sem restrição)
@export var fase_minima: int = 0

# Fase máxima para esta opção aparecer (0 = sem limite superior)
# Ex.: Tesla com fase_minima=5 e fase_maxima=5 só aparece no Mapa 5
@export var fase_maxima: int = 0

# Tipo de ataque especial ("chain_lightning" = Tesla; "" = ataque normal com flecha)
@export var tipo_ataque: String = ""

# Arrays de melhorias por nível (índice 0 = nível 1, índice 1 = nível 2, etc.)
@export var custos: Array[int] = []
@export var dano_por_nivel: Array[int] = []
@export var moedas_por_nivel: Array[int] = []
@export var aliados_por_nivel: Array[int] = []
@export var velocidade_por_nivel: Array[float] = []  # Redução no tempo de ataque
@export var alcance_por_nivel: Array[float] = []
@export var vida_por_nivel: Array[int] = []
@export var modelos_por_nivel: Array[PackedScene] = []  # Modelos 3D para cada nível
