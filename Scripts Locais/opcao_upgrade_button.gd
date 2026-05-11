extends Button

# === REFERÊNCIAS ===
@onready var titulo_label      = $MarginContainer/VBoxContainer/Titulo
@onready var container_viewport = $MarginContainer/VBoxContainer/ViewportContainer
@onready var container_3d      = $MarginContainer/VBoxContainer/ViewportContainer/SubViewport
@onready var bullets_vbox      = $MarginContainer/VBoxContainer/BulletsVBox
@onready var preco_label       = $MarginContainer/VBoxContainer/CostBadge/HBoxPreco/Preco

var modelo_instanciado: Node3D = null

func _ready():
	setup_camera_3d()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func setup_camera_3d():
	if container_3d == null: return
	container_3d.own_world_3d = true
	container_3d.transparent_bg = true
	if container_3d.has_node("CâmaraInterna"): return

	var cam = Camera3D.new()
	cam.name = "CâmaraInterna"
	cam.position = Vector3(0, 0.45, 1.3)
	cam.look_at_from_position(Vector3(0, 0.45, 1.3), Vector3(0, 0.3, 0))
	container_3d.add_child(cam)

	var luz = DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 45, 0)
	luz.light_energy = 1.0
	container_3d.add_child(luz)

func _process(delta):
	if is_instance_valid(modelo_instanciado):
		modelo_instanciado.rotate_y(1.0 * delta)

# === CONFIGURAÇÃO DO CARD ===
func configurar(opcao: Dictionary):
	# Título em maiúsculas
	titulo_label.text = opcao.get("nome", "Upgrade").to_upper()

	# Cor do card (personalizada pelo path ou automática por índice)
	var cor_card: Color
	var cor_custom = opcao.get("cor", Color(0, 0, 0, 0))
	if cor_custom is Color and cor_custom.a > 0.01:
		cor_card = cor_custom
	else:
		cor_card = _cor_por_indice(opcao.get("index", 0))
	_aplicar_cor_card(cor_card)

	# Custo
	preco_label.text = str(opcao.get("custo", 0))

	# Bullets descritivos (sem números)
	var descricoes: Array = opcao.get("descricoes", [])
	_popular_bullets(descricoes)

	# Modelo 3D ou ícone 2D
	set_meta("caminho_index", opcao.get("index", 0))
	var mod_3d = opcao.get("modelo_3d")
	if mod_3d != null:
		_carregar_modelo_3d(mod_3d, opcao.get("escala_modelo", Vector3(1, 1, 1)))
	else:
		var img_2d = opcao.get("icone")
		if img_2d != null:
			_mostrar_icone_2d(img_2d)
		else:
			container_viewport.hide()

	_ignorar_mouse_filhos(self)

func _cor_por_indice(index: int) -> Color:
	# Cores de acento para o TÍTULO de cada caminho (não o fundo do card).
	# Tonalidades distintas mas sem a estética "infantil" de fundos coloridos.
	const CORES = [
		Color(0.95, 0.55, 0.22, 1.0),  # Laranja queimado
		Color(0.38, 0.76, 0.96, 1.0),  # Azul claro
		Color(0.72, 0.50, 0.96, 1.0),  # Lavanda
		Color(0.95, 0.82, 0.28, 1.0),  # Âmbar
	]
	return CORES[index % CORES.size()]

func _aplicar_cor_card(cor: Color) -> void:
	# Cor de acento SOMENTE no título — fundo permanece escuro e uniforme.
	titulo_label.add_theme_color_override("font_color", cor)

	# Borda do hover usa a cor do acento (mais suave)
	var style_h = get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	style_h.border_color = Color(cor.r, cor.g, cor.b, 0.55)
	add_theme_stylebox_override("hover", style_h)

	# Linha separadora sob o título recebe a cor de acento (identidade discreta do card)
	var sep = $MarginContainer/VBoxContainer.get_node_or_null("Separador")
	if sep:
		sep.add_theme_color_override("separator_color", Color(cor.r, cor.g, cor.b, 0.45))

func _popular_bullets(descricoes: Array) -> void:
	var bullet_nodes = bullets_vbox.get_children()
	for i in range(bullet_nodes.size()):
		if i < descricoes.size() and descricoes[i] != "":
			bullet_nodes[i].text = descricoes[i]
			bullet_nodes[i].show()
		else:
			bullet_nodes[i].text = ""
			bullet_nodes[i].hide()

func _carregar_modelo_3d(cena_modelo: PackedScene, escala: Vector3):
	container_viewport.show()
	_esconder_icone_2d()
	for child in container_3d.get_children():
		if not child is Camera3D and not child is DirectionalLight3D:
			child.queue_free()
	if cena_modelo:
		modelo_instanciado = cena_modelo.instantiate()
		container_3d.add_child(modelo_instanciado)
		modelo_instanciado.position = Vector3.ZERO
		modelo_instanciado.scale = escala

func _mostrar_icone_2d(textura: Texture2D):
	if textura == null: return
	container_viewport.hide()
	var vbox = $MarginContainer/VBoxContainer
	var icone_rect = vbox.get_node_or_null("FallbackIcone2D")
	if not icone_rect:
		icone_rect = TextureRect.new()
		icone_rect.name = "FallbackIcone2D"
		icone_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_rect.custom_minimum_size = Vector2(210, 210)
		icone_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(icone_rect)
		vbox.move_child(icone_rect, 1)
	icone_rect.texture = textura
	icone_rect.show()

func _esconder_icone_2d():
	var icone_rect = $MarginContainer/VBoxContainer.get_node_or_null("FallbackIcone2D")
	if icone_rect: icone_rect.hide()

# === FUNÇÕES AUXILIARES ===
func _ignorar_mouse_filhos(node: Node):
	for child in node.get_children():
		if child is Control and child != self:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignorar_mouse_filhos(child)
