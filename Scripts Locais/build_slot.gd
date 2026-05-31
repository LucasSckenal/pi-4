extends Node3D

signal slot_clicado

# ==========================================
# CONFIGURAÇÕES EXPORTADAS
# ==========================================
@export var nivel_necessario: int = 1           # Nível mínimo da base para este slot ficar disponível
@export var ui_construcao_prefab: PackedScene   # Cena da UI (radial ou grade) que será instanciada
@export var manter_tamanho_visual_fixo: bool = true
@export var escala_visual_minima: float = 0.55
@export var escala_visual_maxima: float = 2.8
@export var bolha_tamanho_base: float = 96.0
@export var bolha_escala_zoom_minima: float = 1.0
@export var bolha_escala_zoom_maxima: float = 1.8

# ==========================================
# REFERÊNCIAS (ajuste os nomes conforme sua cena)
# ==========================================
@onready var area = $Area3D
@onready var base_mesh = $BaseMesh
@onready var bolha_btn = $CanvasLayer/TextureButton
@onready var canvas_mobile = $CanvasLayer

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var is_built = false                # Já construiu algo aqui?
var estado_toque_mobile = 0         # 0 = nenhum toque, 1 = primeiro toque (esperando confirmação)
var player_ref_teclado = null       # Referência ao jogador (para PC)
var pode_construir: bool = true     # Controlado pelo ciclo dia/noite
var slot_disponivel: bool = false   # Controlado pelo nível da base
var ui_atual: Control = null        # Referência à UI instanciada
var _tween_destaque: Tween = null   # Animação de destaque do conselheiro

# Throttle: evita chamar unproject_position todo frame (caro em mobile)
var _timer_cam: float = 0.0
var _pos2d_cache: Vector2 = Vector2.ZERO
var _base_mesh_scale_original: Vector3 = Vector3.ONE
var _distancia_camera_referencia: float = 0.0
var _fov_camera_referencia: float = 0.0
var _size_camera_referencia: float = 0.0
var _bolha_hover_scale: float = 1.0

func _ready():
	add_to_group("BuildSlots")

	# Configura visibilidade inicial baseada na plataforma
	if canvas_mobile:
		# Verifica também o recurso 'pc' para garantir a exibição em exportações para desktop
		canvas_mobile.visible = OS.has_feature("mobile") or OS.has_feature("editor") or OS.has_feature("pc")
		canvas_mobile.layer = 1
	
	# Conecta sinais do GameManager
	if GameManager.has_signal("dia_iniciado"):
		GameManager.dia_iniciado.connect(_ao_iniciar_dia)
	if GameManager.has_signal("noite_iniciada"):
		GameManager.noite_iniciada.connect(_ao_iniciar_noite)
	if GameManager.has_signal("upgrade_base_aplicado"):
		GameManager.upgrade_base_aplicado.connect(_verificar_disponibilidade)
	
	# Verifica disponibilidade inicial
	_verificar_disponibilidade()
	
	# Conecta o sinal de input da área (para clique no PC)
	if area:
		area.input_event.connect(_on_area_input_event)

	# Define o pivô no centro e o cursor do mouse
	if bolha_btn:
		bolha_btn.mouse_default_cursor_shape = Control.CURSOR_CROSS
		_configurar_tamanho_bolha()

	if base_mesh:
		_base_mesh_scale_original = base_mesh.scale

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
			# REGRA 2: Se o tutorial manda clicar noutro lote que não este, BLOQUEIA
			if tutorial.alvo_3d_atual != null and tutorial.alvo_3d_atual != self:
				return false
	return true # Se passar pelas travas (ou não tiver tutorial), permite clicar!

# ==========================================
# CONTROLE DE DISPONIBILIDADE POR NÍVEL DA BASE
# ==========================================
func _verificar_disponibilidade():
	var nivel_base = GameManager.nivel_base if "nivel_base" in GameManager else 1
	slot_disponivel = (nivel_base >= nivel_necessario)
	
	if not is_built:
		if slot_disponivel:
			_atualizar_visibilidade_por_tempo()
		else:
			_esconder_todos_elementos()

