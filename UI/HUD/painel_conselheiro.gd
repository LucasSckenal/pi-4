extends Control
class_name PainelConselheiro

const TEX_AJUDA    = preload("res://Assets/UI/Ajuda.png")
const ICON_BRILHO  = preload("res://Assets/Icons/Brilho.png")

# ==========================================
# CORES POR PRIORIDADE
# ==========================================
const COR_URGENTE = Color(0.90, 0.18, 0.18)
const COR_ALTA    = Color(0.90, 0.52, 0.10)
const COR_MEDIA   = Color(0.20, 0.72, 0.38)
const COR_BAIXA   = Color(0.38, 0.62, 0.95)
const COR_NENHUMA = Color(0.50, 0.45, 0.75)

# ==========================================
# ESTADO
# ==========================================
var _conselheiro: ConselheiroIA
var _rec_atual            = null
var _aberto: bool         = false
var _slot_destacado: Node = null
var _tween_pulso: Tween   = null

# ==========================================
# NÓS DA UI
# ==========================================
var _btn_toggle:    Button
var _dialogo:       Control
var _painel:        PanelContainer
var _rtl:           RichTextLabel
var _style_btn:     StyleBoxFlat
var _style_painel:  StyleBoxFlat

# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_conselheiro = ConselheiroIA.new()
	_conselheiro.name = "ConselheiroLogica"
	add_child(_conselheiro)

	_criar_ui()

	GameManager.dia_iniciado.connect(func(_n):  call_deferred("_verificar_urgencia"))
	GameManager.onda_terminada.connect(func():  call_deferred("_verificar_urgencia"))
	GameManager.noite_iniciada.connect(func(_n): _ao_iniciar_noite())
	GameManager.upgrade_aplicado.connect(func(): call_deferred("_verificar_urgencia"))

