extends Control

signal fechar_configuracoes

var master_bus = AudioServer.get_bus_index("Master")

func _ready():
	# 1. Ajustar a barrinha pro volume atual
	var volume_db = AudioServer.get_bus_volume_db(master_bus)
	if $%HSlider:
		$%HSlider.value = db_to_linear(volume_db)
		
	# 2. Ajustar o botão de Mudo pro estado atual
	if $%CheckMudo:
		$%CheckMudo.button_pressed = AudioServer.is_bus_mute(master_bus)
		
	# 3. Ajustar o botão de Tela Cheia pro estado atual do monitor
	if $%CheckTelaCheia:
		var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		$%CheckTelaCheia.button_pressed = is_fullscreen

# ==========================================
# SINAIS (AÇÕES DOS BOTÕES)
# ==========================================

# Quando mexe na barrinha de Volume
func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	# Extra: Se o jogador aumentar o volume, tiramos o Mudo automaticamente!
	if value > 0 and AudioServer.is_bus_mute(master_bus):
		AudioServer.set_bus_mute(master_bus, false)
		if $%CheckMudo: $%CheckMudo.button_pressed = false

# Quando liga/desliga o Mudo
func _on_check_mudo_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(master_bus, toggled_on)

# Quando liga/desliga a Tela Cheia
func _on_check_tela_cheia_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Quando clica em Voltar
func _on_button_pressed() -> void:
	fechar_configuracoes.emit()
