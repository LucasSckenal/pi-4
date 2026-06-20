extends Control

# Caminho para a sua textura do tracinho
var textura_linha = preload("res://Icons/textura_tracinho.png")
var estrela_cheia = preload("res://Icons/star.png")
var estrela_vazia = preload("res://Icons/star_outline_depth.png")
const MODAL_MODO_FASE = preload("res://UI/Modals/modal_modo_fase.tscn")
# Pegamos o nó do pergaminho para jogar as linhas lá dentro
@onready var pergaminho = $Meshy_AI_Blank_Scroll_0416004051_texture
var progresso_atual = 6

@onready var btnVoltar = $BtnVoltar

# Nomes corrigidos exatamente iguais à sua foto!
@onready var botoes_fases = [
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map1,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map2,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map3,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map4,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map5,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map6
]


var linhas_criadas = []

# Pedaços de papel rasgado (PLACEHOLDERS). Cada fase tem o seu; eles se juntam
# conforme as fases liberam. Trocar por arte real depois (ver spec).
var _pecas: Array = []
const _CORES_PAPEL := [
	Color(0.82, 0.72, 0.52), Color(0.80, 0.68, 0.47), Color(0.85, 0.75, 0.56),
	Color(0.78, 0.67, 0.46), Color(0.83, 0.73, 0.53), Color(0.81, 0.70, 0.50),
]

func _ready() -> void:
	# Conecta o sinal para redimensionar
	get_tree().root.size_changed.connect(recalcular_linhas)
	
	for botao in botoes_fases:
		if botao != null:
			# Define o pivô no centro e compensa matematicamente a posição para que 
			# a imagem não sofra um salto visual ao ter seu eixo alterado, 
			# mantendo o layout intacto para as animações de escala.
			var centro = botao.size / 2.0
			botao.pivot_offset = centro
			botao.position -= centro * (Vector2.ONE - botao.scale)
			
			botao.set_meta("escala_original", botao.scale)
			botao.set_meta("rot_original", botao.rotation)

			botao.mouse_entered.connect(func():
				# Impede a animação em fases não liberadas
				if botao.disabled: 
					botao.mouse_default_cursor_shape = Control.CURSOR_ARROW
					return
				
				var escala_base = botao.get_meta("escala_original")
				var tween := create_tween()
				tween.tween_property(botao, "scale", escala_base * 1.10, 0.1).set_trans(Tween.TRANS_SINE)
			)
			
			botao.mouse_exited.connect(func():
				# Impede a animação em fases não liberadas
				if botao.disabled: return
				
				var escala_base = botao.get_meta("escala_original")
				var tween := create_tween()
				tween.tween_property(botao, "scale", escala_base, 0.1).set_trans(Tween.TRANS_SINE)
			)
	
	# Desenha tudo pela primeira vez
	recalcular_linhas()

	# Botão de debug "Desbloquear Tudo" — visível apenas em builds de debug ou editor
	if OS.is_debug_build() or OS.has_feature("editor"):
		_criar_botao_debug_unlock()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# Intercepta o input
			get_viewport().set_input_as_handled()
			
			# Chama a mesma função que você fez para o "BtnVoltar"
			_on_btn_voltar_pressed()

func recalcular_linhas() -> void:
	await get_tree().process_frame
	criar_linhas_tracejadas()
	_criar_pecas()

	# AGORA LÊ DO GLOBAL
	atualizar_mapa(Global.fases_liberadas)

# ==========================================
# PEDAÇOS DE PAPEL RASGADO (placeholders)
# ==========================================
func _criar_pecas() -> void:
	# Esconde o pergaminho 3D antigo — os pedaços passam a ser o "fundo" do mapa
	for m in pergaminho.find_children("*", "MeshInstance3D", true, false):
		m.visible = false

	# Limpa pedaços antigos (recriação em resize)
	for p in _pecas:
		if is_instance_valid(p): p.queue_free()
	_pecas.clear()

	for i in range(botoes_fases.size()):
		var botao = botoes_fases[i]
		if botao == null:
			_pecas.append(null)
			continue
		var centro: Vector2 = botao.global_position + (botao.size * botao.scale) / 2.0
		var peca := _criar_peca_placeholder(i, Vector2(540, 470))
		peca.global_position = centro
		get_tree().current_scene.add_child(peca)
		get_tree().current_scene.move_child(peca, 0)  # atrás de tudo
		_pecas.append(peca)