# ==========================================
# CONTROLE DE VISIBILIDADE POR DIA/NOITE
# ==========================================
func _ao_iniciar_dia(_onda):
	pode_construir = true
	_atualizar_visibilidade_por_tempo()

func _ao_iniciar_noite(_onda):
	pode_construir = false
	parar_destaque()
	cancelar_selecao()
	_atualizar_visibilidade_por_tempo()
	fechar_ui()

func _atualizar_visibilidade_por_tempo():
	if is_built or not slot_disponivel:
		return
	
	var dia = not GameManager.is_night
	pode_construir = dia
	
	if dia:
		if base_mesh: base_mesh.show()
		# Verifica também o recurso 'pc' para garantir a exibição em exportações para desktop
		if canvas_mobile: canvas_mobile.visible = OS.has_feature("mobile") or OS.has_feature("editor") or OS.has_feature("pc")
		# bolha_btn usa top_level=true — mostrar explicitamente para não depender só do _process
		if bolha_btn and estado_toque_mobile == 0: bolha_btn.show()
	else:
		_esconder_todos_elementos()

func _esconder_todos_elementos():
	if base_mesh: base_mesh.hide()
	if canvas_mobile: canvas_mobile.hide()
	# bolha_btn tem top_level=true e não herda a visibilidade do CanvasLayer pai —
	# precisa ser escondida explicitamente para não ficar "travada" na tela.
	if bolha_btn: bolha_btn.hide()
	fechar_ui()

# ==========================================
# LÓGICA DE ABERTURA DA UI
# ==========================================
func _abrir_ui():
	if ui_atual:
		return
	if not ui_construcao_prefab:
		if Global.DEBUG_MODE:
			print("ERRO: ui_construcao_prefab não atribuída no slot!")
		return
		
	slot_clicado.emit()
	ui_atual = ui_construcao_prefab.instantiate()
	
	# Adiciona ao CanvasLayer do slot para garantir que renderize sobre o mundo 3D
	if canvas_mobile:
		canvas_mobile.layer = 100 # Eleva a camada para sobrepor outros CanvasLayers
		canvas_mobile.add_child(ui_atual)
	else:
		get_tree().current_scene.add_child(ui_atual)
	
	# O radial_menu usa PRESET_FULL_RECT internamente, posição deve ser zero
	ui_atual.position = Vector2.ZERO
	
	ui_atual.abrir_menu(self)
	
	if bolha_btn: bolha_btn.hide()

func fechar_ui():
	if ui_atual:
		ui_atual.fechar_menu()  # A UI deve ter um método "fechar_menu()"
		ui_atual.queue_free()
		ui_atual = null

		if canvas_mobile:
			canvas_mobile.layer = 1 # Retorna a camada ao nível padrão

		# Só mostra a bolha se o lote ainda estiver disponível para construção.
		# bolha_btn usa top_level=true (não herda visibilidade do CanvasLayer),
		# por isso precisa ser controlado explicitamente aqui.
		if bolha_btn and not is_built and pode_construir and slot_disponivel:
			bolha_btn.show()

# ==========================================
# CONSTRUÇÃO (chamada pela UI após compra)
# ==========================================
func construir(cena: PackedScene) -> bool:
	if is_built:
		return false

	# Instancia uma única vez — reutiliza para construir ou descarta se sem moedas
	var nova_const = cena.instantiate()
	var custo_final = GameManager.obter_custo_com_desconto(nova_const.custo_moedas)

	if not GameManager.gastar_moedas(custo_final):
		nova_const.free()
		return false

	parar_destaque()
	add_child(nova_const)
	nova_const.global_position = global_position
	nova_const.is_fantasma = false
	is_built = true

	if base_mesh: base_mesh.hide()
	if canvas_mobile: canvas_mobile.hide()

	nova_const.tree_exited.connect(reativar_slot)

	fechar_ui()
	return true

