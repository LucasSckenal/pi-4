extends Control

signal fechar_configuracoes

const SETTINGS_PATH = "user://settings.cfg"

var master_bus: int = -1

# Variáveis temporárias para o preview não afetar o jogo imediatamente (salvas apenas no salvar)
var temp_cursor_size: float = 1.5
var temp_cursor_color: Color = Color.WHITE
var temp_qualidade_3d: int = 2 # 0 = Baixa, 1 = Média, 2 = Alta

# Referências de Áudio
@onready var _slider_master:  HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaAudio/CardAudio/MarginAudio/VBoxAudio/HBoxMaster/SliderMaster")
@onready var _lbl_master:     Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaAudio/CardAudio/MarginAudio/VBoxAudio/HBoxMaster/LabelPctMaster")

@onready var _slider_musica:  HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaAudio/CardAudio/MarginAudio/VBoxAudio/HBoxMusica/SliderMusica")
@onready var _lbl_musica:     Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaAudio/CardAudio/MarginAudio/VBoxAudio/HBoxMusica/LabelPctMusica")

@onready var _slider_voz:     HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaAudio/CardAudio/MarginAudio/VBoxAudio/HBoxVoz/SliderVoz")
@onready var _lbl_voz:        Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaAudio/CardAudio/MarginAudio/VBoxAudio/HBoxVoz/LabelPctVoz")

# Referências de Vídeo
@onready var _check_mudo:     CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaVideo/CardVideo/MarginVideo/VBoxVideo/CheckMudo")
@onready var _check_tela:     CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaVideo/CardVideo/MarginVideo/VBoxVideo/CheckTelaCheia")
@onready var _check_hud:      CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaVideo/CardVideo/MarginVideo/VBoxVideo/CheckHUD")
@onready var _check_shake:    CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaVideo/CardVideo/MarginVideo/VBoxVideo/CheckShakeTela")

# Referências de Cursor
@onready var _preview_cursor: TextureRect = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaCursor/CardCursor/MarginCursor/VBoxCursor/PreviewArea/PreviewCursor")
@onready var _card_cursor:    Control     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaCursor")

# Referência do Painel da Equipe
@onready var _painel_equipe:  ColorRect   = get_node_or_null("FundoEquipe")

