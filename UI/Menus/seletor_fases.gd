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

func recalcular_linhas() -> void:
	await get_tree().process_frame
	criar_linhas_tracejadas()
	
	# AGORA LÊ DO GLOBAL
	atualizar_mapa(Global.fases_liberadas)

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
	for i in range(botoes_fases.size()):
		var botao = botoes_fases[i] 
		var nivel_da_fase = i + 1 
		
		if nivel_da_fase <= fases_liberadas:
			botao.modulate = Color(1, 1, 1, 1) 
			botao.disabled = false 
			# Chamamos a atualização das estrelas aqui:
			atualizar_estrelas_do_botao(botoes_fases[i], nivel_da_fase)
			botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			for botao_child in botao.get_children(): botao_child.visible = true

		else:
			botao.modulate = Color(0.01, 0.01, 0.01, 1) 
			botao.disabled = true
			botao.mouse_default_cursor_shape = Control.CURSOR_ARROW
			for botao_child in botao.get_children(): botao_child.visible = false

	for i in range(linhas_criadas.size()):
		var nivel_destino = i + 2 
		if nivel_destino <= fases_liberadas:
			linhas_criadas[i].show()
		else:
			linhas_criadas[i].hide()

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
