extends CanvasLayer

const ESTRELA_CHEIA = preload("res://Icons/star.png")
const ESTRELA_VAZIA = preload("res://Icons/star_outline_depth.png")

@onready var painel = $CenterContainer/Painel
@onready var vbox = $CenterContainer/Painel/Margin/VBox
@onready var titulo = $CenterContainer/Painel/Margin/VBox/Titulo
@onready var subtitulo = $CenterContainer/Painel/Margin/VBox/Subtitulo
@onready var btn_proxima = $CenterContainer/Painel/Margin/VBox/BtnProximaFase
@onready var btn_menu = $CenterContainer/Painel/Margin/VBox/BtnMenu

var _estrelas_row: HBoxContainer = null
var _label_stats: Label = null

func _ready():
	hide()
	btn_proxima.pressed.connect(_on_proxima_fase_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	GameManager.vitoria.connect(mostrar_tela)
	# Cria a linha de estrelas e o rótulo de estatísticas (entram após o subtítulo)
	_estrelas_row = HBoxContainer.new()
	_estrelas_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_estrelas_row.add_theme_constant_override("separation", 14)
	vbox.add_child(_estrelas_row)
	vbox.move_child(_estrelas_row, 2)
	for i in range(3):
		var empty_star_texture := TextureRect.new()
		empty_star_texture.texture = ESTRELA_VAZIA
		empty_star_texture.custom_minimum_size = Vector2(64, 64)
		empty_star_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		empty_star_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		empty_star_texture.pivot_offset = Vector2(32, 32)
		_estrelas_row.add_child(empty_star_texture)
	_label_stats = Label.new()
	_label_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_stats.add_theme_font_size_override("font_size", 20)
	_label_stats.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(_label_stats)
	vbox.move_child(_label_stats, 3)

func mostrar_tela():
	show()
	get_tree().paused = false
	GameManager.apagar_save()

	var fase: int = GameManager.fase_atual
	var estrelas: int = Global.estrelas_por_fase.get(str(fase), 1)
	var eh_ultima: bool = not GameManager.banco_de_fases.has(fase + 1)

	# Título / subtítulo (especial na última fase)
	if eh_ultima:
		titulo.text = "PARABÉNS!"
		subtitulo.text = "Você encontrou todos os netos!"
		btn_proxima.hide()
	else:
		titulo.text = "VITÓRIA!"
		subtitulo.text = "Fase concluída!"
		btn_proxima.show()

	# Estatísticas da partida
	_label_stats.text = "Inimigos derrotados: %d" % GameManager.inimigos_mortos_sessao

	# Estado inicial das estrelas (vazias e escondidas)
	for empty_star_texture in _estrelas_row.get_children():
		empty_star_texture.texture = ESTRELA_VAZIA
		empty_star_texture.scale = Vector2.ZERO
		empty_star_texture.modulate = Color(1, 1, 1, 0)

	# Pop do painel
	painel.scale = Vector2(0.1, 0.1)
	painel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(painel, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(painel, "modulate:a", 1.0, 0.3)

	# Estrelas surgindo uma a uma (as conquistadas viram douradas com "snap")
	_animar_estrelas(estrelas)

func _animar_estrelas(qtd: int) -> void:
	var estrelas = _estrelas_row.get_children()
	for i in range(estrelas.size()):
		var star_texture: TextureRect = estrelas[i]
		var conquistada := i < qtd
		var atraso := 0.45 + i * 0.25
		var tw := star_texture.create_tween()
		tw.tween_interval(atraso)
		tw.tween_callback(func():
			star_texture.texture = ESTRELA_CHEIA if conquistada else ESTRELA_VAZIA
			star_texture.modulate = Color(1, 1, 1, 1) if conquistada else Color(0.55, 0.55, 0.55, 0.9)
		)
		# pop com overshoot
		var alvo := Vector2(1.25, 1.25) if conquistada else Vector2(1.0, 1.0)
		tw.tween_property(star_texture, "scale", alvo, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if conquistada:
			tw.tween_property(star_texture, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)

func _on_proxima_fase_pressed():
	hide()
	GameManager.ir_para_proxima_fase()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
