extends Node3D

# ==========================================
# ATRIBUTOS EDITÁVEIS NO INSPETOR
# ==========================================
@export var custo_moedas: int = 3
@export var dano: int = 30
@export var vida_maxima: int = 30
@export var tempo_ataque_base: float = 1.5  # Tempo entre disparos (segundos)
@export var cena_flecha: PackedScene        # Arraste a cena Flecha.tscn aqui

# ==========================================
# REFERÊNCIAS (ajuste os caminhos conforme sua cena)
# ==========================================
@onready var timer_ataque = $TimerAtaque
@onready var ponto_de_tiro = $PontoDeTiro   # Onde a flecha aparece
# @onready var health_bar = $HealthBar3D/SubViewport/TextureProgressBar
# @onready var health_bar_container = $HealthBar3D

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var inimigos_no_alcance = []
var alvo_atual: Node3D = null
var vida_atual: int
var is_fantasma: bool = false  # Usado pelo slot de construção

func _ready():
	# Se for fantasma (holograma), desliga tudo
	if is_fantasma:
		if timer_ataque:
			timer_ataque.stop()
		# if health_bar_container: health_bar_container.visible = false
		return

	# Aplica balanceamento centralizado (CSV)
	_aplicar_balanceamento()

	print("Torre construída!")

	# Registra nos grupos para receber buffs e ser atacada
	add_to_group("Construcao")
	add_to_group("Torres")

	# Inicializa vida
	vida_atual = vida_maxima
	# if health_bar:
	#     health_bar.max_value = vida_maxima
	#     health_bar.value = vida_atual
	#     health_bar_container.visible = false
	
	# Aplica os buffs atuais (velocidade de ataque)
	atualizar_status()
	
	# Inicia o timer de ataque (essencial!)
	timer_ataque.start()

# ==========================================
# SISTEMA DE ATAQUE
# ==========================================

func _on_area_ataque_body_entered(body):
	if is_fantasma: return
	if body.is_in_group("inimigos") or body.is_in_group("Inimigos"):
		if not body in inimigos_no_alcance:
			inimigos_no_alcance.append(body)

func _on_area_ataque_body_exited(body):
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

func _process(_delta):
	if is_fantasma: return
	# Remove inimigos mortos da lista
	inimigos_no_alcance = inimigos_no_alcance.filter(func(inimigo): return is_instance_valid(inimigo))
	
	# Define o primeiro da lista como alvo
	alvo_atual = inimigos_no_alcance.front() if inimigos_no_alcance.size() > 0 else null

func _on_timer_ataque_timeout():
	if is_fantasma: return
	if alvo_atual != null and is_instance_valid(alvo_atual):
		atacar()

func atacar():
	if cena_flecha == null or not is_instance_valid(alvo_atual):
		return
	
	var nova_flecha = cena_flecha.instantiate()
	get_tree().root.add_child(nova_flecha)
	
	# Posiciona a flecha
	if ponto_de_tiro:
		nova_flecha.global_position = ponto_de_tiro.global_position
	else:
		nova_flecha.global_position = global_position + Vector3(0, 1.5, 0)
	
	# Configura dano (base + bônus global)
	nova_flecha.dano = max(1, dano + GameManager.bonus_dano)
	nova_flecha.alvo = alvo_atual

# ==========================================
# SISTEMA DE DANO (TORRE RECEBENDO ATAQUE)
# ==========================================

func receber_dano(quantidade: int):
	if is_fantasma: return
	
	vida_atual -= quantidade
	# if health_bar_container: health_bar_container.visible = true
	# if health_bar: health_bar.value = vida_atual
	
	# Efeito visual de tremor
	var tween = create_tween()
	var original_y = position.y
	tween.tween_property(self, "position:y", original_y + 0.15, 0.05)
	tween.tween_property(self, "position:y", original_y, 0.05)
	
	if vida_atual <= 0:
		destruir_construcao()

func destruir_construcao():
	print("Torre destruída!")
	remove_from_group("Construcao")
	remove_from_group("Torres")
	queue_free()

# ==========================================
# APLICAÇÃO DE BUFFS (chamado pelo GameManager)
# ==========================================

func atualizar_status():
	if timer_ataque:
		# Velocidade de ataque: tempo = base / (1 + bônus)
		var novo_tempo = tempo_ataque_base / (1.0 + GameManager.bonus_velocidade_ataque)
		timer_ataque.wait_time = max(0.1, novo_tempo)
		print("Torre atualizada: novo intervalo de tiro = ", timer_ataque.wait_time)

# Lê os valores do CSV de balanceamento (Balanceamento.gd autoload)
func _aplicar_balanceamento() -> void:
	custo_moedas       = Balanceamento.get_int("torre_padrao_custo", custo_moedas)
	dano               = Balanceamento.get_int("torre_padrao_dano", dano)
	vida_maxima        = Balanceamento.get_int("torre_padrao_vida", vida_maxima)
	tempo_ataque_base  = Balanceamento.get_float("torre_padrao_tempo_ataque", tempo_ataque_base)

# Hot-reload F5: reaplica valores sem reiniciar a cena
func recarregar_balanceamento() -> void:
	_aplicar_balanceamento()
	atualizar_status()

func curar_totalmente():
	# Chamado no início do dia
	vida_atual = vida_maxima
	# if health_bar: health_bar.value = vida_atual
	# if health_bar_container: health_bar_container.visible = false
	print("Torre curada para o novo dia!")

# ==========================================
# SISTEMA DE TRANSPARÊNCIA (quando o player passa atrás)
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
