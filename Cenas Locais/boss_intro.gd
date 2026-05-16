extends CanvasLayer

## Cutscene de introdução de boss.
## Chamada por inimigo_base.gd via reproduzir_stream().
## Toda a UI é criada dinamicamente — a cena .tscn só precisa do VideoStreamPlayer.

signal cutscene_finished

# ──────────────────────────────────────────────────
# ESTADO
# ──────────────────────────────────────────────────
var _ja_finalizou := false
var _pode_pular   := false
var _glow_tween:  Tween = null
var _hint_tween:  Tween = null

# ── Nó de vídeo (existe no .tscn) ─────────────────
@onready var _video: VideoStreamPlayer = $VideoStreamPlayer

# ── UI criada dinamicamente ────────────────────────
var _fundo_solido:   ColorRect = null   # fallback quando não há vídeo
var _overlay:        Control   = null
var _vinheta:        ColorRect = null
var _nome_lbl:       Label     = null
var _sub_lbl:        Label     = null
var _linha_sup_e:    ColorRect = null   # metade esquerda da linha superior
var _linha_sup_d:    ColorRect = null   # metade direita
var _linha_inf_e:    ColorRect = null
var _linha_inf_d:    ColorRect = null
var _hint:           Label     = null
var _audio:          AudioStreamPlayer = null

# ──────────────────────────────────────────────────
# INICIALIZAÇÃO
# ──────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200   # acima de tudo


## Ponto de entrada principal.
## stream  — vídeo a reproduzir (pode ser null)
## nome    — nome do boss (obrigatório)
## sub     — subtítulo opcional  (ex: "O Destruidor das Planícies")
## sting   — áudio dramático opcional
func reproduzir_stream(
		stream: VideoStream,
		nome:   String,
		sub:    String         = "",
		sting:  AudioStream    = null) -> void:

	# ── Vídeo ─────────────────────────────────────
	if stream and _video:
		_video.stream        = stream
		_video.expand        = true
		_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_video.play()
		if not _video.finished.is_connected(_finalizar):
			_video.finished.connect(_finalizar)
	else:
		# Sem vídeo → fundo escuro dramático
		_fundo_solido = ColorRect.new()
		_fundo_solido.color = Color(0.04, 0.02, 0.01, 1.0)
		_fundo_solido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_fundo_solido)
		move_child(_fundo_solido, 0)

	get_tree().paused = true

	# ── Constrói UI e inicia sequência ────────────
	_construir_overlay(nome, sub, sting)
	_iniciar_sequencia.call_deferred()


