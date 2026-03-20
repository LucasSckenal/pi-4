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

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var construcao_atual: Node = null

func _ready():
	hide()
	fundo_escuro.modulate.a = 0
	painel_principal.scale = Vector2.ZERO
	botao_fechar.pressed.connect(fechar)
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
		print("Está muito escuro e perigoso para fazer obras agora!")
		return
		
	construcao_atual = construcao
	
	# Atualiza o Título e o Nível (com emoji opcional)
	titulo.text = construcao_atual.name
	if construcao_atual.get("nivel_atual") != null:
		titulo.text += " (Nível " + str(construcao_atual.nivel_atual) + ")"
	titulo.add_theme_font_size_override("font_size", 28)  # AUMENTADO
	
	atualizar_status_atuais()
	atualizar_opcoes()
	
	show()
	
	# ANIMAÇÃO BEM SUCULENTA DE ENTRADA (POP-UP)
	painel_principal.pivot_offset = painel_principal.size / 2
	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 1.0, 0.2)
	painel_principal.scale = Vector2(0.5, 0.5)
	tw.tween_property(painel_principal, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func atualizar_status_atuais():
	# Limpa status antigos
	for child in status_container.get_children():
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
	
func fechar():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(fundo_escuro, "modulate:a", 0.0, 0.2)
	tw.tween_property(painel_principal, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		hide()
		fechado.emit()
		get_tree().paused = false 
	)
