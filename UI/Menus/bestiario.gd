extends Control

# ==========================================
# BESTIÁRIO ("o livro") — info dos inimigos + histórias das fases
# Acesso: menu principal. Conteúdo bloqueado com ??? até ser descoberto.
# ==========================================

const BD = preload("res://Bestiario/bestiario_dados.gd")
const _SHADER_MADEIRA = preload("res://Shaders/wood_desk.gdshader")
const _SHADER_CURL = preload("res://Shaders/page_curl.gdshader")
const _SHADER_PERGAMINHO = preload("res://Shaders/parchment.gdshader")

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

var _secao: String = "inimigos"   # "inimigos" | "historias" | "cartas" | "construcoes"
var _btn_inimigos: Button = null
var _btn_historias: Button = null
var _btn_cartas: Button = null
var _btn_construcoes: Button = null
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
	_btn_cartas = _criar_aba("Cartas", "cartas")
	_btn_construcoes = _criar_aba("Construções", "construcoes")
	abas.add_child(_btn_inimigos)
	abas.add_child(_btn_historias)
	abas.add_child(_btn_cartas)
	abas.add_child(_btn_construcoes)
	_atualizar_abas()

func _criar_aba(texto: String, id: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 58)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 30 if OS.has_feature("mobile") else 28)
	b.pressed.connect(_on_aba_pressed.bind(id))
	return b

func _on_aba_pressed(id: String) -> void:
	if _secao == id:
		return
	_secao = id
	_atualizar_abas()
	_render()

func _atualizar_abas() -> void:
	for par in [[_btn_inimigos, "inimigos"], [_btn_historias, "historias"], [_btn_cartas, "cartas"], [_btn_construcoes, "construcoes"]]:
		var b: Button = par[0]
		var ativo: bool = (_secao == par[1])
		var bg := Color(0.28, 0.18, 0.06) if ativo else Color(0.14, 0.09, 0.04)
		var borda := COR_DOURADO if ativo else COR_BORDA
		b.add_theme_color_override("font_color", Color(1, 0.92, 0.6) if ativo else COR_TEXTO)
		b.add_theme_stylebox_override("normal", _sb_aba(bg, borda))
		b.add_theme_stylebox_override("hover", _sb_aba(Color(0.3, 0.2, 0.07), COR_DOURADO))
		b.add_theme_stylebox_override("pressed", _sb_aba(bg, borda))

func _sb_aba(bg: Color, borda: Color) -> StyleBoxFlat:
	var st := _sb(bg, borda, 2, 12, 0)
	st.content_margin_left = 32
	st.content_margin_right = 32
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st

# ==========================================
# RENDER
# ==========================================
func _render() -> void:
	for c in conteudo.get_children():
		c.queue_free()
	scroll.scroll_vertical = 0
	if _secao == "inimigos":
		_render_inimigos()
	elif _secao == "cartas":
		_render_cartas()
	elif _secao == "construcoes":
		_render_construcoes()
	else:
		_render_historias()

# ==========================================
# ABA CARTAS (poderes de batalha)
# ==========================================
func _render_cartas() -> void:
	var mob := OS.has_feature("mobile")
	var intro := Label.new()
	intro.text = "As cartas que você já encontrou nas batalhas."
	intro.add_theme_font_size_override("font_size", 26 if mob else 24)
	intro.add_theme_color_override("font_color", COR_TEXTO)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(intro)

	# Só mostra as cartas que o jogador já pegou
	var obtidas: Array = []
	var total := 0
	for carta in GameManager.baralho_upgrades:
		if carta != null and ("id" in carta):
			total += 1
			if Global.cartas_obtidas.has(str(carta.id)):
				obtidas.append(carta)

	# Contador de coleção (ex.: 18/30)
	var contador := Label.new()
	contador.text = "Coleção: %d/%d" % [obtidas.size(), total]
	contador.add_theme_font_size_override("font_size", 38 if mob else 34)
	contador.add_theme_color_override("font_color", Color(1, 0.86, 0.4))
	contador.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	contador.add_theme_constant_override("outline_size", 4)
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(contador)

	if obtidas.is_empty():
		var vazio := Label.new()
		vazio.text = "Você ainda não pegou nenhuma carta.\nJogue uma partida para começar a coleção!"
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vazio.add_theme_font_size_override("font_size", 24)
		vazio.add_theme_color_override("font_color", COR_TEXTO)
		conteudo.add_child(vazio)
		return

	var grid := GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(grid)
	for carta in obtidas:
		grid.add_child(_card_powerup(carta, mob))

