extends Control

# Pega o índice do canal principal de áudio do Godot
var master_bus = AudioServer.get_bus_index("Master")

func _ready():
	# Ajusta a barrinha pro volume atual (convertendo de Decibéis para linear 0 a 1)
	var volume_db = AudioServer.get_bus_volume_db(master_bus)
	
	# Usamos o $% para achar o HSlider em qualquer lugar da tela
	if $%HSlider:
		$%HSlider.value = db_to_linear(volume_db)
	else:
		print("Aviso: Não esqueça de colocar o '%' no HSlider clicando com o botão direito!")


# ---------------------------------------------------
# LIGUE O SINAL 'value_changed' DO HSLIDER AQUI:
# ---------------------------------------------------
func _on_h_slider_value_changed(value: float) -> void:
	# Converte o valor da barrinha (0 a 1) para Decibéis e aplica no jogo todo!
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))


# ---------------------------------------------------
# LIGUE O SINAL 'pressed' DO BUTTON "VOLTAR" AQUI:
# ---------------------------------------------------

func _on_button_pressed() -> void:
	print("Salvando configurações e voltando pro menu...")
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
