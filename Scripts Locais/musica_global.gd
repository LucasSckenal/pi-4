extends AudioStreamPlayer

var musica_menu = preload("res://Musicas/MenuMusicTeste.mp3")
var musica_tutorial = preload("res://Musicas/MenuMusicTeste.mp3")  #Só mudar a música quando acharmos ela

# Função chamada pelos menus para garantir que o tema principal esteja tocando
func tocar_menu():
	if stream != musica_menu:
		stream = musica_menu
		play()

# Função chamada pelas fases para alterar o ambiente musical
func tocar_tutorial():
	if stream != musica_tutorial:
		stream = musica_tutorial
		play()
