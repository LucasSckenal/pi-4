extends Node3D # (Ou o tipo de nó que for o seu raiz)

func _ready():
	# 1. Carrega a Fase 1 (10 moedas, nível 0, construções iniciais)
	GameManager.carregar_fase(1)
	
	# (Se você já tiver o script do tutorial aqui, ele vem logo em seguida:)
	if GameManager.is_tutorial_ativo:
		# tutorial.focar_em_slot_3d(...)
		pass
