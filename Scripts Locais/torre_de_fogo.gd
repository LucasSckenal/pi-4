extends Node3D

# ==========================================
# TORRE DE FOGO — Dano contínuo por laser
# Ataca até 3 inimigos ao mesmo tempo.
# Tipo: Inferno Tower (Clash of Clans)
# ==========================================

# ==========================================
# ATRIBUTOS EDITÁVEIS NO INSPETOR
# ==========================================
@export var custo_moedas: int = 5
@export var dano_por_segundo: float = 15.0
@export var vida_maxima: int = 40
@export var alcance: float = 8.0
@export var max_alvos: int = 3
# Ramp-up de dano: quanto mais tempo no mesmo inimigo, mais dano faz
@export var multiplicador_dano_max: float = 4.0  # DPS chega a 4× o base
@export var tempo_ramp_up: float = 4.0            # Segundos para atingir o máximo

# ==========================================
# COMPATIBILIDADE COM O SISTEMA DE SAVE
# (GameManager._dados_construcao usa esses campos)
# ==========================================
var nivel_atual: int = 0
var caminho_atual: int = -1

# ==========================================
# REFERÊNCIAS AOS NÓS DA CENA
# ==========================================
@onready var torre_completa: Node3D = $TorreCompleta
@onready var esfera_fogo: MeshInstance3D = $TorreCompleta/EsferaFogo
@onready var laser_base: MeshInstance3D = $Laser

# ==========================================
# ESTADO INTERNO
# ==========================================
var is_fantasma: bool = false
var vida_atual: int = 0
var alvos_atuais: Array = []
var lasers: Array = []
# Acumulador de dano fracionário por inimigo (instance_id -> float)
var _dano_buffer: Dictionary = {}
# Tempo contínuo focado em cada inimigo — controla o ramp-up (instance_id -> float)
var _tempo_no_alvo: Dictionary = {}

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	if is_fantasma:
		# Modo fantasma (pré-visualização de construção): desliga tudo
		if laser_base:
			laser_base.hide()
		return

	# Aplica balanceamento centralizado (CSV)
	_aplicar_balanceamento()

	add_to_group("Construcao")
	add_to_group("Torres")
	vida_atual = vida_maxima

	# Cria os raios adicionais (o laser_base já existe na cena; clonamos os extras)
	lasers.append(laser_base)
	for _i in range(1, max_alvos):
		var clone := laser_base.duplicate() as MeshInstance3D
		add_child(clone)
		lasers.append(clone)

	# Oculta todos os raios até haver alvos
	for laser in lasers:
		laser.hide()

# ==========================================
# LOOP PRINCIPAL — DANO E VISUAIS
# ==========================================
func _process(delta: float) -> void:
	if is_fantasma:
		return

	# 1. Atualiza a lista de alvos em alcance
	_atualizar_alvos()

	# 2. Gira a torre na direção do alvo principal
	if alvos_atuais.size() > 0 and is_instance_valid(alvos_atuais[0]) and torre_completa:
		var dir_h: Vector3 = alvos_atuais[0].global_position - global_position
		dir_h.y = 0.0
		if dir_h.length_squared() > 0.01:
			torre_completa.look_at(global_position + dir_h, Vector3.UP)

	# 3. Ponto de origem dos raios (centro da EsferaFogo)
	var origem: Vector3
	if is_instance_valid(esfera_fogo):
		origem = esfera_fogo.global_position
	else:
		origem = global_position + Vector3(0, 1.4, 0)

	# 4. Para cada slot de raio: aplica dano e atualiza visual
	for i in range(max_alvos):
		if i < alvos_atuais.size():
			var alvo: Node3D = alvos_atuais[i]
			if not is_instance_valid(alvo):
				if i < lasers.size():
					lasers[i].hide()
				continue

			# Dano contínuo acumulado
			_aplicar_dano_continuo(alvo, delta)

			# Visual do raio — mira no meio do corpo do inimigo
			if i < lasers.size():
				var alvo_pos: Vector3 = alvo.global_position + Vector3(0, 0.5, 0)
				_orientar_laser(lasers[i], origem, alvo_pos)
		else:
			# Sem alvo neste slot — oculta o raio
			if i < lasers.size():
				lasers[i].hide()

# ==========================================
# DETECÇÃO DE INIMIGOS POR DISTÂNCIA
# ==========================================
func _atualizar_alvos() -> void:
	# Busca inimigos no grupo (nome pode variar por cena)
	var todos: Array = get_tree().get_nodes_in_group("inimigos")
	if todos.is_empty():
		todos = get_tree().get_nodes_in_group("Inimigos")

	# Filtra os que estão no alcance e ainda vivos
	var em_alcance: Array = []
	for inimigo in todos:
		if not is_instance_valid(inimigo):
			continue
		if inimigo.get("esta_morto") == true:
			continue
		if global_position.distance_to(inimigo.global_position) <= alcance:
			em_alcance.append(inimigo)

	# Ordena do mais próximo para o mais distante como prioridade
	em_alcance.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return global_position.distance_to(a.global_position) \
			 < global_position.distance_to(b.global_position)
	)

	# Seleciona os primeiros max_alvos
	alvos_atuais.clear()
	for inimigo in em_alcance:
		if alvos_atuais.size() >= max_alvos:
			break
		alvos_atuais.append(inimigo)

	# Remove buffers e ramp-up de inimigos que saíram do alcance (reseta o aquecimento)
	var ids_ativos: Array = []
	for a in alvos_atuais:
		if is_instance_valid(a):
			ids_ativos.append(a.get_instance_id())
	for id in _dano_buffer.keys():
		if id not in ids_ativos:
			_dano_buffer.erase(id)
	for id in _tempo_no_alvo.keys():
		if id not in ids_ativos:
			_tempo_no_alvo.erase(id)  # Inimigo saiu do alcance → ramp-up zera

