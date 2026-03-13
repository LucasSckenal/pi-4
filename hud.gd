extends CanvasLayer

# --- REFERÊNCIAS DA INTERFACE ---
@onready var label_wave = $InterfacePrincipal/CentroTela/LabelWave
@onready var botao_noite = $InterfacePrincipal/MarginInferior/CenterContainer/BotaoNoite
@onready var label_moedas = $InterfacePrincipal/MarginDireita/VBoxDireita/FundoMoedas/LabelMoedas

# Referência da animação do baú 3D (Se o caminho der erro de "null", 
# basta apagar o caminho, arrastar o AnimationPlayer da árvore e soltar aqui!)
@onready var anim_bau = $InterfacePrincipal/MarginDireita/VBoxDireita/ContainerBau/SubViewport/chest2/AnimationPlayer

func _ready():
	# Entra no grupo para escutar os comandos do jogo!
	add_to_group("Interface")
	
	# Garante que o texto da wave comece invisível
	if label_wave != null:
		label_wave.modulate.a = 0.0 
	
	# Conecta o botão de iniciar a noite
	if botao_noite != null:
		botao_noite.pressed.connect(_on_botao_noite_pressed)
	
	atualizar_moedas()
	verificar_estado_dia_noite()

# =======================================
# LÓGICA DO DIA E NOITE
# =======================================
func verificar_estado_dia_noite():
	if botao_noite != null:
		if GameManager.is_night:
			botao_noite.hide()
		else:
			botao_noite.show()

func _on_botao_noite_pressed():
	print("CLIQUEI NO BOTÃO DE INICIAR A NOITE!") # <-- Adicione esta linha!
	if not GameManager.is_night:
		if botao_noite != null:
			botao_noite.hide()
		GameManager.iniciar_noite()

# =======================================
# EFEITO DE FADE DA WAVE (CINEMATOGRÁFICO)
# =======================================
func mostrar_wave_na_tela(texto: String):
	if label_wave == null: return
	
	label_wave.text = texto
	var tween = create_tween()
	
	# Fade In (Aparece em 1 segundo)
	tween.tween_property(label_wave, "modulate:a", 1.0, 1.0)
	# Espera 2 segundos na tela
	tween.tween_interval(2.0)
	# Fade Out (Some em 1 segundo)
	tween.tween_property(label_wave, "modulate:a", 0.0, 1.0)

# =======================================
# LÓGICA DAS MOEDAS E BAÚ
# =======================================
func atualizar_moedas():
	if label_moedas != null: 
		label_moedas.text = "💰 " + str(GameManager.moedas)

func animar_bau_abrindo():
	if anim_bau != null:
		anim_bau.play("open") # Toca a animação de abrir
		await get_tree().create_timer(1.0).timeout # Espera 1 segundo
		anim_bau.play_backwards("open") # Fecha o baú
	else:
		print("AVISO: AnimationPlayer do baú não encontrado na HUD!")



func _on_botao_iniciar_noite_pressed() -> void:
	pass # Replace with function body.
