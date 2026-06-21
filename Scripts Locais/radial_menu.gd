extends Control

## Mantidos por compatibilidade
@export var raio_menu: float = 200.0
@export var prefab_botao: PackedScene

# Ícones pré-carregados (substituem todos os emojis)
const ICON_MOEDAS   = preload("res://Assets/Icons/Moedas.png")
const ICON_ESPADA   = preload("res://Assets/Icons/Espada.png")
const ICON_ESCUDO   = preload("res://Assets/Icons/Escudo.png")
const ICON_CHAVE    = preload("res://Assets/Icons/ChaveInglesa.png")
const ICON_CADEADO  = preload("res://Assets/Icons/cadeado.png")

var _botoes_ativos: Array[Node] = []
var _slot_alvo: Node = null

# Estado de seleção
var _botao_selecionado: Button = null
var _cena_selecionada: PackedScene = null
var _custo_selecionado: int = 0
var _tweens_destaque: Dictionary = {}

# Nós UI (construídos proceduralmente em _ready)
var _painel: PanelContainer = null
var _preview_icone: TextureRect = null
var _preview_nome: Label = null
var _preview_tipo_icone: TextureRect = null  # ícone dinâmico do tipo (espada/escudo/moedas)
var _preview_tipo: Label = null               # texto do tipo
var _preview_desc: Label = null
var _preview_upgrade: Label = null
var _preview_custo: Label = null              # só o número/texto; ícone Moedas fica ao lado
var _preview_custo_icon: TextureRect = null   # ícone de moedas ao lado do custo (escondido quando grátis)
var _btn_confirmar: Button = null
var _grid: GridContainer = null

func _ready() -> void:
	add_to_group("RadialMenu")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	_construir_ui()

