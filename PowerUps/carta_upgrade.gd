extends Resource
class_name CartaUpgrade

enum TipoUpgrade { DANO, MOEDA, VIDA, VELOCIDADE_ATAQUE, VELOCIDADE_INIMIGO, CUSTO_CONSTRUCAO, QUANTIDADE_INIMIGOS, ALCANCE, RICOCHETE, INFLAMAVEL, ESPINHO, DANO_CHEFE, OURO_ABATE, EXPLOSAO_CONSTRUCAO, RENDA_CONSTRUCAO, CRITICO, DANO_AEREO, EXECUCAO, OURO_INICIAL, REROLL_GRATIS, EXPLOSAO_INIMIGO, SOLDADO_FORTE, VENENO, VIDA_TORRES, MAIS_SOLDADOS, DANO_CRESCENTE, ONDA_PERFEITA, PRIMEIRA_GRATIS, BASE_ATIRADORA }

@export var id: String
@export var titulo: String
@export_multiline var descricao: String
@export var icone: Texture2D

@export_group("Efeito Positivo")
@export var tipo_bonus: TipoUpgrade
@export var valor_bonus: float

@export_group("Efeito Bônus 2 (opcional — cartas combo)")
@export var tipo_bonus_2: TipoUpgrade
@export var valor_bonus_2: float = 0.0 # Use 0 se a carta tiver só um efeito

@export_group("Efeito Negativo (Debuff)")
@export var tipo_debuff: TipoUpgrade
@export var valor_debuff: float # Use 0 se não houver debuff
