extends Control

@onready var painel_principal = $CenterContainer/PainelPrincipal
@onready var escurecer_fundo = $EscurecerFundo
@onready var valor_onda = $CenterContainer/PainelPrincipal/VBoxContainer/HBoxStatus/PainelDias/VBoxDias/ValorDias
@onready var valor_moedas = $CenterContainer/PainelPrincipal/VBoxContainer/HBoxStatus/PainelMoedas/VBoxMoedas/ValorMoedas

func _ready():
	hide()

func mostrar():
	if GameManager:
		var dias_completos = max(0, GameManager.onda_atual - 1)
		valor_onda.text = str(dias_completos)
		valor_moedas.text = str(GameManager.moedas)
	
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
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
