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
		_aplicar_outline_automatico(modelo)
		
		modelo.scale = Vector3(0.5, 0.5, 0.5)
		# Toca a animação
		var anim = modelo.get_node_or_null("AnimationPlayer")
		if anim: anim.play("idle")

# ==========================================
# AUTOMAÇÃO DE SHADER DE OUTLINE
# ==========================================
const OUTLINE_SHADER = preload("res://Shaders/Outline.gdshader")

func _aplicar_outline_automatico(no_raiz: Node):
	var mat_outline = ShaderMaterial.new()
	if OUTLINE_SHADER:
		mat_outline.shader = OUTLINE_SHADER
		mat_outline.set_shader_parameter("scale", 1.0)
		mat_outline.set_shader_parameter("outline_spread", 5.0)
		mat_outline.set_shader_parameter("_Color", Color(0, 0, 0, 1))
		mat_outline.set_shader_parameter("_DepthNormalThreshold", 0.1)
		mat_outline.set_shader_parameter("_DepthNormalThresholdScale", 3.0)
		mat_outline.set_shader_parameter("_DepthThreshold", 1.5)
		mat_outline.set_shader_parameter("_NormalThreshold", 2.0)
		
		_varrer_malhas_e_aplicar(no_raiz, mat_outline)

func _varrer_malhas_e_aplicar(no_atual: Node, material_shader: ShaderMaterial):
	if no_atual is MeshInstance3D:
		no_atual.material_overlay = material_shader
	for filho in no_atual.get_children():
		_varrer_malhas_e_aplicar(filho, material_shader)
