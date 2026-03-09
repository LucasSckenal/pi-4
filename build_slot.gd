extends Node3D

@export var building_scene: PackedScene 

@onready var base_mesh = $BaseMesh
@onready var prompt_label = $PromptLabel

var fantasma: Node3D
var is_built = false
var custo_atual = 0

# Variável para guardar quem é o jogador quando ele chega perto
var player_ref = null 

func _ready():
	prompt_label.hide()
	
	if building_scene != null:
		# Cria o holograma/fantasma
		fantasma = building_scene.instantiate()
		
		# =======================================================
		# A LINHA MÁGICA AQUI: Carimba a testa do clone dizendo que é falso
		# =======================================================
		fantasma.set("is_fantasma", true)
		
		add_child(fantasma)
		
		# Verifica o preço da construção em moedas
		if "custo_moedas" in fantasma:
			custo_atual = fantasma.custo_moedas
			prompt_label.text = "[E] Construir (" + str(custo_atual) + " Moedas)"
		else:
			prompt_label.text = "[E] Construir (Grátis)"
		
		# Transforma em holograma e deixa escondido no início
		transformar_em_fantasma(fantasma)
		fantasma.hide()

func _process(_delta):
	# Se o jogador está na área E o slot ainda está vazio
	if player_ref != null and not is_built:
		
		# Se carregar no botão de construir [E]
		if Input.is_action_just_pressed("interact"):
			
			# VERIFICA A CARTEIRA DO JOGADOR
			if player_ref.moedas >= custo_atual:
				# Desconta o dinheiro
				player_ref.moedas -= custo_atual
				
				# Manda o Player atualizar o texto no ecrã (HUD)!
				if player_ref.has_method("atualizar_hud"):
					player_ref.atualizar_hud() 
				
				print("Construção feita! Moedas restantes: ", player_ref.moedas)
				
				# Inicia a construção
				build()
			else:
				# Se não tiver dinheiro, não constrói e avisa na consola do Godot
				print("Faltam moedas! Tens ", player_ref.moedas, " mas custa ", custo_atual)

func build():
	if building_scene != null:
		# Cria a construção real e sólida
		var new_building = building_scene.instantiate()
		add_child(new_building)
		
		is_built = true
		base_mesh.hide()
		prompt_label.hide()
		
		# Apaga o fantasma de vez
		if fantasma != null:
			fantasma.queue_free()

# Quando o jogador ENTRA na área do sensor
func _on_area_3d_body_entered(body):
	if body.name == "Player" and not is_built:
		player_ref = body # Guarda o jogador na variável
		prompt_label.show()
		if fantasma != null:
			fantasma.show()

# Quando o jogador SAI da área do sensor
func _on_area_3d_body_exited(body):
	if body.name == "Player":
		player_ref = null # O jogador foi-se embora, limpa a variável
		prompt_label.hide()
		if fantasma != null:
			fantasma.hide()

# O Varredor: Vasculha as peças para fazer o holograma transparente e sem colisão
func transformar_em_fantasma(no_atual: Node):
	if no_atual is MeshInstance3D:
		no_atual.transparency = 0.5 
		
	elif no_atual is CollisionShape3D:
		no_atual.disabled = true 
		
	for filho in no_atual.get_children():
		transformar_em_fantasma(filho)