func _criar_peca_placeholder(idx: int, tam: Vector2) -> Node2D:
	var raiz := Node2D.new()
	raiz.z_index = -10
	var pts := _gerar_contorno_rasgado(tam)
	# Sombra (dá a sensação de papel sobre papel)
	var sombra := Polygon2D.new()
	sombra.polygon = pts
	sombra.color = Color(0.12, 0.08, 0.05, 0.15) # Deixado mais transparente, antes era 0.55
	sombra.position = Vector2(7, 9)
	raiz.add_child(sombra)
	# Papel
	var papel := Polygon2D.new()
	papel.polygon = pts
	papel.color = _CORES_PAPEL[idx % _CORES_PAPEL.size()]
	raiz.add_child(papel)
	return raiz

# Gera um contorno retangular com bordas irregulares (rasgadas), centrado em (0,0).
func _gerar_contorno_rasgado(tam: Vector2) -> PackedVector2Array:
	var meio := tam / 2.0
	var jag := 20.0       # amplitude do "rasgo"
	var ph := 9           # subdivisões horizontais
	var pv := 7           # subdivisões verticais
	var pts := PackedVector2Array()
	for s in range(ph):  # topo: esquerda -> direita
		pts.append(Vector2(lerpf(-meio.x, meio.x, float(s) / ph), -meio.y + randf_range(-jag, jag)))
	for s in range(pv):  # direita: cima -> baixo
		pts.append(Vector2(meio.x + randf_range(-jag, jag), lerpf(-meio.y, meio.y, float(s) / pv)))
	for s in range(ph):  # baixo: direita -> esquerda
		pts.append(Vector2(lerpf(meio.x, -meio.x, float(s) / ph), meio.y + randf_range(-jag, jag)))
	for s in range(pv):  # esquerda: baixo -> cima
		pts.append(Vector2(-meio.x + randf_range(-jag, jag), lerpf(meio.y, -meio.y, float(s) / pv)))
	return pts

func criar_linhas_tracejadas() -> void:
	# Limpa as antigas
	for l in linhas_criadas:
		l.queue_free()
	linhas_criadas.clear()

	for i in range(botoes_fases.size() - 1):
		var b1 = botoes_fases[i]
		var b2 = botoes_fases[i + 1]
		
		if b1 == null or b2 == null: continue
			
		var linha = Line2D.new()
		
		var p1 = b1.global_position + (b1.size * b1.get_global_transform().get_scale() / 2.0)
		var p2 = b2.global_position + (b2.size * b2.get_global_transform().get_scale() / 2.0)
		
		linha.add_point(p1)
		linha.add_point(p2)
		
		# Se a linha sumir, aumente esse width para 20 ou 30
		linha.width = 250.0 
		linha.texture = textura_linha
		linha.texture_mode = Line2D.LINE_TEXTURE_TILE
		linha.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		linha.default_color = Color(1, 1, 1, 1)
		
		# Z_INDEX alto faz a linha ficar na frente de tudo (para vermos onde ela está!)
		linha.z_index = -1
	
		
		# ADICIONAMOS DIRETO NA RAIZ DA CENA (mais seguro para teste)
		get_tree().current_scene.add_child(linha)
		
		linhas_criadas.append(linha)

