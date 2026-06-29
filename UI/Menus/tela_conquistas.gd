extends Control

const ICON_TROFEU   = preload("res://Assets/Icons/Trofeu.png")
const ICON_MEDALHA  = preload("res://Assets/Icons/Medalha.png")
const ICON_ESPADA   = preload("res://Assets/Icons/Espada.png")
const ICON_CADEADO  = preload("res://Assets/Icons/Trinco.png")
const ICON_CHAPEU   = preload("res://Assets/Icons/Chapeu.png")

var banco_conquistas: Array[ConquistaData] = []

@onready var scroll        := $ScrollContainer
@onready var label_titulo  := $LabelTitulo

# Estado de arrasto (scroll com mouse ou um dedo)
var _arrastando: bool = false

func _ready():
	# Garante que pausas residuais (game-over, etc.) não bloqueiem o menu
	get_tree().paused = false
	_carregar_conquistas_da_pasta("res://Conquistas/")
	_construir_ui()

# ==========================================
# ARRASTAR PARA ROLAR (mouse ou um dedo)
# ==========================================
func _input(event: InputEvent) -> void:
	if scroll == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and scroll.get_global_rect().has_point(event.position):
			_arrastando = true
		else:
			_arrastando = false
	elif event is InputEventMouseMotion and _arrastando:
		scroll.scroll_vertical -= int(event.relative.y)
	elif event is InputEventScreenDrag:
		# Um dedo arrastando dentro da lista rola verticalmente
		if scroll.get_global_rect().has_point(event.position):
			scroll.scroll_vertical -= int(event.relative.y)

# Botão físico "Voltar" do Android
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_BACK and event.pressed:
		_on_btn_voltar_pressed()
		get_viewport().set_input_as_handled()
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# Intercepta o input
			get_viewport().set_input_as_handled()
			
			# Chama a mesma função que você fez para o "BtnVoltar"
			_on_btn_voltar_pressed()

# ==========================================
# CARREGAMENTO
# ==========================================
func _carregar_conquistas_da_pasta(caminho_pasta: String):
	var dir = DirAccess.open(caminho_pasta)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Remove o sufixo .remap gerado pela engine durante a exportação de recursos
		var arquivo_limpo = file_name.trim_suffix(".remap")
		if arquivo_limpo.ends_with(".tres") or arquivo_limpo.ends_with(".res"):
			var res = load(caminho_pasta + arquivo_limpo)  # caminho_pasta já tem "/" no final
			if res is ConquistaData:
				banco_conquistas.append(res)
		file_name = dir.get_next()

# ==========================================
# CONSTRUÇÃO DA UI
# ==========================================
func _construir_ui():
	# Remove container antigo
	for child in scroll.get_children():
		child.free()

	var total: int = banco_conquistas.size()
	var num_ok: int = 0
	for c in banco_conquistas:
		if c != null and c.id in Global.conquistas_desbloqueadas:
			num_ok += 1

	# Atualiza o título com o contador
	if label_titulo:
		label_titulo.text = "Conquistas  —  %d / %d" % [num_ok, total]

	# Wrapper principal
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 20)
	scroll.add_child(wrapper)

	_criar_barra_progresso(wrapper, num_ok, total)
	_criar_painel_estatisticas(wrapper)

	# Grid: 1 coluna no mobile, 2 no desktop
	var grid := GridContainer.new()
	grid.columns = 1 if OS.has_feature("mobile") else 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(grid)

	# Ordena: desbloqueadas primeiro, depois bloqueadas
	var ordenadas: Array = banco_conquistas.duplicate()
	ordenadas.sort_custom(func(a, b):
		var a_ok: bool = a != null and a.id in Global.conquistas_desbloqueadas
		var b_ok: bool = b != null and b.id in Global.conquistas_desbloqueadas
		return a_ok and not b_ok
	)

	# Cria cards com animação de entrada escalonada
	var delay: float = 0.0
	for c in ordenadas:
		if c == null:
			continue
		var card := _criar_card(c)
		grid.add_child(card)
		card.modulate.a = 0.0
		var tw := card.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(card, "modulate:a", 1.0, 0.18)
		delay += 0.04

