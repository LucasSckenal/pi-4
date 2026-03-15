extends Node3D

# ==========================================
# ENUM PARA O TIPO DE CONSTRUÇÃO
# ==========================================
enum TipoConstrucao {
	TORRE,
	MINA,
	CASA,
	MOINHO,
	QUARTEL,
	BASE   # <-- Novo tipo para a base principal
}

# ==========================================
# CONFIGURAÇÕES BÁSICAS (COMUNS A TODOS)
# ==========================================
@export var tipo: TipoConstrucao = TipoConstrucao.TORRE :
	set(valor):
		tipo = valor
		notify_property_list_changed()

@export var custo_moedas: int = 5
@export var vida_maxima: int = 20

# ==========================================
# CONFIGURAÇÕES ESPECÍFICAS PARA TORRES
# ==========================================
@export_group("Atributos de Torre")
@export var dano: int = 30
@export var tempo_ataque_base: float = 1.5
@export var alcance: float = 10.0
@export var cena_flecha: PackedScene
@export var ponto_de_tiro: NodePath
@export var area_ataque_path: NodePath

# ==========================================
# CONFIGURAÇÕES ESPECÍFICAS PARA QUARTEL
# ==========================================
@export_group("Atributos de Quartel")
@export var cena_aliado: PackedScene
@export var numero_aliados_base: int = 1
@export var ponto_spawn_path: NodePath

# ==========================================
# CONFIGURAÇÕES ECONÔMICAS (MINA, CASA, MOINHO)
# ==========================================
@export_group("Atributos Econômicos")
@export var moedas_por_onda: int = 2

# ==========================================
# CONFIGURAÇÕES DE BARRA DE VIDA (OPCIONAL)
# ==========================================
@export_group("Barra de Vida (opcional)")
@export var tem_barra_vida: bool = false
@export var caminho_barra_vida: NodePath
@export var caminho_container_barra: NodePath

# ==========================================
# SISTEMA DE UPGRADES (INDIVIDUAIS)
# ==========================================
@export_group("Upgrades")
@export var nivel_atual: int = 0
@export var upgrade_custos: Array[int] = []
@export var upgrade_dano_por_nivel: Array[int] = []
@export var upgrade_moedas_por_nivel: Array[int] = []
@export var upgrade_aliados_por_nivel: Array[int] = []
@export var upgrade_velocidade_por_nivel: Array[float] = []
@export var upgrade_alcance_por_nivel: Array[float] = []
# Para a BASE: upgrade de vida e/ou desbloqueio de construções (o desbloqueio é global, não individual)
@export var upgrade_vida_por_nivel: Array[int] = []

# ==========================================
# REFERÊNCIAS
# ==========================================
@onready var ponto_tiro = get_node_or_null(ponto_de_tiro)
@onready var ponto_spawn = get_node_or_null(ponto_spawn_path)
@onready var area_ataque = get_node_or_null(area_ataque_path)
@onready var barra_vida = get_node_or_null(caminho_barra_vida) if tem_barra_vida else null
@onready var container_barra = get_node_or_null(caminho_container_barra) if tem_barra_vida else null
@onready var timer_ataque = get_node_or_null("TimerAtaque") if tipo == TipoConstrucao.TORRE else null

# ==========================================
# INFORMAÇÕES DE INTERFACE
# ==========================================
@export_group("Interface")
## Nome que aparecerá no menu radial
@export var nome_construcao: String = "Construção"
## Ícone PNG que aparecerá no botão do menu radial
@export var icone: Texture2D

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var is_fantasma: bool = false
var vida_atual: int
var inimigos_no_alcance = []
var alvo_atual: Node3D = null
# Valores atuais após upgrades
var dano_atual: int
var moedas_por_onda_atual: int
var numero_aliados_atual: int
var tempo_ataque_atual: float
var alcance_atual: float

func _ready():
	if is_fantasma:
		_modo_fantasma()
		return
	
	_atualizar_valores_pos_upgrades()
	vida_atual = vida_maxima
	_inicializar_barra_vida()
	
	match tipo:
		TipoConstrucao.TORRE:
			add_to_group("Torres")
			add_to_group("Construcao")
			_configurar_alcance()
			atualizar_status()
			if timer_ataque:
				timer_ataque.start()
		TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO:
			add_to_group("Construcao")
			GameManager.onda_terminada.connect(_pagar_recompensa)
		TipoConstrucao.QUARTEL:
			add_to_group("Construcao")
			GameManager.noite_iniciada.connect(_spawn_aliados)
		TipoConstrucao.BASE:
			add_to_group("Construcao")
			add_to_group("Base")  # Grupo específico para identificar a base
			# Se a base puder atacar após upgrades, você pode ativar timer etc.
			# Por enquanto, apenas registra
			print("Base principal estabelecida. Nível: ", nivel_atual)