# ==========================================
# CONSTRUÇÃO DA UI
# ==========================================
func _construir_ui() -> void:
	# Fundo escuro semitransparente
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# CenterContainer mantém o painel centrado na tela
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_painel = PanelContainer.new()
	_painel.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.09, 0.06, 0.97), Color(0.55, 0.42, 0.18), 2, 14))
	center.add_child(_painel)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 0)
	_painel.add_child(raiz)

	# ── Cabeçalho ──────────────────────────────────────────────────────
	var cab := PanelContainer.new()
	var st_cab := StyleBoxFlat.new()
	st_cab.bg_color = Color(0.08, 0.06, 0.04, 1.0)
	st_cab.corner_radius_top_left  = 14
	st_cab.corner_radius_top_right = 14
	st_cab.content_margin_left   = 22
	st_cab.content_margin_right  = 12
	st_cab.content_margin_top    = 14
	st_cab.content_margin_bottom = 14
	cab.add_theme_stylebox_override("panel", st_cab)
	raiz.add_child(cab)

	var hcab := HBoxContainer.new()
	hcab.add_theme_constant_override("separation", 8)
	cab.add_child(hcab)

	var titulo := Label.new()
	titulo.text = "Escolha uma construção"
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	titulo.add_theme_constant_override("outline_size", 3)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hcab.add_child(titulo)

	var btn_x := Button.new()
	btn_x.text = "✕"
	btn_x.add_theme_font_size_override("font_size", 24)
	btn_x.add_theme_color_override("font_color", Color(0.80, 0.70, 0.60))
	btn_x.custom_minimum_size = Vector2(48, 48)
	btn_x.focus_mode = Control.FOCUS_NONE
	btn_x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_x.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0),             Color(0,0,0,0), 0, 6))
	btn_x.add_theme_stylebox_override("hover",   _sb(Color(0.45,0.10,0.10,0.75), Color(0,0,0,0), 0, 6))
	btn_x.add_theme_stylebox_override("pressed", _sb(Color(0.65,0.10,0.10,0.95), Color(0,0,0,0), 0, 6))
	btn_x.pressed.connect(func():
		if is_instance_valid(_slot_alvo) and _slot_alvo.has_method("fechar_ui"):
			_slot_alvo.fechar_ui()
	)
	hcab.add_child(btn_x)

	# Linha divisória
	var sep_h := Panel.new()
	sep_h.custom_minimum_size = Vector2(0, 2)
	sep_h.add_theme_stylebox_override("panel", _sb(Color(0.35, 0.27, 0.10), Color(0,0,0,0), 0, 0))
	raiz.add_child(sep_h)

	# ── Corpo ──────────────────────────────────────────────────────────
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 0)
	# No mobile o painel precisa ser largo o suficiente para os botões de construção
	corpo.custom_minimum_size = Vector2(700 if OS.has_feature("mobile") else 920, 540)
	raiz.add_child(corpo)

	# ── ESQUERDA: grade de construções ─────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corpo.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	_grid = GridContainer.new()
	_grid.columns = 2 if OS.has_feature("mobile") else 3
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_grid)

	# Separador vertical
	var sep_v := Panel.new()
	sep_v.custom_minimum_size = Vector2(2, 0)
	sep_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sep_v.add_theme_stylebox_override("panel", _sb(Color(0.35, 0.27, 0.10), Color(0,0,0,0), 0, 0))
	corpo.add_child(sep_v)

	# ── DIREITA: preview da construção selecionada ─────────────────────
	var dir := PanelContainer.new()
	dir.custom_minimum_size = Vector2(300, 0)
	var st_dir := StyleBoxFlat.new()
	st_dir.bg_color = Color(0.08, 0.05, 0.03, 1.0)
	st_dir.content_margin_left   = 18
	st_dir.content_margin_right  = 18
	st_dir.content_margin_top    = 18
	st_dir.content_margin_bottom = 18
	st_dir.corner_radius_bottom_right = 14
	dir.add_theme_stylebox_override("panel", st_dir)
	dir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(dir)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dir.add_child(vbox)

	# Ícone 168×168
	var ic_cont := Control.new()
	ic_cont.custom_minimum_size = Vector2(196, 196)
	ic_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(ic_cont)

	var ic_bg := ColorRect.new()
	ic_bg.color = Color(0.05, 0.03, 0.01, 1.0)
	ic_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic_cont.add_child(ic_bg)

	_preview_icone = TextureRect.new()
	_preview_icone.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_preview_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_icone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview_icone.modulate = Color(0.25, 0.25, 0.25, 0.4)
	ic_cont.add_child(_preview_icone)

	# Nome
	_preview_nome = Label.new()
	_preview_nome.text = "—"
	_preview_nome.add_theme_font_size_override("font_size", 24)
	_preview_nome.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_preview_nome.add_theme_color_override("font_outline_color", Color.BLACK)
	_preview_nome.add_theme_constant_override("outline_size", 3)
	_preview_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_preview_nome)

	# Badge de tipo: [ícone] + [texto]
	var hbox_tipo := HBoxContainer.new()
	hbox_tipo.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_tipo.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_tipo)

	_preview_tipo_icone = TextureRect.new()
	_preview_tipo_icone.custom_minimum_size = Vector2(22, 22)
	_preview_tipo_icone.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_preview_tipo_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_tipo_icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_tipo.add_child(_preview_tipo_icone)

	_preview_tipo = Label.new()
	_preview_tipo.text = ""
	_preview_tipo.add_theme_font_size_override("font_size", 17)
	_preview_tipo.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_preview_tipo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_tipo.add_child(_preview_tipo)

	# O que faz
	_preview_desc = Label.new()
	_preview_desc.text = "← Escolha uma\nconstrução"
	_preview_desc.add_theme_font_size_override("font_size", 18)
	_preview_desc.add_theme_color_override("font_color", Color(0.78, 0.68, 0.50))
	_preview_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_preview_desc)

	# Separador
	var sep_m := Panel.new()
	sep_m.custom_minimum_size = Vector2(0, 1)
	sep_m.add_theme_stylebox_override("panel", _sb(Color(0.30, 0.22, 0.08, 0.5), Color(0,0,0,0), 0, 0))
	vbox.add_child(sep_m)

	# Melhorias: [ícone chave] + [texto]
	var hbox_upg := HBoxContainer.new()
	hbox_upg.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox_upg)

	var upg_icon := TextureRect.new()
	upg_icon.texture = ICON_CHAVE
	upg_icon.custom_minimum_size = Vector2(22, 22)
	upg_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	upg_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	upg_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	upg_icon.modulate = Color(0.60, 0.78, 0.48)
	hbox_upg.add_child(upg_icon)

	_preview_upgrade = Label.new()
	_preview_upgrade.text = ""
	_preview_upgrade.add_theme_font_size_override("font_size", 17)
	_preview_upgrade.add_theme_color_override("font_color", Color(0.60, 0.78, 0.48))
	_preview_upgrade.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_upg.add_child(_preview_upgrade)

	# Custo: [ícone moedas] + [texto]
	var hbox_custo := HBoxContainer.new()
	hbox_custo.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_custo.add_theme_constant_override("separation", 7)
	vbox.add_child(hbox_custo)

	_preview_custo_icon = TextureRect.new()
	_preview_custo_icon.texture = ICON_MOEDAS
	_preview_custo_icon.custom_minimum_size = Vector2(26, 26)
	_preview_custo_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_preview_custo_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_custo_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_custo.add_child(_preview_custo_icon)

	_preview_custo = Label.new()
	_preview_custo.text = ""
	_preview_custo.add_theme_font_size_override("font_size", 22)
	_preview_custo.add_theme_color_override("font_color", Color(1.0, 0.82, 0.20))
	_preview_custo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_custo.add_child(_preview_custo)

	# Espaço flexível
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Botão Construir
	_btn_confirmar = Button.new()
	_btn_confirmar.text = "CONSTRUIR"
	_btn_confirmar.add_theme_font_size_override("font_size", 28 if OS.has_feature("mobile") else 24)
	_btn_confirmar.add_theme_color_override("font_color", Color(0.08, 0.05, 0.02))
	_btn_confirmar.custom_minimum_size = Vector2(0, 88 if OS.has_feature("mobile") else 72)
	_btn_confirmar.focus_mode = Control.FOCUS_NONE
	_btn_confirmar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_confirmar.disabled = true
	_btn_confirmar.add_theme_stylebox_override("normal",   _sb(Color(0.68, 0.52, 0.08),      Color(0,0,0,0), 0, 8))
	_btn_confirmar.add_theme_stylebox_override("hover",    _sb(Color(0.88, 0.68, 0.12),      Color(0,0,0,0), 0, 8))
	_btn_confirmar.add_theme_stylebox_override("pressed",  _sb(Color(0.50, 0.38, 0.06),      Color(0,0,0,0), 0, 8))
	_btn_confirmar.add_theme_stylebox_override("disabled", _sb(Color(0.28, 0.22, 0.07, 0.5), Color(0,0,0,0), 0, 8))
	_btn_confirmar.add_theme_color_override("font_disabled_color", Color(0.45, 0.38, 0.20, 0.5))
	_btn_confirmar.pressed.connect(_ao_confirmar)
	vbox.add_child(_btn_confirmar)

