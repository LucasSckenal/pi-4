extends CharacterBody3D

@export var velocidade: float = 3.0
@export var distancia_de_ataque: float = 2.5 # Ajuste se ele estiver a parar muito longe ou muito perto das casas

# --- NOVO: Variáveis de Vida ---
@export var vida_maxima: int = 100
var vida_atual: int = 100

var gravidade = ProjectSettings.get_setting("physics/3d/default_gravity")
var alvo_atual: Node3D = null

# Puxa o nó de GPS que criámos na cena do Orc
@onready var nav_agent = $NavigationAgent3D

func _ready():
	# Garante que o Orc começa com a vida cheia
	vida_atual = vida_maxima
	add_to_group("inimigos")

func _physics_process(delta):
	# 1. Aplica a gravidade para o Orc não voar
	if not is_on_floor():
		velocity.y -= gravidade * delta

	# 2. Verifica se precisa de um novo alvo (se o atual foi destruído ou não existe)
	if alvo_atual == null or not is_instance_valid(alvo_atual):
		alvo_atual = procurar_novo_alvo()

	# 3. Movimento Inteligente com o GPS (NavMesh)
	if alvo_atual != null:
		# Passa o endereço final do alvo para o GPS do Orc
		nav_agent.target_position = alvo_atual.global_position
		
		# Calcula a distância real em linha reta até ao alvo
		var distancia_ate_alvo = global_position.distance_to(alvo_atual.global_position)
		
		# Se o Orc ainda está longe da casa/castelo...
		if distancia_ate_alvo > distancia_de_ataque:
			# Pergunta ao GPS qual é o próximo passo para desviar das paredes e obstáculos
			var proximo_passo = nav_agent.get_next_path_position()
			
			# Calcula a direção para esse próximo passo
			var direcao = global_position.direction_to(proximo_passo)
			direcao.y = 0 # Mantém o Orc reto, sem tentar olhar para o chão/céu
			direcao = direcao.normalized()
			
			# Gira o corpo do Orc suavemente para a direção do movimento
			if direcao.length() > 0.01:
				look_at(global_position + direcao, Vector3.UP)
			
			# Faz as pernas andarem
			velocity.x = direcao.x * velocidade
			velocity.z = direcao.z * velocidade
			
			# (FUTURO: Aqui vai o AnimationPlayer.play("walk"))
			
		else:
			# Chegou perto o suficiente para atacar!
			velocity.x = 0
			velocity.z = 0
			
			# (FUTURO: Aqui vai o AnimationPlayer.play("attack") e o código de dar dano)
	else:
		# Se não tem alvo nenhum no mapa inteiro, ele fica parado
		velocity.x = 0
		velocity.z = 0

	# Aplica a física no Godot
	move_and_slide()


# ==========================================
# O CÉREBRO DO ORC (SISTEMA DE FARO)
# ==========================================
func procurar_novo_alvo() -> Node3D:
	var construcoes_vivas = get_tree().get_nodes_in_group("Construcao")
	
	# Se existem casas/torres/minas pelo mapa, ele acha a mais próxima
	if construcoes_vivas.size() > 0:
		var alvo_mais_proximo = null
		var menor_distancia = 999999.0 # Começa com um número gigante
		
		for construcao in construcoes_vivas:
			# Ignora os fantasmas do modo de construção
			if "is_fantasma" in construcao and construcao.is_fantasma == true:
				continue
				
			var dist = global_position.distance_to(construcao.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				alvo_mais_proximo = construcao
				
		# Retorna a construção real mais próxima que encontrou
		if alvo_mais_proximo != null:
			return alvo_mais_proximo
			
	# Se o código chegou até aqui, é porque TODAS as construções caíram.
	# A prioridade máxima agora é o Castelo!
	var castelo = get_tree().get_first_node_in_group("Castelo")
	if castelo != null:
		return castelo
		
	# Se não tem construções e não tem castelo, retorna nulo (ele fica parado)
	return null

# ==========================================
# SISTEMA DE VIDA E DANO
# ==========================================
func receber_dano(dano_sofrido: int):
	vida_atual -= dano_sofrido
	print("Orc sofreu ", dano_sofrido, " de dano! Vida restante: ", vida_atual)
	
	# (FUTURO: Aqui podes colocar o AnimationPlayer para piscar vermelho ou tocar som de dor)
	
	if vida_atual <= 0:
		morrer()

func morrer():
	print("O Orc foi derrotado!")
	# (FUTURO: Tocar animação de morte, largar moedas, etc)
	
	# Destrói o Orc e retira-o do mapa
	queue_free()