# ==========================================
# DANO CONTÍNUO com ramp-up
# Quanto mais tempo o laser fica no mesmo inimigo,
# mais dano faz — até multiplicador_dano_max × o base.
# Se o inimigo sair do alcance ou morrer, o contador zera.
# ==========================================
func _aplicar_dano_continuo(alvo: Node3D, delta: float) -> void:
	if not is_instance_valid(alvo):
		return

	var id: int = alvo.get_instance_id()

	# Acumula tempo focado neste inimigo
	_tempo_no_alvo[id] = _tempo_no_alvo.get(id, 0.0) + delta

	# Progresso do ramp-up: 0.0 (início) → 1.0 (máximo)
	var progresso: float = clamp(_tempo_no_alvo[id] / tempo_ramp_up, 0.0, 1.0)

	# DPS atual: sobe de dano_por_segundo até dano_por_segundo × multiplicador_dano_max
	var dps_atual: float = lerp(dano_por_segundo, dano_por_segundo * multiplicador_dano_max, progresso)
	dps_atual += float(GameManager.bonus_dano)

	# Acumula dano fracionário e aplica em inteiros
	_dano_buffer[id] = _dano_buffer.get(id, 0.0) + dps_atual * delta
	if _dano_buffer[id] >= 1.0:
		var dano_int: int = int(_dano_buffer[id])
		_dano_buffer[id] -= float(dano_int)
		if alvo.has_method("receber_dano"):
			alvo.receber_dano(dano_int)

# ==========================================
# VISUAL DO RAIO LASER
# Orienta o CylinderMesh de 'de' até 'para'.
# CylinderMesh padrão: height=2, radius=0.5
#   → escala Y = dist/2  → altura mundial = dist
#   → escala XZ = 0.14   → raio mundial ≈ 0.07
# ==========================================
func _orientar_laser(laser: MeshInstance3D, de: Vector3, para: Vector3) -> void:
	var dir: Vector3 = para - de
	var dist: float = dir.length()
	if dist < 0.05:
		laser.hide()
		return

	laser.show()

	# Eixo Y local do cilindro → direção do raio em espaço mundial
	var y_axis: Vector3 = dir.normalized()

	# Escolhe vetor de referência perpendicular para evitar degeneração
	var ref_axis: Vector3 = Vector3.RIGHT if abs(y_axis.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var x_axis: Vector3 = y_axis.cross(ref_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()

	# Escala: XZ = 0.14 (raio mundial = 0.07), Y = dist/2 (altura mundial = dist)
	var scale_radius: float = 0.14
	var base_basis := Basis(x_axis * scale_radius, y_axis * (dist / 2.0), z_axis * scale_radius)
	laser.global_transform = Transform3D(base_basis, (de + para) / 2.0)
	# AVISO: Se algo quebrou? É por eu ter mudados de "basis" para "base_basis" o nome das variáveis para evitar warnings de override

# ==========================================
# TORRE RECEBENDO DANO DOS INIMIGOS
# ==========================================
func receber_dano(quantidade: int) -> void:
	if is_fantasma:
		return

	vida_atual -= quantidade

	# Efeito de tremor visual
	var tween: Tween = create_tween()
	var orig_y: float = position.y
	tween.tween_property(self, "position:y", orig_y + 0.15, 0.05)
	tween.tween_property(self, "position:y", orig_y, 0.05)

	if vida_atual <= 0:
		destruir_construcao()

func destruir_construcao() -> void:
	# Remove lasers clonados (o laser_base faz parte da cena e é destruído com a árvore)
	for laser in lasers:
		if is_instance_valid(laser) and laser != laser_base:
			laser.queue_free()
	lasers.clear()

	remove_from_group("Construcao")
	remove_from_group("Torres")
	queue_free()

# ==========================================
# BUFFS E CURA (chamados pelo GameManager)
# ==========================================
func atualizar_status() -> void:
	# O dano é calculado em tempo real usando GameManager.bonus_dano no _process;
	# não há timer para ajustar, então este método não precisa fazer nada.
	pass

func curar_totalmente() -> void:
	vida_atual = vida_maxima

# ==========================================
# BALANCEAMENTO (CSV)
# ==========================================
func _aplicar_balanceamento() -> void:
	custo_moedas             = Balanceamento.get_int("torre_fogo_custo", custo_moedas)
	dano_por_segundo         = Balanceamento.get_float("torre_fogo_dps", dano_por_segundo)
	vida_maxima              = Balanceamento.get_int("torre_fogo_vida", vida_maxima)
	alcance                  = Balanceamento.get_float("torre_fogo_alcance", alcance)
	max_alvos                = Balanceamento.get_int("torre_fogo_max_alvos", max_alvos)
	multiplicador_dano_max   = Balanceamento.get_float("torre_fogo_mult_dano_max", multiplicador_dano_max)
	tempo_ramp_up            = Balanceamento.get_float("torre_fogo_tempo_rampup", tempo_ramp_up)

# Hot-reload F5
func recarregar_balanceamento() -> void:
	_aplicar_balanceamento()

# ==========================================
# TRANSPARÊNCIA (jogador passa atrás da torre)
# ==========================================
func _on_area_transparencia_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		_mudar_transparencia(self, 0.75)

func _on_area_transparencia_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		_mudar_transparencia(self, 0.0)

func _mudar_transparencia(no: Node, valor: float) -> void:
	if no is MeshInstance3D:
		(no as MeshInstance3D).transparency = valor
	for filho in no.get_children():
		_mudar_transparencia(filho, valor)
