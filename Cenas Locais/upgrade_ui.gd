extends Control

@onready var titulo = $VBoxContainer/Titulo
@onready var opcoes_container = $VBoxContainer/OpcoesContainer
@onready var botao_fechar = $VBoxContainer/BotaoFechar

@export var cena_opcao_button: PackedScene

var construcao_atual: Node = null
signal fechado

func _ready():
	botao_fechar.pressed.connect(_fechar)
	hide()

func abrir(construcao: Node):
	construcao_atual = construcao
	
	# Atualiza título
	if construcao.has_method("get_nome_construcao"):
		titulo.text = "Upgrade: " + construcao.nome_construcao
	else:
		titulo.text = "Upgrade da Construção"
	
	# Limpa opções antigas
	for child in opcoes_container.get_children():
		child.queue_free()
	
	# Pega opções da construção
	if construcao.has_method("get_opcoes_upgrade"):
		var opcoes = construcao.get_opcoes_upgrade()
		
		if opcoes.size() == 0:
			# Sem upgrades disponíveis
			var label = Label.new()
			label.text = "Nível máximo atingido!"
			opcoes_container.add_child(label)
		else:
			# Cria um botão para cada opção
			for opcao in opcoes:
				var btn = cena_opcao_button.instantiate()
				opcoes_container.add_child(btn)
				btn.configurar(opcao)
				btn.pressed.connect(_on_upgrade_pressed.bind(opcao.index))
	
	show()
	get_tree().paused = true

func _on_upgrade_pressed(index: int):
	if construcao_atual and construcao_atual.has_method("aplicar_upgrade"):
		if construcao_atual.aplicar_upgrade(index):
			# Se aplicou, recarrega a UI
			abrir(construcao_atual)
		else:
			print("Falha ao aplicar upgrade (moedas insuficientes?)")

func _fechar():
	hide()
	fechado.emit()
	get_tree().paused = false
