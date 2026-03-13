extends CanvasLayer

@onready var label_wave = $InterfacePrincipal/CentroTela/LabelWave
@onready var botao_noite = $InterfacePrincipal/MarginInferior/CenterContainer/BotaoIniciarNoite
@onready var label_moedas = $InterfacePrincipal/MarginDireita/VBoxDireita/FundoMoedas/LabelMoedas
@onready var anim_bau = $InterfacePrincipal/MarginDireita/VBoxDireita/ContainerBau/chest2/AnimationPlayer

func _ready():
	# Garante que o texto da wave comece invisível
	label_wave.modulate.a = 0.0 
	
	if botao_noite:
		botao_noite.pressed.connect(_on_botao_noite_pressed)
	
	atualizar_moedas()
	verificar_estado_dia_noite()

# =======================================
# LÓGICA DO DIA E NOITE
# =======================================

func verificar_estado_dia_noite():
	if GameManager.is_night:
		botao_noite.hide()
	else:
		botao_noite.show()

func _on_botao_noite_pressed():
	if not GameManager.is_night:
		botao_noite.hide()
		GameManager.iniciar_noite()
		# Assim que a noite começa, chamamos a animação da Wave!
		mostrar_wave_na_tela("ONDA " + str(GameManager.onda_atual))

# =======================================
# EFEITO DE FADE DA WAVE (CINEMATOGRÁFICO)
# =======================================

func mostrar_wave_na_tela(texto: String):
	label_wave.text = texto
	
	# Cria a animação (Tween) para fazer o fade in e fade out
	var tween = create_tween()
	
	# 1. Faz o texto aparecer suavemente (Fade In) em 1 segundo
	tween.tween_property(label_wave, "modulate:a", 1.0, 1.0)
	
	# 2. Deixa o texto na tela por 2 segundos
	tween.tween_interval(2.0)
	
	# 3. Faz o texto sumir suavemente (Fade Out) em 1 segundo
	tween.tween_property(label_wave, "modulate:a", 0.0, 1.0)


# =======================================
# LÓGICA DAS MOEDAS E BAÚ
# =======================================

func atualizar_moedas():
	if label_moedas: 
		label_moedas.text = "💰 " + str(GameManager.moedas)

func animar_bau_abrindo():
	if anim_bau != null:
		# Toca a sua animação com o nome exato da imagem
		anim_bau.play("open") 
		
		# Espera 1 segundo
		await get_tree().create_timer(1.0).timeout
		
		# Toca a animação "open" de trás pra frente para o baú fechar!
		anim_bau.play_backwards("open")
	else:
		print("Erro: O AnimationPlayer não foi encontrado!")
