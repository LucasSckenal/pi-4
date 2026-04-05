extends Control

signal fechado

@export var cena_opcao_button: PackedScene

# ==========================================
# REFERÊNCIAS
# ==========================================
@onready var fundo_escuro = $FundoEscuro
@onready var painel_principal = $PainelPrincipal
@onready var titulo = $PainelPrincipal/VBoxContainer/Titulo
@onready var status_container = $PainelPrincipal/VBoxContainer/StatusContainer
@onready var opcoes_container = $PainelPrincipal/VBoxContainer/OpcoesContainer
@onready var botao_fechar = $PainelPrincipal/VBoxContainer/BotaoFechar
@onready var instrucao_label = $PainelPrincipal/VBoxContainer/Instrucao  # NOVO: label de instrução (adicione no seu cena)
@onready var botao_vender = $PainelPrincipal/VBoxContainer/BotaoVender # NOVO: botão de venda

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var construcao_atual: Node = null

func _ready():
	hide()
	fundo_escuro.modulate.a = 0
	painel_principal.scale = Vector2.ZERO
	botao_fechar.pressed.connect(fechar)
	
	# NOVO: Conecta o botão de venda
	if botao_vender:
		botao_vender.pressed.connect(_on_botao_vender_pressed)
	
	# NOVO: configura a instrução
	if instrucao_label:
		instrucao_label.text = "👇 Clique numa opção para melhorar"
		instrucao_label.add_theme_font_size_override("font_size", 20)

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
	
	# 1. RESET DE ESTADO (Para não esticar na segunda vez)
	show()
	painel_principal.scale = Vector2.ONE # Força escala normal para ler o tamanho real
	
	# 2. ATUALIZAÇÃO DE TEXTOS E BOTÕES (Seu código original)
	titulo.text = construcao_atual.name
	if "nivel_atual" in construcao_atual:
		titulo.text += " (Nível " + str(construcao_atual.nivel_atual) + ")"
	
	if "tipo" in construcao_atual and "TipoConstrucao" in construcao_atual and construcao_atual.tipo == construcao_atual.TipoConstrucao.BASE:
		botao_vender.hide()
	else:
		botao_vender.show()
		var valor = 0
		if "custo_moedas" in construcao_atual:
			valor = int(float(construcao_atual.custo_moedas) / 2.0)
		botao_vender.text = " Vender (+" + str(valor) + ")"
	
	atualizar_status_atuais()
	atualizar_opcoes()
	
	# Redefine o tamanho do painel para o mínimo necessário após a atualização dos filhos
	painel_principal.size = Vector2.ZERO
	
	# 3. POSICIONAMENTO E ANIMAÇÃO (CORREÇÃO DO PIVOT)
	# Força o pivot para o centro do painel baseado no tamanho real calculado agora
	painel_principal.pivot_offset = painel_principal.size / 2
	
	# Projeta a posição 3D da construção para a tela 2D e posiciona o painel
	# na lateral oposta para garantir a visibilidade da torre e do mapa.
	var camera = get_viewport().get_camera_3d()
	if camera and "global_position" in construcao_atual:
		var pos_2d = camera.unproject_position(construcao_atual.global_position)
		var tela = get_viewport_rect().size
		var distancia_segura = 150
		
		if pos_2d.x > tela.x / 2.0:
			painel_principal.global_position.x = pos_2d.x - painel_principal.size.x - distancia_segura
		else:
			painel_principal.global_position.x = pos_2d.x + distancia_segura
			
		painel_principal.global_position.y = clamp(pos_2d.y - (painel_principal.size.y / 2.0), 20.0, tela.y - painel_principal.size.y - 20.0)
	
	# Começa a animação de um ponto limpo
	painel_principal.scale = Vector2(0.5, 0.5)
	fundo_escuro.modulate.a = 0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 1.0, 0.2)
	tw.tween_property(painel_principal, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func atualizar_status_atuais():
	# Limpa status antigos
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()
		
	var atributos = []
	
	# Toda a construção tem vida máxima
	if "vida_maxima" in construcao_atual:
		atributos.append({"nome": "❤️ Vida Máx", "valor": construcao_atual.vida_maxima})
		
	# Deteta o tipo de construção baseado no Enum do teu Builds.gd
	if "tipo" in construcao_atual:
		var tipo = construcao_atual.tipo
		
		# 0 = TORRE
		if tipo == 0:
			atributos.append({"nome": "⚔️ Dano", "valor": construcao_atual.dano_atual})
			atributos.append({"nome": "⏱️ Vel.", "valor": str(snapped(construcao_atual.tempo_ataque_atual, 0.1)) + "s"})
			atributos.append({"nome": "🎯 Alcance", "valor": construcao_atual.alcance_atual})
			
		# 1 = MINA, 2 = CASA, 3 = MOINHO
		elif tipo == 1 or tipo == 2 or tipo == 3:
			atributos.append({"nome": "💰 Ouro/Onda", "valor": construcao_atual.moedas_por_onda_atual})
			
		# 4 = QUARTEL
		elif tipo == 4:
			atributos.append({"nome": "🛡️ Soldados", "valor": construcao_atual.numero_aliados_atual})
			if "tempo_respawn" in construcao_atual:
				atributos.append({"nome": "⏳ Respawn", "valor": str(construcao_atual.tempo_respawn) + "s"})
				
		# 5 = BASE
		elif tipo == 5:
			pass # Base só precisa mostrar a vida máxima

	var tem_status = false
	for attr in atributos:
		tem_status = true
		var lbl = Label.new()
		lbl.text = attr["nome"] + ": " + str(attr["valor"])
		lbl.add_theme_font_size_override("font_size", 22)  # AUMENTADO
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))  # Mais claro
		status_container.add_child(lbl)
			
	status_container.visible = tem_status

