extends Node3D

# --- CONFIGURAÇÕES NO INSPETOR ---
@export var custo_moedas: int = 3 
@export var dano: int = 30
@export var cena_flecha: PackedScene # Arraste a cena Flecha.tscn para cá no Inspetor!
@export var vida_maxima: int = 30 # Adicionamos vida para a torre poder ser destruída!

# --- REFERÊNCIAS ---
# Se a sua torre tiver barra de vida, descomente as linhas abaixo e ajuste os caminhos!
# @onready var health_bar = $HealthBar3D/SubViewport/TextureProgressBar
# @onready var health_bar_container = $HealthBar3D
@onready var timer_ataque = $TimerAtaque # Adicione a referência ao seu Timer aqui

# --- VARIÁVEIS DE CONTROLE ---
var inimigos_no_alcance = [] 
var alvo_atual: Node3D = null
var vida_atual: int
var is_fantasma: bool = false # Fundamental para o holograma não atirar
var tempo_ataque_base: float = 1.5 # Tempo padrão entre os tiros (ajuste como preferir)

func _ready():
	# 1. Se for fantasma (holograma de construção), desliga a torre!
	if is_fantasma:
		# if health_bar_container: health_bar_container.visible = false
		if timer_ataque: timer_ataque.stop() # Impede o holograma de atirar
		return
		
	print("A torre nasceu e o script está rodando!")
	
	# 2. Registra nos grupos
	add_to_group("Construcao") # Para os orcs saberem que podem atacar
	add_to_group("Torres")     # NOVO: Para o GameManager aplicar buffs e curar
	
	# 3. Inicializa Vida e Status
	vida_atual = vida_maxima
	# if health_bar:
	#     health_bar.max_value = vida_maxima
	#     health_bar.value = vida_atual
	#     health_bar_container.visible = false
	
	# Aplica os buffs atuais caso a torre seja construída no meio do jogo
	atualizar_status() 

func _process(_delta):
	if is_fantasma: return # O fantasma não mira
	
	# Limpa alvos mortos da lista
	inimigos_no_alcance = inimigos_no_alcance.filter(func(inimigo): return is_instance_valid(inimigo))
	
	# Atualiza o alvo atual para o primeiro inimigo da lista
	if inimigos_no_alcance.size() > 0:
		alvo_atual = inimigos_no_alcance[0]
	else:
		alvo_atual = null

# ==========================================
# SISTEMA DE ATAQUE
# ==========================================

func _on_area_ataque_body_entered(body):
	if is_fantasma: return # O fantasma ignora inimigos
	
	if body.is_in_group("inimigos") or body.is_in_group("Inimigos"): 
		print("INIMIGO DETECTADO! ALVO TRAVADO!")
		if not body in inimigos_no_alcance:
			inimigos_no_alcance.append(body)

func _on_area_ataque_body_exited(body):
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

func _on_timer_ataque_timeout():
	if is_fantasma: return # O fantasma não atira
	
	if alvo_atual != null and is_instance_valid(alvo_atual):
		atacar()

func atacar():
	if cena_flecha != null and is_instance_valid(alvo_atual):
		# Cria a flecha
		var nova_flecha = cena_flecha.instantiate()
		
		# Adiciona a flecha ao mundo do jogo (raiz)
		get_tree().root.add_child(nova_flecha)
		
		# Define a posição inicial da flecha (posição da torre + um pouco de altura)
		if has_node("PontoDeTiro"):
			nova_flecha.global_position = $PontoDeTiro.global_position
		else:
			nova_flecha.global_position = global_position + Vector3(0, 1.5, 0) # Posição reserva
		
		# Passa os valores de dano e alvo para a flecha saber o que fazer
		# Usamos max(1, ...) para garantir que mesmo com debuffs a torre dê no mínimo 1 de dano
		nova_flecha.dano = max(1, dano + GameManager.bonus_dano)
		nova_flecha.alvo = alvo_atual

# ==========================================
# SISTEMA DE DANO (Para a torre ser destruída)
# ==========================================

func receber_dano(quantidade: int):
	if is_fantasma: return
	
	vida_atual -= quantidade
	
	# if health_bar_container: health_bar_container.visible = true
	# if health_bar: health_bar.value = vida_atual
	
	# Efeito visual de tremer
	var tween = create_tween()
	var original_y = position.y
	tween.tween_property(self, "position:y", original_y + 0.15, 0.05)
	tween.tween_property(self, "position:y", original_y, 0.05)
	
	if vida_atual <= 0:
		destruir_construcao()

func destruir_construcao():
	print("A torre foi destruída!")
	remove_from_group("Construcao")
	remove_from_group("Torres")
	queue_free()

# ==========================================
# SISTEMA DE TRANSPARÊNCIA
# ==========================================

func _on_area_transparencia_body_entered(body):
	if body.is_in_group("Player"): 
		mudar_transparencia(self, 0.75) 

func _on_area_transparencia_body_exited(body):
	if body.is_in_group("Player"):
		mudar_transparencia(self, 0.0)

func mudar_transparencia(no_atual: Node, valor: float):
	if no_atual is MeshInstance3D:
		no_atual.transparency = valor
		
	for filho in no_atual.get_children():
		mudar_transparencia(filho, valor)

# ==========================================
# INTEGRAÇÃO COM UPGRADES E SISTEMA DE DIA
# ==========================================

func atualizar_status():
	# Ajusta a Velocidade de Ataque baseada no GameManager
	if timer_ataque:
		# Fórmula: Tempo / (1 + Bônus). Se bônus for 0.5 (50%), o tempo cai para 1.0s
		var novo_tempo = tempo_ataque_base / (1.0 + GameManager.bonus_velocidade_ataque)
		timer_ataque.wait_time = max(0.1, novo_tempo) # Limite mínimo de 0.1s para não bugar
		print("Torre atualizada: Velocidade de ataque agora é ", timer_ataque.wait_time)

func curar_totalmente():
	# Chamado pelo GameManager no início do Dia
	vida_atual = vida_maxima
	# if health_bar: health_bar.value = vida_atual
	# if health_bar_container: health_bar_container.visible = false
	print("Torre curada para o novo dia!")
