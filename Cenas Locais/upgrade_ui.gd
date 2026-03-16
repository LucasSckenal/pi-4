extends Control

signal fechado

@export var cena_opcao_button: PackedScene

# ==========================================
# REFERÊNCIAS
# ==========================================
@onready var opcoes_container = $Control/Panel/VBoxContainer/OpcoesContainer
@onready var titulo = $Control/Panel/VBoxContainer/Titulo
@onready var botao_fechar = $Control/Panel/VBoxContainer/BotaoFechar

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var construcao_atual: Node = null

func _ready():
	# Esconde a UI ao iniciar e conecta o botão de fechar
	hide()
	botao_fechar.pressed.connect(fechar)

# Chamado pela HUD para injetar a cena do botão
func set_cena_opcao_button(cena: PackedScene):
	if cena != null:
		cena_opcao_button = cena

# ==========================================
# LÓGICA DE ABERTURA E POPULAÇÃO
# ==========================================
func abrir(construcao: Node):
	construcao_atual = construcao
	
	# Atualiza o título se a construção tiver nome
	if construcao_atual.get("nome_construcao"):
		titulo.text = "Upgrade: " + construcao_atual.nome_construcao
	else:
		titulo.text = "Upgrade da Construção"
		
	_atualizar_opcoes()
	
	# Mostra a tela e pausa o jogo para o jogador escolher em paz
	show()
	get_tree().paused = true

func _atualizar_opcoes():
	# Limpa os botões antigos
	for child in opcoes_container.get_children():
		child.queue_free()
		
	if not construcao_atual.has_method("get_opcoes_proximo_upgrade"):
		return
		
	var opcoes = construcao_atual.get_opcoes_proximo_upgrade()
	
	# Caso a torre já esteja no nível máximo
	if opcoes.size() == 0:
		var label_max = Label.new()
		label_max.text = "Nível Máximo Alcançado!"
		opcoes_container.add_child(label_max)
		return
		
	# Instancia um botão para cada opção de upgrade disponível (Paths ou Linha Única)
	for opcao in opcoes:
		if cena_opcao_button:
			var btn = cena_opcao_button.instantiate()
			# A mágica que impede o botão de sumir: forçamos um tamanho!
			btn.custom_minimum_size = Vector2(160, 180) 
			opcoes_container.add_child(btn)
			
			if btn.has_method("configurar"):
				btn.configurar(opcao)
				
			btn.pressed.connect(_on_opcao_escolhida.bind(opcao.get("index", 0)))

# ==========================================
# AÇÕES DO JOGADOR
# ==========================================
func _on_opcao_escolhida(index: int):
	if construcao_atual and construcao_atual.has_method("aplicar_upgrade"):
		var sucesso = construcao_atual.aplicar_upgrade(index)
		
		if sucesso:
			fechar()
		else:
			print("Sem moedas suficientes para esse upgrade!")
			# Aqui você pode adicionar um feedback visual no futuro se o jogador não tiver moedas

func fechar():
	construcao_atual = null
	hide()
	fechado.emit() # A HUD escuta isso para despausar o jogo
