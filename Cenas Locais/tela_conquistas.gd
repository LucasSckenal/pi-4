extends Control

var painel_cena = preload("res://Cenas Locais/painel_conquista.tscn")
var slot_cena = preload("res://Cenas Locais/slot_personagem.tscn") # <-- Puxamos seu slot aqui!

@onready var lista_container = $ScrollContainer/ListaConquistas

func _ready():
	for child in lista_container.get_children():
		child.queue_free()
		
	for conquista in Global.banco_conquistas:
		if conquista != null:
			criar_painel(conquista)

func criar_painel(conquista):
	var novo_painel = painel_cena.instantiate()
	lista_container.add_child(novo_painel)
	
	# Busca os nós dentro da nova estrutura com MarginContainer
	# Ajuste o caminho se a sua árvore estiver um pouquinho diferente
	var icone_rect = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/Icone")
	var nome_label = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/NomeLabel")
	var desc_label = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/DescricaoLabel")
	var miniatura_container = novo_painel.get_node_or_null("MarginContainer/HBoxContainer/MiniaturaContainer")
	
	var esta_liberada = Global.status_conquistas.get(conquista.id, false)
	
	# --- 1. PREENCHENDO TEXTOS E ÍCONE ---
	if nome_label: nome_label.text = conquista.nome
	if desc_label: desc_label.text = conquista.descricao
	if icone_rect and conquista.icone != null: icone_rect.texture = conquista.icone
		
	# --- 2. A MÁGICA DA SILHUETA DO PERSONAGEM ---
	var index = conquista.libera_personagem_index
	
	# Verifica se essa conquista dá um personagem (index >= 0)
	if index >= 0 and index < Global.lista_personagens.size() and miniatura_container:
		var caminho_personagem = Global.lista_personagens[index]
		
		# Cria o quadradinho do personagem e coloca na tela
		var miniatura = slot_cena.instantiate()
		miniatura_container.add_child(miniatura)
		
		# Força a miniatura a ficar centralizada e com tamanho fixo
		miniatura.custom_minimum_size = Vector2(320, 320) # Troque 80 pelo tamanho que achar melhor
		
		# Faz o boneco aparecer
		if miniatura.has_method("configurar_slot"):
			miniatura.configurar_slot(caminho_personagem)
			
		# Desativa o botão (já que é só para visualizar, não para jogar)
		var btn = miniatura.get_node_or_null("Button")
		if btn: btn.disabled = true
			
		# O SEGREDO DA SILHUETA: Se estiver bloqueado, pinta quase tudo de preto
		if not esta_liberada:
			miniatura.modulate = Color(0.05, 0.05, 0.05, 1.0) # Preto misterioso
		else:
			miniatura.modulate = Color(1.0, 1.0, 1.0, 1.0) # Cores normais
			
	# --- 3. COR DO PAINEL GERAL ---
	if esta_liberada:
		novo_painel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		novo_painel.modulate = Color(0.5, 0.5, 0.5, 1.0) # Painel escurinho


func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