func _ready():
	master_bus = AudioServer.get_bus_index("Master")

	# Garante que o painel da equipe comece invisível
	if _painel_equipe:
		_painel_equipe.hide()

	_configurar_icones()
	_carregar_configuracoes()

	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		if _card_cursor:
			_card_cursor.hide()

	if _slider_master:
		_slider_master.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
		_atualizar_pct(_lbl_master, _slider_master.value)

	if _slider_musica:
		_slider_musica.value = _musica_linear()
		_atualizar_pct(_lbl_musica, _slider_musica.value)

	if _check_mudo:
		_check_mudo.button_pressed = AudioServer.is_bus_mute(master_bus)

	if _check_tela:
		_check_tela.button_pressed = (
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		
	if has_node("/root/CursorManager"):
		var manager = get_node("/root/CursorManager")
		temp_cursor_size = manager.cursor_size
		temp_cursor_color = manager.cursor_color
			
		if _preview_cursor:
			_atualizar_preview_cursor()

# ==========================================
# ÍCONES DOS BOTÕES
# ==========================================
func _configurar_icones() -> void:
	var base = "CenterContainer/Painel/Margin/VBoxRoot/Rodape/"
	_set_icon(base + "BtnVoltar",  "res://Assets/Menu/IconeVoltar.png")
	_set_icon(base + "BtnEquipe",  "res://Assets/Menu/IconeEquipe.png")
	_set_icon(base + "BtnSalvar",  "res://Assets/Menu/IconeSalvar.png")

func _set_icon(node_path: String, texture_path: String, max_px: int = 38) -> void:
	var btn := get_node_or_null(node_path)
	if btn is Button:
		var tex := load(texture_path) as Texture2D
		if tex:
			btn.icon = tex
			btn.add_theme_constant_override("icon_max_width", max_px)

# ==========================================
# HELPERS
# ==========================================
func _atualizar_pct(lbl: Label, value: float) -> void:
	if lbl:
		lbl.text = "%d%%" % int(round(value * 100.0))

func _musica_linear() -> float:
	var mg = get_node_or_null("/root/MusicaGlobal")
	if mg:
		return db_to_linear(mg.volume_db)
	return 1.0

func _atualizar_preview_cursor() -> void:
	if _preview_cursor:
		_preview_cursor.modulate = temp_cursor_color
		_preview_cursor.custom_minimum_size = Vector2(48 * temp_cursor_size, 48 * temp_cursor_size)

# ==========================================
# SINAIS DOS CONTROLES DE ÁUDIO E VÍDEO
# ==========================================

const _Q_BASE := "CenterContainer/Painel/Margin/VBoxRoot/Conteudo/ColunaVideo/CardVideo/MarginVideo/VBoxVideo/HBoxQualidade/"
const _Q_NOMES := ["Mínima", "Baixa", "Média", "Alta"]
const _Q_PATHS := [
	_Q_BASE + "VBoxContainer/BtnQualidadeMinima",
	_Q_BASE + "VBoxContainer2/BtnQualidadeBaixa",
	_Q_BASE + "VBoxContainer/BtnQualidadeMedia",
	_Q_BASE + "VBoxContainer2/BtnQualidadeAlta",
]

# Aplica de facto a qualidade ao viewport (chamado no load e ao Salvar)
func _aplicar_qualidade_3d(nivel: int) -> void:
	temp_qualidade_3d = nivel
	var root_viewport = get_tree().root
	match nivel:
		0: # BAIXISSIMO (codinome: Qualidade Henrique) valor 0.25
			root_viewport.scaling_3d_scale = 0.25
			root_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		1: # Baixo valor 0.5
			root_viewport.scaling_3d_scale = 0.5
			root_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		2: # Médio valor 0.75
			root_viewport.scaling_3d_scale = 0.75
			root_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		3: # Alto valor 1
			root_viewport.scaling_3d_scale = 1.0
			root_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_atualizar_selecao_qualidade(nivel)

# Apenas seleciona (preview) — NÃO aplica ao viewport até clicar em Salvar
func _selecionar_qualidade_3d(nivel: int) -> void:
	temp_qualidade_3d = nivel
	_atualizar_selecao_qualidade(nivel)

# Destaca o botão escolhido e atualiza o rótulo "Qualidade 3D: <nome>"
func _atualizar_selecao_qualidade(nivel: int) -> void:
	for i in range(_Q_PATHS.size()):
		var btn := get_node_or_null(_Q_PATHS[i])
		if btn is Button:
			if i == nivel:
				btn.modulate = Color(1, 1, 1, 1)
				(btn as Button).add_theme_constant_override("outline_size", 0)
				btn.scale = Vector2(1.06, 1.06)
				btn.pivot_offset = btn.size / 2.0
			else:
				btn.modulate = Color(0.62, 0.62, 0.62, 1)
				btn.scale = Vector2.ONE
	var lbl := get_node_or_null(_Q_BASE + "../LabelQualidade") as Label
	if lbl:
		lbl.text = "Qualidade 3D:  %s" % _Q_NOMES[nivel]

func _on_btn_qualidade_minima_pressed() -> void:
	_selecionar_qualidade_3d(0)

func _on_btn_qualidade_baixa_pressed() -> void:
	_selecionar_qualidade_3d(1)

func _on_btn_qualidade_media_pressed() -> void:
	_selecionar_qualidade_3d(2)

func _on_btn_qualidade_alta_pressed() -> void:
	_selecionar_qualidade_3d(3)

func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	_atualizar_pct(_lbl_master, value)
	if value > 0 and AudioServer.is_bus_mute(master_bus):
		AudioServer.set_bus_mute(master_bus, false)
		if _check_mudo:
			_check_mudo.button_pressed = false

func _on_slider_musica_changed(value: float) -> void:
	var mg = get_node_or_null("/root/MusicaGlobal")
	if mg:
		mg.volume_db = linear_to_db(value)
	_atualizar_pct(_lbl_musica, value)
	
func _on_slider_voz_changed(value: float) -> void:
	_atualizar_pct(_lbl_voz, value)

func _on_check_mudo_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(master_bus, toggled_on)

func _on_check_tela_cheia_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_check_hud_toggled(toggled_on: bool) -> void:
	Global.hud_tematico_ativo = toggled_on
	get_tree().call_group("Interface", "aplicar_tema_hud")

func _on_check_shake_tela_toggled(toggled_on: bool) -> void:
	Global.shake_tela_ativo = toggled_on

# ==========================================
# SINAIS DO CURSOR (Tamanho)
# ==========================================
func _on_btn_pequeno_pressed() -> void:
	temp_cursor_size = 1.0
	_atualizar_preview_cursor()

func _on_btn_medio_pressed() -> void:
	temp_cursor_size = 1.5
	_atualizar_preview_cursor()

func _on_btn_grande_pressed() -> void:
	temp_cursor_size = 2.0
	_atualizar_preview_cursor()

# ==========================================
# SINAIS DO CURSOR (Cores)
# ==========================================
func _on_btn_branco_pressed() -> void:
	temp_cursor_color = Color.WHITE
	_atualizar_preview_cursor()

func _on_btn_ciano_pressed() -> void:
	temp_cursor_color = Color.CYAN
	_atualizar_preview_cursor()

func _on_btn_vermelho_pressed() -> void:
	temp_cursor_color = Color.RED
	_atualizar_preview_cursor()

func _on_btn_rosa_pressed() -> void:
	temp_cursor_color = Color("ff99c2")
	_atualizar_preview_cursor()

func _on_btn_gold_pressed() -> void:
	temp_cursor_color = Color(0.93, 0.72, 0.28, 1)
	_atualizar_preview_cursor()

func _on_btn_roxo_pressed() -> void:
	temp_cursor_color = Color("9933ff")
	_atualizar_preview_cursor()


# ==========================================
# SINAIS DOS BOTÕES DO RODAPÉ E DA EQUIPE
# ==========================================
func _on_btn_salvar_pressed() -> void:
	if has_node("/root/CursorManager"):
		var manager = get_node("/root/CursorManager")
		manager.set_cursor_scale(temp_cursor_size)
		manager.set_cursor_color(temp_cursor_color)

	# Só agora a qualidade gráfica escolhida é aplicada de facto ao viewport
	_aplicar_qualidade_3d(temp_qualidade_3d)

	_salvar_configuracoes()

# Abre o painel da equipe
func _on_btn_equipe_pressed() -> void:
	if _painel_equipe:
		_painel_equipe.show()

# Fecha o painel da equipe
func _on_button_fechar_equipe_pressed() -> void:
	if _painel_equipe:
		_painel_equipe.hide()

# Botão Voltar (Fecha o menu de configurações)
func _on_button_pressed() -> void:
	fechar_configuracoes.emit()


# ==========================================
# PERSISTÊNCIA
# ==========================================
func _salvar_configuracoes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master",  db_to_linear(AudioServer.get_bus_volume_db(master_bus)))
	cfg.set_value("audio", "musica",  _musica_linear())
	
	if _slider_voz:
		cfg.set_value("audio", "voz", _slider_voz.value)
		
	cfg.set_value("audio", "mudo",    AudioServer.is_bus_mute(master_bus))
	cfg.set_value("video", "tela_cheia", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	if _check_hud:
		cfg.set_value("video", "hud_customizado", _check_hud.button_pressed)

	cfg.set_value("video", "shake_tela", Global.shake_tela_ativo)
	cfg.set_value("video", "qualidade_3d", temp_qualidade_3d)
		
	cfg.set_value("cursor", "tamanho", temp_cursor_size)
	cfg.set_value("cursor", "cor", temp_cursor_color)
		
	cfg.save(SETTINGS_PATH)

func _carregar_configuracoes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	var vol_master: float = cfg.get_value("audio", "master", 1.0)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(vol_master))

	var vol_musica: float = cfg.get_value("audio", "musica", 1.0)
	var mg = get_node_or_null("/root/MusicaGlobal")
	if mg:
		mg.volume_db = linear_to_db(vol_musica)
		
	if _slider_voz:
		_slider_voz.value = cfg.get_value("audio", "voz", 1.0)

	var mudo: bool = cfg.get_value("audio", "mudo", false)
	AudioServer.set_bus_mute(master_bus, mudo)

	var tela_cheia: bool = cfg.get_value("video", "tela_cheia", false)
	if tela_cheia:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
	if _check_hud:
		var hud_on: bool = cfg.get_value("video", "hud_customizado", true)
		_check_hud.button_pressed = hud_on
		Global.hud_tematico_ativo = hud_on

	var shake_on: bool = cfg.get_value("video", "shake_tela", true)
	Global.shake_tela_ativo = shake_on
	if _check_shake:
		_check_shake.button_pressed = shake_on
		
	var qualidade_3d: int = cfg.get_value("video", "qualidade_3d", 2)
	_aplicar_qualidade_3d(qualidade_3d)
		
	temp_cursor_size = cfg.get_value("cursor", "tamanho", 1.5)
	temp_cursor_color = cfg.get_value("cursor", "cor", Color.WHITE)
