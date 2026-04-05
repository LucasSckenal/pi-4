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
	BASE
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

# Define a escala padrão aplicada aos modelos 3D instanciados por esta construção.
@export var escala_modelo: Vector3 = Vector3(0.44, 0.44, 0.44)

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
@export var indicador_alcance: MeshInstance3D

# ==========================================
# CONFIGURAÇÕES ESPECÍFICAS PARA QUARTEL
# ==========================================
@export_group("Atributos de Quartel")
@export var cena_aliado: PackedScene
@export var numero_aliados_base: int = 1
@export var tempo_respawn: float = 5.0 # Tempo em segundos para respawnar
@export var ponto_spawn_path: NodePath
@onready var sprite_respawn = $SpriteRespawn
@onready var barra_respawn = $RespawnViewport/BarraRespawn

var soldados_vivos: int = 0 # Controle interno

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
# SISTEMA DE UPGRADES (BASE)
# ==========================================
@export_group("Upgrades Base")
@export var nivel_atual: int = 0
@export var upgrade_custos: Array[int] = []          # Usado se não tiver paths
@export var upgrade_dano_por_nivel: Array[int] = []
@export var upgrade_moedas_por_nivel: Array[int] = []
@export var upgrade_aliados_por_nivel: Array[int] = []
@export var upgrade_velocidade_por_nivel: Array[float] = []
@export var upgrade_alcance_por_nivel: Array[float] = []
@export var upgrade_vida_por_nivel: Array[int] = []
@export var modelos_por_nivel: Array[PackedScene] = []  # Modelos visuais para cada nível

# ==========================================
# SISTEMA DE PATHS (MÚLTIPLOS CAMINHOS)
# ==========================================
@export_group("Sistema de Paths")
@export var tem_paths: bool = false
@export var upgrade_paths: Array[UpgradePathData] = []
var caminho_atual: int = -1  # -1 = nenhum caminho escolhido

# ==========================================
# REFERÊNCIAS
# ==========================================
@onready var ponto_tiro = get_node_or_null(ponto_de_tiro)
@onready var ponto_spawn = get_node_or_null(ponto_spawn_path)
@onready var area_ataque = get_node_or_null(area_ataque_path)
@onready var barra_vida = get_node_or_null(caminho_barra_vida) if tem_barra_vida else null
@onready var container_barra = get_node_or_null(caminho_container_barra) if tem_barra_vida else null
@onready var timer_ataque = get_node_or_null("TimerAtaque") if tipo == TipoConstrucao.TORRE else null
@onready var modelo_anchor = $ModeloAnchor  # Nó vazio para conter o modelo 3D

# ==========================================
# INFORMAÇÕES DE INTERFACE
# ==========================================
@export_group("Interface")
@export var nome_construcao: String = "Construção"
@export var icone: Texture2D

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var y_inicial: float
var is_fantasma: bool = false
var vida_atual: int
var inimigos_no_alcance = []
var alvo_atual: Node3D = null
var esta_destruida: bool = false

# Valores atuais após upgrades (calculados dinamicamente)
var dano_atual: int
var moedas_por_onda_atual: int
var numero_aliados_atual: int
var tempo_ataque_atual: float
var alcance_atual: float

signal construcao_selecionada(construcao: Node)

func _ready():
	
	y_inicial = position.y
	
	if is_fantasma:
		_modo_fantasma()
		return
		
	# if indicador_alcance:
#     indicador_alcance.visible = false
	
	
		
	if modelo_anchor == null:
		modelo_anchor = Node3D.new()
		modelo_anchor.name = "ModeloAnchor"
		add_child(modelo_anchor)
	
	_atualizar_valores_pos_upgrades()
	vida_atual = vida_maxima
	_inicializar_barra_vida()
	
	# Carrega o modelo do nível atual (se houver)
	_trocar_modelo(nivel_atual)
	if sprite_respawn:
		sprite_respawn.visible = false
		
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
			add_to_group("Base")
			print("Base principal estabelecida. Nível: ", nivel_atual)
	
	# Área de clique (se existir)
	if has_node("AreaClique"):
		$AreaClique.input_event.connect(_on_area_clique)
	
	# Notifica a interface sobre a existência desta construção após a inicialização dos grupos
	for interface_node in get_tree().get_nodes_in_group("Interface"):
		if interface_node.has_method("_conectar_construcao"):
			interface_node._conectar_construcao(self)