# ==========================================
# LÓGICA DE ABERTURA E FECHAMENTO
# ==========================================
func abrir_menu(slot: Node) -> void:
	_slot_alvo = slot
	_limpar_botoes()
	_botao_selecionado = null
	_cena_selecionada = null
	_custo_selecionado = 0

	var todas := GameManager.get_todas_construcoes_da_fase()
	if todas.is_empty():
		show()
		return

	for dados in todas:
		_criar_botao_grade(dados)

	_preview_vazio()
	modulate.a = 0.0
	show()
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	call_deferred("atualizar_destaque_recomendado")

func fechar_menu() -> void:
	hide()
	_limpar_botoes()
	_slot_alvo = null
	_cena_selecionada = null
	_botao_selecionado = null

# ==========================================
# CRIAÇÃO DOS BOTÕES NA GRADE
# ==========================================
# ==========================================
# CRIAÇÃO DOS BOTÕES NA GRADE
# ==========================================
func _criar_botao_grade(dados: Dictionary) -> void:
	var cena_torre: PackedScene = dados.cena
	var bloqueado: bool         = dados.get("bloqueado", false)
	var nivel_necessario: int   = dados.get("nivel_necessario", 0)

	var temp := cena_torre.instantiate()

	# Extrai o identificador base da torre pelo nome do arquivo (ex: "torre_padrao.tscn" -> "torre_padrao")
	var id_torre: String = cena_torre.resource_path.get_file().get_basename().to_lower()
	
	@warning_ignore("unused_variable")
	var chave_custo: String = id_torre + "_custo"

	temp.process_mode = Node.PROCESS_MODE_DISABLED
	temp.visible = false
	add_child(temp)

	if temp.has_method("_resolver_icone_construcao"):
		temp._resolver_icone_construcao()
		
	var nome: String      = GameManager.nome_para_cena(cena_torre)
	var icone: Texture2D  = temp.get("icone") if "icone" in temp else null
	
	# Resolução em cascata do custo para garantir funcionamento no mobile
	var custo: int = 0
	if dados.has("custo"):
		custo = int(dados.get("custo"))
	elif temp.get("custo_moedas") != null and int(temp.get("custo_moedas")) > 0:
		custo = int(temp.get("custo_moedas"))
	# Caso tenha um Singleton de balanceamento, a integração direta seria aqui:
	# elif GameManager.balanceamento.has(chave_custo):
	# 	custo = int(GameManager.balanceamento[chave_custo])
		
	var descricao: String = str(temp.get("descricao")) if "descricao" in temp else ""
	
	remove_child(temp)
	temp.queue_free()

	## Fallback: Compatibilidade para resolução de ícones em ambientes emulados e exportados
	var caminho_cena: String = cena_torre.resource_path.replace(".remap", "")
	if icone == null:
		icone = _icone_por_path_cena(caminho_cena)

	var custo_final: int = GameManager.obter_custo_com_desconto(custo)

	# Cor do tipo
	var cor := _tipo_cor(nome)
	var bg_n  := Color(0.15, 0.11, 0.07, 0.95).lerp(cor, 0.07)
	var bg_h  := Color(0.22, 0.17, 0.10, 0.95).lerp(cor, 0.12)
	var bg_p  := Color(0.13, 0.10, 0.06, 0.97).lerp(cor, 0.10)
	var brd_n := Color(cor.r, cor.g, cor.b, 0.50)
	var brd_h := Color(cor.r, cor.g, cor.b, 0.85)
	var brd_p := Color(cor.r, cor.g, cor.b, 1.00)

	# Botão de seleção da construção
	var btn := Button.new()
	btn.toggle_mode = true
	btn.text = ""
	btn.custom_minimum_size = Vector2(210, 220) if OS.has_feature("mobile") else Vector2(168, 220)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal",  _sb(bg_n, brd_n, 2, 10))
	btn.add_theme_stylebox_override("hover",   _sb(bg_h, brd_h, 2, 10))
	btn.add_theme_stylebox_override("pressed", _sb(bg_p, brd_p, 3, 10))

	# Conteúdo: ícone + nome + [moedas icon + custo]
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 4)
	btn.add_child(inner)

	var ic := TextureRect.new()
	ic.texture = icone
	var ic_sz := 130 if OS.has_feature("mobile") else 130
	ic.custom_minimum_size = Vector2(ic_sz, ic_sz)
	ic.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(ic)

	var nome_lbl := Label.new()
	nome_lbl.text = nome
	nome_lbl.add_theme_font_size_override("font_size", 22 if OS.has_feature("mobile") else 20)
	nome_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nome_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(nome_lbl)

	# Custo: [ícone Moedas] + [número]
	var hcusto := HBoxContainer.new()
	hcusto.alignment = BoxContainer.ALIGNMENT_CENTER
	hcusto.add_theme_constant_override("separation", 4)
	hcusto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(hcusto)

	var ic_moeda := TextureRect.new()
	ic_moeda.texture = ICON_MOEDAS
	ic_moeda.custom_minimum_size = Vector2(23, 23)
	ic_moeda.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ic_moeda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_moeda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic_moeda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hcusto.add_child(ic_moeda)

	var custo_lbl := Label.new()
	custo_lbl.add_theme_font_size_override("font_size", 19)
	custo_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# PRIMEIRA_GRATIS: enquanto a próxima construção for de graça, mostra "Grátis"
	if GameManager.construcao_gratis_disponivel:
		ic_moeda.visible = false
		custo_lbl.text = "Grátis"
		custo_lbl.add_theme_color_override("font_color", Color(0.45, 0.92, 0.40))
	else:
		custo_lbl.text = str(custo_final)
		custo_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.18))
	hcusto.add_child(custo_lbl)

	btn.set_meta("nome_torre",  nome)
	btn.set_meta("cena_torre",  cena_torre)
	btn.set_meta("custo_torre", custo)
	btn.set_meta("icone_torre", icone if icone else null) # Modificado pois tinha warning, antes era: icone if icone != null else "")
	btn.set_meta("descricao",   descricao)
	btn.set_meta("nivel_necessario", nivel_necessario)

	if bloqueado:
		btn.disabled = true
		btn.modulate = Color(0.45, 0.45, 0.45, 0.9)
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		# Overlay com border-radius igual ao botão
		var ov := Panel.new()
		ov.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.58), Color(0,0,0,0), 0, 10))
		ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ov)
		# Ícone de cadeado centralizado
		var lock_ic := TextureRect.new()
		lock_ic.texture = ICON_CADEADO
		lock_ic.custom_minimum_size = Vector2(36, 36)
		lock_ic.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_ic.anchor_left   = 0.5; lock_ic.anchor_right  = 0.5
		lock_ic.anchor_top    = 0.5; lock_ic.anchor_bottom = 0.5
		lock_ic.offset_left   = -18; lock_ic.offset_right  = 18
		lock_ic.offset_top    = -26; lock_ic.offset_bottom = 10
		lock_ic.modulate = Color(0.85, 0.75, 0.55, 1.0)
		lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_ic)
		# Nível necessário abaixo do ícone
		var lock_lbl := Label.new()
		lock_lbl.text = "Nv. %d" % nivel_necessario
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		lock_lbl.add_theme_font_size_override("font_size", 15)
		lock_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_lbl)

	btn.pressed.connect(_ao_clicar_botao.bind(btn))
	_botoes_ativos.append(btn)
	_grid.add_child(btn)

