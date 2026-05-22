extends CanvasLayer

## Sistema de cutscene por quadros — preencha os arrays no Inspetor da cena de cada fase.
##
## Uso:
##   1. Crie uma cena filha de CutsceneAnimada para cada fase.
##   2. Preencha imagens[], titulos[], textos[], audios[] e caminho_proxima_fase.
##   3. Coloque a cena antes da cena da fase (ou use-a como tela de carregamento).

# ──────────────────────────────────────────────────
# DADOS DOS PAINÉIS  (preencha no Inspetor)
# ──────────────────────────────────────────────────
@export var imagens:  Array[Texture2D]   = []   ## Ilustração de cada quadro (obrigatório)
@export var titulos:  PackedStringArray  = []   ## Título de cada quadro  (ex: "A CHEGADA")
@export var textos:   PackedStringArray  = []   ## Texto descritivo de cada quadro
@export var audios:   Array[AudioStream] = []   ## Dublagem de cada quadro (opcional)

@export var caminho_proxima_fase: String = ""   ## Cena a carregar após o último quadro

# ──────────────────────────────────────────────────
# ESTILO (constantes de cor)
# ──────────────────────────────────────────────────
const COR_FUNDO     := Color(0.05, 0.03, 0.02, 1.0)
const COR_PAINEL_BG := Color(0.09, 0.06, 0.03, 0.97)
const COR_BORDA     := Color(0.60, 0.44, 0.16, 1.0)
const COR_TITULO    := Color(0.96, 0.82, 0.42, 1.0)
const COR_TEXTO     := Color(0.84, 0.72, 0.50, 1.0)
const COR_HINT      := Color(1.0,  0.88, 0.28, 1.0)
const COR_PULAR     := Color(0.70, 0.56, 0.24, 1.0)

# ──────────────────────────────────────────────────
# ESTADO INTERNO
# ──────────────────────────────────────────────────
var _indice:      int   = -1
var _animando:    bool  = false

var _raiz:        Control           = null   # container full-screen
var _quadro:      Control           = null   # painel atual
var _hint:        Label             = null
var _hint_tween:  Tween             = null
var _audio:       AudioStreamPlayer = null

# ──────────────────────────────────────────────────
# INICIALIZAÇÃO
# ──────────────────────────────────────────────────
func _ready() -> void:
	_construir_ui()
	await get_tree().process_frame
	_avancar()


func _construir_ui() -> void:
	# Fundo escuro que cobre tudo
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	# Container raiz (ocupa a tela toda, recebe o quadro actual)
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	# Botão PULAR — canto superior direito
	var btn := Button.new()
	btn.text = "PULAR  >"
	btn.custom_minimum_size = Vector2(130, 44)
	btn.anchor_left   = 1.0
	btn.anchor_right  = 1.0
	btn.anchor_top    = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left   = -145.0
	btn.offset_right  = -10.0
	btn.offset_top    = 12.0
	btn.offset_bottom = 56.0
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var st_btn := StyleBoxFlat.new()
	st_btn.bg_color = Color(0.12, 0.08, 0.03, 0.90)
	st_btn.border_color = COR_BORDA
	st_btn.set_border_width_all(2)
	st_btn.set_corner_radius_all(8)
	st_btn.content_margin_left  = 12.0
	st_btn.content_margin_right = 12.0
	btn.add_theme_stylebox_override("normal",  st_btn)
	btn.add_theme_stylebox_override("hover",   st_btn)
	btn.add_theme_stylebox_override("pressed", st_btn)
	btn.add_theme_color_override("font_color", COR_PULAR)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_ir_para_fase)
	add_child(btn)

	# Dica de interação — rodapé centrado
	_hint = Label.new()
	_hint.text = "Toque para continuar  ▶"
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", COR_HINT)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.anchor_left   = 0.0
	_hint.anchor_right  = 1.0
	_hint.anchor_top    = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top    = -48.0
	_hint.offset_bottom = -8.0
	_hint.modulate.a    = 0.0
	add_child(_hint)

	# AudioStreamPlayer para dublagem
	_audio = AudioStreamPlayer.new()
	add_child(_audio)


# ──────────────────────────────────────────────────
# LÓGICA DE NAVEGAÇÃO
# ──────────────────────────────────────────────────
func _avancar() -> void:
	if _animando:
		return
	_indice += 1
	if _indice >= imagens.size():
		_ir_para_fase()
		return
	_mostrar_painel(_indice)


