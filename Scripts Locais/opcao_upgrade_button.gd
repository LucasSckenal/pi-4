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

	set_meta("caminho_index", opcao.get("index", 0))

	# Limita a altura do viewport 3D para caber no card
	if is_instance_valid(container_viewport):
		container_viewport.custom_minimum_size = Vector2(0, 155)

	# Ícone 2D tem prioridade — mais legível e consistente visualmente.
	# Modelo 3D apenas como fallback quando não há ícone configurado.
	var img_2d = opcao.get("icone")
	if img_2d is Texture2D:
		_mostrar_icone_2d(img_2d)
	else:
		var mod_3d = opcao.get("modelo_3d")
		if mod_3d != null:
			_carregar_modelo_3d(mod_3d, opcao.get("escala_modelo", Vector3(1, 1, 1)))
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
	# Limpa bullets anteriores e recria com ícone + texto
	for child in bullets_vbox.get_children():
		child.queue_free()

	for desc in descricoes:
		if desc == "":
			continue
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 7)
		bullets_vbox.add_child(hbox)

		var ic := TextureRect.new()
		ic.texture = _icone_para_descricao(desc)
		ic.custom_minimum_size = Vector2(18, 18)
		ic.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(ic)

		var lbl := Label.new()
		lbl.text = desc
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.84, 0.96))
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(lbl)

func _icone_para_descricao(desc: String) -> Texture2D:
	var d := desc.to_lower()
	if "dano" in d or "potência" in d or "cadeia" in d:
		return load("res://Assets/Icons/Espada.png")
	if "resistência" in d or "vida" in d:
		return load("res://Assets/Icons/Coracao.png")
	if "alcance" in d:
		return load("res://Assets/Icons/Alvo.png")
	if "ouro" in d:
		return load("res://Assets/Icons/Moedas.png")
	if "soldados" in d:
		return load("res://Assets/Icons/Escudo.png")
	if "devagar" in d or "cadência" in d:
		return load("res://Assets/Icons/Lento.png")
	if "rápido" in d:
		return load("res://Assets/Icons/Veloz.png")
	if "eficiência" in d:
		return load("res://Assets/Icons/ChaveInglesa.png")
	return load("res://Assets/Icons/Estrela.png")

func _carregar_modelo_3d(cena_modelo: PackedScene, escala: Vector3):
	container_viewport.show()
	_esconder_icone_2d()
	for child in container_3d.get_children():
		if not child is Camera3D and not child is DirectionalLight3D:
			child.queue_free()
	if cena_modelo:
		modelo_instanciado = cena_modelo.instantiate()
		if "is_fantasma" in modelo_instanciado:
			modelo_instanciado.is_fantasma = true
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
		icone_rect.custom_minimum_size = Vector2(160, 160)
		icone_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(icone_rect)
		vbox.move_child(icone_rect, 1)
	icone_rect.texture = textura
	icone_rect.show()

func _esconder_icone_2d():
	var icone_rect = $MarginContainer/VBoxContainer.get_node_or_null("FallbackIcone2D")
	if icone_rect: icone_rect.hide()

func bloquear(motivo: String) -> void:
	disabled = true
	mouse_default_cursor_shape = Control.CURSOR_ARROW

	# Preserva o visual do card no estado disabled
	var style_base = get_theme_stylebox("normal").duplicate()
	add_theme_stylebox_override("disabled", style_base)

	var overlay = ColorRect.new()
	overlay.name = "LockOverlay"
	overlay.color = Color(0, 0, 0, 0.68)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var cadeado = TextureRect.new()
	cadeado.texture = load("res://Assets/Icons/Cadeado.png")
	cadeado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cadeado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cadeado.custom_minimum_size = Vector2(56, 56)
	cadeado.anchor_left = 0.5
	cadeado.anchor_top = 0.38
	cadeado.anchor_right = 0.5
	cadeado.anchor_bottom = 0.38
	cadeado.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cadeado.grow_vertical = Control.GROW_DIRECTION_BOTH
	cadeado.offset_left = -28
	cadeado.offset_right = 28
	cadeado.offset_top = -28
	cadeado.offset_bottom = 28
	cadeado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cadeado)

	if motivo != "":
		var lbl = Label.new()
		lbl.text = motivo
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.anchor_left = 0.0
		lbl.anchor_top = 0.62
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 0.62
		lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
		lbl.offset_top = -12
		lbl.offset_bottom = 12
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)

# === FUNÇÕES AUXILIARES ===
func _ignorar_mouse_filhos(node: Node):
	for child in node.get_children():
		if child is Control and child != self:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignorar_mouse_filhos(child)
