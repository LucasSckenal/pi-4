extends Control

signal fechar_configuracoes

const SETTINGS_PATH = "user://settings.cfg"

var master_bus: int = -1

@onready var _slider_master:  HSlider     = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxMaster/HSlider")
@onready var _lbl_master:     Label       = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxMaster/LabelPctMaster")
@onready var _slider_musica:  HSlider     = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxMusica/HSliderMusica")
@onready var _lbl_musica:     Label       = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxMusica/LabelPctMusica")
@onready var _check_mudo:     CheckButton = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CheckMudo")
@onready var _check_tela:     CheckButton = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CheckTelaCheia")

func _ready():
	master_bus = AudioServer.get_bus_index("Master")
	_carregar_configuracoes()

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
	_salvar_configuracoes()

func _on_slider_musica_changed(value: float) -> void:
	var mg = get_node_or_null("/root/MusicaGlobal")
	if mg:
		mg.volume_db = linear_to_db(value)
	_atualizar_pct(_lbl_musica, value)
	_salvar_configuracoes()

func _on_check_mudo_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(master_bus, toggled_on)
	_salvar_configuracoes()

func _on_check_tela_cheia_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_salvar_configuracoes()

func _on_button_pressed() -> void:
	fechar_configuracoes.emit()

# ==========================================
# PERSISTÊNCIA
# ==========================================
func _salvar_configuracoes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master",  db_to_linear(AudioServer.get_bus_volume_db(master_bus)))
	cfg.set_value("audio", "musica",  _musica_linear())
	cfg.set_value("audio", "mudo",    AudioServer.is_bus_mute(master_bus))
	cfg.set_value("video", "tela_cheia",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
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

	var mudo: bool = cfg.get_value("audio", "mudo", false)
	AudioServer.set_bus_mute(master_bus, mudo)

	var tela_cheia: bool = cfg.get_value("video", "tela_cheia", false)
	if tela_cheia:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
