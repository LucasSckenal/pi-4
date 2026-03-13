extends Resource
class_name CartaUpgrade

enum TipoUpgrade { DANO, MOEDA, VIDA, VELOCIDADE_ATAQUE, VELOCIDADE_INIMIGO, CUSTO_CONSTRUCAO, QUANTIDADE_INIMIGOS }

@export var id: String
@export var titulo: String
@export_multiline var descricao: String
@export var icone: Texture2D

@export_group("Efeito Positivo")
@export var tipo_bonus: TipoUpgrade
@export var valor_bonus: float

@export_group("Efeito Negativo (Debuff)")
@export var tipo_debuff: TipoUpgrade
@export var valor_debuff: float # Use 0 se não houver debuff
