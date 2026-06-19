extends Control

# ==========================================
# BESTIÁRIO ("o livro") — info dos inimigos + histórias das fases
# Acesso: menu principal. Conteúdo bloqueado com ??? até ser descoberto.
# ==========================================

const BD = preload("res://Bestiario/bestiario_dados.gd")

@onready var conteudo: VBoxContainer = $ScrollContainer/Conteudo
@onready var abas: HBoxContainer = $Abas
@onready var scroll: ScrollContainer = $ScrollContainer

const COR_DOURADO := Color(0.96, 0.84, 0.3)
const COR_BORDA := Color(0.62, 0.46, 0.16)
const COR_TEXTO := Color(0.84, 0.74, 0.55)

# Paleta do "livro" (dossiê)
const COR_PERGAMINHO := Color(0.86, 0.78, 0.58)
const COR_PERGAMINHO_ESCURA := Color(0.78, 0.69, 0.49)
const COR_COURO := Color(0.20, 0.12, 0.05)
const COR_COURO_BORDA := Color(0.40, 0.25, 0.10)
const COR_TINTA := Color(0.26, 0.16, 0.07)
const COR_TINTA_CLARA := Color(0.42, 0.30, 0.15)

var _flipando: bool = false

var _secao: String = "inimigos"   # "inimigos" | "historias"
var _btn_inimigos: Button = null
var _btn_historias: Button = null
var _capitulo_sel: int = 1        # capítulo (mapa) atualmente aberto na aba Inimigos

func _ready() -> void:
	get_tree().paused = false
	_criar_abas()
	_render()

# ==========================================
# ABAS (seções)
# ==========================================
func _criar_abas() -> void:
	_btn_inimigos = _criar_aba("Inimigos", "inimigos")
	_btn_historias = _criar_aba("Histórias", "historias")
	abas.add_child(_btn_inimigos)
	abas.add_child(_btn_historias)
	_atualizar_abas()

func _criar_aba(texto: String, id: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 48)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 24 if OS.has_feature("mobile") else 22)
	b.pressed.connect(_on_aba_pressed.bind(id))
	return b

func _on_aba_pressed(id: String) -> void:
	if _secao == id:
		return
	_secao = id
	_atualizar_abas()
	_render()

func _atualizar_abas() -> void:
	for par in [[_btn_inimigos, "inimigos"], [_btn_historias, "historias"]]:
		var b: Button = par[0]
		var ativo: bool = (_secao == par[1])
		var bg := Color(0.28, 0.18, 0.06) if ativo else Color(0.14, 0.09, 0.04)
		var borda := COR_DOURADO if ativo else COR_BORDA
		b.add_theme_color_override("font_color", Color(1, 0.92, 0.6) if ativo else COR_TEXTO)
		b.add_theme_stylebox_override("normal", _sb(bg, borda, 2, 10, 20))
		b.add_theme_stylebox_override("hover", _sb(Color(0.3, 0.2, 0.07), COR_DOURADO, 2, 10, 20))
		b.add_theme_stylebox_override("pressed", _sb(bg, borda, 2, 10, 20))

# ==========================================
# RENDER
# ==========================================
func _render() -> void:
	for c in conteudo.get_children():
		c.queue_free()
	scroll.scroll_vertical = 0
	if _secao == "inimigos":
		_render_inimigos()
	else:
		_render_historias()

func _render_inimigos() -> void:
	var mob := OS.has_feature("mobile")

	# Seletor de capítulos (Cap. 1..6)
	var nav := HFlowContainer.new()
	nav.add_theme_constant_override("h_separation", 8)
	nav.add_theme_constant_override("v_separation", 8)
	conteudo.add_child(nav)
	for cap in range(1, 7):
		nav.add_child(_btn_capitulo(cap))

	# Cabeçalho do capítulo selecionado
	conteudo.add_child(_cabecalho_mapa(_capitulo_sel))

	# Grade de retratos clicáveis
	var lista := _inimigos_do_capitulo(_capitulo_sel)
	var grid := GridContainer.new()
	grid.columns = 2 if mob else 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(grid)
	for idx in range(lista.size()):
		grid.add_child(_portrait_inimigo(lista[idx], idx, mob))