# Cor da borda conforme o tipo da carta (ofensiva / defesa / economia / especial)
func _cor_tipo_carta(tipo: int) -> Color:
	match tipo:
		1, 5, 12, 14, 18, 19, 26, 27:   # economia — dourado
			return Color(0.92, 0.74, 0.22)
		2, 10, 13, 21, 23, 24:          # defesa — azul
			return Color(0.32, 0.58, 0.88)
		4, 6:                           # controle / especial — roxo
			return Color(0.66, 0.40, 0.85)
		_:                              # ofensiva — vermelho
			return Color(0.85, 0.30, 0.22)

func _card_powerup(carta, mob: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 150 if mob else 138)
	var cor_borda := _cor_tipo_carta(int(carta.tipo_bonus)) if "tipo_bonus" in carta else COR_BORDA
	card.add_theme_stylebox_override("panel", _sb(Color(0.14, 0.09, 0.04, 0.97), cor_borda, 3, 14, 0))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(hbox)
	card.add_child(margin)

	var cardtexture := TextureRect.new()
	var ic := 120 if mob else 104
	cardtexture.custom_minimum_size = Vector2(ic, ic)
	cardtexture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cardtexture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cardtexture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if "icone" in carta and carta.icone != null:
		cardtexture.texture = carta.icone
	hbox.add_child(cardtexture)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(vbox)

	var titulo := Label.new()
	titulo.text = String(carta.titulo) if "titulo" in carta else ""
	titulo.add_theme_font_size_override("font_size", 30 if mob else 27)
	titulo.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	vbox.add_child(titulo)

	var desc := Label.new()
	desc.text = String(carta.descricao) if "descricao" in carta else ""
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 24 if mob else 21)
	desc.add_theme_color_override("font_color", Color(0.92, 0.85, 0.72))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	return card

# ==========================================
# ABA CONSTRUÇÕES (descobertas ao construir)
# ==========================================
func _render_construcoes() -> void:
	var mob := OS.has_feature("mobile")
	var intro := Label.new()
	intro.text = "As construções que você já ergueu nas batalhas."
	intro.add_theme_font_size_override("font_size", 26 if mob else 24)
	intro.add_theme_color_override("font_color", COR_TEXTO)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(intro)

	var lista: Array = BD.CONSTRUCOES
	var descobertas := 0
	for c in lista:
		if Global.construcoes_descobertas.has(c["id"]):
			descobertas += 1

	var contador := Label.new()
	contador.text = "Coleção: %d/%d" % [descobertas, lista.size()]
	contador.add_theme_font_size_override("font_size", 38 if mob else 34)
	contador.add_theme_color_override("font_color", Color(1, 0.86, 0.4))
	contador.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	contador.add_theme_constant_override("outline_size", 4)
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(contador)

	var grid := GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(grid)
	for c in lista:
		var descoberta: bool = Global.construcoes_descobertas.has(c["id"])
		grid.add_child(_card_construcao(c, descoberta, mob))

# Cor da borda conforme o tipo da construção
func _cor_tipo_construcao(tipo: String) -> Color:
	match tipo:
		"economia": return Color(0.92, 0.74, 0.22)   # dourado
		"defesa":   return Color(0.32, 0.58, 0.88)    # azul
		_:          return Color(0.85, 0.30, 0.22)    # ofensiva — vermelho

