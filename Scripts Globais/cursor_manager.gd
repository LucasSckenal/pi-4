extends Node

# Carregue as texturas aqui
var cursor_normal = preload("res://Icons/Cursor/cursor.png")
var cursor_link = preload("res://Icons/Cursor/cursor_cogs.png")
var cursor_disabled = preload("res://Icons/Cursor/cursor_disabled.png")

func _ready():
	# Define o cursor padrão
	Input.set_custom_mouse_cursor(cursor_normal)
	
	# Define o cursor de "mãozinha" (Pointing Hand)
	Input.set_custom_mouse_cursor(cursor_link, Input.CURSOR_POINTING_HAND)
	
	# Define o cursor bloqueado
	Input.set_custom_mouse_cursor(cursor_disabled, Input.CURSOR_FORBIDDEN)
