extends InimigoBase
class_name HolandesVoador

# ==========================================
# SINAIS — Salto Fantasma
# ==========================================
signal start_teleport_effect(pos: Vector3)
signal teleport_disappear
signal teleport_reappear(pos: Vector3)

# ==========================================
# CONFIGURAÇÕES — Salto Fantasma
# ==========================================
@export_category("Salto Fantasma")
## Porcentagem de vida que ativa o teleporte (0.0–1.0)
@export var hp_gatilho_teleporte: float = 0.5
## Duração da fase de preparação (transparência + fumaça) em segundos
@export var duracao_preparacao: float = 1.2
## Duração da imunidade de ataque após reaparecer em segundos
@export var duracao_imunidade_pos_teleporte: float = 1.0
## Alpha do modelo durante a preparação (0 = invisível, 1 = opaco)
@export var alpha_preparacao: float = 0.3

# ==========================================
# ESTADO — Salto Fantasma
# ==========================================
var initial_path: Vector3 = Vector3.ZERO
var current_path: Vector3 = Vector3.ZERO
var has_teleported: bool = false
var is_teleporting: bool = false


# ==========================================
# READY
# ==========================================
func _ready() -> void:
	super._ready()
	# O spawner define global_position APÓS add_child, então aguardamos um frame
	# antes de registar a posição de spawn como initial_path e current_path.
	call_deferred("_init_navigation")
	initial_path = global_position
	current_path = global_position
	posicao_de_spawn = global_position

	# Pré-aquece a navegação: define alvo e dispara o cálculo de caminho
	# ANTES do primeiro _physics_process, evitando is_navigation_finished()
	# devolver true no frame inicial e o boss ficar parado.
	alvo_atual = procurar_novo_alvo()
	if alvo_atual and nav_agent:
		# Se o spawner estiver ligeiramente fora do navmesh, encaixa o boss
		# no ponto mais próximo para o NavigationServer encontrar o caminho.
		var nav_map := get_world_3d().navigation_map
		var pos_valida := NavigationServer3D.map_get_closest_point(nav_map, global_position)
		if pos_valida.distance_to(global_position) > 0.3:
			global_position = pos_valida
			initial_path  = global_position
			current_path   = global_position
			posicao_de_spawn = global_position
		nav_agent.target_position = alvo_atual.global_position

# ==========================================
# FÍSICA CORRIGIDA (Sem conflito com o 'super')
# ==========================================
func _physics_process(delta: float) -> void:
	if is_teleporting:
		if not is_on_floor():
			velocity.y -= gravity * delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Previne congelamento se a torre foi destruída
	if alvo_atual == null or not is_instance_valid(alvo_atual):
		alvo_atual = procurar_novo_alvo()
		if alvo_atual and nav_agent:
			nav_agent.target_position = alvo_atual.global_position

	# 1. DEIXA A BASE RODAR PRIMEIRO
	# (Ela vai processar timers, animações, gravidade e tentar andar)
	super._physics_process(delta)

	if esta_morto or is_teleporting or alvo_atual == null:
		return

	# 2. VERIFICA SE A BASE FALHOU EM MOVER (Travou)
	var alvo_pos  := alvo_atual.global_position
	var dist_xz   := Vector2(global_position.x - alvo_pos.x, global_position.z - alvo_pos.z).length()
	var vel_horiz := Vector2(velocity.x, velocity.z).length_squared()

	# Se ele está longe do ataque, mas a velocidade horizontal é zero:
	if dist_xz > distancia_ataque and vel_horiz < 0.001:
		
		# 3. FALLBACK: Força o movimento manualmente
		var dir := global_position.direction_to(alvo_pos)
		dir.y = 0.0
		
		if dir.length_squared() > 0.01:
			dir = dir.normalized()
			var vel: float = velocidade * max(0.1, GameManager.multiplicador_velocidade_inimigo as float)
			velocity.x = dir.x * vel
			velocity.z = dir.z * vel
			
			# === O TRUQUE PARA NÃO TREMER (FLICK) ===
			# Salvamos a velocidade Y (gravidade) e zeramos provisoriamente
			# para o 2º move_and_slide() não duplicar o impacto com o chão.
			var gravidade_salva = velocity.y
			if is_on_floor():
				velocity.y = 0.0 
				
			# Rotação: Corrige o "Moonwalk" (virar para onde está andando)
			var look_pos = global_position + dir
			if not global_position.is_equal_approx(look_pos):
				look_at(look_pos, Vector3.UP, true)

			move_and_slide() # Aplica o movimento que o 'super' se recusou a fazer
			
			# Devolve a gravidade para a física do próximo frame funcionar normalmente
			velocity.y = gravidade_salva