# ==========================================
# INTERAÇÃO
# ==========================================
func _ao_clicar_botao(btn: Button) -> void:
	if not is_instance_valid(btn): return
	if GameManager.is_tutorial_ativo:
		_solicitar_construcao(btn.get_meta("cena_torre") as PackedScene, int(btn.get_meta("custo_torre")))
		return
	if _botao_selecionado == btn:
		_ao_confirmar()
		return
	_selecionar_botao(btn)

func _selecionar_botao(btn: Button) -> void:
	if is_instance_valid(_botao_selecionado) and _botao_selecionado != btn:
		_botao_selecionado.button_pressed = false
	_botao_selecionado = btn
	btn.button_pressed = true
	_cena_selecionada  = btn.get_meta("cena_torre") as PackedScene
	_custo_selecionado = int(btn.get_meta("custo_torre"))
	var icone_val = btn.get_meta("icone_torre")
	_atualizar_preview(
		icone_val if icone_val is Texture2D else null,
		str(btn.get_meta("nome_torre")),
		_custo_selecionado,
		str(btn.get_meta("descricao"))
	)
	_btn_confirmar.disabled = false

func _ao_confirmar() -> void:
	if _cena_selecionada == null: return
	_solicitar_construcao(_cena_selecionada, _custo_selecionado)