# ==========================================
# TRAVA CENTRAL DO TUTORIAL
# ==========================================
func _pode_interagir_tutorial() -> bool:
	if GameManager.is_tutorial_ativo:
		var tutorial = get_tree().get_first_node_in_group("TutorialManager")
		if tutorial and tutorial.visible:
			# REGRA 1: Se o tutorial manda clicar na UI, BLOQUEIA o 3D
			if tutorial.alvo_2d_atual != null:
				return false
			# REGRA 2: Se o tutorial manda clicar noutro objeto que não este, BLOQUEIA
			if tutorial.alvo_3d_atual != null and tutorial.alvo_3d_atual != self:
				return false
	return true

func _on_area_clique(camera, event, position, normal, shape_idx):
	if esta_destruida: return  
	
	var clicou_mouse = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	var tocou_tela = (event is InputEventScreenTouch and event.pressed)
	
	if clicou_mouse or tocou_tela:
		if _pode_interagir_tutorial(): 
			construcao_selecionada.emit(self)
			
			# ACENDE O ANEL
			if tipo == TipoConstrucao.TORRE and indicador_alcance:
				indicador_alcance.visible = true
				print("Anel foi ligado!")

# ==========================================
# SISTEMA DE UPGRADES (LÓGICA PRINCIPAL)
# ==========================================
func _atualizar_valores_pos_upgrades():
	# Se tem paths e já escolheu um caminho, usa os valores do path
	if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
		var path = upgrade_paths[caminho_atual]
		var idx = nivel_atual - 1  # arrays começam em 0 para nível 1
		if idx >= 0:
			dano_atual = dano + (path.dano_por_nivel[idx] if idx < path.dano_por_nivel.size() else 0)
			moedas_por_onda_atual = moedas_por_onda + (path.moedas_por_nivel[idx] if idx < path.moedas_por_nivel.size() else 0)
			numero_aliados_atual = numero_aliados_base + (path.aliados_por_nivel[idx] if idx < path.aliados_por_nivel.size() else 0)
			tempo_ataque_atual = tempo_ataque_base - (path.velocidade_por_nivel[idx] if idx < path.velocidade_por_nivel.size() else 0.0)
			alcance_atual = alcance + (path.alcance_por_nivel[idx] if idx < path.alcance_por_nivel.size() else 0.0)
			vida_maxima += (path.vida_por_nivel[idx] if idx < path.vida_por_nivel.size() else 0)
		else:
			# Nível 0 (antes do primeiro upgrade) – valores base
			dano_atual = dano
			moedas_por_onda_atual = moedas_por_onda
			numero_aliados_atual = numero_aliados_base
			tempo_ataque_atual = tempo_ataque_base
			alcance_atual = alcance
	else:
		# Sem paths ou ainda não escolheu – usa os arrays base
		var idx = nivel_atual - 1
		if idx >= 0:
			dano_atual = dano + (upgrade_dano_por_nivel[idx] if idx < upgrade_dano_por_nivel.size() else 0)
			moedas_por_onda_atual = moedas_por_onda + (upgrade_moedas_por_nivel[idx] if idx < upgrade_moedas_por_nivel.size() else 0)
			numero_aliados_atual = numero_aliados_base + (upgrade_aliados_por_nivel[idx] if idx < upgrade_aliados_por_nivel.size() else 0)
			tempo_ataque_atual = tempo_ataque_base - (upgrade_velocidade_por_nivel[idx] if idx < upgrade_velocidade_por_nivel.size() else 0.0)
			alcance_atual = alcance + (upgrade_alcance_por_nivel[idx] if idx < upgrade_alcance_por_nivel.size() else 0.0)
			vida_maxima += (upgrade_vida_por_nivel[idx] if idx < upgrade_vida_por_nivel.size() else 0)
		else:
			# Nível 0
			dano_atual = dano
			moedas_por_onda_atual = moedas_por_onda
			numero_aliados_atual = numero_aliados_base
			tempo_ataque_atual = tempo_ataque_base
			alcance_atual = alcance
	
	# Garante valores mínimos
	tempo_ataque_atual = max(0.1, tempo_ataque_atual)