func atualizar_mapa(fases_liberadas: int) -> void:
	var atraso: float = 0.0  # escalona a animação de descoberta de cada peça nova

	for i in range(botoes_fases.size()):
		var botao = botoes_fases[i]
		var nivel_da_fase = i + 1
		var peca = _pecas[i] if i < _pecas.size() else null

		if nivel_da_fase <= fases_liberadas:
			# LIBERADO → peça + mapa visíveis e interativos
			botao.disabled = false
			botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			atualizar_estrelas_do_botao(botao, nivel_da_fase)
			for botao_child in botao.get_children(): botao_child.visible = true

			if nivel_da_fase > Global.mapas_revelados:
				# Recém-descoberto → peça de papel se encaixando (mapa cai junto)
				_revelar_conjunto(botao, peca, atraso)
				atraso += 0.5
			else:
				# Já conhecido → mostra direto, no lugar
				botao.modulate = Color(1, 1, 1, 1)
				botao.scale = botao.get_meta("escala_original")
				botao.rotation = botao.get_meta("rot_original")
				if peca != null and is_instance_valid(peca):
					peca.modulate = Color(1, 1, 1, 1)
					peca.rotation = 0.0
		elif nivel_da_fase == fases_liberadas + 1 and peca != null and is_instance_valid(peca):
			# PRÓXIMO bloqueado → "teaser": peça escura/fantasma (o pedaço por descobrir)
			peca.modulate = Color(0.45, 0.40, 0.32, 0.4)
			peca.rotation = 0.0
			botao.modulate = Color(1, 1, 1, 0)
			botao.disabled = true
			botao.mouse_default_cursor_shape = Control.CURSOR_ARROW
			for botao_child in botao.get_children(): botao_child.visible = false
		else:
			# Demais bloqueados → totalmente ocultos
			if peca != null and is_instance_valid(peca):
				peca.modulate = Color(1, 1, 1, 0)
			botao.modulate = Color(1, 1, 1, 0)
			botao.disabled = true
			botao.mouse_default_cursor_shape = Control.CURSOR_ARROW
			for botao_child in botao.get_children(): botao_child.visible = false

	# Linhas: visíveis só até o último mapa liberado
	for i in range(linhas_criadas.size()):
		var nivel_destino = i + 2
		linhas_criadas[i].visible = (nivel_destino <= fases_liberadas)

	# Persiste o que já foi revelado para não animar de novo na próxima visita
	if fases_liberadas > Global.mapas_revelados:
		Global.mapas_revelados = fases_liberadas
		Global.salvar_progresso()

# Encaixe de uma peça de mapa rasgado: a peça de papel E o mapa (ícone/nome/estrelas)
# caem juntos meio tortos de cima e se assentam no lugar com um "snap".
func _revelar_conjunto(botao: Button, peca, atraso: float) -> void:
	var offset := Vector2(randf_range(-30.0, 30.0), -62.0)
	var tilt := deg_to_rad(randf_range(-13.0, 13.0))
	var dur := 0.55

	# --- Mapa (botão) ---
	var b_escala: Vector2 = botao.get_meta("escala_original")
	var b_rot: float = botao.get_meta("rot_original")
	var b_pos: Vector2 = botao.position
	botao.scale = b_escala
	botao.modulate = Color(1, 1, 1, 0)
	botao.rotation = b_rot + tilt
	botao.position = b_pos + offset

	var tw := create_tween().set_parallel(true)
	tw.tween_callback(SFXManager.tocar_new_map).set_delay(atraso)
	tw.tween_property(botao, "modulate:a", 1.0, 0.3).set_delay(atraso)
	tw.tween_property(botao, "rotation", b_rot, dur).set_delay(atraso) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(botao, "position", b_pos, dur).set_delay(atraso) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# --- Peça de papel (cai junto) ---
	if peca != null and is_instance_valid(peca):
		var p_pos: Vector2 = peca.position
		peca.modulate = Color(1, 1, 1, 0)
		peca.rotation = tilt
		peca.position = p_pos + offset
		tw.tween_property(peca, "modulate:a", 1.0, 0.3).set_delay(atraso)
		tw.tween_property(peca, "rotation", 0.0, dur).set_delay(atraso) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(peca, "position", p_pos, dur).set_delay(atraso) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _criar_botao_debug_unlock() -> void:
	var btn := Button.new()
	btn.text = "🔓 DEBUG: Desbloquear Tudo"
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(320, 64)

	# Posição: canto inferior-direito da tela
	btn.anchor_left   = 1.0
	btn.anchor_right  = 1.0
	btn.anchor_top    = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left   = -340
	btn.offset_right  = -10
	btn.offset_top    = -74
	btn.offset_bottom = -10

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.08, 0.28, 0.90)
	st.border_color = Color(0.72, 0.40, 0.95)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	st.content_margin_left = 12
	st.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_color_override("font_color", Color(0.88, 0.72, 1.0))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	btn.pressed.connect(func():
		Global.fases_liberadas = botoes_fases.size()
		# Marca todas as cutscenes como vistas — as fases 2-6 ainda têm cutscenes
		# placeholder que não transicionam para a fase, então puladas evitam travar.
		for n in range(1, botoes_fases.size() + 1):
			Global.registrar_cutscene_vista(n)
		Global.salvar_progresso()
		atualizar_mapa(Global.fases_liberadas)
	)
	add_child(btn)