# ==========================================
# PREVIEW (painel direito)
# ==========================================
func _preview_vazio() -> void:
	_preview_icone.texture = null
	_preview_icone.modulate = Color(0.25, 0.25, 0.25, 0.4)
	_preview_nome.text = "—"
	_preview_nome.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_preview_tipo_icone.texture = null
	_preview_tipo.text = ""
	_preview_desc.text = "← Escolha uma\nconstrução"
	_preview_upgrade.text = ""
	_preview_custo.text = ""
	_btn_confirmar.disabled = true

func _atualizar_preview(icone: Texture2D, nome: String, custo: int, descricao: String) -> void:
	_preview_icone.texture = icone
	_preview_icone.modulate = Color(1,1,1,1) if icone != null else Color(0.3,0.3,0.3,0.5)

	var cor := _tipo_cor(nome)
	_preview_nome.text = nome
	_preview_nome.add_theme_color_override("font_color", Color(1,1,1,1).lerp(cor, 0.35))

	# Badge de tipo com ícone real
	_preview_tipo_icone.texture = _tipo_icon(nome)
	_preview_tipo_icone.modulate = cor
	_preview_tipo.text = _tipo_nome(nome)
	_preview_tipo.add_theme_color_override("font_color", cor)

	_preview_desc.text = descricao if descricao != "" else _descricao_fallback(nome)
	_preview_upgrade.text = _upgrade_fallback(nome)

	var custo_final := GameManager.obter_custo_com_desconto(custo)
	# PRIMEIRA_GRATIS: a primeira construção da onda sai de graça
	if GameManager.construcao_gratis_disponivel:
		if _preview_custo_icon: _preview_custo_icon.visible = false
		_preview_custo.text = "Grátis!"
		_preview_custo.add_theme_color_override("font_color", Color(0.45, 0.92, 0.40))
	else:
		if _preview_custo_icon: _preview_custo_icon.visible = true
		_preview_custo.text = "%d moedas" % custo_final
		_preview_custo.add_theme_color_override("font_color", Color(1.0, 0.82, 0.20))

