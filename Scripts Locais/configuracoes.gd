extends Control

signal fechar_configuracoes

const SETTINGS_PATH = "user://settings.cfg"

var master_bus: int = -1

# Variáveis temporárias para o preview do cursor não afetar o jogo imediatamente
var temp_cursor_size: float = 1.5
var temp_cursor_color: Color = Color.WHITE

@onready var _slider_master:  HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardAudio/MarginAudio/VBoxAudio/HBoxMaster/SliderMaster")
@onready var _lbl_master:     Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardAudio/MarginAudio/VBoxAudio/HBoxMaster/LabelPctMaster")

@onready var _slider_musica:  HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardAudio/MarginAudio/VBoxAudio/HBoxMusica/SliderMusica")
@onready var _lbl_musica:     Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardAudio/MarginAudio/VBoxAudio/HBoxMusica/LabelPctMusica")

@onready var _slider_voz:     HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardAudio/MarginAudio/VBoxAudio/HBoxVoz/SliderVoz")
@onready var _lbl_voz:        Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardAudio/MarginAudio/VBoxAudio/HBoxVoz/LabelPctVoz")

@onready var _check_mudo:     CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardVideo/MarginVideo/VBoxVideo/CheckMudo")
@onready var _check_tela:     CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardVideo/MarginVideo/VBoxVideo/CheckTelaCheia")
@onready var _check_hud:      CheckButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Esquerda/CardVideo/MarginVideo/VBoxVideo/CheckHUD")

@onready var _slider_cursor:  HSlider     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Direita/CardCursor/MarginCursor/VBoxCursor/HBoxCursor/SliderCursor")
@onready var _lbl_cursor:     Label       = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Direita/CardCursor/MarginCursor/VBoxCursor/HBoxCursor/LabelScaleCursor")
@onready var _color_picker:   ColorPickerButton = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Direita/CardCursor/MarginCursor/VBoxCursor/ColorPickerCursor")

@onready var _preview_cursor: TextureRect = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Direita/CardCursor/MarginCursor/VBoxCursor/PreviewArea/PreviewCursor")

@onready var _card_cursor:    Control     = get_node_or_null("CenterContainer/Painel/Margin/VBoxRoot/Conteudo/Direita")

func _ready():
	master_bus = AudioServer.get_bus_index("Master")
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
		
		if _slider_cursor:
			_slider_cursor.value = temp_cursor_size
			_lbl_cursor.text = "%.1fx" % temp_cursor_size
		
		if _color_picker:
			_color_picker.color = temp_cursor_color
			
		if _preview_cursor:
			_atualizar_preview_cursor()

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
# SINAIS DOS CONTROLES
# ==========================================
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

func _on_check_hud_toggled(_toggled_on: bool) -> void:
	pass

func _on_cursor_scale_changed(value: float) -> void:
	temp_cursor_size = value
	if _lbl_cursor:
		_lbl_cursor.text = "%.1fx" % value
	_atualizar_preview_cursor()

func _on_cursor_color_changed(color: Color) -> void:
	temp_cursor_color = color
	_atualizar_preview_cursor()

func _on_btn_salvar_pressed() -> void:
	if has_node("/root/CursorManager"):
		var manager = get_node("/root/CursorManager")
		manager.set_cursor_scale(temp_cursor_size)
		manager.set_cursor_color(temp_cursor_color)
		
	_salvar_configuracoes()

func _on_btn_equipe_pressed() -> void:
	pass

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
		_check_hud.button_pressed = cfg.get_value("video", "hud_customizado", true)
		
	temp_cursor_size = cfg.get_value("cursor", "tamanho", 1.5)
	temp_cursor_color = cfg.get_value("cursor", "cor", Color.WHITE)
