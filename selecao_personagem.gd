extends Control

var slot_cena = preload("res://slot_personagem.tscn")

@onready var grid = $HBoxContainer/ScrollContainer/GridContainer
@onready var ponto_spawn = get_node_or_null("HBoxContainer/SubViewportContainer/SubViewport/PontoSpawn")

func _ready():
	# 1. Limpa a grade para não duplicar
	for child in grid.get_children():
		child.queue_free()
	
	# 2. O LOOP CORRETO
	for caminho in Global.lista_personagens:
		var novo_slot = slot_cena.instantiate()
		grid.add_child(novo_slot)
		
		# AQUI ESTÁ O SEGREDO: 
		# Passamos 'caminho' (um por vez), NÃO a 'lista_personagens' (todos)
		if novo_slot.has_method("configurar_slot"):
			novo_slot.configurar_slot(caminho) 
		
		# Conecta o botão
		var btn = novo_slot.get_node_or_null("Button")
		if btn:
			btn.pressed.connect(_ao_escolher.bind(caminho))
	# Limpa a grade
	for child in grid.get_children():
		child.queue_free()
	
	# Cria os slots
	for caminho in Global.lista_personagens:
		var novo_slot = slot_cena.instantiate()
		grid.add_child(novo_slot)
		
		# Chama a função que criamos no script do SLOT
		if novo_slot.has_method("configurar_slot"):
			novo_slot.configurar_slot(caminho)
		
		# Conecta o botão para mostrar o boneco GRANDE
		var btn = novo_slot.get_node_or_null("Button")
		if btn:
			btn.pressed.connect(_ao_escolher.bind(caminho))

func _ao_escolher(caminho):
	if ponto_spawn:
		# Deleta quem estava lá (LIMPEZA CRUCIAL)
		for n in ponto_spawn.get_children():
			n.queue_free()
		
		# Spawna apenas UM por vez
		var grande = load(caminho).instantiate()
		ponto_spawn.add_child(grande)
		grande.scale = Vector3(0.8, 0.8, 0.8)
		
		var anim = grande.get_node_or_null("AnimationPlayer")
		if anim: anim.play("idle")