func _card_construcao(dados: Dictionary, descoberta: bool, mob: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 150 if mob else 138)
	var cor_borda := _cor_tipo_construcao(String(dados.get("tipo", "ofensiva"))) if descoberta else COR_BORDA
	card.add_theme_stylebox_override("panel", _sb(Color(0.14, 0.09, 0.04, 0.97), cor_borda, 3, 14, 0))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(hbox)
	card.add_child(margin)

	var ic := 120 if mob else 104
	if descoberta:
		var texturecard := TextureRect.new()
		texturecard.custom_minimum_size = Vector2(ic, ic)
		texturecard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texturecard.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texturecard.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cam := String(dados.get("icone", ""))
		if cam != "" and ResourceLoader.exists(cam):
			texturecard.texture = load(cam)
		hbox.add_child(texturecard)
	else:
		# Silhueta: mostra "?" grande no lugar do ícone
		var q := Label.new()
		q.text = "?"
		q.add_theme_font_size_override("font_size", 64 if mob else 56)
		q.add_theme_color_override("font_color", Color(0.55, 0.45, 0.30))
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.custom_minimum_size = Vector2(ic, ic)
		hbox.add_child(q)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(vbox)

	var titulo := Label.new()
	titulo.text = String(dados.get("nome", "")) if descoberta else "???"
	titulo.add_theme_font_size_override("font_size", 30 if mob else 27)
	titulo.add_theme_color_override("font_color", Color(1, 0.92, 0.6) if descoberta else Color(0.62, 0.52, 0.36))
	vbox.add_child(titulo)

	var desc := Label.new()
	if descoberta:
		var txt := String(dados.get("descricao", ""))
		if dados.has("melhoria") and String(dados.melhoria) != "":
			txt += "\nMelhoria: " + String(dados.melhoria)
		desc.text = txt
	else:
		desc.text = "Construa esta construção em uma partida para revelá-la."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 24 if mob else 21)
	desc.add_theme_color_override("font_color", Color(0.92, 0.85, 0.72) if descoberta else Color(0.60, 0.52, 0.40))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	return card

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

	# Grade de retratos clicáveis — cards grandes que preenchem a tela
	var lista := _inimigos_do_capitulo(_capitulo_sel)
	var n := lista.size()
	# Poucas colunas = cards maiores (melhor pro público idoso e ocupa mais espaço)
	var cols := 2 if mob else (2 if n <= 4 else 3)
	var rows := int(ceil(float(n) / float(cols)))
	var sep := 18
	# Altura disponível abaixo do título/abas/cabeçalho — distribui entre as linhas
	var vp_h := get_viewport_rect().size.y
	var reservado := 360.0
	var disp := maxf(vp_h - reservado, 320.0)
	var card_h := clampf((disp - float(rows - 1) * sep) / float(maxi(rows, 1)), 190.0, 440.0)

	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", sep)
	grid.add_theme_constant_override("v_separation", sep)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(grid)
	for idx in range(n):
		grid.add_child(_portrait_inimigo(lista[idx], idx, mob, card_h))

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

# Retrato clicável que abre o dossiê. card_h define a altura (preenche a tela).
func _portrait_inimigo(dados: Dictionary, idx: int, mob: bool, card_h: float) -> Button:
	var descoberto: bool = String(dados["nome"]) in Global.inimigos_descobertos
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, card_h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _sb(Color(0.14, 0.09, 0.04, 0.97), COR_BORDA, 2, 14, 0))
	b.add_theme_stylebox_override("hover", _sb(Color(0.22, 0.14, 0.05, 0.98), COR_DOURADO, 3, 14, 0))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.12, 0.08, 0.03, 0.98), COR_BORDA, 2, 14, 0))

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 10)
	# Margem interna para a arte respirar
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left", 14)
	mc.add_theme_constant_override("margin_right", 14)
	mc.add_theme_constant_override("margin_top", 14)
	mc.add_theme_constant_override("margin_bottom", 14)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(v)
	b.add_child(mc)

	var icontexture := TextureRect.new()
	icontexture.custom_minimum_size = Vector2(0, card_h * 0.58)
	icontexture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icontexture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icontexture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icontexture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if descoberto and ResourceLoader.exists(String(dados["icone"])):
		icontexture.texture = load(String(dados["icone"]))
		icontexture.modulate = Color.WHITE
	else:
		icontexture.modulate = Color(0, 0, 0, 0)  # silhueta vazia
	v.add_child(icontexture)

	var lbl := Label.new()
	lbl.text = String(dados["nome"]) if descoberto else "???"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 24 if not mob else 22)
	lbl.add_theme_color_override("font_color", Color(1, 0.92, 0.6) if descoberto else Color(0.66, 0.6, 0.5))
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
	var pw: float = minf(vp.x - 60.0, 1300.0)
	var ph: float = minf(vp.y - 60.0, 840.0)
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

	# Fundo de pergaminho envelhecido (shader)
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat_paper := ShaderMaterial.new()
	mat_paper.shader = _SHADER_PERGAMINHO
	paper.material = mat_paper
	holder.add_child(paper)

	# Conteúdo que vira (corpo)
	var mc_corpo := MarginContainer.new()
	mc_corpo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc_corpo.add_theme_constant_override("margin_left", 34)
	mc_corpo.add_theme_constant_override("margin_right", 34)
	mc_corpo.add_theme_constant_override("margin_top", 28)
	mc_corpo.add_theme_constant_override("margin_bottom", 26)
	holder.add_child(mc_corpo)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 10)
	mc_corpo.add_child(corpo)

	# Indicador de página + rodapé de navegação (sobre a capa de couro)
	var pagina_lbl := Label.new()
	pagina_lbl.add_theme_font_size_override("font_size", 22)
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
		_flip(folha, corpo, montar, -1)
	)
	btn_prox.pressed.connect(func():
		if _flipando: return
		estado["i"] = (estado["i"] + 1) % lista.size()
		_flip(folha, corpo, montar, 1)
	)
	btn_fechar.pressed.connect(func(): layer.queue_free())
	if lista.size() <= 1:
		btn_ant.disabled = true
		btn_prox.disabled = true
	montar.call()

