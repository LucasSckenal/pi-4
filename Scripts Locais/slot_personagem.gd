extends Control

# Caminho exato para o seu Node3D dentro do Slot
@onready var spawn = get_node_or_null("SubViewportContainer/SubViewport/PontoSpawnSlot")

func configurar_slot(caminho_recebido: String):
	# 'caminho_recebido' é apenas UM texto, ex: "res://.../male-a.glb"
	
	if spawn:
		# Limpa o que já estava lá (por segurança)
		for n in spawn.get_children():
			n.queue_free()
		
		# Instancia APENAS o personagem recebido
		var modelo = load(caminho_recebido).instantiate()
		spawn.add_child(modelo)
		
		modelo.scale = Vector3(0.5, 0.5, 0.5)
		# Toca a animação
		var anim = modelo.get_node_or_null("AnimationPlayer")
		if anim: anim.play("idle")