# ==========================================
# CRIAÇÃO DA UI
# ==========================================
func _criar_ui():
	# ── Botão de Ajuda (Tamanho Médio/Equilibrado) ────────────────────────────
	_btn_toggle = Button.new()
	_btn_toggle.text = ""
	_btn_toggle.icon = TEX_AJUDA
	_btn_toggle.expand_icon = true
	
	# Tamanho intermediário: 260x114 (Redução de ~25% do original)
	_btn_toggle.custom_minimum_size = Vector2(260, 114) 
	
	_btn_toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_toggle.anchor_left   = 0.0
	_btn_toggle.anchor_right  = 0.0
	_btn_toggle.anchor_top    = 1.0
	_btn_toggle.anchor_bottom = 1.0
	
	# Posicionamento com margem leve
	_btn_toggle.offset_left   = 10
	_btn_toggle.offset_right  = 270 # offset_left + largura
	_btn_toggle.offset_top    = -126 # -(altura + 12px de margem)
	_btn_toggle.offset_bottom = -12

	_style_btn = StyleBoxFlat.new()
	_style_btn.bg_color = Color(1, 1, 1, 0)
	_style_btn.border_color = COR_NENHUMA
	_style_btn.set_border_width_all(0)
	_style_btn.content_margin_left = 0
	_style_btn.content_margin_top = 0
	_style_btn.content_margin_right = 0
	_style_btn.content_margin_bottom = 0

	var style_hover := _style_btn.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(1, 1, 1, 0)

	_btn_toggle.add_theme_stylebox_override("normal",  _style_btn)
	_btn_toggle.add_theme_stylebox_override("hover",   style_hover)
	_btn_toggle.add_theme_stylebox_override("pressed", _style_btn)
	_btn_toggle.add_theme_color_override("font_color", Color.WHITE)
	_btn_toggle.add_theme_font_size_override("font_size", 20)

	# ── Label AJUDA ────────────────
	var label_ajuda := Label.new()
	label_ajuda.text = "AJUDA"
	label_ajuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_ajuda.anchor_left = 0.0
	label_ajuda.anchor_top = 0.0
	label_ajuda.anchor_right = 1.0
	label_ajuda.anchor_bottom = 1.0
	
	# Ajuste do texto para o centro da área de escrita da placa
	label_ajuda.offset_left = 100.0   
	label_ajuda.offset_top = 0
	label_ajuda.offset_right = -15.0
	label_ajuda.offset_bottom = -5.0
	
	label_ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_ajuda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Fonte em 30px (Equilíbrio entre o 40 original e o 22 pequeno)
	label_ajuda.add_theme_font_size_override("font_size", 30) 
	label_ajuda.add_theme_color_override("font_color", Color.WHITE)
	label_ajuda.add_theme_color_override("font_outline_color", Color.BLACK)
	label_ajuda.add_theme_constant_override("outline_size", 5)
	_btn_toggle.add_child(label_ajuda)

	add_child(_btn_toggle)
	_btn_toggle.pressed.connect(_toggle)

	# Configura a animação de hover no botão de ajuda
	_btn_toggle.pivot_offset = _btn_toggle.custom_minimum_size / 2.0
	_btn_toggle.mouse_entered.connect(func():
		var tween := create_tween()
		tween.tween_property(_btn_toggle, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	)
	_btn_toggle.mouse_exited.connect(func():
		var tween := create_tween()
		tween.tween_property(_btn_toggle, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	)

	# ── Container do diálogo (aparece na parte inferior da tela) ──────────
	_dialogo = Control.new()
	_dialogo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogo.visible = false
	add_child(_dialogo)

	# Painel estilo tutorial
	_painel = PanelContainer.new()
	_painel.anchor_left   = 0.0
	_painel.anchor_right  = 1.0
	_painel.anchor_top    = 1.0
	_painel.anchor_bottom = 1.0
	_painel.offset_left   = 18
	_painel.offset_right  = -18
	_painel.offset_top    = -360
	_painel.offset_bottom = -108   # acima do botão toggle
	_painel.mouse_filter  = Control.MOUSE_FILTER_STOP

	_style_painel = StyleBoxFlat.new()
	_style_painel.bg_color = Color(0.13, 0.13, 0.15, 0.97)
	_style_painel.border_color = COR_NENHUMA
	_style_painel.set_border_width_all(3)
	_style_painel.corner_radius_top_left    = 15
	_style_painel.corner_radius_top_right   = 15
	_style_painel.corner_radius_bottom_left = 15
	_style_painel.corner_radius_bottom_right = 15
	_style_painel.content_margin_left   = 16
	_style_painel.content_margin_right  = 16
	_style_painel.content_margin_top    = 14
	_style_painel.content_margin_bottom = 14
	_painel.add_theme_stylebox_override("panel", _style_painel)
	_dialogo.add_child(_painel)

	# VBox raiz do painel
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_painel.add_child(vbox)

	# ── Cabeçalho: nome + botão fechar ───────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var brilho_ic := TextureRect.new()
	brilho_ic.texture = ICON_BRILHO
	brilho_ic.custom_minimum_size = Vector2(22, 22)
	brilho_ic.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	brilho_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brilho_ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brilho_ic.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(brilho_ic)

	var label_nome := Label.new()
	label_nome.text = "Berta"
	label_nome.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label_nome.add_theme_font_size_override("font_size", 22)
	label_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label_nome)

	var btn_fechar := Button.new()
	btn_fechar.text = "✕"
	btn_fechar.custom_minimum_size = Vector2(40, 40)
	btn_fechar.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_fechar.add_theme_font_size_override("font_size", 20)
	btn_fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var st_fechar := StyleBoxFlat.new()
	st_fechar.bg_color = Color(0.22, 0.10, 0.10, 0.90)
	st_fechar.border_color = Color(0.65, 0.28, 0.28)
	st_fechar.set_border_width_all(2)
	st_fechar.corner_radius_top_left    = 8
	st_fechar.corner_radius_top_right   = 8
	st_fechar.corner_radius_bottom_left = 8
	st_fechar.corner_radius_bottom_right = 8
	btn_fechar.add_theme_stylebox_override("normal", st_fechar)
	btn_fechar.add_theme_stylebox_override("hover",  st_fechar)
	btn_fechar.add_theme_color_override("font_color", Color(0.95, 0.65, 0.65))
	btn_fechar.pressed.connect(_fechar)
	header.add_child(btn_fechar)

	# ── Corpo: [texto | retrato] ─────────────────────────────────────────────
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	# Texto da fala (RichTextLabel — mesma configuração do tutorial)
	_rtl = RichTextLabel.new()
	_rtl.bbcode_enabled  = true
	_rtl.scroll_active   = false
	_rtl.fit_content     = true
	_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rtl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_rtl.add_theme_font_size_override("font_size",        28)
	_rtl.add_theme_font_size_override("normal_font_size", 28)
	_rtl.add_theme_font_size_override("bold_font_size",   28)
	_rtl.add_theme_color_override("default_color",      Color.WHITE)
	_rtl.add_theme_constant_override("outline_size",    6)
	_rtl.add_theme_color_override("font_outline_color", Color.BLACK)
	_rtl.add_theme_constant_override("line_separation", 6)
	_rtl.text = ""
	hbox.add_child(_rtl)

	# Retrato Berta — SubViewportContainer 3D (igual ao tutorial)
	var retrato_container := SubViewportContainer.new()
	retrato_container.custom_minimum_size = Vector2(150, 150)
	retrato_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(retrato_container)

	var sub_vp := SubViewport.new()
	sub_vp.own_world_3d = true
	sub_vp.transparent_bg = true
	sub_vp.handle_input_locally = false
	sub_vp.size = Vector2i(150, 150)
	sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	retrato_container.add_child(sub_vp)

	var luz := DirectionalLight3D.new()
	luz.transform = Transform3D(Basis(), Vector3(0, 0.36, 0.94))
	sub_vp.add_child(luz)

	var berta_inst = load("res://Personagens/character-female-c.glb").instantiate()
	berta_inst.transform = Transform3D(Basis(), Vector3(0, 0, -0.41))
	sub_vp.add_child(berta_inst)
	call_deferred("_iniciar_animacao_berta", berta_inst)

	var camera := Camera3D.new()
	camera.transform = Transform3D(Basis(), Vector3(0, 0.476, 0))
	sub_vp.add_child(camera)

# ==========================================
# FECHAR AO CLICAR FORA
# ==========================================
func _input(event: InputEvent) -> void:
	if not _aberto or not _dialogo.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _painel != null and not _painel.get_global_rect().has_point(event.position):
			_fechar()

# ==========================================
# TOGGLE ABRIR / FECHAR
# ==========================================
func _toggle():
	if _aberto:
		_fechar()
	else:
		_abrir()

func _abrir():
	if not is_instance_valid(_conselheiro) or not _conselheiro.is_inside_tree():
		return

	_rec_atual = _conselheiro.analisar()
	_aberto = true

	# Expõe o nome recomendado ao menu radial para destaque
	GameManager.recomendacao_conselheiro = _rec_atual.nome_construcao

	# Se o menu radial já está aberto, atualiza o destaque imediatamente
	get_tree().call_group("RadialMenu", "atualizar_destaque_recomendado")

	# Atualiza visual do botão e painel com a cor da prioridade
	_aplicar_cor_prioridade(_rec_atual.prioridade)

	# Monta o texto BBCode estilo tutorial
	_rtl.text = _montar_bbcode(_rec_atual)
	_rtl.visible_ratio = 0.0

	# Aparece com fade
	_dialogo.modulate.a = 0.0
	_dialogo.visible = true
	var tw := create_tween()
	tw.tween_property(_dialogo, "modulate:a", 1.0, 0.18)

	# Animação de texto (igual ao tutorial — revela caractere a caractere)
	var duracao: float = clamp(float(_rtl.get_total_character_count()) * 0.028, 0.5, 4.0)
	var tw2 := create_tween()
	tw2.tween_property(_rtl, "visible_ratio", 1.0, duracao)

	# Destaca o slot recomendado automaticamente (sem clique extra)
	_aplicar_destaque(_rec_atual)

func _fechar():
	_aberto = false
	var tw := create_tween()
	tw.tween_property(_dialogo, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): _dialogo.visible = false)
	_limpar_destaque()

