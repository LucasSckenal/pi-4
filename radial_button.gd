extends TextureButton

var cena_construcao: PackedScene
var ui_ref: Control

func configurar(cena: PackedScene, ui: Control):
	cena_construcao = cena
	ui_ref = ui
	
	# Estilização via código
	custom_minimum_size = Vector2(80, 80)
	size = Vector2(80, 80)
	
	# Cor de fundo (usando TextureRect virtual, mas TextureButton não tem cor direta)
	# Vamos criar uma textura procedural simples
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color8(70, 130, 180, 200))  # Azul aço semi-transparente
	
	# Desenha uma borda branca
	for x in range(80):
		img.set_pixel(x, 0, Color.WHITE)
		img.set_pixel(x, 79, Color.WHITE)
	for y in range(80):
		img.set_pixel(0, y, Color.WHITE)
		img.set_pixel(79, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(img)
	texture_normal = texture
	texture_pressed = texture  # mesma textura (ou podia escurecer)
	
	# Conecta sinais
	pressed.connect(_on_pressed)

func _on_pressed():
	# Informa ao menu que este botão foi pressionado
	ui_ref.botao_pressionado(cena_construcao)
