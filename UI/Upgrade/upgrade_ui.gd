extends Control

signal fechado

@export var cena_opcao_button: PackedScene

# ==========================================
# REFERÊNCIAS
# ==========================================
@onready var fundo_escuro     = $FundoEscuro
@onready var painel_principal = $PainelPrincipal
@onready var titulo_header    = $PainelPrincipal/VBoxContainer/HeaderBand/HeaderVBox/TituloHeader
@onready var titulo           = $PainelPrincipal/VBoxContainer/HeaderBand/HeaderVBox/Titulo
@onready var status_container = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/StatusContainer
@onready var opcoes_container = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/OpcoesContainer
@onready var conteudo_vbox    = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox
@onready var botao_vender     = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/BotoesRow/BotaoVender
@onready var botao_fechar     = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/BotoesRow/BotaoFechar
@onready var instrucao_label  = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/Instrucao
@onready var spacer_b         = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/SpacerB
@onready var spacer_c         = $PainelPrincipal/VBoxContainer/ConteudoMargin/ConteudoVBox/SpacerC

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var construcao_atual: Node = null
var _sec_desbloqueios: Control = null

func _ready():
	hide()
	fundo_escuro.modulate.a = 0
	painel_principal.scale = Vector2.ZERO

	# Encapsula em CanvasLayer de nível máximo para sobreposição absoluta.
	var canvas_topo = CanvasLayer.new()
	canvas_topo.layer = 120
	get_tree().root.call_deferred("add_child", canvas_topo)
	call_deferred("reparent", canvas_topo)

	botao_fechar.pressed.connect(fechar)
	botao_fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if botao_vender:
		botao_vender.pressed.connect(_on_botao_vender_pressed)
		botao_vender.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_cena_opcao_button(cena: PackedScene):
	if cena != null:
		cena_opcao_button = cena

# ==========================================
# LÓGICA DE ABERTURA E POPULAÇÃO
# ==========================================
func abrir(construcao: Node):
	if GameManager.is_night == true:
		return

	construcao_atual = construcao
	show()
	painel_principal.scale = Vector2.ONE

	# Título do header: "MELHORAR TORRE" etc.
	var tipo_val = construcao_atual.get("tipo") if "tipo" in construcao_atual else -1
	titulo_header.text = "MELHORAR " + _get_nome_tipo(tipo_val)

	titulo.hide()

	# Botão vender: oculto na BASE
	if construcao_atual.get("tipo") == 5:
		botao_vender.hide()
	else:
		botao_vender.show()
		var valor = 0
		if "custo_moedas" in construcao_atual:
			valor = int(float(construcao_atual.custo_moedas) / 2.0)
		botao_vender.text = "💰 VENDER (+" + str(valor) + ")"

	atualizar_status_atuais()
	atualizar_opcoes()

	painel_principal.reset_size()
	# Centraliza após o layout calcular o tamanho real do conteúdo.
	call_deferred("_centralizar_painel_deferred")

	painel_principal.scale = Vector2(0.5, 0.5)
	fundo_escuro.modulate.a = 0

	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 1.0, 0.2)
	tw.tween_property(painel_principal, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

func _get_nome_tipo(tipo: int) -> String:
	match tipo:
		0: return "TORRE"
		1: return "MINA"
		2: return "CASA"
		3: return "MOINHO"
		4: return "QUARTEL"
		5: return "BASE"
		6: return "CALDEIRÃO"
		_: return "CONSTRUÇÃO"

# Exibe os atributos atuais como pills com ícone + nome (sem valores numéricos).
func atualizar_status_atuais():
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()

	var atributos = []

	var tipo_check = construcao_atual.get("tipo") if "tipo" in construcao_atual else -1
	if "vida_maxima" in construcao_atual and tipo_check != 5:
		atributos.append({"icone": "❤️", "nome": "Vida"})

	if "tipo" in construcao_atual:
		var tipo = construcao_atual.tipo
		if tipo == 0:
			atributos.append({"icone": "⚔️", "nome": "Dano"})
			atributos.append({"icone": "⚡", "nome": "Velocidade"})
			atributos.append({"icone": "🎯", "nome": "Alcance"})
		elif tipo == 1 or tipo == 2 or tipo == 3:
			atributos.append({"icone": "💰", "nome": "Ouro/Onda"})
		elif tipo == 4:
			atributos.append({"icone": "🛡️", "nome": "Soldados"})
		elif tipo == 5:
			pass
		elif tipo == 6:
			atributos.append({"icone": "☠️", "nome": "Veneno"})

	for attr in atributos:
		var pill = _criar_pill(attr["icone"] + "  " + attr["nome"])
		status_container.add_child(pill)

	status_container.visible = atributos.size() > 0

func _criar_pill(texto: String) -> PanelContainer:
	var pill = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color    = Color(0.17, 0.19, 0.27, 1)
	style.border_color = Color(0.28, 0.30, 0.44, 1)
	style.border_width_left   = 1
	style.border_width_top    = 1
	style.border_width_right  = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left  = 6
	style.content_margin_left   = 10
	style.content_margin_right  = 10
	style.content_margin_top    = 4
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)

	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.72, 0.76, 0.90, 1))
	pill.add_child(lbl)
	return pill

