extends Button 

# === REFERÊNCIAS ===
@onready var titulo_label = $VBoxContainer/Titulo
@onready var container_viewport = $VBoxContainer/ViewportContainer
@onready var container_3d = $VBoxContainer/ViewportContainer/SubViewport
@onready var status_container = $VBoxContainer/StatusContainer
@onready var preco_label = $VBoxContainer/HBoxPreco/Preco

var modelo_instanciado: Node3D = null

func _ready():
	setup_camera_3d()
	
	# Define a mudança visual do cursor para indicar interatividade
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if preco_label:
		preco_label.add_theme_font_size_override("font_size", 22)

func setup_camera_3d():
	if container_3d == null: return
	
	container_3d.own_world_3d = true 
	container_3d.transparent_bg = true 
		
	if container_3d.has_node("CâmaraInterna"): return
	
	var cam = Camera3D.new()
	cam.name = "CâmaraInterna"
	cam.position = Vector3(0, 0.4, 1.2) 
	cam.look_at(Vector3(0, 0.3, 0))
	container_3d.add_child(cam)
	
	var luz = DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 45, 0)
	luz.light_energy = 1.0
	container_3d.add_child(luz)

func _process(delta):
	if is_instance_valid(modelo_instanciado):
		modelo_instanciado.rotate_y(1.0 * delta)

# === LÓGICA DE CONFIGURAÇÃO ===
func configurar(opcao: Dictionary):
	titulo_label.text = opcao.get("nome", "Upgrade")
	titulo_label.add_theme_font_size_override("font_size", 24)  
	
	preco_label.text = "💰 " + str(opcao.get("custo", 0))
	
	var beneficio_texto = opcao.get("beneficio", "")
	if beneficio_texto != "":
		var linha_beneficio = _emojificar_beneficio(beneficio_texto)
		$VBoxContainer/StatusContainer/LabelVida.text = linha_beneficio
		$VBoxContainer/StatusContainer/LabelVida.add_theme_font_size_override("font_size", 18)  
		$VBoxContainer/StatusContainer/LabelVida.show()
	else:
		$VBoxContainer/StatusContainer/LabelVida.hide()
		
	$VBoxContainer/StatusContainer/LabelDano.hide()
	
	set_meta("caminho_index", opcao.get("index", 0))
	
	var mod_3d = opcao.get("modelo_3d")
	
	if mod_3d != null:
		_carregar_modelo_3d(mod_3d, opcao.get("escala_modelo", Vector3(1, 1, 1)))
	else:
		var img_2d = opcao.get("icone")
		if img_2d != null:
			_mostrar_icone_2d(img_2d)
		else:
			_esconder_icone_2d()
			$VBoxContainer/ViewportContainer.hide()

	# Aplica a regra para que todos os filhos (incluindo os gerados 
	# dinamicamente) ignorem o mouse, permitindo que apenas o botão raiz brilhe
	_ignorar_mouse_filhos(self)

func _emojificar_beneficio(texto: String) -> String:
	var texto_lower = texto.to_lower()
	if "dano" in texto_lower:
		return "⚔️ " + texto
	elif "vida" in texto_lower:
		return "❤️ " + texto
	elif "velocidade" in texto_lower or "vel." in texto_lower:
		return "⏱️ " + texto
	elif "alcance" in texto_lower:
		return "🎯 " + texto
	elif "ouro" in texto_lower or "moeda" in texto_lower:
		return "💰 " + texto
	elif "soldado" in texto_lower or "aliado" in texto_lower:
		return "🛡️ " + texto
	elif "respawn" in texto_lower:
		return "⏳ " + texto
	else:
		return "✨ " + texto  

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
	
	var icone_rect = $VBoxContainer.get_node_or_null("FallbackIcone2D")
	if not icone_rect:
		icone_rect = TextureRect.new()
		icone_rect.name = "FallbackIcone2D"
		icone_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_rect.custom_minimum_size = Vector2(150, 150)  
		icone_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		$VBoxContainer.add_child(icone_rect)
		$VBoxContainer.move_child(icone_rect, 2)
		
	icone_rect.texture = textura
	icone_rect.show()

func _esconder_icone_2d():
	var icone_rect = $VBoxContainer.get_node_or_null("FallbackIcone2D")
	if icone_rect: icone_rect.hide()

func _atualizar_labels_status(texto_completo: String):  
	for child in status_container.get_children():
		child.queue_free()
		
	if texto_completo == "Melhora geral" or texto_completo == "★ NÍVEL MÁXIMO ALCANÇADO ★":
		var lbl = Label.new()
		lbl.text = texto_completo
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)
		status_container.add_child(lbl)
		return

	var partes = texto_completo.split(" | ")
	for parte in partes:
		var lbl = Label.new()
		lbl.text = parte.strip_edges()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		
		if "+" in parte:
			lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) 
		elif "-" in parte:
			if "Vel." in parte or "Tempo" in parte or "Custo" in parte:
				lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) 
			else:
				lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) 
		else:
			lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				
		status_container.add_child(lbl)

# === FUNÇÕES AUXILIARES ===
func _ignorar_mouse_filhos(node: Node):
	# Função recursiva que garante que os filhos não bloqueiem eventos de mouse do botão raiz
	for child in node.get_children():
		if child is Control and child != self:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignorar_mouse_filhos(child)
