extends Node

# Carregue as texturas aqui
var cursor_normal = preload("res://Assets/Cursor/cursor.png")
var cursor_link = preload("res://Assets/Cursor/cursor_cogs.png")
var cursor_disabled = preload("res://Assets/Cursor/cursor_disabled.png")
var cursor_build = preload("res://Assets/Cursor/cursor_build.png")
var cursor_upgrade = preload("res://Assets/Cursor/cursor_upgrade.png")

## Offset do hotspot do cursor (coordenadas de pixel que é considerado o ponto de clique)
@export var cursor_offset = Vector2(10, 10)

##
@export var cursor_size: float = 1.5

##
@export var cursor_color: Color = Color.WHITE

func _ready():
	update_cursors()

## Aplica as configurações de tamanho e cor aos cursores
func update_cursors():
	var scaled_normal = _prepare_cursor(cursor_normal)
	var scaled_link = _prepare_cursor(cursor_link)
	var scaled_disabled = _prepare_cursor(cursor_disabled)
	var scaled_upgrade = _prepare_cursor(cursor_upgrade)
	var scaled_build = _prepare_cursor(cursor_build)
	var final_offset = cursor_offset * cursor_size

	Input.set_custom_mouse_cursor(scaled_normal, Input.CURSOR_ARROW, final_offset)
	Input.set_custom_mouse_cursor(scaled_link, Input.CURSOR_POINTING_HAND, final_offset)
	Input.set_custom_mouse_cursor(scaled_disabled, Input.CURSOR_FORBIDDEN, final_offset)
	Input.set_custom_mouse_cursor(scaled_upgrade, Input.CURSOR_DRAG, final_offset)
	Input.set_custom_mouse_cursor(scaled_build, Input.CURSOR_CROSS, final_offset)

func _prepare_cursor(tex: Texture2D) -> ImageTexture:
	var img = tex.get_image()
	if img.is_compressed():
		img.decompress()
	
	# Recolorir: Substitui pixels brancos pela cor escolhida
	if cursor_color != Color.WHITE:
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var pixel = img.get_pixel(x, y)
				# Verifica se o pixel é branco (ou muito próximo de branco) e não é transparente
				if pixel.r > 0.5 and pixel.g > 0.5 and pixel.b > 0.5 and pixel.a > 0:
					img.set_pixel(x, y, cursor_color)
	
	var new_width = int(img.get_width() * cursor_size)
	var new_height = int(img.get_height() * cursor_size)
	
	img.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
	
	return ImageTexture.create_from_image(img)

## Altera o tamanho do cursor e recarrega as texturas
func set_cursor_scale(scale: float) -> void:
	cursor_size = scale
	update_cursors()

## Altera a cor do cursor e recarrega as texturas
func set_cursor_color(color: Color) -> void:
	cursor_color = color
	update_cursors()