func atualizar_opcoes():
	for child in opcoes_container.get_children():
		opcoes_container.remove_child(child)
		child.queue_free()
		
	if not construcao_atual.has_method("get_opcoes_proximo_upgrade"):
		return
		
	var opcoes = construcao_atual.get_opcoes_proximo_upgrade()
	
	if opcoes.size() == 0:
		var label_max = Label.new()
		label_max.text = "🌟 NÍVEL MÁXIMO ALCANÇADO 🌟"
		label_max.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_max.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		label_max.add_theme_font_size_override("font_size", 24)  # AUMENTADO
		opcoes_container.add_child(label_max)
		return
		
	for opcao in opcoes:
		if cena_opcao_button:
			var btn = cena_opcao_button.instantiate()
			btn.name = "Upgrade"
			# AUMENTADO tamanho mínimo do botão
			btn.custom_minimum_size = Vector2(260, 320) 
			opcoes_container.add_child(btn)
			
			if btn.has_method("configurar"):
				btn.configurar(opcao)
				
			btn.pressed.connect(_on_opcao_escolhida.bind(opcao.get("index", 0)))

# ==========================================
# AÇÕES DO JOGADOR
# ==========================================
func _on_opcao_escolhida(index: int):
	if construcao_atual and construcao_atual.has_method("aplicar_upgrade"):
		construcao_atual.aplicar_upgrade(index)
		
	fechar()

func _on_botao_vender_pressed():
	if construcao_atual and construcao_atual.has_method("vender_construcao"):
		# 1. Vende a construção e devolve o dinheiro (lógica do Builds.gd)
		construcao_atual.vender_construcao()
		
		# 2. Grita para a HUD atualizar os números na tela!
		if GameManager.has_signal("moedas_atualizadas"):
			GameManager.moedas_atualizadas.emit()
			
	fechar()

func fechar():
	# Mata qualquer tween antigo que ainda esteja rodando no painel
	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 0.0, 0.1)
	tw.tween_property(painel_principal, "scale", Vector2(0.5, 0.5), 0.1)
	
	tw.chain().tween_callback(func():
		hide()
		# Reset físico para garantir que o layout não fique "preso"
		painel_principal.scale = Vector2.ONE 
		fechado.emit()
		get_tree().paused = false 
	)
