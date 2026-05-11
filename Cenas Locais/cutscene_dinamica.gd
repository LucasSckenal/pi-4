extends CanvasLayer

@export var caminho_proxima_fase: String = ""

@onready var animador = $AnimationPlayer
@onready var aviso_pular = $AvisoPular

func _ready():
	# Inicia a animação que vamos criar chamada "animacao_cutscene"
	animador.play("animacao_cutscene")
	# Fica de olho para quando ela acabar
	animador.animation_finished.connect(_on_animacao_terminou)

func _on_animacao_terminou(_anim_name):
	# Quando acaba, avisa o jogador
	aviso_pular.text = "Clique para Continuar!"
	aviso_pular.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))

func _input(event):
	# Pula a cena com clique do mouse ou Enter/Espaço
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		ir_para_fase()
	elif event.is_action_pressed("ui_accept"):
		ir_para_fase()

func ir_para_fase():
	if caminho_proxima_fase != "":
		get_tree().change_scene_to_file(caminho_proxima_fase)
	else:
		print("ERRO: Caminho da próxima fase não foi preenchido no Inspetor!")
