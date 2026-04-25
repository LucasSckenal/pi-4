extends Node3D

@export var custo_moedas: int = 5 
@export var moedas_por_onda: int = 3 # Quanto a mina/casa paga no fim do turno

# =========================================================
# NOVO: TRAVA CONTRA FANTASMAS (Evita dinheiro grátis)
# =========================================================
var is_fantasma: bool = false 

# =========================================================
# SISTEMA DE VIDA
# =========================================================
@export var vida_maxima: int = 20
var vida_atual: int

func _ready():
	# A TRAVA: Se for só o holograma do BuildSlot, para o código aqui e não faz mais nada!
	if is_fantasma == true:
		return

	# Aplica balanceamento centralizado (CSV)
	_aplicar_balanceamento()

	# 1. Quando a construção REAL é feita, a vida começa no máximo
	vida_atual = vida_maxima

	# 2. Fica à escuta do GameManager para o fim da onda (O fantasma nunca chega aqui)
	GameManager.onda_terminada.connect(_pagar_recompensa)

func _aplicar_balanceamento() -> void:
	custo_moedas    = Balanceamento.get_int("mina_custo", custo_moedas)
	moedas_por_onda = Balanceamento.get_int("mina_renda_onda", moedas_por_onda)
	vida_maxima     = Balanceamento.get_int("mina_vida", vida_maxima)

func recarregar_balanceamento() -> void:
	_aplicar_balanceamento()

# =========================================================
# SISTEMA DE PAGAMENTO 
# =========================================================
func _pagar_recompensa():
	# Agora procura o jogador apenas na hora de pagar!
	var player_ref = get_tree().get_first_node_in_group("Player")
	
	if player_ref != null:
		player_ref.moedas += moedas_por_onda
		
		# Atualiza o texto na cabeça do jogador
		if player_ref.has_method("atualizar_hud"):
			player_ref.atualizar_hud()
			
		print("A construção gerou ", moedas_por_onda, " moedas!")
	else:
		print("ERRO: Jogador não encontrado! Confirma se o grupo se chama mesmo 'Player'.")

# =========================================================
# FUNÇÃO PARA SOFRER DANO DOS INIMIGOS
# =========================================================
func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print("A construção sofreu ", quantidade, " de dano! Vida: ", vida_atual)
	
	if vida_atual <= 0:
		destruir_construcao()

func destruir_construcao():
	print("A construção foi destruída!")
	# O queue_free() apaga o objeto do jogo. 
	queue_free()

# =========================================================
# O TEU SISTEMA DE TRANSPARÊNCIA (Intacto!)
# =========================================================
func _on_area_3d_body_entered(body):
	if body.name == "Player":
		mudar_transparencia(self, 0.75) 

func _on_area_3d_body_exited(body):
	if body.name == "Player":
		mudar_transparencia(self, 0.0)

func mudar_transparencia(no_atual: Node, valor: float):
	if no_atual is MeshInstance3D:
		no_atual.transparency = valor
		
	for filho in no_atual.get_children():
		mudar_transparencia(filho, valor)