# ==========================================
# VISUAL — COR DA PRIORIDADE
# ==========================================
func _aplicar_cor_prioridade(prio: int):
	var cor := _cor_prio(prio)
	_style_painel.border_color = cor
	_style_btn.border_color    = cor

	if prio <= ConselheiroIA.PRIO_ALTA:
		_btn_toggle.text = ""
		_btn_toggle.add_theme_color_override("font_color", cor)
		_iniciar_pulso(cor)
	else:
		_btn_toggle.text = ""
		_btn_toggle.add_theme_color_override("font_color", Color.WHITE)
		_parar_pulso()

func _cor_prio(p: int) -> Color:
	if p == ConselheiroIA.PRIO_URGENTE: return COR_URGENTE
	if p == ConselheiroIA.PRIO_ALTA:    return COR_ALTA
	if p == ConselheiroIA.PRIO_MEDIA:   return COR_MEDIA
	if p == ConselheiroIA.PRIO_BAIXA:   return COR_BAIXA
	return COR_NENHUMA

# ==========================================
# PULSO DE URGÊNCIA NO BOTÃO
# ==========================================
func _iniciar_pulso(cor: Color):
	_parar_pulso()
	_tween_pulso = create_tween().set_loops()
	_tween_pulso.tween_property(_style_btn, "border_color", cor, 0.4)
	_tween_pulso.tween_property(_style_btn, "border_color", COR_NENHUMA, 0.4)

