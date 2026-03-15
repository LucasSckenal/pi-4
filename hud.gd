extends CanvasLayer

# --- REFERÊNCIAS DA INTERFACE ---
@onready var label_wave = $InterfacePrincipal/CentroTela/LabelWave
@onready var botao_noite = $InterfacePrincipal/MarginInferior/CenterContainer/BotaoNoite
@onready var label_moedas = $InterfacePrincipal/MarginDireita/VBoxDireita/FundoMoedas/LabelMoedas
@export var cena_carta_ui: PackedScene

@onready var anim_bau = $InterfacePrincipal/MarginDireita/VBoxDireita/ContainerBau/SubViewport/chest2/AnimationPlayer

# --- REFERÊNCIAS DO SISTEMA DE UPGRADE ---
@onready var menu_upgrade = $InterfacePrincipal/MenuUpgrade
@onready var container_cartas = $InterfacePrincipal/MenuUpgrade/HBoxContainer
@onready var botao_reroll = $InterfacePrincipal/MenuUpgrade/BotaoReroll  # Botão de reroll

func _ready():
	# Entra no grupo para escutar os comandos do jogo!
	add_to_group("Interface")
	
	# Conecta o sinal do GameManager
	if GameManager.has_signal("mostrar_menu_upgrade"):
		GameManager.mostrar_menu_upgrade.connect(_on_abrir_menu_upgrade)
	
	menu_upgrade.hide()
	
	if label_wave != null:
		label_wave.modulate.a = 0.0 
	
	if botao_noite != null:
		if not botao_noite.pressed.is_connected(_on_botao_noite_pressed):
			botao_noite.pressed.connect(_on_botao_noite_pressed)
	
	# Conecta o botão de reroll
	if botao_reroll != null:
		botao_reroll.pressed.connect(_on_botao_reroll_pressed)
	
	atualizar_moedas()
	verificar_estado_dia_noite()

# =======================================
# LÓGICA DO DIA E NOITE
# =======================================
func verificar_estado_dia_noite():
	if botao_noite != null:
		botao_noite.visible = not GameManager.is_night

func _on_botao_noite_pressed():
	if not GameManager.is_night:
		GameManager.iniciar_noite()

# =======================================
# EFEITO DE FADE DA WAVE
# =======================================
func mostrar_wave_na_tela(texto: String):
	if label_wave == null: return
	
	label_wave.text = texto
	var tween = create_tween()
	tween.tween_property(label_wave, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(label_wave, "modulate:a", 0.0, 1.0)

# =======================================
# LÓGICA DAS MOEDAS E BAÚ
# =======================================
func atualizar_moedas():
	if label_moedas != null: 
		label_moedas.text = "💰 " + str(GameManager.moedas)

func animar_bau_abrindo():
	if anim_bau != null:
		anim_bau.play("open") 
		await get_tree().create_timer(1.0).timeout 
		anim_bau.play_backwards("open")

# =======================================
# SISTEMA DE UPGRADES (ROGUELIKE)
# =======================================
func _on_abrir_menu_upgrade(cartas_sorteadas):
	# 1. Limpa cartas antigas
	for crianca in container_cartas.get_children():
		crianca.queue_free()
	
	# 2. Mostra o menu e pausa o jogo
	menu_upgrade.show()
	get_tree().paused = true
	
	# 3. Cria as 3 cartas novas
	for dados in cartas_sorteadas:
		if cena_carta_ui != null:
			var nova_carta = cena_carta_ui.instantiate()
			container_cartas.add_child(nova_carta)
			
			if nova_carta.has_method("configurar"):
				nova_carta.configurar(dados) 
			
			nova_carta.pressed.connect(_ao_escolher_upgrade.bind(dados))
	
	# 4. Atualiza o estado do botão de reroll
	if botao_reroll != null:
		botao_reroll.disabled = GameManager.reroll_usado
		# Feedback visual se tiver moedas suficientes
		if GameManager.moedas < GameManager.custo_reroll:
			botao_reroll.modulate = Color(0.5, 0.5, 0.5)
		else:
			botao_reroll.modulate = Color(1, 1, 1)

func _ao_escolher_upgrade(dados):
	GameManager.aplicar_upgrade(dados)
	menu_upgrade.hide()
	get_tree().paused = false

# =======================================
# REROLL
# =======================================
func _on_botao_reroll_pressed():
	GameManager.rerolar_cartas()
	# O menu será atualizado automaticamente quando o sinal for emitido novamente
