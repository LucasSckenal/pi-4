extends CanvasLayer

## Sistema de cutscene em estilo HQ.
## Preencha imagens[], titulos[], textos[], audios[] e caminho_proxima_fase no Inspetor.

@export var imagens: Array[Texture2D] = []
@export var titulos: PackedStringArray = []
@export var textos: PackedStringArray = []
@export var audios: Array[AudioStream] = []
@export var caminho_proxima_fase: String = ""
@export var numero_fase: int = 0

const COR_FUNDO := Color(0.05, 0.03, 0.02, 1.0)
const COR_PAINEL_BG := Color(0.09, 0.06, 0.03, 0.97)
const COR_BORDA := Color(0.60, 0.44, 0.16, 1.0)
const COR_TITULO := Color(0.96, 0.82, 0.42, 1.0)
const COR_TEXTO := Color(0.84, 0.72, 0.50, 1.0)
const COR_HINT := Color(1.0, 0.88, 0.28, 1.0)
const COR_PULAR := Color(0.70, 0.56, 0.24, 1.0)

const MARGEM_TELA := 34.0
const MARGEM_TOPO := 78.0
const ESPACO_ENTRE_PAINEIS := 14.0
const ALTURA_HINT := 72.0
const ALTURA_CABECALHO := 46.0
const ASPECTO_PADRAO_IMAGEM := 16.0 / 9.0
const TEMPO_REORGANIZAR := 0.28
const TEMPO_ENTRADA := 0.38

var _indice: int = -1
var _animando: bool = false
var _finalizando: bool = false
var _paineis: Array[Control] = []

var _raiz: Control = null
var _hint: Label = null
var _hint_tween: Tween = null
var _audio: AudioStreamPlayer = null


func _ready() -> void:
	# Fallback: cenas de cutscene que esqueceram de definir numero_fase no Inspetor
	# (fases 2-6) herdam a fase actual — evita travar sem transição no fim.
	if numero_fase <= 0:
		numero_fase = GameManager.fase_atual
	if numero_fase > 0:
		Global.registrar_cutscene_vista(numero_fase)
		if caminho_proxima_fase == "":
			caminho_proxima_fase = GameManager.caminhos_das_fases.get(numero_fase, "")
	_construir_ui()
	await get_tree().process_frame
	_avancar()


func _construir_ui() -> void:
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	var btn := Button.new()
	btn.text = "PULAR  >"
	btn.custom_minimum_size = Vector2(200, 70)
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -300.0
	btn.offset_right = -10.0
	btn.offset_top = 12.0
	btn.offset_bottom = 56.0
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var st_btn := StyleBoxFlat.new()
	st_btn.bg_color = Color(0.12, 0.08, 0.03, 0.90)
	st_btn.border_color = COR_BORDA
	st_btn.set_border_width_all(2)
	st_btn.set_corner_radius_all(8)
	st_btn.content_margin_left = 12.0
	st_btn.content_margin_right = 12.0
	btn.add_theme_stylebox_override("normal", st_btn)
	btn.add_theme_stylebox_override("hover", st_btn)
	btn.add_theme_stylebox_override("pressed", st_btn)
	btn.add_theme_color_override("font_color", COR_PULAR)
	btn.add_theme_font_size_override("font_size", 32)
	btn.pressed.connect(_pular_cutscene)
	add_child(btn)

	_hint = Label.new()
	_hint.text = "Toque para revelar o proximo quadro  >"
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", COR_HINT)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.anchor_left = 0.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top = -48.0
	_hint.offset_bottom = -8.0
	_hint.modulate.a = 0.0
	add_child(_hint)

	_audio = AudioStreamPlayer.new()
	add_child(_audio)


func _avancar() -> void:
	if _animando:
		return

	_indice += 1
	if _indice >= imagens.size():
		_ir_para_fase(false)
		return

	_revelar_painel(_indice)