# ==========================================
# BARRA DE PROGRESSO
# ==========================================
func _criar_barra_progresso(parent: VBoxContainer, n: int, total: int):
	var mob: bool = OS.has_feature("mobile")

	# Margem extra acima para a barra "respirar" e ficar centralizada visualmente
	var topo := Control.new()
	topo.custom_minimum_size = Vector2(0, 10)
	parent.add_child(topo)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	var lbl := Label.new()
	lbl.text = "%d desbloqueadas" % n
	lbl.add_theme_font_size_override("font_size", 24 if mob else 22)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.76, 0.28))
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max(1, total)
	bar.value = n
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 30 if mob else 26)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	var fill_st := StyleBoxFlat.new()
	fill_st.bg_color = Color(0.85, 0.65, 0.12)
	fill_st.corner_radius_top_left    = 5
	fill_st.corner_radius_top_right   = 5
	fill_st.corner_radius_bottom_left = 5
	fill_st.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("fill", fill_st)

	var bg_st := StyleBoxFlat.new()
	bg_st.bg_color = Color(0.15, 0.09, 0.03)
	bg_st.corner_radius_top_left    = 5
	bg_st.corner_radius_top_right   = 5
	bg_st.corner_radius_bottom_left = 5
	bg_st.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", bg_st)
	hbox.add_child(bar)

# ==========================================
# PAINEL DE ESTATÍSTICAS
# ==========================================
func _criar_painel_estatisticas(parent: VBoxContainer) -> void:
	var mob: bool = OS.has_feature("mobile")
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.13, 0.08, 0.03, 0.95)
	st.border_color = Color(0.62, 0.46, 0.14)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", st)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28 if not mob else 18)
	card.add_child(row)

	row.add_child(_stat_coluna("Inimigos\nderrotados", str(Global.total_inimigos_mortos), mob))
	row.add_child(_separador_vertical())
	row.add_child(_stat_coluna("Melhor onda\n(infinito)", str(Global.melhor_onda_infinito), mob))
	row.add_child(_separador_vertical())
	row.add_child(_stat_coluna("Tempo\njogado", Global.formatar_tempo_jogado(), mob))

	parent.add_child(card)

func _stat_coluna(rotulo: String, valor: String, mob: bool) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vlbl := Label.new()
	vlbl.text = valor
	vlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vlbl.add_theme_font_size_override("font_size", 30 if mob else 26)
	vlbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	col.add_child(vlbl)
	var rlbl := Label.new()
	rlbl.text = rotulo
	rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rlbl.add_theme_font_size_override("font_size", 16 if mob else 13)
	rlbl.add_theme_color_override("font_color", Color(0.70, 0.62, 0.45))
	col.add_child(rlbl)
	return col

func _separador_vertical() -> Panel:
	var sep := Panel.new()
	sep.custom_minimum_size = Vector2(2, 44)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.40, 0.32, 0.12, 0.6)
	sep.add_theme_stylebox_override("panel", st)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return sep

