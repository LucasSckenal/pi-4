extends Control

@onready var painel_principal = $CenterContainer/PainelPrincipal
@onready var escurecer_fundo = $EscurecerFundo
@onready var valor_onda = $CenterContainer/PainelPrincipal/VBoxContainer/HBoxStatus/PainelDias/VBoxDias/ValorDias
@onready var valor_moedas = $CenterContainer/PainelPrincipal/VBoxContainer/HBoxStatus/PainelMoedas/VBoxMoedas/ValorMoedas

var _info_recorde: VBoxContainer = null

func _ready():
	hide()
	# Bloco de recorde do modo infinito (criado uma vez, mostrado só no infinito)
	var vbox = $CenterContainer/PainelPrincipal/VBoxContainer
	_info_recorde = VBoxContainer.new()
	_info_recorde.alignment = BoxContainer.ALIGNMENT_CENTER
	_info_recorde.add_theme_constant_override("separation", 4)
	var lbl_rec := Label.new()
	lbl_rec.name = "LabelRecorde"
	lbl_rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rec.add_theme_font_size_override("font_size", 22)
	lbl_rec.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	_info_recorde.add_child(lbl_rec)
	var lbl_novo := Label.new()
	lbl_novo.name = "LabelNovoRecorde"
	lbl_novo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_novo.add_theme_font_size_override("font_size", 28)
	lbl_novo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl_novo.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl_novo.add_theme_constant_override("outline_size", 5)
	lbl_novo.text = "🏆 NOVO RECORDE! 🏆"
	_info_recorde.add_child(lbl_novo)
	vbox.add_child(_info_recorde)
	vbox.move_child(_info_recorde, 1)  # logo abaixo do status
	_info_recorde.hide()

func mostrar():
	
	SFXManager.tocar_defeat()
	
	if GameManager:
		var dias_completos = max(0, GameManager.onda_atual - 1)
		valor_onda.text = str(dias_completos)
		valor_moedas.text = str(GameManager.moedas)

	# Recorde — só no modo infinito
	if GameManager and GameManager.modo_infinito:
		_info_recorde.show()
		_info_recorde.get_node("LabelRecorde").text = "Melhor onda: %d" % Global.melhor_onda_infinito
		var lbl_novo: Label = _info_recorde.get_node("LabelNovoRecorde")
		lbl_novo.visible = GameManager.novo_recorde_infinito
		if GameManager.novo_recorde_infinito:
			lbl_novo.scale = Vector2.ZERO
			lbl_novo.pivot_offset = lbl_novo.size / 2.0
			var tw_r := lbl_novo.create_tween()
			tw_r.tween_interval(0.5)
			tw_r.tween_property(lbl_novo, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_info_recorde.hide()

	show()
	escurecer_fundo.modulate.a = 0.0
	painel_principal.modulate.a = 0.0
	painel_principal.scale = Vector2(0.6, 0.6)
	painel_principal.pivot_offset = painel_principal.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(escurecer_fundo, "modulate:a", 1.0, 0.3)
	tween.tween_property(painel_principal, "modulate:a", 1.0, 0.4)
	tween.tween_property(painel_principal, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ==========================================
# NOVOS BOTÕES
# ==========================================

func _on_botao_repetir_noite_pressed():
	get_tree().paused = false
	if GameManager.has_method("reiniciar_noite_atual"):
		GameManager.reiniciar_noite_atual()
	hide()

func _on_botao_reiniciar_pressed():
	if GameManager.has_method("reiniciar_partida"):
		GameManager.reiniciar_partida()
	hide()

func _on_botao_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/Menus/main_menu.tscn")
