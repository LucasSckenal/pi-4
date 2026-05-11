extends Control

var banco_conquistas: Array[ConquistaData] = []

@onready var scroll        := $ScrollContainer
@onready var label_titulo  := $LabelTitulo

func _ready():
	_carregar_conquistas_da_pasta("res://Conquistas/")
	_construir_ui()

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
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res = load(caminho_pasta + "/" + file_name)
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
		label_titulo.text = "🏆  Conquistas  —  %d / %d" % [num_ok, total]

	# Wrapper principal
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 20)
	scroll.add_child(wrapper)

	_criar_barra_progresso(wrapper, num_ok, total)

	# Grid 2 colunas
	var grid := GridContainer.new()
	grid.columns = 2
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
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	parent.add_child(hbox)

	var lbl := Label.new()
	lbl.text = "%d desbloqueadas" % n
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.76, 0.28))
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max(1, total)
	bar.value = n
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	var fill_st := StyleBoxFlat.new()
	fill_st.bg_color = Color(0.85, 0.68, 0.15)
	fill_st.corner_radius_top_left    = 5
	fill_st.corner_radius_top_right   = 5
	fill_st.corner_radius_bottom_left = 5
	fill_st.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("fill", fill_st)

	var bg_st := StyleBoxFlat.new()
	bg_st.bg_color = Color(0.18, 0.18, 0.22)
	bg_st.corner_radius_top_left    = 5
	bg_st.corner_radius_top_right   = 5
	bg_st.corner_radius_bottom_left = 5
	bg_st.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", bg_st)
	hbox.add_child(bar)

# ==========================================
# CARD INDIVIDUAL
# ==========================================
func _criar_card(conquista: ConquistaData) -> PanelContainer:
	var liberada: bool = conquista.id in Global.conquistas_desbloqueadas

	# ── Painel externo ────────────────────────────────────────────────
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 148)

	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.12, 0.11, 0.08, 0.97) if liberada else Color(0.09, 0.09, 0.11, 0.95)
	st.border_color = Color(0.82, 0.65, 0.12)        if liberada else Color(0.26, 0.26, 0.30)
	st.set_border_width_all(2)
	st.corner_radius_top_left     = 12
	st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left  = 12
	st.corner_radius_bottom_right = 12
	st.content_margin_left   = 14
	st.content_margin_right  = 14
	st.content_margin_top    = 12
	st.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", st)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	card.add_child(hbox)

	# ── Ícone (quadrado, 110×110) ─────────────────────────────────────
	var ic_cont := Control.new()
	ic_cont.custom_minimum_size = Vector2(110, 110)
	ic_cont.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(ic_cont)

	var ic_bg := ColorRect.new()
	ic_bg.color = Color(0.06, 0.06, 0.09, 1.0)
	ic_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic_cont.add_child(ic_bg)

	if conquista.icone != null:
		var tr := TextureRect.new()
		tr.texture = conquista.icone
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color(1, 1, 1) if liberada else Color(0.20, 0.20, 0.20)
		ic_cont.add_child(tr)
	else:
		var ph := Label.new()
		ph.text = "🏅" if liberada else "❓"
		ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		ph.add_theme_font_size_override("font_size", 42)
		ph.modulate = Color(1, 1, 1) if liberada else Color(0.35, 0.35, 0.35)
		ic_cont.add_child(ph)

	# Overlay de cadeado (bloqueada) ou check (liberada)
	if not liberada:
		var ov := ColorRect.new()
		ov.color = Color(0, 0, 0, 0.52)
		ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic_cont.add_child(ov)
		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 30)
		ic_cont.add_child(lock_lbl)
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
	nome_lbl.add_theme_font_size_override("font_size", 19)
	nome_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.42) if liberada else Color(0.50, 0.50, 0.55))
	nome_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	nome_lbl.add_theme_constant_override("outline_size", 3)
	nome_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(nome_lbl)

	# Descrição
	var desc_lbl := Label.new()
	desc_lbl.text = conquista.descricao if liberada else "Continue jogando para descobrir..."
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color",
		Color(0.72, 0.72, 0.78) if liberada else Color(0.30, 0.30, 0.34))
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
			rlbl.add_theme_font_size_override("font_size", 12)
			rlbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
			rlbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rrow.add_child(rlbl)

			if tem_chapeu:
				var b := Label.new()
				b.text = "🎩"
				b.add_theme_font_size_override("font_size", 17)
				b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				rrow.add_child(b)
			if tem_arma:
				var b := Label.new()
				b.text = "⚔"
				b.add_theme_font_size_override("font_size", 17)
				b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				rrow.add_child(b)

	return card

# ==========================================
# NAVEGAÇÃO
# ==========================================
func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
