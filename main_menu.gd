extends Control

# Esse botão vai carregar o jogo
func _on_btn_jogar_pressed():
	# Substitua o caminho abaixo pelo caminho exato da sua cena principal (World)!
	get_tree().change_scene_to_file("res://World.tscn")

# Esse botão vai abrir a tela de escolher o boneco
func _on_btn_customizar_pressed():
	print("Mudar para a tela de Customização!")
	get_tree().change_scene_to_file("res://selecao_personagem.tscn")

# Esse botão vai abrir as opções
func _on_btn_configuracoes_pressed():
	print("Mudar para a tela de Configurações!")
	# Futuramente colocamos a tela de volume/gráficos aqui