# ==========================================
# CONSTRUÇÃO
# ==========================================
func _solicitar_construcao(cena_torre: PackedScene, _custo: int) -> void:
	if _slot_alvo and _slot_alvo.has_method("construir"):
		if _slot_alvo.construir(cena_torre):
			SFXManager.tocar_construcao()
			fechar_menu()
		else:
			_preview_custo.text = "Moedas insuficientes!"
			_preview_custo.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
			SFXManager.tocar_erro_compra()
			var tw := create_tween()
			tw.tween_interval(1.8)
			tw.tween_callback(func():
				if is_instance_valid(_preview_custo) and _cena_selecionada != null:
					_preview_custo.text = "%d moedas" % GameManager.obter_custo_com_desconto(_custo_selecionado)
					_preview_custo.add_theme_color_override("font_color", Color(1.0, 0.82, 0.20))
			)

func _limpar_botoes() -> void:
	_tweens_destaque.clear()
	for botao in _botoes_ativos:
		if is_instance_valid(botao): botao.queue_free()
	_botoes_ativos.clear()

# ==========================================
# DESTAQUE DE RECOMENDAÇÃO
# ==========================================
func atualizar_destaque_recomendado() -> void:
	var rec: String = GameManager.recomendacao_conselheiro
	for btn in _botoes_ativos:
		if not is_instance_valid(btn): continue
		var nome_b: String = btn.get_meta("nome_torre") if btn.has_meta("nome_torre") else ""
		if rec != "" and nome_b == rec: _iniciar_destaque(btn)
		else: _parar_destaque(btn)