func _parar_pulso():
	if _tween_pulso != null and is_instance_valid(_tween_pulso):
		_tween_pulso.kill()
	_tween_pulso = null

# ==========================================
# TEXTO BBCODE (estilo diálogo de personagem)
# ==========================================
func _montar_bbcode(rec) -> String:
	const _COR_NOME  = "#FFD700"   # amarelo — nome da Berta
	const COR_TORRE = "#FFD700"   # dourado — torres
	const COR_ECO   = "#88FF88"   # verde   — construções econômicas
	const COR_UPG   = "#88DDFF"   # azul    — upgrades

	# Cor da construção recomendada
	var cor_const := COR_TORRE
	if rec.tipo == ConselheiroIA.TIPO_UPGRADE:
		cor_const = COR_UPG
	elif rec.nome_construcao in ["Casa", "Mina", "Moinho"]:
		cor_const = COR_ECO

	# Colore o nome da construção no texto de explicação
	var corpo: String = rec.explicacao
	if rec.nome_construcao != "":
		corpo = corpo.replace(
			rec.nome_construcao,
			"[color=%s][b]%s[/b][/color]" % [cor_const, rec.nome_construcao]
		)

	return corpo

# ==========================================
# DESTAQUE DE SLOT
# ==========================================
func _aplicar_destaque(rec):
	_limpar_destaque()
	if rec == null or rec.slot_recomendado == null:
		return
	var slot = rec.slot_recomendado
	if is_instance_valid(slot) and slot.has_method("destacar"):
		slot.destacar()
		_slot_destacado = slot

func _limpar_destaque():
	if _slot_destacado != null and is_instance_valid(_slot_destacado):
		if _slot_destacado.has_method("parar_destaque"):
			_slot_destacado.parar_destaque()
	_slot_destacado = null

# ==========================================
# CICLO DIA / NOITE
# ==========================================
func _verificar_urgencia():
	if not is_instance_valid(_conselheiro) or not _conselheiro.is_inside_tree():
		return
	var rec = _conselheiro.analisar()
	_style_btn.border_color = _cor_prio(rec.prioridade)
	if rec.prioridade <= ConselheiroIA.PRIO_ALTA:
		_btn_toggle.text = ""
		_btn_toggle.add_theme_color_override("font_color", _cor_prio(rec.prioridade))
		_iniciar_pulso(_cor_prio(rec.prioridade))
	else:
		_btn_toggle.text = ""
		_btn_toggle.add_theme_color_override("font_color", Color.WHITE)
		_parar_pulso()

func _ao_iniciar_noite():
	if _aberto:
		_fechar()
	GameManager.recomendacao_conselheiro = ""
	_parar_pulso()
	_style_btn.border_color = COR_NENHUMA
	_btn_toggle.text = ""
	_btn_toggle.add_theme_color_override("font_color", Color.WHITE)

# ==========================================
# ANIMAÇÃO DA BERTA NO RETRATO
# ==========================================
func _iniciar_animacao_berta(berta_inst: Node):
	var anim = berta_inst.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation("idle"):
		anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		anim.play("idle")