func _mostrar_painel(idx: int) -> void:
	_animando = true

	# Para o pulso anterior do hint
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint.modulate.a = 0.0

	# Para áudio anterior
	if _audio.playing:
		_audio.stop()

	# Remove quadro anterior com fade-out rápido
	if _quadro and is_instance_valid(_quadro):
		var old := _quadro
		_quadro = null
		var tw_out := create_tween()
		tw_out.tween_property(old, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
		tw_out.tween_callback(old.queue_free)

	# Cria novo quadro (começa fora da tela pela direita)
	var novo := _criar_quadro(idx)
	_raiz.add_child(novo)
	_quadro = novo

	# Aguarda um frame para o layout calcular o tamanho
	await get_tree().process_frame

	var vp_size := get_viewport().get_visible_rect().size
	var largura := novo.size.x if novo.size.x > 0 else vp_size.x * 0.84
	var altura  := novo.size.y if novo.size.y > 0 else vp_size.y * 0.80

	# Posição centrada na tela
	var pos_x_alvo := (vp_size.x - largura) * 0.5
	var pos_y_alvo := (vp_size.y - altura)  * 0.5

	novo.modulate.a = 0.0
	novo.position   = Vector2(vp_size.x, pos_y_alvo)   # começa à direita

	# Anima entrada: slide da direita + fade
	var tw := create_tween().set_parallel(true)
	tw.tween_property(novo, "position:x", pos_x_alvo, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(novo, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	await tw.finished

	# Toca áudio de dublagem, se houver
	if idx < audios.size() and audios[idx] != null:
		_audio.stream = audios[idx]
		_audio.play()

	# Atualiza hint para o último quadro
	if idx == imagens.size() - 1:
		_hint.text = "Iniciar fase  ▶"
	else:
		_hint.text = "Toque para continuar  ▶"

	_animando = false
	_animar_hint()


func _criar_quadro(idx: int) -> Control:
	var vp_size := get_viewport().get_visible_rect().size
	var largura := minf(vp_size.x * 0.84, 740.0)
	var altura  := minf(vp_size.y * 0.82, 580.0)

	# PanelContainer principal
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(largura, altura)

	var st := StyleBoxFlat.new()
	st.bg_color = COR_PAINEL_BG
	st.set_border_width_all(3)
	st.border_color = COR_BORDA
	st.set_corner_radius_all(14)
	st.content_margin_left   = 20.0
	st.content_margin_right  = 20.0
	st.content_margin_top    = 16.0
	st.content_margin_bottom = 16.0
	# Sombra suave
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size  = 8
	painel.add_theme_stylebox_override("panel", st)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	painel.add_child(vbox)

	# ── CABEÇALHO (número + título) ──────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	# Número do quadro
	var num_str: String = str(idx + 1)
	var num_lbl := Label.new()
	num_lbl.text = num_str
	num_lbl.add_theme_font_size_override("font_size", 26)
	num_lbl.add_theme_color_override("font_color", COR_TITULO)
	num_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	num_lbl.add_theme_constant_override("outline_size", 3)
	header.add_child(num_lbl)

	# Título
	if idx < titulos.size() and titulos[idx] != "":
		var tit := Label.new()
		tit.text = titulos[idx].to_upper()
		tit.add_theme_font_size_override("font_size", 22)
		tit.add_theme_color_override("font_color", COR_TITULO)
		tit.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		tit.add_theme_constant_override("outline_size", 2)
		tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(tit)

	# Separador dourado
	var sep := HSeparator.new()
	var sep_st := StyleBoxFlat.new()
	sep_st.bg_color = COR_BORDA
	sep_st.content_margin_top    = 1.0
	sep_st.content_margin_bottom = 1.0
	sep.add_theme_stylebox_override("separator", sep_st)
	vbox.add_child(sep)

	# ── IMAGEM ───────────────────────────────────────
	if idx < imagens.size() and imagens[idx] != null:
		var img := TextureRect.new()
		img.texture           = imagens[idx]
		img.expand_mode       = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img.stretch_mode      = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(img)

	# ── TEXTO DESCRITIVO ─────────────────────────────
	if idx < textos.size() and textos[idx] != "":
		var txt := Label.new()
		txt.text         = textos[idx]
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.add_theme_font_size_override("font_size", 16)
		txt.add_theme_color_override("font_color", COR_TEXTO)
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(txt)

	return painel


func _animar_hint() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_property(_hint, "modulate:a", 0.35, 0.55).set_trans(Tween.TRANS_SINE)


# ──────────────────────────────────────────────────
# INPUT
# ──────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _animando:
		return
	var clicou := false
	if event is InputEventMouseButton:
		clicou = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		clicou = event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	elif event is InputEventScreenTouch:
		clicou = event.pressed
	if clicou:
		_avancar()


# ──────────────────────────────────────────────────
# TRANSIÇÃO PARA A FASE
# ──────────────────────────────────────────────────
func _ir_para_fase() -> void:
	if _animando:
		return
	_animando = true

	if _audio.playing:
		_audio.stop()

	if caminho_proxima_fase == "":
		push_error("[CutsceneDinamica] caminho_proxima_fase não preenchido no Inspetor!")
		return

	# Fade para preto antes de mudar de cena
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	add_child(overlay)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	await tw.finished

	get_tree().change_scene_to_file(caminho_proxima_fase)