func _modo_fantasma():
	for child in get_children():
		_desativar_fantasma(child)
	if timer_ataque:
		timer_ataque.stop()
	if container_barra:
		container_barra.visible = false

func _desativar_fantasma(no: Node):
	if no is MeshInstance3D:
		no.transparency = 0.5
	elif no is CollisionObject3D:
		no.collision_layer = 0
		no.collision_mask = 0
	elif no is CollisionShape3D or no is CollisionPolygon3D:
		no.set_deferred("disabled", true)
	elif no is NavigationObstacle3D:
		no.avoidance_enabled = false
	for filho in no.get_children():
		_desativar_fantasma(filho)

func _inicializar_barra_vida():
	if tem_barra_vida and barra_vida and container_barra:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		container_barra.visible = false

# ==========================================
# SISTEMA DE UPGRADES (INDIVIDUAIS)
# ==========================================
func _atualizar_valores_pos_upgrades():
	match tipo:
		TipoConstrucao.TORRE:
			dano_atual = dano + (upgrade_dano_por_nivel[nivel_atual-1] if nivel_atual > 0 and nivel_atual-1 < upgrade_dano_por_nivel.size() else 0)
			tempo_ataque_atual = tempo_ataque_base - (upgrade_velocidade_por_nivel[nivel_atual-1] if nivel_atual > 0 and nivel_atual-1 < upgrade_velocidade_por_nivel.size() else 0.0)
			alcance_atual = alcance + (upgrade_alcance_por_nivel[nivel_atual-1] if nivel_atual > 0 and nivel_atual-1 < upgrade_alcance_por_nivel.size() else 0.0)
		TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO:
			moedas_por_onda_atual = moedas_por_onda + (upgrade_moedas_por_nivel[nivel_atual-1] if nivel_atual > 0 and nivel_atual-1 < upgrade_moedas_por_nivel.size() else 0)
		TipoConstrucao.QUARTEL:
			numero_aliados_atual = numero_aliados_base + (upgrade_aliados_por_nivel[nivel_atual-1] if nivel_atual > 0 and nivel_atual-1 < upgrade_aliados_por_nivel.size() else 0)
		TipoConstrucao.BASE:
			# A base pode ganhar mais vida, e também aumentar o nível global (ver em aplicar_upgrade)
			vida_maxima += (upgrade_vida_por_nivel[nivel_atual-1] if nivel_atual > 0 and nivel_atual-1 < upgrade_vida_por_nivel.size() else 0)
			vida_atual = vida_maxima  # cura ao upar

func get_custo_proximo_upgrade() -> int:
	if nivel_atual >= upgrade_custos.size():
		return -1
	return upgrade_custos[nivel_atual]

func aplicar_upgrade() -> bool:
	var custo = get_custo_proximo_upgrade()
	if custo <= 0:
		return false
	if GameManager.gastar_moedas(custo):
		nivel_atual += 1
		_atualizar_valores_pos_upgrades()
		
		# Se for a BASE, também atualiza o nível global no GameManager
		if tipo == TipoConstrucao.BASE:
			GameManager.nivel_base = nivel_atual
			GameManager.upgrade_base_aplicado.emit()  # Sinal para UI atualizar construções liberadas
		
		if tipo == TipoConstrucao.TORRE:
			_configurar_alcance()
			atualizar_status()
		
		print("%s upgrade para nível %d" % [name, nivel_atual])
		return true
	return false

# ==========================================
# CONFIGURAÇÃO DE ALCANCE (TORRE)
# ==========================================
func _configurar_alcance():
	if area_ataque and area_ataque.has_node("CollisionShape3D"):
		var shape = area_ataque.get_node("CollisionShape3D").shape
		if shape is SphereShape3D:
			shape.radius = alcance_atual
		elif shape is CylinderShape3D:
			shape.radius = alcance_atual
		print("Alcance da torre ajustado para: ", alcance_atual)

# ==========================================
# SISTEMA DE ATAQUE (TORRE)
# ==========================================
func _on_area_ataque_body_entered(body):
	if tipo != TipoConstrucao.TORRE or is_fantasma: return
	if body.is_in_group("inimigos") or body.is_in_group("Inimigos"):
		if not body in inimigos_no_alcance:
			inimigos_no_alcance.append(body)