func get_custo_proximo_upgrade() -> int:
	# Retorna o custo do próximo upgrade, ou -1 se não houver
	if tem_paths:
		if caminho_atual == -1:
			# Primeira escolha: retorna o menor custo entre os caminhos? Melhor deixar a UI lidar com múltiplos.
			# Para compatibilidade, retorna -1, indicando que há múltiplas opções.
			return -1
		else:
			var path = upgrade_paths[caminho_atual]
			if nivel_atual < path.custos.size():
				return path.custos[nivel_atual]
	else:
		if nivel_atual < upgrade_custos.size():
			return upgrade_custos[nivel_atual]
	return -1

# FUNÇÃO ATUALIZADA NO BUILDS.GD
func get_opcoes_proximo_upgrade() -> Array:
	var opcoes = []
	var escala_perfeita_ui = _calcular_escala_ideal_para_ui()

	if tem_paths and caminho_atual == -1:
		# Primeira escolha: todos os caminhos disponíveis
		for i in range(upgrade_paths.size()):
			var path = upgrade_paths[i]
			if path and path.custos.size() > 0:
				var nome_path = path.nome
				if nome_path == null or nome_path == "":
					nome_path = "Caminho " + str(i + 1)
				
				var escala_deste_path = _calcular_escala_ideal_para_ui(path)
				
				# Pega o modelo do NÍVEL 0 deste caminho específico
				var modelo_correto = null
				if path.modelos_por_nivel.size() > 0:
					modelo_correto = path.modelos_por_nivel[0]

				opcoes.append({
					"index": i,
					"nome": nome_path,
					"icone": path.icone,
					"custo": path.custos[0],
					"beneficio": _descrever_beneficio(path, 0),
					"modelo_3d": modelo_correto, # <-- AGORA ENVIA SÓ 1 MODELO
					"escala_modelo": escala_deste_path
				})
	elif tem_paths and caminho_atual >= 0:
		# Já tem caminho: próximo nível desse caminho
		var path = upgrade_paths[caminho_atual]
		var prox_nivel = nivel_atual
		if path and prox_nivel < path.custos.size():
			var nome_path = path.nome
			if nome_path == null or nome_path == "":
				nome_path = "Upgrade"
			
			var escala_deste_path = _calcular_escala_ideal_para_ui(path)
			
			# Pega o modelo do PRÓXIMO NÍVEL exato!
			var modelo_correto = null
			if prox_nivel < path.modelos_por_nivel.size():
				modelo_correto = path.modelos_por_nivel[prox_nivel]

			opcoes.append({
				"index": caminho_atual,
				"nome": nome_path,
				"icone": path.icone,
				"custo": path.custos[prox_nivel],
				"beneficio": _descrever_beneficio(path, prox_nivel),
				"modelo_3d": modelo_correto, # <-- AGORA ENVIA SÓ 1 MODELO
				"escala_modelo": escala_deste_path
			})
	else:
		# Sem paths: opção única (upgrade linear)
		var custo = get_custo_proximo_upgrade()
		if custo != -1:
			
			# Pega o modelo do PRÓXIMO NÍVEL na lista geral
			var modelo_correto = null
			if nivel_atual < modelos_por_nivel.size():
				modelo_correto = modelos_por_nivel[nivel_atual]
				
			opcoes.append({
				"index": 0,
				"nome": "Upgrade",
				"icone": icone,
				"custo": custo,
				"beneficio": _descrever_beneficio_simples(),
				"modelo_3d": modelo_correto, # <-- AGORA ENVIA SÓ 1 MODELO
				"escala_modelo": escala_perfeita_ui
			})
	return opcoes