# Animação de virar página (page-curl real via shader): tira um "snapshot" da
# página atual, troca o conteúdo por baixo e enrola o snapshot revelando a nova.
func _flip(folha: Control, corpo: Control, montar: Callable, dir: int) -> void:
	if _flipando:
		return
	_flipando = true
	if SFXManager and SFXManager.has_method("tocar_som_pagina"):
		SFXManager.tocar_som_pagina()

	# Captura a página atual antes de trocar o conteúdo
	await RenderingServer.frame_post_draw
	if not is_instance_valid(folha) or not is_instance_valid(corpo):
		_flipando = false
		return
	var snap := _snapshot_controle(folha)
	montar.call()  # nova página por baixo
	if snap == null:
		_flipando = false
		return

	var overlay := TextureRect.new()
	overlay.texture = snap
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER_CURL
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("curl_radius", 0.16)
	mat.set_shader_parameter("flip_x", 0.0 if dir >= 0 else 1.0)
	overlay.material = mat
	folha.add_child(overlay)

	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.55) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
		_flipando = false
	)

# Snapshot de um Control para textura (recorta o frame do viewport na região dele)
func _snapshot_controle(ctrl: Control) -> ImageTexture:
	var vp := get_viewport()
	if vp == null:
		return null
	var img := vp.get_texture().get_image()
	if img == null:
		return null
	var vis := vp.get_visible_rect().size
	if vis.x <= 0.0 or vis.y <= 0.0:
		return null
	var gr := ctrl.get_global_rect()
	var sx := float(img.get_width()) / vis.x
	var sy := float(img.get_height()) / vis.y
	var rx := clampi(int(round(gr.position.x * sx)), 0, img.get_width() - 1)
	var ry := clampi(int(round(gr.position.y * sy)), 0, img.get_height() - 1)
	var rw := clampi(int(round(gr.size.x * sx)), 1, img.get_width() - rx)
	var rh := clampi(int(round(gr.size.y * sy)), 1, img.get_height() - ry)
	var region := img.get_region(Rect2i(rx, ry, rw, rh))
	return ImageTexture.create_from_image(region)

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

	# Arte (moldura "montada" sobre o pergaminho, com sombra)
	var moldura := PanelContainer.new()
	var st_mold := StyleBoxFlat.new()
	st_mold.bg_color = Color(0.94, 0.88, 0.71)
	st_mold.border_color = Color(0.34, 0.22, 0.10)
	st_mold.set_border_width_all(3)
	st_mold.set_corner_radius_all(10)
	st_mold.shadow_color = Color(0.22, 0.14, 0.07, 0.55)
	st_mold.shadow_size = 10
	st_mold.shadow_offset = Vector2(0, 5)
	moldura.add_theme_stylebox_override("panel", st_mold)
	var arte_lado := 400 if not mob else 280
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
	nome.add_theme_font_size_override("font_size", 48 if not mob else 36)
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
	cap_lbl.add_theme_font_size_override("font_size", 22)
	cap_lbl.add_theme_color_override("font_color", COR_TINTA_CLARA)
	info.add_child(cap_lbl)

	# Ficha (campos do dossiê)
	if descoberto:
		info.add_child(_linha_dossie("Primeiro avistamento", String(dados.get("avistamento", "—")), mob))
		info.add_child(_linha_dossie("Comportamento", String(dados.get("comportamento", "—")), mob))
		info.add_child(_linha_dossie("Fraqueza", String(dados.get("fraqueza", "—")), mob))

		# Vídeo de apresentação (só chefes que têm vídeo)
		var vid_path := _caminho_video(dados)
		if vid_path != "":
			info.add_child(_botao_video(vid_path, String(dados["nome"]), mob))

		var sep2 := HSeparator.new()
		var sl2 := StyleBoxLine.new()
		sl2.color = Color(0.45, 0.32, 0.16, 0.4)
		sl2.thickness = 1
		sep2.add_theme_stylebox_override("separator", sl2)
		info.add_child(sep2)

	var lore := Label.new()
	lore.text = String(dados["lore"]) if descoberto else "Inimigo ainda não descoberto.\nDerrote-o em batalha para revelar seu dossiê."
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.add_theme_font_size_override("font_size", 22 if not mob else 19)
	lore.add_theme_color_override("font_color", COR_TINTA if descoberto else Color(0.5, 0.42, 0.3))
	lore.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(lore)