func _inimigos_do_capitulo(cap: int) -> Array:
	var lista: Array = []
	for e in BD.INIMIGOS:
		if int(e["mapa"]) == cap:
			lista.append(e)
	return lista

func _btn_capitulo(cap: int) -> Button:
	var b := Button.new()
	b.text = "Cap. %d" % cap
	b.custom_minimum_size = Vector2(0, 42)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = BD.NOMES_MAPAS[cap] if cap < BD.NOMES_MAPAS.size() else ""
	b.add_theme_font_size_override("font_size", 18)
	var ativo := cap == _capitulo_sel
	var bg := Color(0.28, 0.18, 0.06) if ativo else Color(0.14, 0.09, 0.04)
	var borda := COR_DOURADO if ativo else COR_BORDA
	b.add_theme_color_override("font_color", Color(1, 0.92, 0.6) if ativo else COR_TEXTO)
	var st := _sb(bg, borda, 2, 9, 0)
	st.content_margin_left = 16; st.content_margin_right = 16
	var st_h := _sb(Color(0.3, 0.2, 0.07), COR_DOURADO, 2, 9, 0)
	st_h.content_margin_left = 16; st_h.content_margin_right = 16
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st_h)
	b.add_theme_stylebox_override("pressed", st)
	b.pressed.connect(func():
		if _capitulo_sel != cap:
			_capitulo_sel = cap
			_render()
	)
	return b

# Retrato clicável que abre o dossiê
func _portrait_inimigo(dados: Dictionary, idx: int, mob: bool) -> Button:
	var descoberto: bool = String(dados["nome"]) in Global.inimigos_descobertos
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 168 if mob else 156)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _sb(Color(0.14, 0.09, 0.04, 0.97), COR_BORDA, 2, 12, 0))
	b.add_theme_stylebox_override("hover", _sb(Color(0.22, 0.14, 0.05, 0.98), COR_DOURADO, 2, 12, 0))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.12, 0.08, 0.03, 0.98), COR_BORDA, 2, 12, 0))

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 6)
	b.add_child(v)

	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(0, 96 if mob else 88)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if descoberto and ResourceLoader.exists(String(dados["icone"])):
		tr.texture = load(String(dados["icone"]))
		tr.modulate = Color.WHITE
	else:
		tr.modulate = Color(0, 0, 0, 0)  # silhueta vazia
	v.add_child(tr)

	var lbl := Label.new()
	lbl.text = String(dados["nome"]) if descoberto else "???"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 17 if mob else 15)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.55) if descoberto else Color(0.5, 0.45, 0.38))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lbl)

	if not descoberto:
		b.modulate = Color(0.85, 0.85, 0.85, 0.92)
	b.pressed.connect(_abrir_dossie.bind(_capitulo_sel, idx))
	return b

