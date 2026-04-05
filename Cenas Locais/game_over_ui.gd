extends Control

@onready var painel_principal = $CenterContainer/PainelPrincipal
@onready var escurecer_fundo = $EscurecerFundo
@onready var valor_onda = $CenterContainer/PainelPrincipal/VBoxContainer/HBoxStatus/PainelDias/VBoxDias/ValorDias
@onready var valor_moedas = $CenterContainer/PainelPrincipal/VBoxContainer/HBoxStatus/PainelMoedas/VBoxMoedas/ValorMoedas
@onready var botao_reiniciar = $CenterContainer/PainelPrincipal/VBoxContainer/BotaoReiniciar

func _ready():
	hide()

func mostrar():
	if GameManager:
		var dias_completos = max(0, GameManager.onda_atual - 1)
		valor_onda.text = str(dias_completos)
		valor_moedas.text = str(GameManager.moedas)
	
	# Prepara os nós para a animação
	show()
	escurecer_fundo.modulate.a = 0.0
	painel_principal.modulate.a = 0.0
	painel_principal.scale = Vector2(0.6, 0.6)
	
	# Força o centro geométrico para o painel escalar a partir do meio
	painel_principal.pivot_offset = painel_principal.size / 2.0
	
	# Animação de entrada
	var tween = create_tween().set_parallel(true)
	tween.tween_property(escurecer_fundo, "modulate:a", 1.0, 0.3)
	tween.tween_property(painel_principal, "modulate:a", 1.0, 0.4)
	tween.tween_property(painel_principal, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_botao_reiniciar_pressed():
	if Input.is_joy_known(0): 
		Input.vibrate_handheld(50) 
		
	botao_reiniciar.disabled = true

	# Animação de saída
	painel_principal.pivot_offset = painel_principal.size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(painel_principal, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	
	await tween.finished
	
	hide()
	modulate.a = 1.0
	botao_reiniciar.disabled = false
	
	GameManager.reiniciar_partida()
