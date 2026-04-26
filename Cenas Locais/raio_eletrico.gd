extends Node3D

# Tempo de vida do efeito visual
var duracao: float = 0.25
var _timer: float = 0.0

# Referências internas
var _mesh: MeshInstance3D
var _luz: OmniLight3D
var _material: StandardMaterial3D

func _ready() -> void:
	_criar_visual()

func configurar(origem: Vector3, destino: Vector3) -> void:
	var meio: Vector3 = (origem + destino) * 0.5
	var direcao: Vector3 = destino - origem
	var comprimento: float = direcao.length()

	global_position = meio

	# Orientar o cilindro entre origem e destino
	if direcao.length_squared() > 0.0001:
		look_at(destino, Vector3.UP)
		# OmniLight no meio
		if _luz:
			_luz.global_position = meio

	# Escalar o cilindro para cobrir a distância
	if _mesh:
		var cil := _mesh.mesh as CylinderMesh
		if cil:
			cil.height = comprimento

func _criar_visual() -> void:
	# Material azul emissivo para o raio
	_material = StandardMaterial3D.new()
	_material.emission_enabled = true
	_material.emission = Color(0.4, 0.8, 1.0)
	_material.emission_energy_multiplier = 4.0
	_material.albedo_color = Color(0.6, 0.9, 1.0)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = 0.9

	# Malha do raio (cilindro fino)
	var cil := CylinderMesh.new()
	cil.top_radius = 0.03
	cil.bottom_radius = 0.03
	cil.height = 1.0  # será redimensionado em configurar()
	cil.material = _material

	_mesh = MeshInstance3D.new()
	_mesh.mesh = cil
	# Rotacionar 90° em X para o cilindro ficar alinhado com o eixo Z (look_at)
	_mesh.rotation_degrees.x = 90.0
	add_child(_mesh)

	# Luz pontual azul no meio para iluminar o ambiente
	_luz = OmniLight3D.new()
	_luz.light_color = Color(0.4, 0.8, 1.0)
	_luz.light_energy = 3.0
	_luz.omni_range = 3.0
	add_child(_luz)

func _process(delta: float) -> void:
	_timer += delta
	var progresso: float = _timer / duracao

	# Fade out progressivo
	if _material:
		_material.albedo_color.a = lerp(0.9, 0.0, progresso)
		_material.emission_energy_multiplier = lerp(4.0, 0.0, progresso)
	if _luz:
		_luz.light_energy = lerp(3.0, 0.0, progresso)

	if _timer >= duracao:
		queue_free()