func _on_area_ataque_body_exited(body):
	if tipo != TipoConstrucao.TORRE or is_fantasma: return
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

func _process(_delta):
	if tipo != TipoConstrucao.TORRE or is_fantasma: return
	inimigos_no_alcance = inimigos_no_alcance.filter(func(inimigo): return is_instance_valid(inimigo))
	alvo_atual = inimigos_no_alcance.front() if inimigos_no_alcance.size() > 0 else null

func _on_timer_ataque_timeout():
	if tipo != TipoConstrucao.TORRE or is_fantasma: return
	if alvo_atual != null and is_instance_valid(alvo_atual):
		atacar()

func atacar():
	if cena_flecha == null or not is_instance_valid(alvo_atual):
		return
	var flecha = cena_flecha.instantiate()
	get_tree().root.add_child(flecha)
	flecha.global_position = ponto_tiro.global_position if ponto_tiro else global_position + Vector3(0, 1.5, 0)
	flecha.dano = max(1, dano_atual + GameManager.bonus_dano)
	flecha.alvo = alvo_atual

# ==========================================
# SISTEMA ECONÔMICO (MINA, CASA, MOINHO)
# ==========================================
func _pagar_recompensa():
	if is_fantasma: return
	GameManager.moedas += moedas_por_onda_atual
	print("%s gerou %d moedas! Total: %d" % [name, moedas_por_onda_atual, GameManager.moedas])
	get_tree().call_group("Interface", "atualizar_moedas")
	if tipo == TipoConstrucao.MOINHO:
		get_tree().call_group("Interface", "animar_bau_abrindo")

# ==========================================
# SISTEMA DO QUARTEL (SPAWN DE ALIADOS)
# ==========================================
func _spawn_aliados(_onda_atual):
	if is_fantasma or cena_aliado == null:
		return
	for i in range(numero_aliados_atual):
		var aliado = cena_aliado.instantiate()
		get_tree().current_scene.add_child(aliado)
		if ponto_spawn:
			aliado.global_position = ponto_spawn.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		else:
			aliado.global_position = global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		aliado.add_to_group("aliados")
	print("%s spawnou %d aliados" % [name, numero_aliados_atual])

# ==========================================
# SISTEMA DE DANO (COMUM A TODOS)
# ==========================================
func receber_dano(quantidade: int):
	if is_fantasma: return
	vida_atual -= quantidade
	if tem_barra_vida and container_barra:
		container_barra.visible = true
		if barra_vida:
			barra_vida.value = vida_atual
	
	var tween = create_tween()
	var original_y = position.y
	tween.tween_property(self, "position:y", original_y + 0.15, 0.05)
	tween.tween_property(self, "position:y", original_y, 0.05)
	
	if vida_atual <= 0:
		destruir()

func destruir():
	print("%s destruída!" % name)
	if tipo == TipoConstrucao.BASE:
		GameManager.game_over()  # Você precisa implementar isso no GameManager
	# Desconectar sinais
	if GameManager.onda_terminada.is_connected(_pagar_recompensa):
		GameManager.onda_terminada.disconnect(_pagar_recompensa)
	if GameManager.noite_iniciada.is_connected(_spawn_aliados):
		GameManager.noite_iniciada.disconnect(_spawn_aliados)
	remove_from_group("Construcao")
	remove_from_group("Torres")
	queue_free()

# ==========================================
# BUFFS GLOBAIS (apenas para TORRE)
# ==========================================
func atualizar_status():
	if tipo == TipoConstrucao.TORRE and timer_ataque:
		var tempo_com_upgrade = tempo_ataque_atual
		var tempo_final = tempo_com_upgrade / (1.0 + GameManager.bonus_velocidade_ataque)
		timer_ataque.wait_time = max(0.1, tempo_final)

func curar_totalmente():
	vida_atual = vida_maxima
	if tem_barra_vida and barra_vida:
		barra_vida.value = vida_atual
	if tem_barra_vida and container_barra:
		container_barra.visible = false
	print("%s curada!" % name)

# ==========================================
# TRANSPARÊNCIA
# ==========================================
func _on_area_transparencia_body_entered(body):
	if body.is_in_group("Player"):
		_set_transparencia(self, 0.75)

func _on_area_transparencia_body_exited(body):
	if body.is_in_group("Player"):
		_set_transparencia(self, 0.0)

func _set_transparencia(no: Node, valor: float):
	if no is MeshInstance3D:
		no.transparency = valor
	for filho in no.get_children():
		_set_transparencia(filho, valor)
