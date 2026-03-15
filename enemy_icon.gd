extends Control

@onready var fundo = $Fundo
@onready var container = $Container
@onready var label = $Container/Quantidade
@onready var texture_rect = $Container/TextureRect
@onready var color_rect = $Container/ColorRect

func configurar(icone: Texture2D, cor: Color, qtd: int):
	# Fundo mais circular (aumentei o corner radius)
	var style_fundo = StyleBoxFlat.new()
	style_fundo.bg_color = Color(0, 0, 0, 0.6)
	style_fundo.corner_radius_top_left = 40
	style_fundo.corner_radius_top_right = 40
	style_fundo.corner_radius_bottom_left = 40
	style_fundo.corner_radius_bottom_right = 40
	fundo.add_theme_stylebox_override("panel", style_fundo)
	
	# Ícone ou fallback colorido
	if icone:
		texture_rect.show()
		color_rect.hide()
		texture_rect.texture = icone
		texture_rect.size = Vector2(32, 32)
	else:
		texture_rect.hide()
		color_rect.show()
		var style = StyleBoxFlat.new()
		style.bg_color = cor
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 20
		color_rect.add_theme_stylebox_override("panel", style)
		color_rect.size = Vector2(32, 32)
	
	label.text = str(qtd)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	# Garante a ordem: ícone em cima, label embaixo
	# Move o ícone para a posição 0 e o label para a posição 1
	if icone:
		container.move_child(texture_rect, 0)
	else:
		container.move_child(color_rect, 0)
	container.move_child(label, 1)