# ──────────────────────────────────────────────────
# CONSTRUÇÃO DA UI
# ──────────────────────────────────────────────────
func _construir_overlay(nome: String, sub: String, sting: AudioStream) -> void:
	# Container raiz da UI (sobre o vídeo)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a   = 0.0
	add_child(_overlay)

	# Vinheta escura nas 4 bordas (gradiente simulado com opacidade)
	_vinheta = ColorRect.new()
	_vinheta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vinheta.color        = Color(0.0, 0.0, 0.0, 0.52)
	_vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_vinheta)

	# ── Área central do reveal ─────────────────────
	# Posicionada no terço inferior (estilo Elden Ring: nome ~65-75% da tela)
	var area := Control.new()
	area.set_anchor(SIDE_LEFT,   0.05)
	area.set_anchor(SIDE_RIGHT,  0.95)
	area.set_anchor(SIDE_TOP,    0.62)
	area.set_anchor(SIDE_BOTTOM, 0.88)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(area)

	# ── Linhas douradas (sup e inf) — duas metades cada ──
	_linha_sup_e = _nova_linha_metade(area, true)
	_linha_sup_d = _nova_linha_metade(area, false)
	# Posição: topo da área
	for l in [_linha_sup_e, _linha_sup_d]:
		l.set_anchor(SIDE_TOP,    0.0)
		l.set_anchor(SIDE_BOTTOM, 0.0)
		l.offset_bottom = 2.0

	_linha_inf_e = _nova_linha_metade(area, true)
	_linha_inf_d = _nova_linha_metade(area, false)
	# Posição: rodapé da área
	for l in [_linha_inf_e, _linha_inf_d]:
		l.set_anchor(SIDE_TOP,    1.0)
		l.set_anchor(SIDE_BOTTOM, 1.0)
		l.offset_top    = -2.0
		l.offset_bottom =  0.0

	# ── Nome do boss ──────────────────────────────
	_nome_lbl = Label.new()
	_nome_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_nome_lbl.text                 = nome.to_upper()
	_nome_lbl.add_theme_font_size_override("font_size", 54)
	_nome_lbl.add_theme_color_override("font_color",         Color(0.96, 0.88, 0.58, 1.0))
	_nome_lbl.add_theme_color_override("font_outline_color", Color(0.0,  0.0,  0.0,  1.0))
	_nome_lbl.add_theme_constant_override("outline_size",    7)
	_nome_lbl.modulate.a = 0.0
	_nome_lbl.scale      = Vector2(1.15, 1.15)
	area.add_child(_nome_lbl)

	# ── Subtítulo (linha abaixo do nome) ──────────
	if sub != "":
		_sub_lbl = Label.new()
		_sub_lbl.set_anchor(SIDE_LEFT,   0.0)
		_sub_lbl.set_anchor(SIDE_RIGHT,  1.0)
		_sub_lbl.set_anchor(SIDE_TOP,    1.0)
		_sub_lbl.set_anchor(SIDE_BOTTOM, 1.0)
		_sub_lbl.offset_top    = 10.0
		_sub_lbl.offset_bottom = 44.0
		_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_sub_lbl.text = sub
		_sub_lbl.add_theme_font_size_override("font_size", 22)
		_sub_lbl.add_theme_color_override("font_color",         Color(0.78, 0.64, 0.38, 1.0))
		_sub_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
		_sub_lbl.add_theme_constant_override("outline_size",    3)
		_sub_lbl.modulate.a = 0.0
		area.add_child(_sub_lbl)

	# ── Dica de interação ─────────────────────────
	_hint = Label.new()
	_hint.set_anchor(SIDE_LEFT,   0.0)
	_hint.set_anchor(SIDE_RIGHT,  1.0)
	_hint.set_anchor(SIDE_TOP,    1.0)
	_hint.set_anchor(SIDE_BOTTOM, 1.0)
	_hint.offset_top    = -50.0
	_hint.offset_bottom = -10.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.text = "Toque para continuar  ▶"
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color",         Color(0.90, 0.80, 0.48, 0.90))
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size",    3)
	_hint.modulate.a = 0.0
	_overlay.add_child(_hint)

	# ── Áudio ─────────────────────────────────────
	_audio = AudioStreamPlayer.new()
	if sting:
		_audio.stream = sting
	add_child(_audio)


## Cria metade de uma linha dourada (esquerda ou direita do centro).
## esquerda=true → ancora do centro para a esquerda.
func _nova_linha_metade(parent: Control, esquerda: bool) -> ColorRect:
	var c := ColorRect.new()
	c.color        = Color(0.90, 0.74, 0.28, 0.92)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.offset_bottom = 2.0
	if esquerda:
		c.set_anchor(SIDE_LEFT,  0.0)
		c.set_anchor(SIDE_RIGHT, 0.5)
	else:
		c.set_anchor(SIDE_LEFT,  0.5)
		c.set_anchor(SIDE_RIGHT, 1.0)
	# Começa com largura zero — escala a partir da borda central
	c.scale.x = 0.0
	# Pivot na borda central (direita para a esq, esquerda para a dir)
	c.pivot_offset = Vector2(c.size.x if esquerda else 0.0, 0.5)
	parent.add_child(c)
	return c


