extends Node

# Carregue as texturas aqui
var cursor_normal = preload("res://Assets/Cursor/cursor.png")
var cursor_link = preload("res://Assets/Cursor/cursor_cogs.png")
var cursor_disabled = preload("res://Assets/Cursor/cursor_disabled.png")
var cursor_build = preload("res://Assets/Cursor/cursor_build.png")
var cursor_upgrade = preload("res://Assets/Cursor/cursor_upgrade.png")

func _ready():
	# Define o cursor padrão
	Input.set_custom_mouse_cursor(cursor_normal)
	
	# Define o cursor de "mãozinha" (Pointing Hand)
	Input.set_custom_mouse_cursor(cursor_link, Input.CURSOR_POINTING_HAND)
	
	# Define o cursor bloqueado
	Input.set_custom_mouse_cursor(cursor_disabled, Input.CURSOR_FORBIDDEN)

	# Define o cursor para dar upgrade
	Input.set_custom_mouse_cursor(cursor_upgrade, Input.CURSOR_DRAG)
	
	# Define o cursor para construir
	Input.set_custom_mouse_cursor(cursor_build, Input.CURSOR_CROSS)
	