# ==========================================
# NOVO: REATIVAÇÃO DO SLOT APÓS VENDA
# ==========================================
func reativar_slot():
	is_built = false
	estado_toque_mobile = 0
	
	# Garante que o Canvas (bolha) e a malha do chão voltem a aparecer
	if base_mesh: base_mesh.show()
	if canvas_mobile: 
		canvas_mobile.show() # Mostra o pai
		if bolha_btn:
			bolha_btn.modulate.a = 1.0 # Garante que a bolha não esteja transparente
			bolha_btn.scale = Vector2(1.0, 1.0)
			bolha_btn.show()
			
	# Reavalia se deve estar disponível (nível da base/dia/noite)
	_verificar_disponibilidade()

# ==========================================
# INTERAÇÕES (PC E MOBILE)
# ==========================================
func _process(delta):
	_atualizar_tamanho_visual_fixo()

	if is_built or not pode_construir or not slot_disponivel or ui_atual:
		return
	
	# Posicionamento da bolha mobile (segue o mundo 3D)
	if canvas_mobile and canvas_mobile.visible and is_instance_valid(bolha_btn):
		var camera = get_viewport().get_camera_3d()
		if camera and not camera.is_position_behind(global_position):
			# Throttle: unproject_position a 20 fps — caro em mobile, imperceptível na UI
			_timer_cam -= delta
			if _timer_cam <= 0.0:
				_timer_cam = 0.05
				_pos2d_cache = camera.unproject_position(global_position)
			_configurar_tamanho_bolha()
			bolha_btn.position = _pos2d_cache - (bolha_btn.size / 2)
			
			# Transição suave de escala e cor baseada no hover do mouse
			var hover = bolha_btn.is_hovered()
			_bolha_hover_scale = 1.15 if hover else 1.0
			var escala_zoom := _obter_escala_bolha_por_zoom(camera)
			var escala_alvo = Vector2.ONE * escala_zoom * _bolha_hover_scale
			bolha_btn.scale = bolha_btn.scale.lerp(escala_alvo, 15.0 * delta)
			
			var cor_alvo = Color(1.2, 1.2, 1.2) if hover else Color(1.0, 1.0, 1.0)
			bolha_btn.modulate = bolha_btn.modulate.lerp(cor_alvo, 15.0 * delta)
			
			if estado_toque_mobile == 0:
				bolha_btn.show()
		else:
			bolha_btn.hide()
	
	# Tecla "E" no PC
	if pode_construir and player_ref_teclado != null and Input.is_action_just_pressed("interact"):
		if _pode_interagir_tutorial(): # <-- APLICAÇÃO DA TRAVA AQUI
			_abrir_ui()

func _atualizar_tamanho_visual_fixo() -> void:
	if not manter_tamanho_visual_fixo or not is_instance_valid(base_mesh) or not base_mesh.visible:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	if _distancia_camera_referencia <= 0.0:
		_distancia_camera_referencia = camera.global_position.distance_to(global_position)
		_fov_camera_referencia = camera.fov
		_size_camera_referencia = camera.size
		return

	var fator := 1.0
	if camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		var distancia_atual := maxf(0.01, camera.global_position.distance_to(global_position))
		var tangente_ref := tan(deg_to_rad(_fov_camera_referencia) * 0.5)
		var tangente_atual := tan(deg_to_rad(camera.fov) * 0.5)
		fator = (distancia_atual * tangente_atual) / maxf(0.01, _distancia_camera_referencia * tangente_ref)
	else:
		fator = camera.size / maxf(0.01, _size_camera_referencia)

	fator = clampf(fator, escala_visual_minima, escala_visual_maxima)
	base_mesh.scale = _base_mesh_scale_original * fator

