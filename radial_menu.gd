extends Control

signal construcao_escolhida(cena: PackedScene)

@onready var center_label = $CenterLabel  # Vamos criar via código também, ou pode colocar na cena
@onready var hold_timer = $HoldTimer

var slot_origem: Node = null
var botao_prefab = preload("res://Cenas Locais/radial_button.tscn")  # Ajuste o caminho
var opcoes: Array[Dictionary] = []
var raio: float = 150.0
var centro: Vector2

func _ready():
	# Se não houver CenterLabel na cena, criamos um
	if not center_label:
		center_label = Label.new()
		center_label.name = "CenterLabel"
		center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		center_label.add_theme_font_size_override("font_size", 24)
		center_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(center_label)
	
	# Se não houver Timer, criamos
	if not hold_timer:
		hold_timer = Timer.new()
		hold_timer.name = "HoldTimer"
		hold_timer.one_shot = true
		hold_timer.wait_time = 0.5
		hold_timer.timeout.connect(_mostrar_descricao)
		add_child(hold_timer)
	
	centro = get_viewport().get_visible_rect().size / 2
	hide()

func abrir(slot: Node):
	slot_origem = slot
	_criar_opcoes()
	show()

func fechar():
	hide()
	# Limpa botões
	for child in get_children():
		if child is TextureButton and child != center_label:
			child.queue_free()
	slot_origem = null

func _criar_opcoes():
	# Remove botões antigos
	for child in get_children():
		if child is TextureButton and child != center_label:
			child.queue_free()
	opcoes.clear()
	
	var construcoes = GameManager.get_construcoes_disponiveis()
	if construcoes.is_empty():
		center_label.text = "Nenhuma"
		return
	
	var angulo_intervalo = 2 * PI / construcoes.size()
	var angulo_inicial = -PI/2  # Começa do topo
	
	for i in range(construcoes.size()):
		var cena = construcoes[i]
		var angulo = angulo_inicial + i * angulo_intervalo
		
		# Instancia botão
		var botao = botao_prefab.instantiate()
		add_child(botao)
		
		# Posiciona em coordenadas da UI
		botao.position = centro + Vector2(cos(angulo), sin(angulo)) * raio - botao.size / 2
		
		# Configura
		botao.configurar(cena, self)
		
		# Conecta sinais de hold
		botao.button_down.connect(_iniciar_hold.bind(botao))
		botao.button_up.connect(_cancelar_hold)
		
		opcoes.append({ "cena": cena, "botao": botao, "angulo": angulo })
	
	center_label.text = "Selecione"

func botao_pressionado(cena: PackedScene):
	# Cancelar hold
	_cancelar_hold()
	
	# Verifica custo e compra
	var temp = cena.instantiate()
	var custo = GameManager.obter_custo_com_desconto(temp.custo_moedas)
	temp.queue_free()
	
	if GameManager.gastar_moedas(custo):
		slot_origem.construir(cena)
		fechar()
	else:
		center_label.text = "Sem moedas!"
		await get_tree().create_timer(0.5).timeout
		center_label.text = "Selecione"

func _iniciar_hold(botao):
	hold_timer.start()
	set_meta("botao_hold", botao)

func _cancelar_hold():
	hold_timer.stop()

func _mostrar_descricao():
	var botao = get_meta("botao_hold") if has_meta("botao_hold") else null
	if botao:
		for opt in opcoes:
			if opt["botao"] == botao:
				_abrir_descricao(opt["cena"])
				break

func _abrir_descricao(cena: PackedScene):
	# Simples: mostra nome e preço no centro
	var temp = cena.instantiate()
	var nome = temp.name
	var custo = GameManager.obter_custo_com_desconto(temp.custo_moedas)
	temp.queue_free()
	
	center_label.text = nome + "\nCusto: " + str(custo)
	await get_tree().create_timer(1.5).timeout
	center_label.text = "Selecione"
