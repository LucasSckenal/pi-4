extends Node3D

# --- CONFIGURAÇÕES NO INSPETOR ---
@export var custo_moedas: int = 3 
@export var dano: int = 30
@export var cena_flecha: PackedScene # Arraste a cena Flecha.tscn para cá no Inspetor!

# --- VARIÁVEIS DE CONTROLE ---
var inimigos_no_alcance = [] 
var alvo_atual: Node3D = null
func _ready():
	print("A torre nasceu e o script está rodando!")
func _process(_delta):
	# Atualiza o alvo atual para o primeiro inimigo da lista
	if inimigos_no_alcance.size() > 0:
		alvo_atual = inimigos_no_alcance[0]
	else:
		alvo_atual = null

# ==========================================
# SISTEMA DE ATAQUE
# ==========================================

# Conecte o sinal 'body_entered' da Area3D de ataque aqui
func _on_area_ataque_body_entered(body):
	print("ALGO ENTROU NO RAIO DA TORRE: ", body.name) # <-- Adicione esta linha
	if body.is_in_group("inimigos"):
		print("INIMIGO DETECTADO! ALVO TRAVADO!") # <-- E esta linha
		inimigos_no_alcance.append(body)

# Conecte o sinal 'body_exited' da Area3D de ataque aqui
func _on_area_ataque_body_exited(body):
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

# Conecte o sinal 'timeout' do seu TimerAtaque aqui
func _on_timer_ataque_timeout():
	if alvo_atual != null:
		atacar()

func atacar():
	if cena_flecha != null and is_instance_valid(alvo_atual):
		# Cria a flecha
		var nova_flecha = cena_flecha.instantiate()
		
		# Adiciona a flecha ao mundo do jogo (raiz)
		get_tree().root.add_child(nova_flecha)
		
		# Define a posição inicial da flecha (posição da torre + um pouco de altura)
		nova_flecha.global_position = $PontoDeTiro.global_position
		
		# Passa os valores de dano e alvo para a flecha saber o que fazer
		nova_flecha.dano = dano
		nova_flecha.alvo = alvo_atual

# ==========================================
# SISTEMA DE TRANSPARÊNCIA
# ==========================================

# Conecte o sinal 'body_entered' da Area3D de transparência aqui
func _on_area_transparencia_body_entered(body):
	if body.name == "Player":
		mudar_transparencia(self, 0.75) 

# Conecte o sinal 'body_exited' da Area3D de transparência aqui
func _on_area_transparencia_body_exited(body):
	if body.name == "Player":
		mudar_transparencia(self, 0.0)

func mudar_transparencia(no_atual: Node, valor: float):
	if no_atual is MeshInstance3D:
		no_atual.transparency = valor
		
	for filho in no_atual.get_children():
		mudar_transparencia(filho, valor)
