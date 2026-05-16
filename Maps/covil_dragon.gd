extends Node3D
@export var conquista_fim: ConquistaData

func _ready():
	get_tree().paused = false
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.total_spawners = 3
	GameManager.carregar_fase(6)
	MusicaGlobal.tocar_covil()
	GameManager.vitoria.connect(_on_fase_vencida)


func _on_dia_iniciado(_onda_atual: int) -> void:
	print("Dia iniciado!!!!")
	

func _on_noite_iniciada(_onda_atual: int) -> void:
	pass

func _on_fase_vencida():
	if conquista_fim != null:
		Global.processar_recompensa(conquista_fim)
