extends CanvasLayer

var _btn_voltar: Button
var _btn_sair_fase: Button
var _btn_sair_jogo: Button

func _ready():
	_btn_voltar    = $CenterContainer/VBoxContainer/BotaoVoltar
	_btn_sair_fase = $CenterContainer/VBoxContainer/BotaoSair
	_btn_sair_jogo = Button.new()

	# Renomeia o segundo botão para "Sair da Fase"
	_btn_sair_fase.text = "SAIR DA FASE"
	_btn_sair_fase.add_theme_color_override("font_hover_color", Color(1.0, 0.80, 0.3, 1))

	# Adiciona botão "Sair do Jogo" abaixo
	_btn_sair_jogo.text = "SAIR DO JOGO"
	_btn_sair_jogo.custom_minimum_size = Vector2(300, 80)
	_btn_sair_jogo.add_theme_color_override("font_hover_color", Color(1, 0.31, 0.31, 1))
	_btn_sair_jogo.add_theme_font_size_override("font_size", 32)
	$CenterContainer/VBoxContainer.add_child(_btn_sair_jogo)

	_btn_voltar.pressed.connect(_on_voltar_pressed)
	_btn_sair_fase.pressed.connect(_on_sair_fase_pressed)
	_btn_sair_jogo.pressed.connect(_on_sair_jogo_pressed)

	hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if visible:
			_on_voltar_pressed()
		else:
			_abrir()
		get_viewport().set_input_as_handled()

func _abrir():
	show()
	get_tree().paused = true

func _on_voltar_pressed():
	hide()
	get_tree().paused = false

func _on_sair_fase_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/Menus/seletor_fases.tscn")

func _on_sair_jogo_pressed():
	get_tree().quit()
