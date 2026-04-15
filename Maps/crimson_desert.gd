extends Node3D

@onready var anim_player = $DayNightAnimator

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = false
	
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	
	await get_tree().process_frame
	
	GameManager.carregar_fase(2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_dia_iniciado(_onda_atual: int) -> void:
	print("Dia iniciado!!!!")
	if anim_player and anim_player.has_animation("transicao_para_dia"):
		anim_player.play("transicao_para_dia")
		

# Executa a transição de iluminação e ambiente para o ciclo da noite
func _on_noite_iniciada(_onda_atual: int) -> void:
	print("Noite iniciada!!!!")
	if anim_player and anim_player.has_animation("transicao_para_noite"):
		anim_player.play("transicao_para_noite")
