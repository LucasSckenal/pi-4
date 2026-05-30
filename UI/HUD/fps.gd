extends Label

func _process(_delta: float) -> void:
	# Pega o FPS atual do motor do jogo
	var fps = Engine.get_frames_per_second()
	
	# Atualiza o texto do Label
	text = "FPS: " + str(fps)