# NOVA FUNÇÃO AUXILIAR NO BUILDS.GD
func _calcular_escala_ideal_para_ui(path_data: Resource = null) -> Vector3:
	# 1. Tenta pegar a escala específica definida no PathData (se existir no futuro)
	if path_data and path_data.get("escala_ui_customizada") != null:
		return path_data.escala_ui_customizada
		
	# 2. Senão, calcula baseado no Tipo de Construção (Enum do Builds.gd)
	var tipo_construcao = self.tipo # Acessa o tipo da tua construção atual
	
	# Valores base sugeridos (Ajuste aqui conforme necessário)
	var escala_padrao_pequena = Vector3(1.2, 1.2, 1.2) # Bom para Casas
	var escala_padrao_media = Vector3(0.8, 0.8, 0.8)   # Bom para Minas/Moinhos
	var escala_padrao_grande = Vector3(0.5, 0.5, 0.5)  # Bom para Torres/Quartéis
	
	match tipo_construcao:
		0: # TORRE
			return escala_padrao_grande
		1: # MINA
			return escala_padrao_pequena
		2: # CASA
			return escala_padrao_pequena
		3: # MOINHO
			return escala_padrao_media
		4: # QUARTEL
			return escala_padrao_grande
		5: # BASE
			return escala_padrao_grande
		_:
			return Vector3(1, 1, 1) # Fallback seguro
func _descrever_beneficio(path: UpgradePathData, nivel: int) -> String:
	var partes = []
	if nivel < path.dano_por_nivel.size() and path.dano_por_nivel[nivel] != 0:
		partes.append("Dano +%d" % path.dano_por_nivel[nivel])
	if nivel < path.moedas_por_nivel.size() and path.moedas_por_nivel[nivel] != 0:
		partes.append("Moedas +%d" % path.moedas_por_nivel[nivel])
	if nivel < path.aliados_por_nivel.size() and path.aliados_por_nivel[nivel] != 0:
		partes.append("Aliados +%d" % path.aliados_por_nivel[nivel])
	if nivel < path.velocidade_por_nivel.size() and path.velocidade_por_nivel[nivel] != 0:
		partes.append("Vel. -%.2f" % path.velocidade_por_nivel[nivel])
	if nivel < path.alcance_por_nivel.size() and path.alcance_por_nivel[nivel] != 0:
		partes.append("Alcance +%.1f" % path.alcance_por_nivel[nivel])
	if nivel < path.vida_por_nivel.size() and path.vida_por_nivel[nivel] != 0:
		partes.append("Vida +%d" % path.vida_por_nivel[nivel])
	if partes.size() == 0:
		return "Melhora geral"
	return " | ".join(partes)

func _descrever_beneficio_simples() -> String:
	# Para upgrades sem path, descreve com base nos arrays base
	var nivel = nivel_atual
	var partes = []
	if nivel < upgrade_dano_por_nivel.size() and upgrade_dano_por_nivel[nivel] != 0:
		partes.append("Dano +%d" % upgrade_dano_por_nivel[nivel])
	if nivel < upgrade_moedas_por_nivel.size() and upgrade_moedas_por_nivel[nivel] != 0:
		partes.append("Moedas +%d" % upgrade_moedas_por_nivel[nivel])
	if nivel < upgrade_aliados_por_nivel.size() and upgrade_aliados_por_nivel[nivel] != 0:
		partes.append("Aliados +%d" % upgrade_aliados_por_nivel[nivel])
	if nivel < upgrade_velocidade_por_nivel.size() and upgrade_velocidade_por_nivel[nivel] != 0:
		partes.append("Vel. -%.2f" % upgrade_velocidade_por_nivel[nivel])
	if nivel < upgrade_alcance_por_nivel.size() and upgrade_alcance_por_nivel[nivel] != 0:
		partes.append("Alcance +%.1f" % upgrade_alcance_por_nivel[nivel])
	if nivel < upgrade_vida_por_nivel.size() and upgrade_vida_por_nivel[nivel] != 0:
		partes.append("Vida +%d" % upgrade_vida_por_nivel[nivel])
	if partes.size() == 0:
		return "Melhora geral"
	return " | ".join(partes)