func _iniciar_destaque(btn: Button) -> void:
	if _tweens_destaque.has(btn) and is_instance_valid(_tweens_destaque[btn]): return
	var tw := btn.create_tween().set_loops()
	tw.tween_property(btn, "modulate", Color(1.5, 1.3, 0.2, 1.0), 0.4)
	tw.tween_property(btn, "modulate", Color(1.1, 1.0, 0.6, 1.0), 0.4)
	_tweens_destaque[btn] = tw

func _parar_destaque(btn: Button) -> void:
	if _tweens_destaque.has(btn):
		var tw = _tweens_destaque[btn]
		if is_instance_valid(tw): tw.kill()
		_tweens_destaque.erase(btn)
	btn.create_tween().tween_property(btn, "modulate", Color(1,1,1,1), 0.2)

# Legacy no-op
func atualizar_informacoes(_nome: String, _custo: int) -> void: pass
func atualizar_info_bloqueado(_nome: String, _nivel: int) -> void: pass
func limpar_informacoes() -> void: pass

# ==========================================
# TIPO DE CONSTRUÇÃO
# ==========================================
func _eh_economia(n: String) -> bool:
	return "fazenda" in n or "mina" in n or "mercado" in n or "ouro" in n \
		or "celeiro" in n or "casa" in n or "moinho" in n or "aldeia" in n or "vila" in n

func _eh_defensivo(n: String) -> bool:
	return "muro" in n or "parede" in n or "barricada" in n \
		or "quartel" in n or "escudo" in n

func _tipo_cor(nome: String) -> Color:
	var n := nome.to_lower()
	if _eh_economia(n):  return Color(0.92, 0.72, 0.08)  # dourado
	if _eh_defensivo(n): return Color(0.24, 0.52, 0.92)  # azul
	return Color(0.90, 0.26, 0.16)                        # vermelho

func _tipo_icon(nome: String) -> Texture2D:
	var n := nome.to_lower()
	if _eh_economia(n):  return ICON_MOEDAS
	if _eh_defensivo(n): return ICON_ESCUDO
	return ICON_ESPADA

func _tipo_nome(nome: String) -> String:
	var n := nome.to_lower()
	if _eh_economia(n):  return "Economia"
	if _eh_defensivo(n): return "Defensiva"
	return "Ofensiva"

# ==========================================
# TEXTOS DE DESCRIÇÃO E MELHORIA
# ==========================================
func _descricao_fallback(nome: String) -> String:
	var n := nome.to_lower()
	if "arqueiro" in n or "torre" in n: return "Protege a área atirando flechas nos inimigos."
	if "muro" in n or "parede" in n:   return "Bloqueia e atrasa os inimigos no caminho."
	if "quartel" in n:                  return "Treina soldados que patrulham e combatem."
	if "caldeirão" in n or "caldeirao" in n: return "Arremessa projéteis que causam dano em área."
	if "fazenda" in n or "mina" in n:  return "Gera ouro extra automaticamente a cada onda."
	if "casa" in n:                     return "Gera ouro passivo para a sua aldeia."
	if "moinho" in n:                   return "Processa recursos e gera renda extra."
	return "Construção defensiva que ajuda na defesa."

func _upgrade_fallback(nome: String) -> String:
	var n := nome.to_lower()
	if "arqueiro" in n or "torre" in n: return "Melhoria: atira mais rápido e mais longe."
	if "muro" in n or "parede" in n:   return "Melhoria: aguenta mais antes de quebrar."
	if "quartel" in n:                  return "Melhoria: soldados mais fortes e em maior número."
	if "caldeirão" in n or "caldeirao" in n: return "Melhoria: explosões maiores e mais dano."
	if "fazenda" in n or "mina" in n:  return "Melhoria: produz ainda mais ouro por onda."
	if "casa" in n:                     return "Melhoria: aumenta a renda gerada por onda."
	if "moinho" in n:                   return "Melhoria: processa mais recursos por onda."
	return "Pode ser melhorada após ser construída."

