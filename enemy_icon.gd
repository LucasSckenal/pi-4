extends Control

@onready var label = $BolhaNumero/Quantidade
@onready var texture_rect = $Fundo/TextureRect
@onready var color_rect = $Fundo/ColorRect
@onready var seta = $Seta

# Atualiza a rotação e a posição do indicador visual de direção (órbita)
func atualizar_seta(angulo_radianos: float):
	if seta:
		# Rotação da seta para apontar para o alvo
		seta.rotation = angulo_radianos
		
		# Define o raio da órbita (distância do centro do ícone até a seta)
		# Aumente esse valor se a seta estiver colidindo com o círculo
		var raio_orbita = 45.0 
		var centro = size / 2.0
		
		# Calcula a posição orbital usando trigonometria
		var pos_x = cos(angulo_radianos) * raio_orbita
		var pos_y = sin(angulo_radianos) * raio_orbita
		
		# Posiciona a seta subtraindo a metade do próprio tamanho para centralizá-la no ponto exato
		seta.position = centro + Vector2(pos_x, pos_y) - (seta.size / 2.0)

func configurar(icone: Texture2D, cor: Color, qtd: int):
	# Ícone ou fallback colorido
	if icone:
		texture_rect.show()
		color_rect.hide()
		texture_rect.texture = icone
	else:
		texture_rect.hide()
		color_rect.show()
		color_rect.color = cor
	
	label.text = str(qtd)
