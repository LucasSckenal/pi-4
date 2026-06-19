extends Control

@onready var ponto_lobby = $CenarioFundo/Camera3D/PontoLobby

var _tween_escala: Tween = null

# Referências para a interface (Atualizadas para a nova hierarquia sem MarginContainer)
@onready var btn_jogar          = $CanvasLayer/BtnJogar
@onready var menu_icones        = $CanvasLayer/HBoxContainer
@onready var btn_continuar      = $CanvasLayer/BtnContinuar
@onready var btn_sair           = $CanvasLayer/BtnSair
@onready var cena_configuracoes = $CanvasLayer/Configuracoes
@onready var titulo_img         = $CanvasLayer/Titulo

func _ready():
	MusicaGlobal.tocar_menu()

	if btn_continuar:
		var existe_save = GameManager.tem_jogo_salvo()
		btn_continuar.disabled = not existe_save
		btn_continuar.visible = existe_save

	if cena_configuracoes:
		cena_configuracoes.hide()
		cena_configuracoes.fechar_configuracoes.connect(_voltar_para_menu)

	_instanciar_player_no_menu()
	_animar_entrada_botoes()
	_conectar_sinais_escala_botoes()

	get_viewport().size_changed.connect(_atualizar_largura_botoes)
	_atualizar_largura_botoes()
	
	var btn_personagem = get_node_or_null("CanvasLayer/BtnPersonagemInvisivel")
	if btn_personagem:
		btn_personagem.mouse_entered.connect(_on_personagem_mouse_entered)
		btn_personagem.mouse_exited.connect(_on_personagem_mouse_exited)

func _atualizar_largura_botoes() -> void:
	var largura_tela: float = get_viewport_rect().size.x
	var largura_btn: float = clamp(largura_tela * 0.25, 150.0, 450.0)
	var altura_principal: float = clamp(largura_tela * 0.02, 45.0, 85.0)
	var altura_secundaria: float = clamp(largura_tela * 0.04, 35.0, 65.0)
	
	# Aplica o redimensionamento em todos os botões, onde quer que estejam
	var todos_botoes = _obter_todos_os_botoes()
	for btn in todos_botoes:
		var eh_principal: bool = btn.name in ["BtnContinuar", "BtnJogar"]
		btn.custom_minimum_size.y = altura_principal if eh_principal else altura_secundaria
		
		# Define largura fixa para os botões principais de navegação
		if eh_principal:
			btn.custom_minimum_size.x = largura_btn
		
		# garante que o pivot seja sempre o centro para a escala funcionar corretamente
		btn.pivot_offset = btn.size / 2.0

	if is_instance_valid(titulo_img):
		var fator: float = largura_btn / 280.0
		titulo_img.scale = Vector2(0.8 * fator, 0.8 * fator)
		
		# Centralização dinâmica do título
		var largura_titulo_escalado = titulo_img.texture.get_width() * titulo_img.scale.x
		titulo_img.position.x = (largura_tela - largura_titulo_escalado) / 1.95
		titulo_img.position.y = 100.0

# Função auxiliar para localizar botões espalhados
func _obter_todos_os_botoes() -> Array:
	var lista = []
	if btn_jogar: lista.append(btn_jogar)
	if menu_icones: lista.append_array(menu_icones.get_children())
	if btn_continuar: lista.append(btn_continuar)
	if btn_sair: lista.append(btn_sair)
	
	return lista.filter(func(node): return node is Button)

# Conecta hover/press de cada botão para animação de escala via tween
func _conectar_sinais_escala_botoes() -> void:
	for btn in _obter_todos_os_botoes():
		btn.mouse_entered.connect(_on_btn_hover_entrou.bind(btn))
		btn.mouse_exited.connect(_on_btn_hover_saiu.bind(btn))
		btn.button_down.connect(_on_btn_pressionado.bind(btn))
		btn.button_up.connect(_on_btn_solto.bind(btn))

# Hover → escala 1.05
func _on_btn_hover_entrou(btn: Button) -> void:
	_animar_escala_btn(btn, 1.05)

# Mouse sai → volta ao normal 1.0
func _on_btn_hover_saiu(btn: Button) -> void:
	_animar_escala_btn(btn, 1.0)

# Pressionado → escala 0.95
func _on_btn_pressionado(btn: Button) -> void:
	_animar_escala_btn(btn, 0.95)

# Solto → volta ao hover (1.05) se o mouse ainda estiver sobre o botão, senão ao normal
func _on_btn_solto(btn: Button) -> void:
	var escala_alvo := 1.05 if btn.is_hovered() else 1.0
	_animar_escala_btn(btn, escala_alvo)

# Aplica a animação de escala com tween suave, usando o pivot no centro do botão
func _animar_escala_btn(btn: Button, escala: float) -> void:
	# Atualiza o pivot para o centro atual (tamanho pode mudar com o viewport)
	btn.pivot_offset = btn.size / 2.0
	var tw := btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(escala, escala), 0.12)

func _instanciar_player_no_menu():
	var cena_p = load("res://Cenas Locais/player.tscn")
	
	if cena_p and ponto_lobby:
		var player_instancia = cena_p.instantiate()
		ponto_lobby.add_child(player_instancia)
		player_instancia.global_position = ponto_lobby.global_position
		player_instancia.scale = Vector3(1, 1, 1)
		player_instancia.set_physics_process(false)
		player_instancia.set_process(false)
		
		if player_instancia is CharacterBody3D:
			player_instancia.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		
		if player_instancia.has_method("_configurar_modelo_escolhido"):
			player_instancia._configurar_modelo_escolhido()
			
		call_deferred("_atualizar_estado_cabeca", player_instancia)
		_aplicar_outline_automatico(player_instancia)