func atualizar_opcoes():
	for child in opcoes_container.get_children():
		opcoes_container.remove_child(child)
		child.queue_free()

	# Remove seção de desbloqueios anterior (free() imediato evita duplicata)
	if is_instance_valid(_sec_desbloqueios):
		_sec_desbloqueios.free()
	_sec_desbloqueios = null

	if not construcao_atual.has_method("get_opcoes_proximo_upgrade"):
		return

	var opcoes = construcao_atual.get_opcoes_proximo_upgrade()

	if opcoes.size() == 0:
		instrucao_label.hide()
		painel_principal.custom_minimum_size.x = 360
		var label_max = Label.new()
		label_max.text = "🌟 NÍVEL MÁXIMO ALCANÇADO 🌟"
		label_max.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_max.add_theme_color_override("font_color", Color(0.78, 0.52, 0.08, 1))
		label_max.add_theme_font_size_override("font_size", 24)
		opcoes_container.add_child(label_max)
		return

	# Ajusta largura do painel e label de instrução conforme o nº de opções
	# A altura é determinada pelo conteúdo (y = 0) para não ocupar toda a tela
	var n_opcoes = opcoes.size()

	if n_opcoes == 1:
		painel_principal.custom_minimum_size = Vector2(340, 0)
		instrucao_label.hide()
		spacer_b.show()
		spacer_c.hide()
	elif n_opcoes == 2:
		painel_principal.custom_minimum_size = Vector2(560, 0)
		instrucao_label.text = "Escolha um caminho:"
		instrucao_label.show()
		spacer_b.show()
		spacer_c.show()
	else:
		painel_principal.custom_minimum_size = Vector2(720, 0)
		instrucao_label.text = "Escolha uma melhoria:"
		instrucao_label.show()
		spacer_b.show()
		spacer_c.show()

	# Seção de desbloqueios (estilo CoC)
	for opcao in opcoes:
		var desbs: Array = opcao.get("desbloqueios", [])
		if desbs.size() > 0:
			_criar_secao_desbloqueios(desbs)
			break

	for opcao in opcoes:
		if cena_opcao_button:
			var btn = cena_opcao_button.instantiate()
			btn.name = "Upgrade"
			btn.custom_minimum_size = Vector2(230, 245)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
			opcoes_container.add_child(btn)

			if btn.has_method("configurar"):
				btn.configurar(opcao)

			if opcao.get("bloqueado", false):
				if btn.has_method("bloquear"):
					btn.bloquear(opcao.get("motivo_bloqueio", ""))
			else:
				btn.pressed.connect(_on_opcao_escolhida.bind(opcao.get("index", 0)))

				# Feedback visual de moedas insuficientes
				var custo_opcao: int = opcao.get("custo", 0)
				if GameManager.moedas < custo_opcao:
					btn.modulate = Color(0.55, 0.55, 0.55, 0.85)
					btn.tooltip_text = "Moedas insuficientes (%d/%d)" % [GameManager.moedas, custo_opcao]

# ==========================================
# AÇÕES DO JOGADOR
# ==========================================
func _on_opcao_escolhida(index: int):
	if construcao_atual and construcao_atual.has_method("aplicar_upgrade"):
		var sucesso = construcao_atual.aplicar_upgrade(index)
		if sucesso:
			fechar()
		else:
			atualizar_opcoes()

func _on_botao_vender_pressed():
	if construcao_atual and construcao_atual.has_method("vender_construcao"):
		construcao_atual.vender_construcao()
		if GameManager.has_signal("moedas_atualizadas"):
			GameManager.moedas_atualizadas.emit()
	fechar()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			fechar()

func fechar():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 0.0, 0.1)
	tw.tween_property(painel_principal, "scale", Vector2(0.5, 0.5), 0.1)

	tw.chain().tween_callback(func():
		hide()
		painel_principal.scale = Vector2.ONE
		fechado.emit()
		get_tree().paused = false
	)

