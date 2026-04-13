extends MarginContainer

# --- REFERÊNCIAS: ZOOM ---
@onready var btn_lupa_mais = $AreaInterativa/HBoxZoom/VBoxLupas/BtnLupaMais
@onready var btn_lupa_menos = $AreaInterativa/HBoxZoom/VBoxLupas/BtnLupaMenos
@onready var indicador_caixas = $AreaInterativa/HBoxZoom/VBoxIndicadorZoom.get_children()

# --- REFERÊNCIAS: MENU & VELOCIDADE (ÓRBITA) ---
@onready var btn_menu_gigante = $AreaInterativa/BtnMenuGigante
@onready var btn_lento = $AreaInterativa/GrupoVelocidades/BtnLento
@onready var btn_normal = $AreaInterativa/GrupoVelocidades/BtnNormal
@onready var btn_rapido = $AreaInterativa/GrupoVelocidades/BtnRapido
@onready var grupo_velocidades = $AreaInterativa/GrupoVelocidades 

# Lógica do Zoom
var nivel_zoom_atual = 1
const MAX_NIVEIS_ZOOM = 4

# Estilos recuperados da cena
var estilo_caixa_cheia: StyleBoxFlat
var estilo_caixa_vazia: StyleBoxFlat
var estilo_vel_ativa: StyleBoxFlat
var estilo_vel_inativa: StyleBoxFlat

# Controle de Tempo e Estado
var jogo_pausado: bool = false
var ultima_velocidade: float = 1.0

func _ready():
	# Garante que as quebras de linha sejam respeitadas pelo motor
	btn_lento.text = ">\nLENTO"
	btn_normal.text = ">>\nNORMAL"
	btn_rapido.text = ">>>\nRÁPIDO"

	# Guarda os estilos
	estilo_caixa_vazia = indicador_caixas[0].get_theme_stylebox("panel")
	estilo_caixa_cheia = indicador_caixas[3].get_theme_stylebox("panel")
	estilo_vel_ativa = btn_normal.get_theme_stylebox("normal")
	estilo_vel_inativa = btn_lento.get_theme_stylebox("normal")

	# Sinais de Zoom
	btn_lupa_mais.pressed.connect(_zoom_aproximar)
	btn_lupa_menos.pressed.connect(_zoom_afastar)
	btn_menu_gigante.pressed.connect(_on_menu_pressionado)

	# Sinais de Velocidade
	btn_lento.pressed.connect(func(): _alterar_velocidade(0.5, btn_lento))
	btn_normal.pressed.connect(func(): _alterar_velocidade(1.0, btn_normal))
	btn_rapido.pressed.connect(func(): _alterar_velocidade(2.0, btn_rapido))
	
	# Conexões para atualizar o botão de acordo com a fase do jogo
	if GameManager.has_signal("dia_iniciado"):
		GameManager.dia_iniciado.connect(_ao_iniciar_dia)
	if GameManager.has_signal("noite_iniciada"):
		GameManager.noite_iniciada.connect(_ao_iniciar_noite)

	if GameManager.estado_atual == GameManager.EstadoJogo.DIA:
		btn_menu_gigante.text = "▶"
		grupo_velocidades.hide()
	else:
		btn_menu_gigante.text = "❚❚"
		grupo_velocidades.show()
	
	# Inicia visual
	_atualizar_caixas_zoom()
	_alterar_velocidade(1.0, btn_normal)

# --- ZOOM ---
func _zoom_aproximar():
	if nivel_zoom_atual < MAX_NIVEIS_ZOOM:
		nivel_zoom_atual += 1
		_atualizar_caixas_zoom()

func _zoom_afastar():
	if nivel_zoom_atual > 1:
		nivel_zoom_atual -= 1
		_atualizar_caixas_zoom()

func _atualizar_caixas_zoom():
	var caixas_invertidas = indicador_caixas.duplicate()
	caixas_invertidas.reverse() # Para preencher de baixo para cima
	
	for i in range(caixas_invertidas.size()):
		if i < nivel_zoom_atual:
			caixas_invertidas[i].add_theme_stylebox_override("panel", estilo_caixa_cheia)
		else:
			caixas_invertidas[i].add_theme_stylebox_override("panel", estilo_caixa_vazia)
			
	_aplicar_fov_na_camera()

func _aplicar_fov_na_camera():
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Lógica simples de FOV (ajuste os valores conforme o seu jogo)
		var fov_calculado = 90.0 - ((nivel_zoom_atual) * 15.0)
		camera.fov = fov_calculado

# --- GERENCIAMENTO DE ESTADO DIA/NOITE ---
func _ao_iniciar_dia(_onda):
	jogo_pausado = false
	_alterar_velocidade(1.0, btn_normal)
	btn_menu_gigante.text = "▶"
	grupo_velocidades.hide()

func _ao_iniciar_noite(_onda):
	jogo_pausado = false
	btn_menu_gigante.text = "❚❚"
	grupo_velocidades.show()

# --- VELOCIDADE & MENU ---
func _on_menu_pressionado():
	if GameManager.estado_atual == GameManager.EstadoJogo.DIA:
		#if not GameManager.is_tutorial_ativo:
			GameManager.iniciar_noite()
	else:
		if jogo_pausado:
			_retomar_jogo()
		else:
			_pausar_jogo()

func _pausar_jogo():
	jogo_pausado = true
	ultima_velocidade = Engine.time_scale
	Engine.time_scale = 0.0
	btn_menu_gigante.text = "▶❚"

func _retomar_jogo():
	jogo_pausado = false
	Engine.time_scale = ultima_velocidade
	btn_menu_gigante.text = "❚❚"

func _alterar_velocidade(multiplicador: float, botao_clicado: Button):
	ultima_velocidade = multiplicador
	
	if not jogo_pausado:
		Engine.time_scale = multiplicador
	
	var botoes = [btn_lento, btn_normal, btn_rapido]
	for b in botoes:
		b.add_theme_stylebox_override("normal", estilo_vel_inativa)
		b.add_theme_color_override("font_color", Color(1, 1, 1)) # Texto branco quando inativo
		
	botao_clicado.add_theme_stylebox_override("normal", estilo_vel_ativa)
	botao_clicado.add_theme_color_override("font_color", Color(0, 0, 0)) # Texto preto quando ativo (Destaque)
