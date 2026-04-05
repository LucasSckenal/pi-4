extends Node3D

signal slot_clicado

# ==========================================
# CONFIGURAÇÕES EXPORTADAS
# ==========================================
@export var nivel_necessario: int = 1           # Nível mínimo da base para este slot ficar disponível
@export var ui_construcao_prefab: PackedScene   # Cena da UI (radial ou grade) que será instanciada

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

func _ready():
	# Configura visibilidade inicial baseada na plataforma
	if canvas_mobile:
		canvas_mobile.visible = OS.has_feature("mobile") or OS.has_feature("editor")
	
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
		if canvas_mobile: canvas_mobile.visible = OS.has_feature("mobile") or OS.has_feature("editor")
	else:
		_esconder_todos_elementos()

func _esconder_todos_elementos():
	if base_mesh: base_mesh.hide()
	if canvas_mobile: canvas_mobile.hide()
	fechar_ui()

# ==========================================
# LÓGICA DE ABERTURA DA UI
# ==========================================
func _abrir_ui():
	if ui_atual:
		return
	if not ui_construcao_prefab:
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
	
	# Calcula o centro exato da tela para posicionar o menu estático
	var tamanho_tela = get_viewport().get_visible_rect().size
	ui_atual.position = tamanho_tela / 2.0
	
	ui_atual.abrir_menu(self)
	
	if bolha_btn: bolha_btn.hide()

func fechar_ui():
	if ui_atual:
		ui_atual.fechar_menu()  # A UI deve ter um método "fechar_menu()"
		ui_atual.queue_free()
		ui_atual = null
		
		if canvas_mobile:
			canvas_mobile.layer = 1 # Retorna a camada ao nível padrão
		
		if bolha_btn: bolha_btn.show()

# ==========================================
# CONSTRUÇÃO (chamada pela UI após compra)
# ==========================================
func construir(cena: PackedScene):
	if is_built:
		return
	
	var temp_instancia = cena.instantiate()
	var custo_final = GameManager.obter_custo_com_desconto(temp_instancia.custo_moedas)
	temp_instancia.queue_free()
	
	if GameManager.gastar_moedas(custo_final):
		var nova_const = cena.instantiate()
		add_child(nova_const)
		nova_const.global_position = global_position
		nova_const.is_fantasma = false  # Se suas construções usarem essa variável
		is_built = true
		
		# Esconde ou remove elementos do slot
		if base_mesh: base_mesh.hide()
		if canvas_mobile: canvas_mobile.queue_free()  # Remove a bolha permanentemente
		
		fechar_ui()

# ==========================================
# INTERAÇÕES (PC E MOBILE)
# ==========================================
func _process(_delta):
	if is_built or not pode_construir or not slot_disponivel or ui_atual:
		return
	
	# Posicionamento da bolha mobile (segue o mundo 3D)
	if canvas_mobile and canvas_mobile.visible and is_instance_valid(bolha_btn):
		var camera = get_viewport().get_camera_3d()
		if camera and not camera.is_position_behind(global_position):
			var pos_2d = camera.unproject_position(global_position)
			bolha_btn.position = pos_2d - (bolha_btn.size / 2)
			if estado_toque_mobile == 0:
				bolha_btn.show()
		else:
			bolha_btn.hide()
	
	# Tecla "E" no PC
	if pode_construir and player_ref_teclado != null and Input.is_action_just_pressed("interact"):
		if _pode_interagir_tutorial(): # <-- APLICAÇÃO DA TRAVA AQUI
			_abrir_ui()

func _input(event):
	if not pode_construir or not slot_disponivel or ui_atual:
		return
	
	# Clique fora para cancelar a seleção no mobile (primeiro toque)
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed and estado_toque_mobile == 1 and is_instance_valid(bolha_btn):
			get_tree().create_timer(0.05).timeout.connect(func():
				if is_instance_valid(bolha_btn) and not bolha_btn.get_global_rect().has_point(event.position):
					cancelar_selecao()
			)

func _on_area_input_event(_camera, _event, position, _normal, _shape_idx):
	if not pode_construir or is_built or not slot_disponivel or ui_atual:
		return
	if _event is InputEventMouseButton and _event.button_index == MOUSE_BUTTON_LEFT and _event.pressed:
		if _pode_interagir_tutorial(): # <-- APLICAÇÃO DA TRAVA AQUI
			_abrir_ui()

func _on_texture_button_pressed():
	if is_built or not pode_construir or not slot_disponivel or ui_atual:
		return
		
	if not _pode_interagir_tutorial(): # <-- APLICAÇÃO DA TRAVA AQUI
		return
	
	if estado_toque_mobile == 0:
		# Primeiro toque: prepara para confirmação
		estado_toque_mobile = 1
		bolha_btn.modulate.a = 0.0  # Torna a bolha invisível mas ainda clicável
	else:
		# Segundo toque: abre a UI
		_abrir_ui()

func cancelar_selecao():
	estado_toque_mobile = 0
	if bolha_btn:
		bolha_btn.modulate.a = 1.0
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