# Caminho do vídeo de apresentação do chefe (Boss<N>.ogv por mapa), se existir.
func _caminho_video(dados: Dictionary) -> String:
	if String(dados.get("categoria", "")) != "Chefe":
		return ""
	var p := "res://Assets/Videos/Boss%d.ogv" % int(dados["mapa"])
	return p if ResourceLoader.exists(p) else ""

func _botao_video(caminho: String, nome: String, mob: bool) -> Button:
	var b := Button.new()
	b.text = "▶  Ver apresentação"
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(0, 58)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 23 if not mob else 20)
	b.add_theme_color_override("font_color", Color(1, 0.93, 0.72))
	b.add_theme_stylebox_override("normal", _sb_video(Color(0.50, 0.13, 0.10)))
	b.add_theme_stylebox_override("hover", _sb_video(Color(0.66, 0.18, 0.13)))
	b.add_theme_stylebox_override("pressed", _sb_video(Color(0.40, 0.10, 0.08)))
	b.pressed.connect(_abrir_video.bind(caminho, nome))
	return b

func _sb_video(bg: Color) -> StyleBoxFlat:
	var st := _sb(bg, Color(0.92, 0.42, 0.26), 2, 10, 0)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	return st

# Overlay em tela cheia que toca o vídeo de reveal do chefe
func _abrir_video(caminho: String, nome: String) -> void:
	var stream = load(caminho)
	if stream == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 140
	layer.name = "VideoBoss"
	add_child(layer)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 1)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)

	var vid := VideoStreamPlayer.new()
	vid.stream = stream
	vid.expand = true
	vid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(vid)

	# Nome do chefe (rodapé)
	var titulo := Label.new()
	titulo.text = nome.to_upper()
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", COR_DOURADO)
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	titulo.add_theme_constant_override("outline_size", 5)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.anchor_left = 0.0
	titulo.anchor_right = 1.0
	titulo.anchor_top = 1.0
	titulo.anchor_bottom = 1.0
	titulo.offset_top = -110.0
	titulo.offset_bottom = -54.0
	layer.add_child(titulo)

	# Botão fechar (canto superior direito)
	var btn := _botao_leitor("Fechar")
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.offset_left = -156.0
	btn.offset_right = -16.0
	btn.offset_top = 16.0
	btn.offset_bottom = 68.0
	layer.add_child(btn)

	var fechar := func():
		if is_instance_valid(layer):
			layer.queue_free()
	btn.pressed.connect(fechar)
	vid.finished.connect(fechar)
	vid.play()

# Linha "Rótulo: valor" usando Labels comuns (rótulo em cor de destaque) — render
# consistente com o resto, sem o negrito sintético torto do RichTextLabel.
func _linha_dossie(rotulo: String, valor: String, mob: bool) -> HBoxContainer:
	var fs := 19 if not mob else 17
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lr := Label.new()
	lr.text = rotulo + ":"
	lr.add_theme_font_size_override("font_size", fs)
	lr.add_theme_color_override("font_color", COR_TINTA_CLARA)
	lr.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(lr)

	var lv := Label.new()
	lv.text = valor
	lv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lv.add_theme_font_size_override("font_size", fs)
	lv.add_theme_color_override("font_color", COR_TINTA)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lv)
	return h

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
	st.content_margin_left = 11; st.content_margin_right = 11
	st.content_margin_top = 4; st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = "Ameaça: " + nivel
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", cor.lightened(0.55))
	p.add_child(l)
	return p