func aplicar_upgrade(index: int = 0) -> bool:
	# index é o índice do caminho escolhido (usado apenas se tem_paths e caminho_atual == -1)
	if tem_paths and caminho_atual == -1:
		# Primeira escolha de caminho
		if index < 0 or index >= upgrade_paths.size():
			return false
		var path = upgrade_paths[index]
		var custo = path.custos[0] if path.custos.size() > 0 else 0
		if GameManager.gastar_moedas(custo):
			caminho_atual = index
			nivel_atual = 1
			_atualizar_valores_pos_upgrades()
			_trocar_modelo(nivel_atual)
			if tipo == TipoConstrucao.BASE:
				GameManager.nivel_base = nivel_atual
				GameManager.upgrade_base_aplicado.emit()
			if tipo == TipoConstrucao.TORRE:
				_configurar_alcance()
				atualizar_status()
			print("%s escolheu caminho %s e subiu para nível 1" % [name, path.nome])
			return true
		else:
			return false
	else:
		# Upgrade normal (com ou sem path já escolhido)
		var custo = get_custo_proximo_upgrade()
		if custo == -1:
			return false
		if GameManager.gastar_moedas(custo):
			nivel_atual += 1
			_atualizar_valores_pos_upgrades()
			_trocar_modelo(nivel_atual)
			if tipo == TipoConstrucao.BASE:
				GameManager.nivel_base = nivel_atual
				GameManager.upgrade_base_aplicado.emit()
			if tipo == TipoConstrucao.TORRE:
				_configurar_alcance()
				atualizar_status()
			print("%s upgrade para nível %d" % [name, nivel_atual])
			return true
	return false

func _trocar_modelo(nivel: int):
	# Remove modelo antigo
	for child in modelo_anchor.get_children():
		child.queue_free()
	
	# Escolhe o modelo baseado na configuração
	var modelo_scene = null
	if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
		var path = upgrade_paths[caminho_atual]
		var idx = nivel - 1
		if idx >= 0 and idx < path.modelos_por_nivel.size():
			modelo_scene = path.modelos_por_nivel[idx]
	else:
		var idx = nivel - 1
		if idx >= 0 and idx < modelos_por_nivel.size():
			modelo_scene = modelos_por_nivel[idx]
	
	# Aplica o modelo
	if modelo_scene:
		var modelo = modelo_scene.instantiate()
		modelo_anchor.add_child(modelo)
		modelo.scale = escala_modelo
		
		# Esconde as malhas da torre base para evitar sobreposição
		_esconder_malhas_originais(self)
	else:
		# APENAS avisa no console, sem instanciar a própria cena!
		push_warning(name + ": Nenhum modelo configurado para o nível " + str(nivel))

# Nova função para ocultar o modelo 3D original que veio do .glb
func _esconder_malhas_originais(no: Node):
	for filho in no.get_children():
		if filho == modelo_anchor:
			continue 
		
		# Protege o anel para ele não ser apagado!
		if indicador_alcance and filho == indicador_alcance:
			continue 
			
		if filho is MeshInstance3D:
			filho.hide()
		elif filho.get_child_count() > 0:
			_esconder_malhas_originais(filho)

# ==========================================
# DEMAIS FUNÇÕES (MANTIDAS IGUAIS)
# ==========================================
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

