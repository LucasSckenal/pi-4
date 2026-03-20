extends Camera3D

@export var player: Node3D
@export var limite_maximo_pan_x: float = 4.0
@export var limite_maximo_pan_z: float = 8.0
var offset: Vector3
var velocidade_suavizacao: float = 8.0
var fov_inicial: float
var size_inicial: float
var posicao_inicial: Vector3

func _ready():
	# Salva a distância exata e a posição central entre a câmera e o player no momento que o jogo abre
	if player:
		offset = global_position - player.global_position
		
	posicao_inicial = global_position
	fov_inicial = fov
	size_inicial = size

func _process(delta):
	if player:
		var posicao_alvo = player.global_position + offset
		
		# Calcula a porcentagem atual de zoom aplicada (0.0 = nenhum zoom, 1.0 = muito zoom)
		var fator_zoom = 0.0
		if projection == Camera3D.PROJECTION_PERSPECTIVE:
			fator_zoom = 1.0 - (fov / fov_inicial)
		else:
			fator_zoom = 1.0 - (size / size_inicial)
			
		fator_zoom = clamp(fator_zoom, 0.0, 1.0)
		
		# Calcula a área de limite dinâmico com base no zoom atual
		var limite_atual_x = limite_maximo_pan_x * fator_zoom
		var limite_atual_z = limite_maximo_pan_z * fator_zoom
		
		# Restringe a movimentação da câmera ao limite dinâmico do centro original da fase
		posicao_alvo.x = clamp(posicao_alvo.x, posicao_inicial.x - limite_atual_x, posicao_inicial.x + limite_atual_x)
		
		# Aplica o deslocamento no eixo X apenas quando há zoom ativo
		if fator_zoom > 0.0:
			posicao_alvo.x += 3.0 * fator_zoom
			
		posicao_alvo.z = clamp(posicao_alvo.z, posicao_inicial.z - limite_atual_z, posicao_inicial.z + limite_atual_z)
		
		# Garante a fixação da altura da câmera
		posicao_alvo.y = posicao_inicial.y
		
		# Interpola a posição copiando e colando de forma suave
		global_position = global_position.lerp(posicao_alvo, velocidade_suavizacao * delta)
