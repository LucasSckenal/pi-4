extends AudioStreamPlayer

var musica_menu = preload("res://Musicas/MenuMusicTeste.mp3")
var musica_tutorial = preload("res://Musicas/Festival_In_The_High_Pines.mp3")  #Só mudar a música quando acharmos ela
var musica_deserto = preload("res://Musicas/Oasis_at_Noon.mp3")
var musica_covil = preload("res://Musicas/The_Serpent_s_Last_March.mp3")
var musica_bruxa = preload("res://Musicas/Crooked_Path_to_the_Bayou.mp3")

# Definindo propriedade para ter loop na música (agradecemos Bira pelo beta test ao vivo)
func _ready():
	musica_menu.loop = true
	musica_tutorial.loop = true
	musica_deserto.loop = true
	musica_covil.loop = true
	musica_bruxa.loop = true

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
		
func tocar_deserto():
	if stream != musica_deserto:
		stream = musica_deserto
		play()

func tocar_bruxa():
	if stream != musica_bruxa:
		stream = musica_bruxa
		play()

func tocar_aquatico():
	# Trocar pelo certo depois
	if stream != musica_tutorial:
		stream = musica_tutorial
		play()

func tocar_scifi():
	# Trocar pelo certo depois
	if stream != musica_tutorial:
		stream = musica_tutorial
		play()

func tocar_covil():
	if stream != musica_covil:
		stream = musica_covil
		play()