# ==========================================
# DOSSIÊ (página dedicada por inimigo, estilo ARK)
# ==========================================
func _abrir_dossie(cap: int, idx: int) -> void:
	var lista := _inimigos_do_capitulo(cap)
	if lista.is_empty():
		return
	var mob := OS.has_feature("mobile")
	var estado := {"i": clampi(idx, 0, lista.size() - 1)}

	var layer := CanvasLayer.new()
	layer.layer = 130
	layer.name = "DossieInimigo"
	add_child(layer)

	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.01, 0.95)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)

	# Capa do livro (couro)
	var pagina := PanelContainer.new()
	pagina.add_theme_stylebox_override("panel", _sb_livro_capa())
	pagina.anchor_left = 0.5
	pagina.anchor_right = 0.5
	pagina.anchor_top = 0.5
	pagina.anchor_bottom = 0.5
	pagina.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pagina.grow_vertical = Control.GROW_DIRECTION_BOTH
	var vp := get_viewport_rect().size
	var pw: float = minf(vp.x - 70.0, 920.0)
	var ph: float = minf(vp.y - 70.0, 580.0)
	pagina.custom_minimum_size = Vector2(pw, ph)
	layer.add_child(pagina)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 18)
	mc.add_theme_constant_override("margin_right", 18)
	mc.add_theme_constant_override("margin_top", 16)
	mc.add_theme_constant_override("margin_bottom", 14)
	mc.add_child(outer)
	pagina.add_child(mc)

	# Folha de pergaminho (as páginas), com vinco/lombada central estático
	var folha := PanelContainer.new()
	folha.add_theme_stylebox_override("panel", _sb_pergaminho())
	folha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	folha.clip_contents = true
	outer.add_child(folha)

	var holder := Control.new()
	folha.add_child(holder)

	var vinco := Panel.new()
	var st_vinco := StyleBoxFlat.new()
	st_vinco.bg_color = COR_PERGAMINHO_ESCURA
	st_vinco.shadow_color = Color(0.3, 0.2, 0.1, 0.45)
	st_vinco.shadow_size = 12
	vinco.add_theme_stylebox_override("panel", st_vinco)
	vinco.anchor_left = 0.5
	vinco.anchor_right = 0.5
	vinco.anchor_top = 0.0
	vinco.anchor_bottom = 1.0
	vinco.offset_left = -3.0
	vinco.offset_right = 3.0
	vinco.offset_top = 12.0
	vinco.offset_bottom = -12.0
	vinco.visible = not mob
	holder.add_child(vinco)

	# Conteúdo que vira (corpo)
	var mc_corpo := MarginContainer.new()
	mc_corpo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc_corpo.add_theme_constant_override("margin_left", 20)
	mc_corpo.add_theme_constant_override("margin_right", 20)
	mc_corpo.add_theme_constant_override("margin_top", 16)
	mc_corpo.add_theme_constant_override("margin_bottom", 16)
	holder.add_child(mc_corpo)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 10)
	mc_corpo.add_child(corpo)

	# Indicador de página + rodapé de navegação (sobre a capa de couro)
	var pagina_lbl := Label.new()
	pagina_lbl.add_theme_font_size_override("font_size", 18)
	pagina_lbl.add_theme_color_override("font_color", COR_TEXTO)
	pagina_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(pagina_lbl)

	var rodape := HBoxContainer.new()
	rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	rodape.add_theme_constant_override("separation", 20)
	outer.add_child(rodape)
	var btn_ant := _botao_leitor("◀")
	var btn_fechar := _botao_leitor("Voltar")
	var btn_prox := _botao_leitor("▶")
	rodape.add_child(btn_ant)
	rodape.add_child(btn_fechar)
	rodape.add_child(btn_prox)

	var montar := func():
		for c in corpo.get_children():
			c.queue_free()
		_preencher_dossie(corpo, lista[estado["i"]], mob)
		pagina_lbl.text = "%d / %d" % [estado["i"] + 1, lista.size()]

	btn_ant.pressed.connect(func():
		if _flipando: return
		estado["i"] = (estado["i"] - 1 + lista.size()) % lista.size()
		_flip(corpo, montar)
	)
	btn_prox.pressed.connect(func():
		if _flipando: return
		estado["i"] = (estado["i"] + 1) % lista.size()
		_flip(corpo, montar)
	)
	btn_fechar.pressed.connect(func(): layer.queue_free())
	if lista.size() <= 1:
		btn_ant.disabled = true
		btn_prox.disabled = true
	montar.call()

# Animação de "virar página": o conteúdo dobra no vinco (escala X → 0),
# troca de inimigo e desdobra do outro lado.
func _flip(corpo: Control, montar: Callable) -> void:
	if _flipando:
		return
	_flipando = true
	if SFXManager and SFXManager.has_method("tocar_som_pagina"):
		SFXManager.tocar_som_pagina()
	corpo.pivot_offset = corpo.size * 0.5
	var tw := create_tween()
	tw.tween_property(corpo, "scale:x", 0.04, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		if is_instance_valid(corpo):
			montar.call()
			corpo.pivot_offset = corpo.size * 0.5
	)
	tw.tween_property(corpo, "scale:x", 1.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _flipando = false)