# ==========================================
# CARD INDIVIDUAL
# ==========================================
func _criar_card(conquista: ConquistaData) -> PanelContainer:
	var liberada: bool = conquista.id in Global.conquistas_desbloqueadas
	var mob: bool = OS.has_feature("mobile")

	# ── Painel externo ────────────────────────────────────────────────
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 260 if mob else 148)

	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.17, 0.10, 0.04, 0.97) if liberada else Color(0.10, 0.07, 0.03, 0.95)
	st.border_color = Color(0.82, 0.63, 0.14)        if liberada else Color(0.42, 0.32, 0.10, 0.7)
	st.set_border_width_all(2)
	st.corner_radius_top_left     = 12
	st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left  = 12
	st.corner_radius_bottom_right = 12
	st.content_margin_left   = 18 if mob else 14
	st.content_margin_right  = 18 if mob else 14
	st.content_margin_top    = 16 if mob else 12
	st.content_margin_bottom = 16 if mob else 12
	card.add_theme_stylebox_override("panel", st)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18 if mob else 14)
	card.add_child(hbox)

	# ── Ícone (quadrado, 150×150 no mobile / 110×110 no desktop) ─────
	var ic_sz: int = 175 if mob else 110
	var ic_cont := Control.new()
	ic_cont.custom_minimum_size = Vector2(ic_sz, ic_sz)
	ic_cont.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(ic_cont)

	var ic_bg := ColorRect.new()
	ic_bg.color = Color(0.09, 0.06, 0.02, 1.0)
	ic_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic_cont.add_child(ic_bg)

	if conquista.icone != null:
		var tr_icone := TextureRect.new()
		tr_icone.texture = conquista.icone
		tr_icone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr_icone.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr_icone.modulate = Color(1, 1, 1) if liberada else Color(0.20, 0.20, 0.20)
		ic_cont.add_child(tr_icone)
	else:
		var ph := TextureRect.new()
		ph.texture = ICON_MEDALHA if liberada else null
		ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ph.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ph.modulate = Color(1, 1, 1) if liberada else Color(0.35, 0.35, 0.35)
		ic_cont.add_child(ph)
		if not liberada:
			var ph_lbl := Label.new()
			ph_lbl.text = "?"
			ph_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ph_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			ph_lbl.add_theme_font_size_override("font_size", 42)
			ph_lbl.modulate = Color(0.35, 0.35, 0.35)
			ic_cont.add_child(ph_lbl)

	# Overlay de cadeado (bloqueada) ou check (liberada)
	if not liberada:
		var ov := ColorRect.new()
		ov.color = Color(0, 0, 0, 0.52)
		ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic_cont.add_child(ov)
		var lock_ic := TextureRect.new()
		lock_ic.texture = ICON_CADEADO
		lock_ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_ic.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_ic.modulate = Color(0.8, 0.7, 0.5, 0.9)
		lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic_cont.add_child(lock_ic)
	else:
		var check := Label.new()
		check.text = "✓"
		check.anchor_left   = 1.0
		check.anchor_right  = 1.0
		check.anchor_top    = 0.0
		check.anchor_bottom = 0.0
		check.offset_left   = -28
		check.offset_right  = 2
		check.offset_top    = -2
		check.offset_bottom = 24
		check.add_theme_font_size_override("font_size", 18)
		check.add_theme_color_override("font_color", Color(0.2, 0.92, 0.38))
		check.add_theme_color_override("font_outline_color", Color.BLACK)
		check.add_theme_constant_override("outline_size", 3)
		ic_cont.add_child(check)

	# ── Conteúdo (nome + descrição + recompensas) ─────────────────────
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(vbox)

	# Nome (sempre visível)
	var nome_lbl := Label.new()
	nome_lbl.text = conquista.nome
	nome_lbl.add_theme_font_size_override("font_size", 32 if mob else 24)
	nome_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.42) if liberada else Color(0.50, 0.50, 0.55))
	nome_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	nome_lbl.add_theme_constant_override("outline_size", 3)
	nome_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(nome_lbl)

	# Descrição
	var desc_lbl := Label.new()
	desc_lbl.text = conquista.descricao if liberada else "Continue jogando para descobrir..."
	desc_lbl.add_theme_font_size_override("font_size", 23 if mob else 18)
	desc_lbl.add_theme_color_override("font_color",
		Color(0.78, 0.68, 0.48) if liberada else Color(0.36, 0.28, 0.16))
	desc_lbl.autowrap_mode    = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.max_lines_visible = 3
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)

	# Recompensas (só para desbloqueadas)
	if liberada:
		var tem_chapeu: bool = conquista.libera_chapeu_id != ""
		var tem_arma: bool   = conquista.libera_arma_id   != ""
		if tem_chapeu or tem_arma:
			var sep := Control.new()
			sep.custom_minimum_size = Vector2(0, 4)
			vbox.add_child(sep)

			var rrow := HBoxContainer.new()
			rrow.add_theme_constant_override("separation", 6)
			vbox.add_child(rrow)

			var rlbl := Label.new()
			rlbl.text = "Desbloqueou:"
			rlbl.add_theme_font_size_override("font_size", 28 if mob else 19)
			rlbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
			rlbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rrow.add_child(rlbl)

			if tem_chapeu:
				var b := TextureRect.new()
				b.texture = ICON_CHAPEU
				b.custom_minimum_size = Vector2(32, 32) if mob else Vector2(24, 24)
				b.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
				b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				rrow.add_child(b)
			if tem_arma:
				var b := TextureRect.new()
				b.texture = ICON_ESPADA
				b.custom_minimum_size = Vector2(32, 32) if mob else Vector2(24, 24)
				b.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
				b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				rrow.add_child(b)

	# Cards não devem consumir cliques/toques — deixa o arrasto rolar a lista
	_ignorar_mouse_recursivo(card)
	return card

func _ignorar_mouse_recursivo(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for filho in node.get_children():
		_ignorar_mouse_recursivo(filho)

# ==========================================
# NAVEGAÇÃO
# ==========================================
func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
