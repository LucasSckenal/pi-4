extends Node3D

@export var building_scene: PackedScene 

@onready var base_mesh = $BaseMesh
@onready var prompt_label = $PromptLabel
@onready var bolha_btn = $CanvasLayer/TextureButton
@onready var canvas_mobile = $CanvasLayer

var fantasma: Node3D
var is_built = false
var custo_atual = 0
var estado_toque_mobile = 0 
var player_ref_teclado = null 

func _ready():
	# Ativa interface apenas em Mobile ou no Editor para testes
	if canvas_mobile:
		canvas_mobile.visible = OS.has_feature("mobile") or OS.has_feature("editor")
	if prompt_label:
		prompt_label.hide()
	
	if building_scene != null:
		fantasma = building_scene.instantiate()
		fantasma.set("is_fantasma", true)
		add_child(fantasma)
		if "custo_moedas" in fantasma: 
			custo_atual = fantasma.custo_moedas
		transformar_em_fantasma(fantasma)
		fantasma.hide()

func _process(_delta):
	if is_built: return

	# Posicionamento da Bolha (segue o mundo 3D)
	if canvas_mobile and canvas_mobile.visible and is_instance_valid(bolha_btn):
		var camera = get_viewport().get_camera_3d()
		if camera and not camera.is_position_behind(global_position):
			var pos_2d = camera.unproject_position(global_position)
			bolha_btn.position = pos_2d - (bolha_btn.size / 2)
			# Se estiver no estado 0, garante que a bolha está visível
			if estado_toque_mobile == 0: bolha_btn.show()
		else:
			bolha_btn.hide()

	# Teclado (PC)
	if player_ref_teclado != null and Input.is_action_just_pressed("interact"):
		tentar_construir()

func _input(event):
	# Detecta clique fora para cancelar a seleção no Mobile
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed and estado_toque_mobile == 1 and is_instance_valid(bolha_btn):
			# Aguarda um microssegundo para não conflitar com o clique do próprio botão
			get_tree().create_timer(0.05).timeout.connect(func():
				if is_instance_valid(bolha_btn):
					if not bolha_btn.get_global_rect().has_point(event.position):
						cancelar_selecao()
			)

func cancelar_selecao():
	estado_toque_mobile = 0
	if is_instance_valid(fantasma): fantasma.hide()
	if prompt_label: prompt_label.hide()
	if is_instance_valid(bolha_btn):
		bolha_btn.modulate.a = 1.0 # Torna a bolha visível de novo
		bolha_btn.show()

func _on_texture_button_pressed():
	if is_built: return
	
	if estado_toque_mobile == 0:
		# Primeiro Toque: Mostra o fantasma e torna a bolha invisível (mas clicável)
		estado_toque_mobile = 1
		if fantasma: fantasma.show()
		bolha_btn.modulate.a = 0.0 
		if prompt_label:
			prompt_label.text = "Custo: " + str(custo_atual) + "\nToque na torre para confirmar"
			prompt_label.show()
	else:
		# Segundo Toque: Confirmação
		tentar_construir()

# ==========================================
# A MÁGICA FOI ARRUMADA AQUI NESTA FUNÇÃO:
# ==========================================
func tentar_construir():
	# O GameManager tenta gastar o dinheiro. Se ele retornar true,
	# significa que o dinheiro foi descontado, a HUD atualizou e o baú abriu!
	if GameManager.gastar_moedas(custo_atual):
		print("Construção realizada! Saldo restante: ", GameManager.moedas)
		build()
	else:
		print("Moedas insuficientes! Você precisa de: ", custo_atual)
		cancelar_selecao()

func build():
	if building_scene != null:
		var new_building = building_scene.instantiate()
		add_child(new_building)
		is_built = true
		
		if base_mesh: base_mesh.hide()
		if prompt_label: prompt_label.hide()
		
		# Limpa os elementos de interface e fantasma com segurança
		if is_instance_valid(canvas_mobile): canvas_mobile.queue_free()
		if is_instance_valid(fantasma): fantasma.queue_free()

func _on_area_3d_body_entered(body):
	if body.is_in_group("Player") and not is_built:
		player_ref_teclado = body
		if not OS.has_feature("mobile"):
			if prompt_label:
				prompt_label.text = "[E] Construir (" + str(custo_atual) + ")"
				prompt_label.show()
			if fantasma: fantasma.show()

func _on_area_3d_body_exited(body):
	if body == player_ref_teclado:
		player_ref_teclado = null
		if not is_built:
			if prompt_label: prompt_label.hide()
			if estado_toque_mobile == 0 and fantasma: fantasma.hide()

func transformar_em_fantasma(no_atual: Node):
	if no_atual is MeshInstance3D: 
		no_atual.transparency = 0.5 
	elif no_atual is CollisionObject3D:
		no_atual.collision_layer = 0
		no_atual.collision_mask = 0
	elif no_atual is CollisionShape3D or no_atual is CollisionPolygon3D: 
		no_atual.set_deferred("disabled", true)
	elif no_atual is NavigationObstacle3D:
		no_atual.avoidance_enabled = false
		
	for filho in no_atual.get_children(): 
		transformar_em_fantasma(filho)