func _criar_secao_desbloqueios(desbloqueios: Array) -> void:
	var sec = VBoxContainer.new()
	sec.name = "DesbloqueiosSection"
	sec.add_theme_constant_override("separation", 10)
	conteudo_vbox.add_child(sec)
	# Abaixo dos cards de upgrade, acima dos botões
	conteudo_vbox.move_child(sec, opcoes_container.get_index() + 1)
	_sec_desbloqueios = sec

	var lbl_title = Label.new()
	lbl_title.text = "Desbloqueia:"
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.55, 0.58, 0.66, 1.0))
	sec.add_child(lbl_title)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	sec.add_child(row)

	for item in desbloqueios:
		row.add_child(_criar_icone_desbloqueio(item))

func _criar_icone_desbloqueio(item: Dictionary) -> Control:
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	outer.custom_minimum_size = Vector2(78, 100)

	# Badge "Novo"
	var badge = PanelContainer.new()
	var bsty = StyleBoxFlat.new()
	bsty.bg_color                   = Color(0.08, 0.55, 0.20, 1.0)
	bsty.corner_radius_top_left     = 7
	bsty.corner_radius_top_right    = 7
	bsty.content_margin_left        = 0
	bsty.content_margin_right       = 0
	bsty.content_margin_top         = 2
	bsty.content_margin_bottom      = 2
	badge.add_theme_stylebox_override("panel", bsty)
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var blbl = Label.new()
	blbl.text = "Novo"
	blbl.add_theme_font_size_override("font_size", 12)
	blbl.add_theme_color_override("font_color", Color.WHITE)
	blbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(blbl)
	outer.add_child(badge)

	# Área do ícone
	var panel = PanelContainer.new()
	var psty = StyleBoxFlat.new()
	psty.bg_color                    = Color(0.16, 0.19, 0.28, 1.0)
	psty.border_color                = Color(0.26, 0.30, 0.48, 1.0)
	psty.border_width_left           = 2
	psty.border_width_right          = 2
	psty.border_width_bottom         = 2
	psty.corner_radius_bottom_right  = 7
	psty.corner_radius_bottom_left   = 7
	psty.content_margin_left         = 4
	psty.content_margin_right        = 4
	psty.content_margin_top          = 4
	psty.content_margin_bottom       = 4
	panel.add_theme_stylebox_override("panel", psty)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	panel.add_child(inner)

	var icone_2d = item.get("icone_2d")
	if icone_2d is Texture2D:
		var tr_icone = TextureRect.new()
		tr_icone.texture = icone_2d
		tr_icone.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr_icone.custom_minimum_size = Vector2(52, 52)
		tr_icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(tr_icone)
	else:
		var elbl = Label.new()
		elbl.text = item.get("emoji", "•")
		elbl.add_theme_font_size_override("font_size", 32)
		elbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(elbl)

	var nlbl = Label.new()
	nlbl.text = item.get("nome", "")
	nlbl.add_theme_font_size_override("font_size", 11)
	nlbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.90, 1.0))
	nlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(nlbl)

	outer.add_child(panel)
	return outer

func _centralizar_painel_deferred() -> void:
	if not is_instance_valid(painel_principal): return
	await get_tree().process_frame
	if not is_instance_valid(painel_principal): return

	var s  : Vector2 = painel_principal.size
	var vp : Vector2 = get_viewport_rect().size
	const MARGEM := 10.0

	painel_principal.set_anchors_preset(Control.PRESET_CENTER)
	painel_principal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel_principal.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var off_x := -s.x * 0.5
	var off_y := -s.y * 0.5

	# Garante que o topo não saia da tela
	var topo_abs := vp.y * 0.5 + off_y
	if topo_abs < MARGEM:
		off_y = MARGEM - vp.y * 0.5

	# Garante que o rodapé também não saia da tela
	var base_abs := vp.y * 0.5 + off_y + s.y
	if base_abs > vp.y - MARGEM:
		off_y -= base_abs - (vp.y - MARGEM)
		# Re-clamp o topo caso a altura seja maior que a tela
		off_y = max(off_y, MARGEM - vp.y * 0.5)

	painel_principal.offset_left   = off_x
	painel_principal.offset_right  = off_x + s.x
	painel_principal.offset_top    = off_y
	painel_principal.offset_bottom = off_y + s.y
	painel_principal.pivot_offset  = s * 0.5
