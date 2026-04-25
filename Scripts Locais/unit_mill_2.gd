extends Node3D

# --- CONFIGURAÇÕES ---
@export var custo_moedas: int = 3 
@export var moedas_por_onda: int = 2 
@export var vida_maxima: int = 20

# --- REFERÊNCIAS ---
@onready var health_bar = $HealthBar3D/SubViewport/TextureProgressBar
@onready var health_bar_container = $HealthBar3D

# --- ESTADO ---
var vida_atual: int
var is_fantasma: bool = false 

func _ready():
	# Se for apenas o holograma (fantasma), limpamos e paramos o código
	if is_fantasma:
		if health_bar_container: health_bar_container.visible = false
		return

	# Aplica balanceamento centralizado (CSV)
	_aplicar_balanceamento()

	# 1. Registro no grupo para os orcs atacarem
	add_to_group("Construcao")

	# 2. Inicializa Vida e Barra
	vida_atual = vida_maxima
	if health_bar:
		health_bar.max_value = vida_maxima
		health_bar.value = vida_atual
		health_bar_container.visible = false # Escondida até levar dano
	
	# 3. Conecta ao sinal de fim de onda para ganhar moedas
	if GameManager.has_signal("onda_terminada"):
		GameManager.onda_terminada.connect(_pagar_recompensa)

# --- SISTEMA DE PAGAMENTO (NOVO) ---
func _pagar_recompensa():
	if is_fantasma: return
	
	# Adiciona o dinheiro no GameManager direto
	GameManager.moedas += moedas_por_onda
	print("Construção gerou ", moedas_por_onda, " moedas!")
	
	# Grita pelo rádio para a HUD atualizar e o baú abrir
	get_tree().call_group("Interface", "atualizar_moedas")
	get_tree().call_group("Interface", "animar_bau_abrindo")

# --- SISTEMA DE DANO ---
func receber_dano(quantidade: int):
	if is_fantasma: return
	
	vida_atual -= quantidade
	
	# Mostra a barra de vida ao levar dano
	if health_bar_container:
		health_bar_container.visible = true
	
	# Atualiza o valor visual da barra
	if health_bar:
		health_bar.value = vida_atual
	
	# Efeito visual de tremer (Game Juice!)
	var tween = create_tween()
	var original_y = position.y
	tween.tween_property(self, "position:y", original_y + 0.15, 0.05)
	tween.tween_property(self, "position:y", original_y, 0.05)
	
	if vida_atual <= 0:
		destruir_construcao()

func destruir_construcao():
	print("A construção foi destruída!")
	# Desconecta o sinal para evitar erros de memória
	if GameManager.onda_terminada.is_connected(_pagar_recompensa):
		GameManager.onda_terminada.disconnect(_pagar_recompensa)
		
	remove_from_group("Construcao")
	queue_free()

# --- TRANSPARÊNCIA (PLAYER PASSANDO POR TRÁS) ---
func _on_area_3d_body_entered(body):
	if body.is_in_group("Player"):
		mudar_transparencia(self, 0.75) 

func _on_area_3d_body_exited(body):
	if body.is_in_group("Player"):
		mudar_transparencia(self, 0.0)

func mudar_transparencia(no_atual: Node, valor: float):
	if no_atual is MeshInstance3D:
		no_atual.transparency = valor
	for filho in no_atual.get_children():
		mudar_transparencia(filho, valor)

# ==========================================
# BALANCEAMENTO (CSV)
# ==========================================
func _aplicar_balanceamento() -> void:
	custo_moedas    = Balanceamento.get_int("moinho_custo", custo_moedas)
	moedas_por_onda = Balanceamento.get_int("moinho_renda_onda", moedas_por_onda)
	vida_maxima     = Balanceamento.get_int("moinho_vida", vida_maxima)

func recarregar_balanceamento() -> void:
	_aplicar_balanceamento()
