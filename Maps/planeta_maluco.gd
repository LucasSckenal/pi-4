extends Node3D
@export var conquista_fim_Espaco: ConquistaData

func _ready():
	get_tree().paused = false
	GameManager.total_spawners = 4
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.carregar_fase(5)
	MusicaGlobal.tocar_scifi()
	GameManager.vitoria.connect(_on_fase_vencida)

func _on_dia_iniciado(_onda_atual: int) -> void:
	pass

func _on_noite_iniciada(_onda_atual: int) -> void:
	pass

func _on_fase_vencida():
	Global.processar_recompensa(conquista_fim_Espaco)