func atualizar_estrelas_do_botao(botao: Button, nivel_da_fase: int) -> void:
	# Puxa as estrelas do Global. Usa str() para buscar "1", "2", etc.
	var qtd_estrelas = Global.estrelas_por_fase.get(str(nivel_da_fase), 0)
	
	# Faz um loop de 1 a 3 para verificar Star1, Star2 e Star3
	for n in range(1, 4):
		var nome_node = "Star" + str(n)
		if botao.has_node(nome_node):
			var estrela_node = botao.get_node(nome_node) as MeshInstance2D
			
			if estrela_node != null:
				if qtd_estrelas >= n:
					estrela_node.texture = estrela_cheia
				else:
					estrela_node.texture = estrela_vazia
				
# ==========================================
# SINAIS DE MOUSE
# ==========================================			

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")


func _on_map_1_pressed() -> void:
	_abrir_modal_fase(1)

func _on_map_2_pressed() -> void:
	_abrir_modal_fase(2)

func _on_map_3_pressed() -> void:
	_abrir_modal_fase(3)

func _on_map_4_pressed() -> void:
	_abrir_modal_fase(4)

func _on_map_5_pressed() -> void:
	_abrir_modal_fase(5)

func _on_map_6_pressed() -> void:
	_abrir_modal_fase(6)


# ==========================================
# MODAL DE SELEÇÃO DE MODO (NORMAL / INFINITO)
# ==========================================
func _abrir_modal_fase(numero_fase: int) -> void:
	var modal = MODAL_MODO_FASE.instantiate()
	add_child(modal)
	modal.abrir(numero_fase)
	modal.modo_confirmado.connect(func(infinito: bool):
		_iniciar_fase(numero_fase, infinito)
	)


func _iniciar_fase(numero_fase: int, infinito: bool) -> void:
	GameManager.modo_infinito = infinito
	# Define a fase atual ANTES de carregar — a cutscene e a cena da fase leem
	# GameManager.fase_atual para saber qual fase iniciar.
	GameManager.fase_atual = numero_fase

	# Limpa o estado da sessão anterior antes de trocar de cena.
	# Isso garante que nivel_base (e demais bônus) estejam zerados quando a nova
	# cena carregar — a base lê GameManager.nivel_base em _ready(), então se esse
	# valor ficar sujo de uma sessão anterior a base aparece no nível máximo.
	get_tree().paused = false
	GameManager.limpar_estado_sessao()

	# Toca a música correspondente à fase
	match numero_fase:
		1: MusicaGlobal.tocar_tutorial()
		2: MusicaGlobal.tocar_deserto()
		3: MusicaGlobal.tocar_bruxa()
		4: MusicaGlobal.tocar_aquatico()
		5: MusicaGlobal.tocar_scifi()
		6: MusicaGlobal.tocar_covil()

	get_tree().change_scene_to_file(GameManager.obter_cena_entrada_fase(numero_fase))



# Deus me salve esse botão tem de scale (-0.10, 0.077)
# Hover → escala 1.05
func _on_btn_hover_entrou() -> void:
	_animar_escala_btn(btnVoltar, 1.05)

# Mouse sai → volta ao normal 1.0
func _on_btn_hover_saiu() -> void:
	_animar_escala_btn(btnVoltar, 1.0)

# Pressionado → escala 0.95
func _on_btn_pressionado() -> void:
	_animar_escala_btn(btnVoltar, 0.95)

# Solto → volta ao hover (1.05) se o mouse ainda estiver sobre o botão, senão ao normal
func _on_btn_solto() -> void:
	var escala_alvo := 1.05 if btnVoltar.is_hovered() else 1.0
	_animar_escala_btn(btnVoltar, escala_alvo)

# Aplica a animação de escala com tween suave, usando o pivot no centro do botão
func _animar_escala_btn(btnEscolhido: Button, escala: float) -> void:
	# Atualiza o pivot para o centro atual (tamanho pode mudar com o viewport)
	btnEscolhido.pivot_offset = btnEscolhido.size / 2.0
	var tw := btnEscolhido.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btnEscolhido, "scale", Vector2(escala, escala), 0.12)
