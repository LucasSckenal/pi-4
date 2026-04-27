extends Node3D

@onready var anim_player = $DayNightAnimator

func _ready():
	get_tree().paused = false
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.carregar_fase(3)
	MusicaGlobal.tocar_bruxa()

func _on_dia_iniciado(_onda_atual: int) -> void:
	if anim_player and anim_player.has_animation("transicao_para_dia"):
		anim_player.play("transicao_para_dia")

func _on_noite_iniciada(_onda_atual: int) -> void:
	if anim_player and anim_player.has_animation("transicao_para_noite"):
		anim_player.play("transicao_para_noite")