func _render_historias() -> void:
	var mob := OS.has_feature("mobile")
	var intro := Label.new()
	intro.text = "A jornada dos vovôs em busca dos netos."
	intro.add_theme_font_size_override("font_size", 22 if mob else 20)
	intro.add_theme_color_override("font_color", COR_TEXTO)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(intro)

	# Só os mapas já liberados
	var mapas_lib: Array = []
	for m in BD.MAPAS:
		if int(m["numero"]) <= Global.fases_liberadas:
			mapas_lib.append(m)
	if mapas_lib.is_empty():
		return

	# Grade de capítulos que preenche a tela (cards grandes)
	var n := mapas_lib.size()
	var cols := 1 if mob else mini(3, n)
	var rows := int(ceil(float(n) / float(cols)))
	var sep := 18
	var vp_h := get_viewport_rect().size.y
	var reservado := 330.0
	var disp := maxf(vp_h - reservado, 320.0)
	var card_h := clampf((disp - float(rows - 1) * sep) / float(maxi(rows, 1)), 210.0, 430.0)

	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", sep)
	grid.add_theme_constant_override("v_separation", sep)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_child(grid)
	for m in mapas_lib:
		grid.add_child(_card_historia(m, mob, card_h))

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
	st.border_color = cor.darkened(0.35)
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.content_margin_left = 11
	st.content_margin_right = 11
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = cat
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("outline_size", 2)
	p.add_child(l)
	return p

# ==========================================
# CARD DE HISTÓRIA (capítulo)
# ==========================================
func _card_historia(m: Dictionary, mob: bool, card_h: float) -> PanelContainer:
	var num := int(m["numero"])
	var liberado: bool = num <= Global.fases_liberadas
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, card_h)
	card.add_theme_stylebox_override("panel", _sb(Color(0.14, 0.09, 0.04, 0.97), COR_BORDA, 2, 14, 0))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(vbox)
	card.add_child(margin)

	# Miniatura grande do mapa (ocupa o topo do card)
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.04, 0.02), Color(0.35, 0.26, 0.12), 1, 8, 0))
	moldura.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moldura.clip_contents = true
	var maptexture := TextureRect.new()
	maptexture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	maptexture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	maptexture.custom_minimum_size = Vector2(0, card_h * 0.45)
	if liberado and ResourceLoader.exists(String(m["thumb"])):
		maptexture.texture = load(String(m["thumb"]))
	else:
		# Bloqueado: "?" grande no lugar da miniatura
		var q := Label.new()
		q.text = "?"
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 72)
		q.add_theme_color_override("font_color", Color(0.4, 0.34, 0.24))
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		moldura.add_child(q)
	moldura.add_child(maptexture)
	vbox.add_child(moldura)

	var titulo := Label.new()
	titulo.text = "Capítulo %d — %s" % [num, String(m["nome"])] if liberado else "Capítulo %d — ???" % num
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_font_size_override("font_size", 25 if not mob else 23)
	titulo.add_theme_color_override("font_color", Color(1, 0.92, 0.6) if liberado else Color(0.6, 0.54, 0.44))
	vbox.add_child(titulo)

	if liberado:
		var btn := Button.new()
		btn.text = "📖  Ler história"
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 22 if not mob else 20)
		btn.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
		btn.add_theme_stylebox_override("normal", _sb(Color(0.22, 0.14, 0.05), COR_BORDA, 2, 10, 0))
		btn.add_theme_stylebox_override("hover", _sb(Color(0.3, 0.2, 0.07), COR_DOURADO, 3, 10, 0))
		btn.add_theme_stylebox_override("pressed", _sb(Color(0.18, 0.11, 0.04), COR_BORDA, 2, 10, 0))
		btn.pressed.connect(_abrir_leitor.bind(String(m["cutscene"]), String(m["nome"])))
		vbox.add_child(btn)
	else:
		var bloq := Label.new()
		bloq.text = "🔒  Conclua a fase anterior para liberar"
		bloq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bloq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bloq.add_theme_font_size_override("font_size", 18 if not mob else 17)
		bloq.add_theme_color_override("font_color", Color(0.6, 0.54, 0.44))
		vbox.add_child(bloq)
		card.modulate = Color(0.82, 0.82, 0.82, 0.92)

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
	b.custom_minimum_size = Vector2(150, 58)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 24)
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

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