# ==========================================
# DANO CORRIGIDO (Bug 3)
# ==========================================
# Removendo tipagem estrita (int/String) para evitar conflitos silenciosos com InimigoBase
func receber_dano(qtd, origem = "torre") -> void:
	super.receber_dano(qtd, origem)

	# Impede ativar teleporte múltiplo
	if has_teleported or is_teleporting or esta_morto:
		return

	var porcentagem: float = float(vida_atual) / float(vida_maxima)
	if porcentagem <= hp_gatilho_teleporte:
		_salto_fantasma()

# ==========================================
# HABILIDADE — Salto Fantasma
# ==========================================
func _salto_fantasma() -> void:
	# Trava dupla: não pode ativar mais de uma vez
	if has_teleported or is_teleporting:
		return

	has_teleported = true
	is_teleporting = true

	# --- 1. Para completamente ---
	velocity = Vector3.ZERO

	# --- 2. Preparação ---
	start_teleport_effect.emit(global_position)

	if modelo_3d:
		var tw_fade = create_tween()
		tw_fade.tween_property(
			modelo_3d, "modulate:a",
			alpha_preparacao,
			duracao_preparacao * 0.6
		)

	await get_tree().create_timer(duracao_preparacao).timeout

	# Abortado se o boss morreu durante a preparação
	if esta_morto:
		is_teleporting = false
		return

	# --- 3. Desaparece ---
	teleport_disappear.emit()
	if modelo_3d:
		modelo_3d.visible = false

	# --- 4. Seleciona novo caminho ---
	var novo_pos: Vector3 = _selecionar_novo_caminho()

	if novo_pos == Vector3.ZERO:
		# Nenhum caminho válido — desfaz sem punição
		if modelo_3d:
			modelo_3d.visible = true
			modelo_3d.modulate.a = 1.0
		is_teleporting = false
		return

	# --- 5. Reposiciona e reaparece ---
	current_path = novo_pos
	global_position = novo_pos

	# Aguarda a NavigationAgent registar a nova posição
	await get_tree().process_frame

	if modelo_3d:
		modelo_3d.modulate.a = alpha_preparacao
		modelo_3d.visible = true
		var tw_appear = create_tween()
		tw_appear.tween_property(modelo_3d, "modulate:a", 1.0, 0.4)

	teleport_reappear.emit(global_position)

	# Imunidade temporária de ataque — deixa o jogador se preparar
	pode_atacar = false
	await get_tree().create_timer(duracao_imunidade_pos_teleporte).timeout

	if not esta_morto:
		pode_atacar = true

	is_teleporting = false

# ==========================================
# SELECIONA NOVO CAMINHO
# Exclui: caminho atual + caminho inicial (spawn original)
# ==========================================
func _selecionar_novo_caminho() -> Vector3:
	var spawners: Array = get_tree().get_nodes_in_group("Spawner")
	var candidatos: Array[Vector3] = []

	for spawner in spawners:
		if not is_instance_valid(spawner):
			continue
		var pos: Vector3 = spawner.global_position
		# Exclui o caminho onde está agora
		if pos.distance_to(current_path) < 1.0:
			continue
		# Exclui o caminho onde nasceu
		if pos.distance_to(initial_path) < 1.0:
			continue
		candidatos.append(pos)

	if candidatos.is_empty():
		return Vector3.ZERO

	return candidatos[randi() % candidatos.size()]

func _init_navigation():
	initial_path = global_position
	current_path = global_position
	posicao_de_spawn = global_position

	alvo_atual = procurar_novo_alvo()

	if alvo_atual and nav_agent:
		nav_agent.target_position = alvo_atual.global_position
