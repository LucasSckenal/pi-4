extends Control

@onready var label        = $BolhaNumero/Quantidade
@onready var texture_rect = $Fundo/TextureRect
@onready var color_rect   = $Fundo/ColorRect

var _conveyor: Control = null

func _ready():
	# Esconde a seta orbital legada
	var seta_antiga = get_node_or_null("Seta")
	if seta_antiga:
		seta_antiga.hide()

	_criar_conveyor()

func _criar_conveyor():
	_conveyor = Control.new()
	_conveyor.name = "Conveyor"
	_conveyor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var larg := 54.0
	var alt  := 20.0
	_conveyor.custom_minimum_size = Vector2(larg, alt)
	_conveyor.pivot_offset = Vector2(larg * 0.5, alt * 0.5)
	add_child(_conveyor)

	for i in range(3):
		var lbl = Label.new()
		lbl.text = "▶"
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
		lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.custom_minimum_size = Vector2(18, 20)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(float(i) * 18.0, 0.0)
		lbl.name = "A" + str(i)
		lbl.modulate.a = 0.15
		_conveyor.add_child(lbl)

	_iniciar_animacao()

func _iniciar_animacao():
	var setas := []
	for i in range(3):
		var s = _conveyor.get_node_or_null("A" + str(i))
		if s:
			setas.append(s)
	if setas.size() < 3:
		return

	# Acende cada seta em sequência, criando efeito de esteira
	var tw = create_tween().set_loops()
	for s in setas:
		tw.tween_property(s, "modulate:a", 1.0,  0.07)
		tw.tween_interval(0.05)
		tw.tween_property(s, "modulate:a", 0.15, 0.20)
	tw.tween_interval(0.28)  # pausa antes de recomeçar

# Chamado a cada frame pela HUD com o ângulo centro→spawner.
# Inverte para spawner→base (direção real do caminho dos inimigos).
func atualizar_seta(angulo_radianos: float):
	if _conveyor == null:
		return

	var ang := angulo_radianos + PI  # spawner → base
	var centro := custom_minimum_size * 0.5
	var dist   := 46.0

	_conveyor.position = centro + Vector2(cos(ang), sin(ang)) * dist - _conveyor.pivot_offset
	_conveyor.rotation = ang

func configurar(icone: Texture2D, cor: Color, qtd: int, descricao: String = ""):
	if icone:
		texture_rect.show()
		color_rect.hide()
		texture_rect.texture = icone
	else:
		texture_rect.hide()
		color_rect.show()
		color_rect.color = cor

	label.text = str(qtd)
	tooltip_text = descricao