func _revelar_painel(idx: int) -> void:
	_animando = true
	_parar_hint()

	if _audio.playing:
		_audio.stop()

	var novo := _criar_quadro(idx)
	_raiz.add_child(novo)
	_paineis.append(novo)

	await get_tree().process_frame

	var layout := _calcular_layout(_paineis.size())
	var destino: Dictionary = layout[idx]
	var destino_pos: Vector2 = destino["position"]
	var destino_size: Vector2 = destino["size"]
	novo.pivot_offset = destino_size * 0.5
	novo.position = destino_pos + Vector2(0, 24)
	novo.size = destino_size
	novo.custom_minimum_size = destino_size
	novo.scale = Vector2(0.88, 0.88)
	novo.modulate.a = 0.0

	await _animar_layout(layout, novo)

	if idx < audios.size() and audios[idx] != null:
		_audio.stream = audios[idx]
		_audio.play()

	if idx == imagens.size() - 1:
		_hint.text = "Iniciar fase  >"
	else:
		_hint.text = "Toque para revelar o proximo quadro  >"

	_animando = false
	_animar_hint()


func _animar_layout(layout: Array[Dictionary], novo: Control) -> void:
	var tw := create_tween().set_parallel(true)

	for i in range(_paineis.size()):
		var painel := _paineis[i]
		var alvo: Dictionary = layout[i]
		var alvo_pos: Vector2 = alvo["position"]
		var alvo_size: Vector2 = alvo["size"]
		painel.pivot_offset = alvo_size * 0.5
		tw.tween_property(painel, "position", alvo_pos, TEMPO_REORGANIZAR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(painel, "size", alvo_size, TEMPO_REORGANIZAR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(painel, "custom_minimum_size", alvo_size, TEMPO_REORGANIZAR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var novo_destino: Dictionary = layout[_paineis.size() - 1]
	tw.tween_property(novo, "position", novo_destino["position"], TEMPO_ENTRADA).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(novo, "scale", Vector2.ONE, TEMPO_ENTRADA).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(novo, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _calcular_layout(qtd: int) -> Array[Dictionary]:
	var vp_size := get_viewport().get_visible_rect().size
	var area_pos := Vector2(MARGEM_TELA, MARGEM_TOPO)
	var area_size := Vector2(
		maxf(280.0, vp_size.x - MARGEM_TELA * 2.0),
		maxf(240.0, vp_size.y - MARGEM_TOPO - ALTURA_HINT)
	)
	var imagem_aspecto := _obter_aspecto_imagem()

	if qtd == 1:
		var tamanho_unico := _encaixar_tamanho(area_size, _obter_aspecto_painel(imagem_aspecto, area_size))
		return [{
			"position": area_pos + (area_size - tamanho_unico) * 0.5,
			"size": tamanho_unico,
		}]

	var colunas := ceili(sqrt(float(qtd)))
	var linhas := ceili(float(qtd) / float(colunas))
	if vp_size.x < 760.0:
		colunas = min(colunas, 2)
		linhas = ceili(float(qtd) / float(colunas))

	var celula_size := Vector2(
		floorf((area_size.x - ESPACO_ENTRE_PAINEIS * float(colunas - 1)) / float(colunas)),
		floorf((area_size.y - ESPACO_ENTRE_PAINEIS * float(linhas - 1)) / float(linhas))
	)
	var tamanhos_linha: Array[Vector2] = []
	var alturas_linha: Array[float] = []
	var altura_total := ESPACO_ENTRE_PAINEIS * float(linhas - 1)
	for linha in range(linhas):
		var inicio_medida := linha * colunas
		var qtd_linha_medida := mini(colunas, qtd - inicio_medida)
		var largura_linha := floorf((area_size.x - ESPACO_ENTRE_PAINEIS * float(qtd_linha_medida - 1)) / float(qtd_linha_medida))
		var limite_linha := Vector2(largura_linha, celula_size.y)
		var aspecto_linha := _obter_aspecto_painel(imagem_aspecto, limite_linha)
		var tamanho_linha := _encaixar_tamanho(limite_linha, aspecto_linha)
		tamanhos_linha.append(tamanho_linha)
		alturas_linha.append(tamanho_linha.y)
		altura_total += tamanho_linha.y

	var y := area_pos.y + (area_size.y - altura_total) * 0.5

	var layout: Array[Dictionary] = []
	for linha in range(linhas):
		var inicio_layout := linha * colunas
		var qtd_linha_layout := mini(colunas, qtd - inicio_layout)
		var tamanho_linha := tamanhos_linha[linha]
		var largura_total_linha := tamanho_linha.x * float(qtd_linha_layout) + ESPACO_ENTRE_PAINEIS * float(qtd_linha_layout - 1)
		var x := area_pos.x + (area_size.x - largura_total_linha) * 0.5
		for coluna in range(qtd_linha_layout):
			layout.append({
				"position": Vector2(x + float(coluna) * (tamanho_linha.x + ESPACO_ENTRE_PAINEIS), y),
				"size": tamanho_linha,
			})
		y += alturas_linha[linha] + ESPACO_ENTRE_PAINEIS
	return layout


func _obter_aspecto_imagem() -> float:
	for textura in imagens:
		if textura == null:
			continue
		var tamanho := textura.get_size()
		if tamanho.x > 0.0 and tamanho.y > 0.0:
			return tamanho.x / tamanho.y
	return ASPECTO_PADRAO_IMAGEM


func _obter_aspecto_painel(imagem_aspecto: float, limite: Vector2) -> float:
	return imagem_aspecto / maxf(0.35, 1.0 + ALTURA_CABECALHO / maxf(160.0, limite.y - ALTURA_CABECALHO))


func _encaixar_tamanho(limite: Vector2, aspecto: float) -> Vector2:
	var largura := limite.x
	var altura := largura / aspecto
	if altura > limite.y:
		altura = limite.y
		largura = altura * aspecto
	return Vector2(floorf(largura), floorf(altura))


func _criar_quadro(idx: int) -> PanelContainer:
	var painel := PanelContainer.new()
	painel.clip_contents = false
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.set_border_width_all(0)
	st.set_corner_radius_all(0)
	st.content_margin_left = 0.0
	st.content_margin_right = 0.0
	st.content_margin_top = 0.0
	st.content_margin_bottom = 0.0
	st.shadow_size = 0
	painel.add_theme_stylebox_override("panel", st)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(vbox)

	if idx < titulos.size() and titulos[idx] != "":
		var tit := Label.new()
		tit.text = titulos[idx].to_upper()
		tit.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tit.add_theme_font_size_override("font_size", 18)
		tit.add_theme_color_override("font_color", COR_TITULO)
		tit.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		tit.add_theme_constant_override("outline_size", 2)
		tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(tit)

	if idx < imagens.size() and imagens[idx] != null:
		var img := TextureRect.new()
		img.texture = imagens[idx]
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.size_flags_vertical = Control.SIZE_EXPAND_FILL
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(img)

	if idx < textos.size() and textos[idx] != "":
		var txt := Label.new()
		txt.text = textos[idx]
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.add_theme_font_size_override("font_size", 14)
		txt.add_theme_color_override("font_color", COR_TEXTO)
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(txt)

	return painel


func _animar_hint() -> void:
	_parar_hint()
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_property(_hint, "modulate:a", 0.35, 0.55).set_trans(Tween.TRANS_SINE)


func _parar_hint() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint.modulate.a = 0.0


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


func _pular_cutscene() -> void:
	_ir_para_fase(true)


func _ir_para_fase(forcar: bool = false) -> void:
	if _finalizando:
		return
	if _animando and not forcar:
		return
	_finalizando = true
	_animando = true

	_parar_hint()

	if _audio.playing:
		_audio.stop()

	if caminho_proxima_fase == "":
		push_error("[CutsceneDinamica] caminho_proxima_fase nao preenchido no Inspetor!")
		_animando = false
		return

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	add_child(overlay)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	await tw.finished

	get_tree().change_scene_to_file(caminho_proxima_fase)