func _configurar_tamanho_bolha() -> void:
	if not is_instance_valid(bolha_btn):
		return
	var tamanho := Vector2.ONE * bolha_tamanho_base
	if bolha_btn.size != tamanho:
		bolha_btn.custom_minimum_size = tamanho
		bolha_btn.size = tamanho
		bolha_btn.pivot_offset = tamanho * 0.5

func _obter_escala_bolha_por_zoom(camera: Camera3D) -> float:
	if camera == null:
		return 1.0
	if _distancia_camera_referencia <= 0.0:
		return 1.0

	var fator := 1.0
	if camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		var distancia_atual := maxf(0.01, camera.global_position.distance_to(global_position))
		var tangente_ref := tan(deg_to_rad(_fov_camera_referencia) * 0.5)
		var tangente_atual := tan(deg_to_rad(camera.fov) * 0.5)
		var escala_mundo := (_distancia_camera_referencia * tangente_ref) / maxf(0.01, distancia_atual * tangente_atual)
		fator = sqrt(maxf(1.0, escala_mundo))
	else:
		fator = _size_camera_referencia / maxf(0.01, camera.size)
	return clampf(fator, bolha_escala_zoom_minima, bolha_escala_zoom_maxima)

func _input(event):
	if not pode_construir or not slot_disponivel or ui_atual:
		return
	
	# Clique fora para cancelar a seleção no mobile (primeiro toque)
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed and estado_toque_mobile == 1 and is_instance_valid(bolha_btn):
			# Verifica imediatamente (sem create_timer) — o layout já está calculado
			if not bolha_btn.get_global_rect().has_point(event.position):
				cancelar_selecao()

func _on_area_input_event(_camera, _event, _position, _normal, _shape_idx):
	if not pode_construir or is_built or not slot_disponivel or ui_atual:
		return
	if _event is InputEventMouseButton and _event.button_index == MOUSE_BUTTON_LEFT and _event.pressed:
		if _pode_interagir_tutorial(): # <-- APLICAÇÃO DA TRAVA AQUI
			# Consome o evento para que outras áreas sobrepostas não disparem também
			get_viewport().set_input_as_handled()
			_abrir_ui()

func _on_texture_button_pressed():
	# Se já tem algo construído, se está de noite ou se a UI já está aberta, não faz nada
	if is_built or not pode_construir or not slot_disponivel or ui_atual:
		return
		
	# Verifica a trava do tutorial
	if not _pode_interagir_tutorial(): 
		return
	
	# ABRE DIRETAMENTE (Sem precisar de dois cliques)
	_abrir_ui()

func cancelar_selecao():
	estado_toque_mobile = 0
	if bolha_btn:
		bolha_btn.modulate.a = 1.0
		bolha_btn.scale = Vector2.ONE * _obter_escala_bolha_por_zoom(get_viewport().get_camera_3d())
		bolha_btn.show()

# ==========================================
# DETECÇÃO DE PROXIMIDADE DO JOGADOR (PC)
# ==========================================
func _on_area_3d_body_entered(body):
	if body.is_in_group("Player") and not is_built and pode_construir and slot_disponivel:
		player_ref_teclado = body

func _on_area_3d_body_exited(body):
	if body == player_ref_teclado:
		player_ref_teclado = null

# ==========================================
# DESTAQUE DO CONSELHEIRO IA
# ==========================================
func destacar():
	parar_destaque()
	if not is_instance_valid(bolha_btn):
		return
	bolha_btn.show()
	_tween_destaque = create_tween().set_loops()
	_tween_destaque.tween_property(bolha_btn, "modulate", Color(1.6, 1.4, 0.2, 1.0), 0.45)
	_tween_destaque.tween_property(bolha_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)

func parar_destaque():
	if _tween_destaque != null and is_instance_valid(_tween_destaque):
		_tween_destaque.kill()
	_tween_destaque = null
	if is_instance_valid(bolha_btn):
		bolha_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
