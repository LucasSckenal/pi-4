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
@onready var instrucao_label = $PainelPrincipal/VBoxContainer/Instrucao
@onready var botao_vender = $PainelPrincipal/VBoxContainer/BotaoVender

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var construcao_atual: Node = null

func _ready():
	hide()
	fundo_escuro.modulate.a = 0
	painel_principal.scale = Vector2.ZERO
	
	# Encapsula a interface em um CanvasLayer de nível máximo anexado à raiz do jogo.
	# Isso garante a sobreposição absoluta sobre lotes de construção e outros HUDs.
	var canvas_topo = CanvasLayer.new()
	canvas_topo.layer = 120
	get_tree().root.call_deferred("add_child", canvas_topo)
	call_deferred("reparent", canvas_topo)
	
	botao_fechar.pressed.connect(fechar)
	botao_fechar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if botao_vender:
		botao_vender.pressed.connect(_on_botao_vender_pressed)
		botao_vender.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
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
	
	show()
	painel_principal.scale = Vector2.ONE 
	
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
	
	# Reseta o tamanho para o PanelContainer recalcular a partir do conteúdo.
	# Ancora no canto superior-esquerdo para que position controle o layout.
	painel_principal.reset_size()
	painel_principal.set_anchors_preset(Control.PRESET_TOP_LEFT)

	# Estimativa de pivot para a animação de entrada ficar centrada visualmente.
	# O valor exato é corrigido em _centralizar_painel() após o layout ser calculado.
	painel_principal.pivot_offset = Vector2(320.0, 220.0)

	# call_deferred garante que o Godot já terminou o passo de layout e
	# painel_principal.size reflete o tamanho real do conteúdo.
	# Funciona tanto no editor (1280×720) quanto em builds mobile.
	call_deferred("_centralizar_painel_deferred")
	
	painel_principal.scale = Vector2(0.5, 0.5)
	fundo_escuro.modulate.a = 0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 1.0, 0.2)
	tw.tween_property(painel_principal, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func atualizar_status_atuais():
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()
		
	var atributos = []
	
	if "vida_maxima" in construcao_atual:
		atributos.append({"nome": "❤️ Vida Máx", "valor": construcao_atual.vida_maxima})
		
	if "tipo" in construcao_atual:
		var tipo = construcao_atual.tipo
		
		if tipo == 0:
			atributos.append({"nome": "⚔️ Dano", "valor": construcao_atual.dano_atual})
			atributos.append({"nome": "⏱️ Vel.", "valor": str(snapped(construcao_atual.tempo_ataque_atual, 0.1)) + "s"})
			atributos.append({"nome": "🎯 Alcance", "valor": construcao_atual.alcance_atual})
			
		elif tipo == 1 or tipo == 2 or tipo == 3:
			atributos.append({"nome": "💰 Ouro/Onda", "valor": construcao_atual.moedas_por_onda_atual})
			
		elif tipo == 4:
			atributos.append({"nome": "🛡️ Soldados", "valor": construcao_atual.numero_aliados_atual})
			if "tempo_respawn" in construcao_atual:
				atributos.append({"nome": "⏳ Respawn", "valor": str(construcao_atual.tempo_respawn) + "s"})
				
		elif tipo == 5:
			pass 

	var tem_status = false
	for attr in atributos:
		tem_status = true
		var lbl = Label.new()
		lbl.text = attr["nome"] + ": " + str(attr["valor"])
		lbl.add_theme_font_size_override("font_size", 22)  
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))  
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
		label_max.add_theme_font_size_override("font_size", 24)  
		opcoes_container.add_child(label_max)
		return
		
	for opcao in opcoes:
		if cena_opcao_button:
			var btn = cena_opcao_button.instantiate()
			btn.name = "Upgrade"
			btn.custom_minimum_size = Vector2(260, 320)
			opcoes_container.add_child(btn)

			if btn.has_method("configurar"):
				btn.configurar(opcao)

			# Sempre conecta o sinal — aplicar_upgrade() valida moedas internamente
			btn.pressed.connect(_on_opcao_escolhida.bind(opcao.get("index", 0)))

			# Feedback visual de moedas insuficientes (botão permanece clicável)
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
			# Recarrega os botões para refletir o estado atual de moedas
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

# Chamado via call_deferred para garantir que o layout já foi calculado.
# Centraliza o painel no meio exato da tela independente do tamanho do conteúdo
# ou da resolução (funciona no editor com 1280×720 e em builds mobile).
func _centralizar_painel_deferred() -> void:
	if not is_instance_valid(painel_principal): return
	var tela : Vector2 = get_viewport_rect().size
	var s    : Vector2 = painel_principal.size
	# Garante que o painel nunca saia dos limites da tela
	var margem : float = 20.0
	var pos_x  : float = clamp((tela.x - s.x) / 2.0, margem, tela.x - s.x - margem)
	var pos_y  : float = clamp((tela.y - s.y) / 2.0, margem, tela.y - s.y - margem)
	painel_principal.position     = Vector2(pos_x, pos_y)
	painel_principal.pivot_offset = s / 2.0
	
