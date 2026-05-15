extends MarginContainer

@onready var btn_lupa_mais: Button = $AreaInterativa/HBoxZoom/VBoxLupas/BtnLupaMais
@onready var btn_lupa_menos: Button = $AreaInterativa/HBoxZoom/VBoxLupas/BtnLupaMenos
@onready var indicador_caixas = $AreaInterativa/HBoxZoom/VBoxIndicadorZoom.get_children()

@onready var btn_menu_gigante: Button = $AreaInterativa/BtnMenuGigante
@onready var btn_lento: Button = $AreaInterativa/GrupoVelocidades/BtnLento
@onready var btn_normal: Button = $AreaInterativa/GrupoVelocidades/BtnNormal
@onready var btn_rapido: Button = $AreaInterativa/GrupoVelocidades/BtnRapido
@onready var grupo_velocidades: Control = $AreaInterativa/GrupoVelocidades

const TEX_PLAY = preload("res://Assets/UI/BotaoPlay.png")
const TEX_PAUSE = preload("res://Assets/UI/BotaoPause.png")
const TEX_RESUME = preload("res://Assets/UI/BotaoResume.png")

var nivel_zoom_atual := 1
const MAX_NIVEIS_ZOOM := 4

var estilo_caixa_cheia: StyleBox
var estilo_caixa_vazia: StyleBox
var estilo_vel_ativa: StyleBox
var estilo_vel_inativa: StyleBox

var jogo_pausado := false
var ultima_velocidade := 1.0

func _ready() -> void:
	btn_lento.text = ">\nLENTO"
	btn_normal.text = ">>\nNORMAL"
	btn_rapido.text = ">>>\nRAPIDO"

	estilo_caixa_vazia = indicador_caixas[0].get_theme_stylebox("panel")
	estilo_caixa_cheia = indicador_caixas[3].get_theme_stylebox("panel")
	estilo_vel_ativa = btn_normal.get_theme_stylebox("normal")
	estilo_vel_inativa = btn_lento.get_theme_stylebox("normal")

	btn_lupa_mais.pressed.connect(_zoom_aproximar)
	btn_lupa_menos.pressed.connect(_zoom_afastar)
	btn_menu_gigante.pressed.connect(_on_menu_pressionado)

	_configurar_animacao_hover(btn_lupa_mais)
	_configurar_animacao_hover(btn_lupa_menos)
	_configurar_animacao_hover(btn_menu_gigante)

	for btn in [btn_lento, btn_normal, btn_rapido]:
		btn.add_theme_color_override("font_hover_color", Color.BLACK)
		btn.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
		_configurar_animacao_hover(btn)

	btn_lento.pressed.connect(func(): _alterar_velocidade(0.5, btn_lento))
	btn_normal.pressed.connect(func(): _alterar_velocidade(1.0, btn_normal))
	btn_rapido.pressed.connect(func(): _alterar_velocidade(2.0, btn_rapido))

	if GameManager.has_signal("dia_iniciado"):
		GameManager.dia_iniciado.connect(_ao_iniciar_dia)
	if GameManager.has_signal("noite_iniciada"):
		GameManager.noite_iniciada.connect(_ao_iniciar_noite)

	if GameManager.estado_atual == GameManager.EstadoJogo.DIA:
		_definir_icone_menu(TEX_PLAY)
		grupo_velocidades.hide()
	else:
		_definir_icone_menu(TEX_PAUSE)
		grupo_velocidades.show()

	_atualizar_caixas_zoom()
	_alterar_velocidade(1.0, btn_normal)

func _zoom_aproximar() -> void:
	if nivel_zoom_atual < MAX_NIVEIS_ZOOM:
		nivel_zoom_atual += 1
		_atualizar_caixas_zoom()

func _zoom_afastar() -> void:
	if nivel_zoom_atual > 1:
		nivel_zoom_atual -= 1
		_atualizar_caixas_zoom()

func _atualizar_caixas_zoom() -> void:
	var caixas_invertidas := indicador_caixas.duplicate()
	caixas_invertidas.reverse()

	for i in range(caixas_invertidas.size()):
		if i < nivel_zoom_atual:
			caixas_invertidas[i].add_theme_stylebox_override("panel", estilo_caixa_cheia)
		else:
			caixas_invertidas[i].add_theme_stylebox_override("panel", estilo_caixa_vazia)

	_aplicar_fov_na_camera()

func _aplicar_fov_na_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		camera.fov = 90.0 - (nivel_zoom_atual * 15.0)

func _ao_iniciar_dia(_onda) -> void:
	jogo_pausado = false
	_alterar_velocidade(1.0, btn_normal)
	_definir_icone_menu(TEX_PLAY)
	grupo_velocidades.hide()

func _ao_iniciar_noite(_onda) -> void:
	jogo_pausado = false
	_definir_icone_menu(TEX_PAUSE)
	grupo_velocidades.show()

func _on_menu_pressionado() -> void:
	if GameManager.estado_atual == GameManager.EstadoJogo.DIA:
		GameManager.iniciar_noite()
	else:
		if jogo_pausado:
			_retomar_jogo()
		else:
			_pausar_jogo()

func _pausar_jogo() -> void:
	jogo_pausado = true
	ultima_velocidade = Engine.time_scale
	Engine.time_scale = 0.0
	_definir_icone_menu(TEX_RESUME)

func _retomar_jogo() -> void:
	jogo_pausado = false
	Engine.time_scale = ultima_velocidade
	_definir_icone_menu(TEX_PAUSE)

func _definir_icone_menu(textura: Texture2D) -> void:
	if is_instance_valid(btn_menu_gigante):
		btn_menu_gigante.icon = textura
		btn_menu_gigante.text = ""

func _alterar_velocidade(multiplicador: float, botao_clicado: Button) -> void:
	ultima_velocidade = multiplicador

	if not jogo_pausado:
		Engine.time_scale = multiplicador

	for botao in [btn_lento, btn_normal, btn_rapido]:
		botao.add_theme_stylebox_override("normal", estilo_vel_inativa)
		botao.add_theme_color_override("font_color", Color.WHITE)

	botao_clicado.add_theme_stylebox_override("normal", estilo_vel_ativa)
	botao_clicado.add_theme_color_override("font_color", Color.BLACK)

func verificar_estado_dia_noite() -> void:
	if GameManager.estado_atual == GameManager.EstadoJogo.DIA:
		jogo_pausado = false
		_alterar_velocidade(1.0, btn_normal)

		if is_instance_valid(btn_menu_gigante):
			btn_menu_gigante.disabled = false
			_definir_icone_menu(TEX_PLAY)

		if is_instance_valid(grupo_velocidades):
			grupo_velocidades.hide()

func _configurar_animacao_hover(botao: Button) -> void:
	if botao.custom_minimum_size != Vector2.ZERO:
		botao.pivot_offset = botao.custom_minimum_size / 2.0
	else:
		botao.pivot_offset = botao.size / 2.0
	
	botao.mouse_entered.connect(func():
		var tween := create_tween()
		tween.tween_property(botao, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
	)
	
	botao.mouse_exited.connect(func():
		var tween := create_tween()
		tween.tween_property(botao, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	)