# ──────────────────────────────────────────────────
# SEQUÊNCIA DE ANIMAÇÃO
# ──────────────────────────────────────────────────
func _iniciar_sequencia() -> void:
	# Aguarda o layout calcular os tamanhos reais dos nós ancorados
	await get_tree().process_frame
	await get_tree().process_frame

	# Corrige pivot das linhas (precisa do size calculado)
	_linha_sup_e.pivot_offset = Vector2(_linha_sup_e.size.x, 1.0)
	_linha_sup_d.pivot_offset = Vector2(0.0,                 1.0)
	_linha_inf_e.pivot_offset = Vector2(_linha_inf_e.size.x, 0.0)
	_linha_inf_d.pivot_offset = Vector2(0.0,                 0.0)

	# Corrige pivot do nome (centro)
	_nome_lbl.pivot_offset = _nome_lbl.size * 0.5

	# 1. Fade in do overlay (vinheta aparece sobre o vídeo)
	_overlay.modulate.a = 0.0
	var tw_fade := create_tween()
	tw_fade.tween_property(_overlay, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	await tw_fade.finished

	await get_tree().create_timer(0.35).timeout

	# 2. Sting de áudio
	if _audio and _audio.stream:
		_audio.play()

	# 3. Reveal coordenado: linhas sweeping + nome
	var tw := create_tween().set_parallel(true)

	# Linhas expandem do centro para fora
	tw.tween_property(_linha_sup_e, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(_linha_sup_d, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(_linha_inf_e, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(_linha_inf_d, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# Nome: fade in + zoom leve
	tw.tween_property(_nome_lbl, "modulate:a", 1.0,          0.40).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_nome_lbl, "scale",      Vector2.ONE,  0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tw.finished

	# 4. Subtítulo aparece logo depois
	if _sub_lbl:
		var tw_sub := create_tween()
		tw_sub.tween_property(_sub_lbl, "modulate:a", 1.0, 0.50).set_trans(Tween.TRANS_SINE)

	# 5. Glow pulsante suave no nome
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_nome_lbl, "modulate:v", 1.12, 1.5).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_nome_lbl, "modulate:v", 1.00, 1.5).set_trans(Tween.TRANS_SINE)

	await get_tree().create_timer(1.0).timeout

	# 6. Libera skip + hint pulsante
	_pode_pular = true

	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_hint, "modulate:a", 0.95, 0.55).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_property(_hint, "modulate:a", 0.28, 0.55).set_trans(Tween.TRANS_SINE)


# ──────────────────────────────────────────────────
# FALLBACK — detecta fim do vídeo pelo _process
# ──────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if not _ja_finalizou and _video and _video.stream and not _video.is_playing():
		_finalizar()


# ──────────────────────────────────────────────────
# INPUT
# ──────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not _pode_pular:
		return
	var clicou := false
	if event is InputEventMouseButton:
		clicou = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		clicou = event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]
	elif event is InputEventScreenTouch:
		clicou = event.pressed
	if clicou:
		_finalizar()


# ──────────────────────────────────────────────────
# FINALIZAÇÃO
# ──────────────────────────────────────────────────
func _finalizar() -> void:
	if _ja_finalizou:
		return
	_ja_finalizou = true

	# Para tweens em loop
	if _glow_tween  and _glow_tween.is_valid():  _glow_tween.kill()
	if _hint_tween  and _hint_tween.is_valid():  _hint_tween.kill()
	if _audio       and _audio.playing:          _audio.stop()

	# Fade out
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.50).set_trans(Tween.TRANS_SINE)
	if _fundo_solido:
		tw.tween_property(_fundo_solido, "modulate:a", 0.0, 0.50).set_trans(Tween.TRANS_SINE)
	if _video and _video.stream:
		tw.tween_property(_video, "modulate:a", 0.0, 0.50).set_trans(Tween.TRANS_SINE)
	await tw.finished

	get_tree().paused = false
	cutscene_finished.emit()
	queue_free()
