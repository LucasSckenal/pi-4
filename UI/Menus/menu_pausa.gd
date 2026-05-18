extends CanvasLayer

var _btn_voltar:    Button
var _btn_repetir:   Button
var _btn_sair_fase: Button
var _btn_sair_jogo: Button

var _time_scale_antes_pause: float = 1.0

func _ready():
	_btn_voltar    = $CenterContainer/VBoxContainer/BotaoVoltar
	_btn_repetir   = $CenterContainer/VBoxContainer/BotaoRepetir
	_btn_sair_fase = $CenterContainer/VBoxContainer/BotaoSair
	_btn_sair_jogo = Button.new()

	_btn_voltar.mouse_default_cursor_shape    = Control.CURSOR_POINTING_HAND
	_btn_repetir.mouse_default_cursor_shape   = Control.CURSOR_POINTING_HAND
	_btn_sair_fase.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Botão "Sair da Fase"
	_btn_sair_fase.text = "SAIR DA FASE"
	_btn_sair_fase.add_theme_color_override("font_hover_color", Color(1.0, 0.80, 0.3, 1))
	
	hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if visible:
			_on_voltar_pressed()
		else:
			_abrir()
		get_viewport().set_input_as_handled()

func _abrir():
	_time_scale_antes_pause = Engine.time_scale
	Engine.time_scale       = 0.0
	get_tree().paused       = true
	show()

func _on_voltar_pressed():
	hide()
	get_tree().paused = false
	Engine.time_scale = _time_scale_antes_pause  # restaura velocidade anterior

func _on_repetir_pressed():
	Engine.time_scale = 1.0        # reseta velocidade antes de recarregar
	GameManager.reiniciar_partida()

func _on_sair_fase_pressed():
	Engine.time_scale = 1.0        # reseta velocidade antes de sair
	get_tree().paused = false
	GameManager.limpar_estado_sessao()
	MusicaGlobal.tocar_menu()
	get_tree().change_scene_to_file("res://UI/Menus/seletor_fases.tscn")

func _on_sair_jogo_pressed():
	get_tree().quit()
