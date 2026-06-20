extends CanvasLayer

const TELA_CONFIGURACOES = preload("res://UI/Menus/configuracoes.tscn")

var _btn_voltar:  Button
var _btn_repetir: Button
var _btn_sair:    Button
var _btn_config:  Button

var _time_scale_antes_pause: float = 1.0

func _ready():
	_btn_voltar  = $Centro/PainelPrincipal/VBoxContainer/BotaoVoltar
	_btn_repetir = $Centro/BotoesRow/VBoxRepetir/BotaoRepetir
	_btn_sair    = $Centro/BotoesRow/VBoxSair/BotaoSair
	_btn_config  = $Centro/BotoesRow/VBoxConfig/BotaoConfiguracoes

	_btn_voltar.mouse_default_cursor_shape  = Control.CURSOR_POINTING_HAND
	_btn_repetir.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_sair.mouse_default_cursor_shape    = Control.CURSOR_POINTING_HAND
	_btn_config.mouse_default_cursor_shape  = Control.CURSOR_POINTING_HAND

	hide()

func _unhandled_input(event: InputEvent) -> void:
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
	Engine.time_scale = _time_scale_antes_pause

func _on_configuracoes_pressed():
	# Esconde o miolo do menu de pausa para não ficar bagunçado atrás da tela de config
	$Centro.hide()
	
	# Cria a tela de configurações
	var config_instancia = TELA_CONFIGURACOES.instantiate()
	
	# Adiciona ela na tela (como filha do menu de pausa)
	add_child(config_instancia)
	
	# Conecta o sinal que você já criou no configuracoes.gd
	config_instancia.fechar_configuracoes.connect(func():
		config_instancia.queue_free() # Destrói a tela de configurações
		$Centro.show()                # Mostra os botões do pause novamente
	)

func _on_repetir_pressed():
	Engine.time_scale = 1.0
	GameManager.reiniciar_partida()

func _on_sair_fase_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameManager.limpar_estado_sessao()
	MusicaGlobal.tocar_menu()
	get_tree().change_scene_to_file("res://UI/Menus/seletor_fases.tscn")

func _on_sair_jogo_pressed():
	get_tree().quit()