# ==========================================
# HELPER STYLEBOX
# ==========================================
func _sb(bg: Color, borda: Color, esp: int, raio: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	if esp > 0:
		st.border_color = borda
		st.set_border_width_all(esp)
	st.corner_radius_top_left     = raio
	st.corner_radius_top_right    = raio
	st.corner_radius_bottom_left  = raio
	st.corner_radius_bottom_right = raio
	return st

# ==========================================
# CLIQUE FORA DO PAINEL
# ==========================================
func _input(event: InputEvent) -> void:
	if not visible: return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(_slot_alvo) and _slot_alvo.has_method("fechar_ui"):
				_slot_alvo.call_deferred("fechar_ui")
				get_viewport().set_input_as_handled()
			return

	if GameManager.is_tutorial_ativo:
		var tut = get_tree().get_first_node_in_group("TutorialManager")
		if tut and tut.visible and tut.alvo_2d_atual != null:
			return

	var clicou := false
	var pos_clique := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicou = true; pos_clique = event.position
	elif event is InputEventScreenTouch and event.pressed:
		clicou = true; pos_clique = event.position

	if clicou and is_instance_valid(_painel):
		if not _painel.get_global_rect().has_point(pos_clique):
			if is_instance_valid(_slot_alvo) and _slot_alvo.has_method("fechar_ui"):
				_slot_alvo.call_deferred("fechar_ui")
				get_viewport().set_input_as_handled()

# ==========================================
# ÍCONE FALLBACK POR CAMINHO DO TSCN
# ==========================================
const _ICON_CONSTRUCAO_TORRE    = preload("res://Assets/Construcoes/ConstrucaoTorre.png")
const _ICON_CONSTRUCAO_MOINHO   = preload("res://Assets/Construcoes/ConstrucaoMoinho.png")
const _ICON_CONSTRUCAO_CASA     = preload("res://Assets/Construcoes/ConstrucaoCasa.png")
const _ICON_CONSTRUCAO_MINA     = preload("res://Assets/Construcoes/ConstrucaoMina.png")
const _ICON_CONSTRUCAO_QUARTEL  = preload("res://Assets/Construcoes/ConstrucaoQuartel.png")
const _ICON_CONSTRUCAO_BRUXA    = preload("res://Assets/Construcoes/ConstrucaoBruxa.png")
const _ICON_CONSTRUCAO_PIRATA   = preload("res://Assets/Construcoes/ConstrucaoPirata.png")
const _ICON_CONSTRUCAO_DESERTO  = preload("res://Assets/Construcoes/ConstrucaoDeserto.png")
const _ICON_CONSTRUCAO_SCIFI    = preload("res://Assets/Construcoes/ConstrucaoScifi.png")
const _ICON_CONSTRUCAO_COVIL    = preload("res://Assets/Construcoes/ConstrucaoCovil.png")

func _icone_por_path_cena(path: String) -> Texture2D:
	if "tower" in path:      return _ICON_CONSTRUCAO_TORRE
	if "mill" in path:       return _ICON_CONSTRUCAO_MOINHO
	if "house" in path or "casebre" in path or "casa" in path: return _ICON_CONSTRUCAO_CASA
	if "mina" in path:       return _ICON_CONSTRUCAO_MINA
	if "quartel" in path:    return _ICON_CONSTRUCAO_QUARTEL
	if "caldeiron" in path:  return _ICON_CONSTRUCAO_BRUXA
	if "pirata" in path:     return _ICON_CONSTRUCAO_PIRATA
	if "egipcio" in path or "deserto" in path: return _ICON_CONSTRUCAO_DESERTO
	if "tesla" in path or "scifi" in path:     return _ICON_CONSTRUCAO_SCIFI
	if "fogo" in path or "covil" in path:      return _ICON_CONSTRUCAO_COVIL
	return _ICON_CONSTRUCAO_TORRE  # genérico