func _sb_livro_capa() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = COR_COURO
	st.border_color = COR_COURO_BORDA
	st.set_border_width_all(5)
	st.set_corner_radius_all(14)
	st.shadow_color = Color(0, 0, 0, 0.6)
	st.shadow_size = 18
	return st

func _sb_pergaminho() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = COR_PERGAMINHO
	st.border_color = Color(0.55, 0.42, 0.22)
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	return st

func _preencher_dossie(corpo: VBoxContainer, dados: Dictionary, mob: bool) -> void:
	var descoberto: bool = String(dados["nome"]) in Global.inimigos_descobertos
	var cap := int(dados["mapa"])

	var topo := BoxContainer.new()
	topo.vertical = mob
	topo.add_theme_constant_override("separation", 18)
	topo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(topo)

	# Arte (moldura sobre pergaminho)
	var moldura := PanelContainer.new()
	var st_mold := _sb(Color(0.91, 0.85, 0.67, 1), COR_COURO_BORDA, 2, 12, 0)
	moldura.add_theme_stylebox_override("panel", st_mold)
	var arte_lado := 300 if not mob else 220
	moldura.custom_minimum_size = Vector2(arte_lado, arte_lado)
	moldura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var arte := TextureRect.new()
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if descoberto and ResourceLoader.exists(String(dados["icone"])):
		arte.texture = load(String(dados["icone"]))
	else:
		arte.modulate = Color(0, 0, 0, 0)
	var mc_arte := MarginContainer.new()
	mc_arte.add_theme_constant_override("margin_left", 10)
	mc_arte.add_theme_constant_override("margin_right", 10)
	mc_arte.add_theme_constant_override("margin_top", 10)
	mc_arte.add_theme_constant_override("margin_bottom", 10)
	mc_arte.add_child(arte)
	moldura.add_child(mc_arte)
	topo.add_child(moldura)

	# Coluna de informações
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 10)
	topo.add_child(info)

	var nome := Label.new()
	nome.text = String(dados["nome"]) if descoberto else "???"
	nome.add_theme_font_size_override("font_size", 38 if not mob else 30)
	nome.add_theme_color_override("font_color", COR_TINTA if descoberto else Color(0.55, 0.45, 0.32))
	info.add_child(nome)

	# Selos: categoria + ameaça
	if descoberto:
		var selos := HBoxContainer.new()
		selos.add_theme_constant_override("separation", 8)
		selos.add_child(_badge_categoria(String(dados["categoria"])))
		selos.add_child(_badge_ameaca(String(dados["categoria"])))
		info.add_child(selos)

	var sep := HSeparator.new()
	var sl := StyleBoxLine.new()
	sl.color = Color(0.45, 0.32, 0.16, 0.55)
	sl.thickness = 2
	sep.add_theme_stylebox_override("separator", sl)
	info.add_child(sep)

	var cap_lbl := Label.new()
	var nome_cap: String = BD.NOMES_MAPAS[cap] if cap < BD.NOMES_MAPAS.size() else ""
	cap_lbl.text = "Capítulo %d — %s" % [cap, nome_cap]
	cap_lbl.add_theme_font_size_override("font_size", 18)
	cap_lbl.add_theme_color_override("font_color", COR_TINTA_CLARA)
	info.add_child(cap_lbl)

	var lore := Label.new()
	lore.text = String(dados["lore"]) if descoberto else "Inimigo ainda não descoberto.\nDerrote-o em batalha para revelar seu dossiê."
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.add_theme_font_size_override("font_size", 18 if not mob else 16)
	lore.add_theme_color_override("font_color", COR_TINTA if descoberto else Color(0.5, 0.42, 0.3))
	lore.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(lore)

func _badge_ameaca(cat: String) -> PanelContainer:
	var nivel := "Baixa"
	var cor := Color(0.3, 0.45, 0.3)
	match cat:
		"Chefe": nivel = "Alta"; cor = Color(0.7, 0.18, 0.15)
		"Mini-Chefe": nivel = "Média"; cor = Color(0.7, 0.45, 0.12)
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.08, 0.05)
	st.border_color = cor
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.content_margin_left = 8; st.content_margin_right = 8
	st.content_margin_top = 2; st.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = "Ameaça: " + nivel
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", cor.lightened(0.3))
	p.add_child(l)
	return p

