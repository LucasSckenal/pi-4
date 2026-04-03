extends Control

var painel_cena = preload("res://Cenas Locais/painel_conquista.tscn")

# Lista que vai guardar as conquistas
var banco_conquistas: Array[ConquistaData] = []

@onready var lista_container = $ScrollContainer/ListaConquistas

func _ready():
	# 1. Carrega automaticamente os ficheiros .tres da sua pasta!
	# IMPORTANTE: Altere "res://Conquistas/" para a pasta real onde guarda as suas conquistas.
	_carregar_conquistas_da_pasta("res://Conquistas/") 
	
	# 2. Limpa os itens de teste que possam estar no editor
	for child in lista_container.get_children():
		child.queue_free()
		
	# 3. Cria os painéis no ecrã
	for conquista in banco_conquistas:
		if conquista != null:
			criar_painel(conquista)

# Função nova para poupar trabalho: Carrega todos os ficheiros da pasta sozinhos!
func _carregar_conquistas_da_pasta(caminho_pasta: String):
	var dir = DirAccess.open(caminho_pasta)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Procura por ficheiros de conquistas (.tres ou .res)
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource = load(caminho_pasta + "/" + file_name)
				if resource is ConquistaData:
					banco_conquistas.append(resource)
			file_name = dir.get_next()

func criar_painel(conquista: ConquistaData):
	var novo_painel = painel_cena.instantiate()
	lista_container.add_child(novo_painel)
	
	# Procura os nós (textos e imagens)
	var icone_rect = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/Icone")
	var nome_label = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/NomeLabel")
	var desc_label = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/DescricaoLabel")
	var miniatura_container = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/MiniaturaContainer")
	
	# Verifica no Global se esta conquista já foi ganha
	var esta_liberada = conquista.id in Global.conquistas_desbloqueadas
	
	# Preenche o Nome, Descrição e Ícone
	if nome_label: nome_label.text = conquista.nome
	if desc_label: desc_label.text = conquista.descricao
	if icone_rect and conquista.icone != null: icone_rect.texture = conquista.icone
		
	# Esconde o antigo "slot_personagem" que já não existe no seu jogo atual
	if miniatura_container:
		miniatura_container.hide()
		
	# Faz a magia da silhueta escurecida
	if not esta_liberada:
		# Se estiver bloqueada, o painel fica escuro/cinzento
		novo_painel.modulate = Color(0.3, 0.3, 0.3, 0.8) 
	else:
		# Se já ganhou, fica com a cor normal e brilhante
		novo_painel.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
