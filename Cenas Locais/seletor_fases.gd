extends Control

# Sinal para avisar o Menu Principal que queremos voltar
signal fechar_seletor

# 1. Mundo Tutorial
func _on_btn_tutorial_pressed() -> void:
	MusicaGlobal.tocar_tutorial()
	get_tree().change_scene_to_file("res://Maps/tutorial_world.tscn")

# 2. Covil do Dragão
func _on_btn_covil_pressed() -> void:
	MusicaGlobal.tocar_covil()
	get_tree().change_scene_to_file("res://Maps/Covil_Dragon.tscn")

# 3. Casa da Bruxa
func _on_btn_bruxa_pressed() -> void:
	MusicaGlobal.tocar_bruxa()
	get_tree().change_scene_to_file("res://Maps/Witch_house.tscn")

# Botão de Voltar
func _on_btn_voltar_pressed() -> void:
	fechar_seletor.emit()