func _configurar_alcance():
	if area_ataque and area_ataque.has_node("CollisionShape3D"):
		
		# 1. CONSRETA O BUG DO CLIQUE: O mouse vai ignorar essa área gigante
		area_ataque.input_ray_pickable = false 
		
		# 2. CONSERTA O BUG DE ATIRAR LONGE: Separa a área de cada torre
		var shape_original = area_ataque.get_node("CollisionShape3D").shape
		var shape_unica = shape_original.duplicate() # <- A mágica acontece aqui!
		area_ataque.get_node("CollisionShape3D").shape = shape_unica
		
		if shape_unica is SphereShape3D or shape_unica is CylinderShape3D:
			shape_unica.radius = alcance_atual
			
		print("Alcance da torre ajustado para: ", alcance_atual)

	# 3. FAZ O ANEL APARECER NO TAMANHO CERTO
	if indicador_alcance:
		indicador_alcance.scale = Vector3(alcance_atual * 2, 1, alcance_atual * 2)

# ==========================================
# SISTEMA DE ATAQUE (TORRE)
# ==========================================
func _on_area_ataque_body_entered(body):
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	if body.is_in_group("inimigos") or body.is_in_group("Inimigos"):
		if not body in inimigos_no_alcance:
			inimigos_no_alcance.append(body)

func _on_area_ataque_body_exited(body):
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

func _process(_delta):
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	inimigos_no_alcance = inimigos_no_alcance.filter(func(inimigo): return is_instance_valid(inimigo))
	alvo_atual = inimigos_no_alcance.front() if inimigos_no_alcance.size() > 0 else null

func _on_timer_ataque_timeout():
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
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
	if is_fantasma or esta_destruida: return
	var ondas_restantes = GameManager.onda_atual
	var bonus_onda = max(1, 6 - GameManager.onda_atual)  # Ajuste conforme balanceamento
	
	var moedas_geradas = moedas_por_onda_atual + bonus_onda
	GameManager.moedas += moedas_geradas
	
	print("%s gerou %d moedas" % [name, moedas_geradas])
	get_tree().call_group("Interface", "atualizar_moedas")
	if tipo == TipoConstrucao.MOINHO:
		get_tree().call_group("Interface", "animar_bau_abrindo")

# ==========================================
# SISTEMA DO QUARTEL (SPAWN DE ALIADOS)
# ==========================================
func _spawn_aliados(_onda_atual):
	if is_fantasma or esta_destruida or cena_aliado == null:
		return
		
	# Trava de segurança: só spawna o que falta para completar o limite
	var quantidade_para_spawnar = numero_aliados_atual - soldados_vivos
	if quantidade_para_spawnar <= 0:
		return
		
	for i in range(quantidade_para_spawnar):
		_criar_um_aliado()

func _criar_um_aliado():
	var aliado = cena_aliado.instantiate()
	get_tree().current_scene.add_child(aliado)
	
	# 1. Pega a posição base
	var posicao_base = global_position
	if ponto_spawn:
		posicao_base = ponto_spawn.global_position
		
	# 2. Sorteia um ponto ao redor
	var pos_aleatoria = posicao_base + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	
	# 3. Raio da Física (RayCast)
	var espaco_fisica = get_world_3d().direct_space_state
	var origem_raio = pos_aleatoria + Vector3(0, 5.0, 0)
	var destino_raio = pos_aleatoria + Vector3(0, -10.0, 0)
	var query = PhysicsRayQueryParameters3D.create(origem_raio, destino_raio)
	
	var colisao = espaco_fisica.intersect_ray(query)
	
	# 4. Posiciona o soldado (Validação de terreno)
	if colisao:
		# Se colidir com água, tenta centralizar no ponto de spawn original
		if colisao.collider.is_in_group("Agua"):
			aliado.global_position = posicao_base
		else:
			aliado.global_position = colisao.position
	else:
		aliado.global_position = pos_aleatoria
	
	aliado.add_to_group("aliados")
	soldados_vivos += 1
	
	if aliado.has_signal("morreu"):
		aliado.morreu.connect(_on_aliado_morreu)

