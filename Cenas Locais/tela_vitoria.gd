extends CanvasLayer

@onready var painel = $CenterContainer/Painel
@onready var btn_proxima = $CenterContainer/Painel/Margin/VBox/BtnProximaFase
@onready var btn_menu = $CenterContainer/Painel/Margin/VBox/BtnMenu

func _ready():
	# Esconde no início
	hide()
	
	# Conecta os botões
	btn_proxima.pressed.connect(_on_proxima_fase_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	# Ouve o sinal do GameManager para aparecer
	GameManager.vitoria.connect(mostrar_tela)

func mostrar_tela():
	show()
	get_tree().paused = true # Pausa o jogo
	
	# Invalida o save para que a fase concluída não possa ser continuada posteriormente
	GameManager.apagar_save()
	
	# Efeito visual do painel "saltando" na tela (Tween)
	painel.scale = Vector2(0.1, 0.1)
	painel.modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(painel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(painel, "modulate:a", 1.0, 0.3)

func _on_proxima_fase_pressed():
	get_tree().paused = false
	# Aqui você avança a fase. Exemplo:
	GameManager.carregar_fase(GameManager.fase_atual + 1)
	hide()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas Locais/main_menu.tscn")
