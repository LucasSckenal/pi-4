extends Control

var slot_cena = preload("res://slot_personagem.tscn")

@onready var grid = $HBoxContainer/ScrollContainer/GridContainer
@onready var ponto_spawn = get_node_or_null("HBoxContainer/SubViewportContainer/SubViewport/PontoSpawn")

func _ready():
	print("Limpando e Gerando a Grade...")
	
	# 1. Limpa a grade (essencial!)
	for child in grid.get_children():
		child.queue_free()
	
	# 2. Loop para criar apenas os BOTÕES da grade
	for caminho in Global.lista_personagens:
		var novo_slot = slot_cena.instantiate()
		grid.add_child(novo_slot)
		
		# --- MINIATURA (Dentro do slot) ---
		var vp = novo_slot.get_node_or_null("SubViewportContainer/SubViewport")
		if vp == null: vp = novo_slot.get_node_or_null("SubViewport")
		
		if vp:
			var mini = load(caminho).instantiate()
			vp.add_child(mini)
			mini.scale = Vector3(0.5, 0.5, 0.5)
			var anim = mini.get_node_or_null("AnimationPlayer")
			if anim: anim.play("idle")

		# --- CONEXÃO DO CLIQUE ---
		var btn = novo_slot.get_node_or_null("Button")
		if btn:
			# O BIND é o que diz ao botão qual personagem ele representa
			btn.pressed.connect(_ao_escolher.bind(caminho))

# --- ESSA FUNÇÃO DEVE FICAR FORA DO LOOP 'FOR' ---
func _ao_escolher(caminho):
	print("Você clicou no personagem: ", caminho)
	
	if ponto_spawn:
		# LIMPEZA: Remove quem já estava lá (para não amontoar)
		for n in ponto_spawn.get_children():
			n.queue_free()
			
		# SPAWN: Agora sim, coloca o NOVO boneco sozinho
		var grande = load(caminho).instantiate()
		ponto_spawn.add_child(grande)
		
		# Ajuste para ele não ficar gigante na tela
		grande.scale = Vector3(0.8, 0.8, 0.8) 
		
		var anim = grande.get_node_or_null("AnimationPlayer")
		if anim: 
			anim.play("idle")
