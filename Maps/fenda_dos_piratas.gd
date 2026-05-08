extends Node3D
@export var conquista_fim_Fenda: ConquistaData
const BolhasFundo = preload("res://Cenas Locais/bolhas_fundo.tscn")

func _ready():
	get_tree().paused = false
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)
	await get_tree().process_frame
	GameManager.carregar_fase(4)
	MusicaGlobal.tocar_aquatico()
	add_child(BolhasFundo.instantiate())

func _on_dia_iniciado(_onda_atual: int) -> void:
	pass

func _on_noite_iniciada(_onda_atual: int) -> void:
	pass

func _on_fase_vencida():
	Global.processar_recompensa(conquista_fim_Fenda)