func _render_historias() -> void:
	var mob := OS.has_feature("mobile")
	var intro := Label.new()
	intro.text = "A jornada dos vovôs em busca dos netos."
	intro.add_theme_font_size_override("font_size", 20 if mob else 18)
	intro.add_theme_color_override("font_color", COR_TEXTO)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(intro)
	for m in BD.MAPAS:
		conteudo.add_child(_card_historia(m, mob))

# ==========================================
# CABEÇALHO DE MAPA
# ==========================================
func _cabecalho_mapa(num: int) -> Control:
	var nome: String = BD.NOMES_MAPAS[num] if num < BD.NOMES_MAPAS.size() else ""
	var lbl := Label.new()
	lbl.text = "Mapa %d — %s" % [num, nome]
	lbl.add_theme_font_size_override("font_size", 28 if OS.has_feature("mobile") else 26)
	lbl.add_theme_color_override("font_color", COR_DOURADO)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 3)
	return lbl

func _badge_categoria(cat: String) -> PanelContainer:
	var cor := Color(0.45, 0.4, 0.3)
	match cat:
		"Chefe": cor = Color(0.7, 0.18, 0.15)
		"Mini-Chefe": cor = Color(0.7, 0.45, 0.12)
		_: cor = Color(0.3, 0.4, 0.3)
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = cor
	st.set_corner_radius_all(6)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = cat
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	p.add_child(l)
	return p

# ==========================================
# CARD DE HISTÓRIA (capítulo)
# ==========================================
func _card_historia(m: Dictionary, mob: bool) -> PanelContainer:
	var num := int(m["numero"])
	var liberado: bool = num <= Global.fases_liberadas
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _sb(Color(0.14, 0.09, 0.04, 0.97), COR_BORDA, 2, 12, 0))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_child(hbox)
	card.add_child(margin)

	# Miniatura do mapa
	var thumb_w := 150 if mob else 130
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(thumb_w, thumb_w * 0.62)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if liberado and ResourceLoader.exists(String(m["thumb"])):
		tr.texture = load(String(m["thumb"]))
	hbox.add_child(tr)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(vbox)

	var titulo := Label.new()
	titulo.text = "Capítulo %d — %s" % [num, String(m["nome"])] if liberado else "Capítulo %d — ???" % num
	titulo.add_theme_font_size_override("font_size", 24 if mob else 21)
	titulo.add_theme_color_override("font_color", Color(1, 0.9, 0.55) if liberado else Color(0.5, 0.45, 0.38))
	vbox.add_child(titulo)

	if liberado:
		var btn := Button.new()
		btn.text = "📖  Ler história"
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.add_theme_font_size_override("font_size", 18 if mob else 16)
		btn.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
		btn.add_theme_stylebox_override("normal", _sb(Color(0.22, 0.14, 0.05), COR_BORDA, 2, 9, 0))
		btn.add_theme_stylebox_override("hover", _sb(Color(0.3, 0.2, 0.07), COR_DOURADO, 2, 9, 0))
		btn.add_theme_stylebox_override("pressed", _sb(Color(0.18, 0.11, 0.04), COR_BORDA, 2, 9, 0))
		btn.pressed.connect(_abrir_leitor.bind(String(m["cutscene"]), String(m["nome"])))
		vbox.add_child(btn)
	else:
		var bloq := Label.new()
		bloq.text = "🔒  Complete a fase anterior para desbloquear este capítulo."
		bloq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bloq.add_theme_font_size_override("font_size", 15)
		bloq.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4))
		vbox.add_child(bloq)
		card.modulate = Color(0.8, 0.8, 0.8, 0.9)

	return card