func _on_aliado_morreu(aliado_morto: Node):
	soldados_vivos -= 1
	
	# 1. MOSTRA A BARRA E INICIA A ANIMAÇÃO
	if sprite_respawn and barra_respawn:
		sprite_respawn.visible = true
		barra_respawn.value = 0.0
		
		var tween = create_tween()
		tween.tween_property(barra_respawn, "value", 100.0, tempo_respawn)
	
	# 2. AGUARDA O TEMPO DO TIMER DO JOGO
	await get_tree().create_timer(tempo_respawn).timeout
	
	# 3. VERIFICA SE A CONSTRUÇÃO AINDA EXISTE E NÃO ESTÁ DESTRUÍDA
	if not is_instance_valid(self) or esta_destruida or soldados_vivos >= numero_aliados_atual:
		return
	
	# 4. CRIA O NOVO SOLDADO
	_criar_um_aliado()
	
	# 5. ESCONDE A BARRA (Apenas se o quartel estiver com todos os soldados vivos novamente)
	if sprite_respawn and soldados_vivos >= numero_aliados_atual:
		sprite_respawn.visible = false

# ==========================================
# SISTEMA DE DANO (COMUM A TODOS)
# ==========================================
func receber_dano(quantidade: int):
	if is_fantasma or esta_destruida: return
	vida_atual -= quantidade
	if tem_barra_vida and container_barra:
		container_barra.visible = true
		if barra_vida:
			barra_vida.value = vida_atual
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", y_inicial + 0.15, 0.05)
	tween.tween_property(self, "position:y", y_inicial, 0.05)
	
	if vida_atual <= 0:
		destruir()

func destruir():
	print("%s destruída!" % name)
	if tipo == TipoConstrucao.BASE:
		GameManager.acionar_game_over() 
		return

	esta_destruida = true
	visible = false 
	
	# Remove do grupo para os Orcs pararem de focar nela
	remove_from_group("Construcao")
	
	# Desconectar sinais para evitar chamadas após destruição
	if tipo in [TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO]:
		if GameManager.onda_terminada.is_connected(_pagar_recompensa):
			GameManager.onda_terminada.disconnect(_pagar_recompensa)
	elif tipo == TipoConstrucao.QUARTEL:
		if GameManager.noite_iniciada.is_connected(_spawn_aliados):
			GameManager.noite_iniciada.disconnect(_spawn_aliados)
	
	if timer_ataque:
		timer_ataque.stop()
		
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)
		
	if not GameManager.onda_terminada.is_connected(reviver):
		GameManager.onda_terminada.connect(reviver)

func reviver():
	print("%s reconstruída!" % name)
	esta_destruida = false
	visible = true
	vida_atual = vida_maxima
	
	# MOSTRA AOS ORCS NOVAMENTE
	add_to_group("Construcao")
	
	# Reconectar sinais específicos
	match tipo:
		TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO:
			if not GameManager.onda_terminada.is_connected(_pagar_recompensa):
				GameManager.onda_terminada.connect(_pagar_recompensa)
		TipoConstrucao.QUARTEL:
			if not GameManager.noite_iniciada.is_connected(_spawn_aliados):
				GameManager.noite_iniciada.connect(_spawn_aliados)
	
	_inicializar_barra_vida()
	
	if timer_ataque and tipo == TipoConstrucao.TORRE:
		timer_ataque.start()
		
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", false)
		
	if GameManager.onda_terminada.is_connected(reviver):
		GameManager.onda_terminada.disconnect(reviver)

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

func esconder_indicador():
	if indicador_alcance:
		indicador_alcance.visible = false
		
# ==========================================
# SISTEMA DE VENDA
# ==========================================
func vender_construcao():
	# SISTEMA DE PROTEÇÃO: Impede vender a base principal
	if tipo == TipoConstrucao.BASE:
		print("Operação cancelada: A Base não pode ser vendida!")
		return
	
	# Calcula o retorno (metade do custo)
	var valor_de_venda = custo_moedas / 2
	
	# Entrega o dinheiro usando a função nova (que já atualiza a HUD)
	GameManager.adicionar_moedas(valor_de_venda)
	
	# Remove a construção
	queue_free()