func _atualizar_estado_cabeca(player_instancia: Node):
	if is_instance_valid(player_instancia):
		var todos_os_nos = player_instancia.find_children("*", "", true, false)
		for no in todos_os_nos:
			if "head-mesh" in no.name.to_lower():
				no.visible = not Global.usando_set_hollow_knight

func _animar_entrada_botoes() -> void:
	var botoes = _obter_todos_os_botoes()
	for i in botoes.size():
		var btn = botoes[i]
		btn.modulate.a = 0.0
		var delay := i * 0.09
		var tw := create_tween().set_parallel(true)
		tw.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_btn_continuar_pressed():
	if btn_continuar:
		btn_continuar.disabled = true
	var sucesso = await GameManager.carregar_jogo_salvo_manual()
	if not sucesso and btn_continuar:
		btn_continuar.disabled = false

func _on_btn_jogar_pressed():
	# Primeira vez (ainda não passou do tutorial): entra direto no mapa do tutorial,
	# pulando o seletor (que só mostraria a fase 1 mesmo). Depois de concluir,
	# fases_liberadas >= 2 e o botão passa a abrir o seletor de fases.
	if Global.fases_liberadas <= 1:
		_iniciar_tutorial()
	else:
		get_tree().change_scene_to_file("res://UI/Menus/seletor_fases.tscn")

func _iniciar_tutorial():
	GameManager.modo_infinito = false
	GameManager.fase_atual = 1
	get_tree().paused = false
	GameManager.limpar_estado_sessao()
	# Marca o tutorial como "conhecido" — ao abrir o seletor depois, o mapa 1 não
	# anima de descoberta (o jogador acabou de jogá-lo); só os novos revelam.
	if Global.mapas_revelados < 1:
		Global.mapas_revelados = 1
		Global.salvar_progresso()
	MusicaGlobal.tocar_tutorial()
	# obter_cena_entrada_fase devolve a cutscene (se ainda não vista) ou o mapa
	get_tree().change_scene_to_file(GameManager.obter_cena_entrada_fase(1))

func _on_btn_conquistas_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/tela_conquistas.tscn")

func _on_btn_bestiario_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/bestiario.tscn")

func _on_btn_sair_pressed() -> void:
	get_tree().quit()

func _on_btn_configuracoes_pressed():
	if not is_instance_valid(cena_configuracoes):
		return
	
	# Esconde os elementos da interface principal individualmente
	if btn_jogar: btn_jogar.hide()
	if menu_icones: menu_icones.hide()
	if btn_continuar: btn_continuar.hide()
	if btn_sair: btn_sair.hide()
	if titulo_img: titulo_img.hide()
	
	cena_configuracoes.show()
	cena_configuracoes.pivot_offset = cena_configuracoes.size / 2
	cena_configuracoes.scale = Vector2(0.8, 0.8)
	cena_configuracoes.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(cena_configuracoes, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cena_configuracoes, "modulate:a", 1.0, 0.2)

func _voltar_para_menu():
	cena_configuracoes.hide()
	
	if btn_jogar: btn_jogar.show()
	if menu_icones: menu_icones.show()
	if btn_sair: btn_sair.show()
	if titulo_img: titulo_img.show()
	if btn_continuar:
		btn_continuar.visible = GameManager.tem_jogo_salvo()

func _voltar_para_menu_do_seletor():
	if btn_jogar: btn_jogar.show()

func _aplicar_outline_automatico(no_raiz: Node):
	# Garante que a outline existente inicie com os valores padrões (Preto)
	_atualizar_nextpass_outline(no_raiz, 0.01, Color(0, 0, 0, 1))

# Altera os parâmetros do shader que já existe no next_pass das malhas
func _atualizar_nextpass_outline(no_atual: Node, novo_weight: float, nova_color: Color) -> void:
	if no_atual is MeshInstance3D:
		var mesh = no_atual.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var mat = no_atual.get_active_material(i)
				if mat and mat.next_pass and mat.next_pass is ShaderMaterial:
					if not mat.next_pass.resource_local_to_scene:
						mat.next_pass = mat.next_pass.duplicate()
						
					var shader_mat = mat.next_pass as ShaderMaterial
					# Documentação: Strings corrigidas para letras minúsculas respeitando o Outline.gdshader
					shader_mat.set_shader_parameter("weight", novo_weight)
					shader_mat.set_shader_parameter("color", nova_color)
					
	for filho in no_atual.get_children():
		_atualizar_nextpass_outline(filho, novo_weight, nova_color)

func _on_btn_personagem_invisivel_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menus/menu_customizacao.tscn")

# Executa os efeitos visuais ao passar o mouse sobre o personagem
func _on_personagem_mouse_entered() -> void:
	var personagem = ponto_lobby.get_child(0) if ponto_lobby.get_child_count() > 0 else null
	if not personagem: return

	_atualizar_nextpass_outline(personagem, 0.016, Color(1, 1, 1, 1))
	
	if _tween_escala and _tween_escala.is_valid():
		_tween_escala.kill()
	_tween_escala = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_escala.tween_property(ponto_lobby, "scale", Vector3(1.08, 1.08, 1.08), 0.15)

# Restaura os valores originais quando o mouse deixa o personagem
func _on_personagem_mouse_exited() -> void:
	var personagem = ponto_lobby.get_child(0) if ponto_lobby.get_child_count() > 0 else null
	if not personagem: return

	_atualizar_nextpass_outline(personagem, 0.01, Color(0, 0, 0, 1))
	
	if _tween_escala and _tween_escala.is_valid():
		_tween_escala.kill()
	_tween_escala = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_escala.tween_property(ponto_lobby, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