# ==========================================
# LEITOR DE HISTÓRIA (overlay paginado)
# ==========================================
func _abrir_leitor(caminho_cutscene: String, nome_mapa: String) -> void:
	var imagens := BD.obter_imagens_historia(caminho_cutscene)

	var layer := CanvasLayer.new()
	layer.layer = 130
	layer.name = "LeitorHistoria"
	add_child(layer)

	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.01, 0.96)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)

	var titulo := Label.new()
	titulo.text = nome_mapa
	titulo.add_theme_font_size_override("font_size", 36)
	titulo.add_theme_color_override("font_color", COR_DOURADO)
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	titulo.add_theme_constant_override("outline_size", 4)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.anchor_left = 0.0
	titulo.anchor_right = 1.0
	titulo.offset_top = 24.0
	titulo.offset_bottom = 76.0
	layer.add_child(titulo)

	var img_rect := TextureRect.new()
	img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img_rect.offset_top = 90.0
	img_rect.offset_bottom = -120.0
	img_rect.offset_left = 60.0
	img_rect.offset_right = -60.0
	layer.add_child(img_rect)

	var vazio := Label.new()
	vazio.text = "História ainda não ilustrada.\nAs páginas aparecem aqui quando a cutscene desta fase tiver arte."
	vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vazio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vazio.add_theme_font_size_override("font_size", 22)
	vazio.add_theme_color_override("font_color", COR_TEXTO)
	vazio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vazio.offset_top = 90.0
	vazio.offset_bottom = -120.0
	vazio.visible = imagens.is_empty()
	layer.add_child(vazio)

	# Indicador de página
	var pagina_lbl := Label.new()
	pagina_lbl.add_theme_font_size_override("font_size", 20)
	pagina_lbl.add_theme_color_override("font_color", COR_TEXTO)
	pagina_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pagina_lbl.anchor_left = 0.0
	pagina_lbl.anchor_right = 1.0
	pagina_lbl.anchor_top = 1.0
	pagina_lbl.anchor_bottom = 1.0
	pagina_lbl.offset_top = -104.0
	pagina_lbl.offset_bottom = -72.0
	layer.add_child(pagina_lbl)

	# Estado de página
	var estado := {"i": 0}
	var atualizar := func():
		if imagens.is_empty():
			pagina_lbl.text = ""
			return
		img_rect.texture = imagens[estado["i"]]
		pagina_lbl.text = "Página %d / %d" % [estado["i"] + 1, imagens.size()]

	# Botões ◀ ▶ Fechar
	var barra := HBoxContainer.new()
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 24)
	barra.anchor_left = 0.0
	barra.anchor_right = 1.0
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_top = -64.0
	barra.offset_bottom = -16.0
	layer.add_child(barra)

	var btn_ant := _botao_leitor("◀")
	var btn_prox := _botao_leitor("▶")
	var btn_fechar := _botao_leitor("Fechar")
	barra.add_child(btn_ant)
	barra.add_child(btn_fechar)
	barra.add_child(btn_prox)

	btn_ant.pressed.connect(func():
		if imagens.is_empty(): return
		estado["i"] = (estado["i"] - 1 + imagens.size()) % imagens.size()
		atualizar.call()
	)
	btn_prox.pressed.connect(func():
		if imagens.is_empty(): return
		estado["i"] = (estado["i"] + 1) % imagens.size()
		atualizar.call()
	)
	btn_fechar.pressed.connect(func(): layer.queue_free())

	if imagens.size() <= 1:
		btn_ant.disabled = true
		btn_prox.disabled = imagens.size() <= 1
	atualizar.call()

func _botao_leitor(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(120, 48)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	b.add_theme_stylebox_override("normal", _sb(Color(0.22, 0.14, 0.05), COR_BORDA, 2, 10, 0))
	b.add_theme_stylebox_override("hover", _sb(Color(0.3, 0.2, 0.07), COR_DOURADO, 2, 10, 0))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.18, 0.11, 0.04), COR_BORDA, 2, 10, 0))
	b.add_theme_stylebox_override("disabled", _sb(Color(0.12, 0.1, 0.07), Color(0.3, 0.26, 0.2), 2, 10, 0))
	return b

# ==========================================
# HELPERS
# ==========================================
func _sb(bg: Color, borda: Color, esp: int, raio: int, _margem: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	if esp > 0:
		st.border_color = borda
		st.set_border_width_all(esp)
	st.set_corner_radius_all(raio)
	return st

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
