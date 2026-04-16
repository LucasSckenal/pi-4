extends Camera3D

@export var player: Node3D
@export var limite_maximo_pan_x: float = 4.0
@export var limite_maximo_pan_z: float = 8.0

## Define se os limites de movimentação encolhem junto com o zoom (comportamento original) ou se permanecem fixos permitindo visão total das bordas do mapa (modo panorama livre)
@export var escalar_limites_com_zoom: bool = true

## Velocidade com que a câmera segue o jogador (por padrão é "8.0")
@export var velocidade_suavizacao: float = 8.0
var offset: Vector3
var fov_inicial: float
var size_inicial: float
var posicao_inicial: Vector3

func _ready():
	posicao_inicial = global_position
	fov_inicial = fov
	size_inicial = size
	
	# Calcula o offset ideal projetando a visão da câmera até a altura do jogador
	# Isso garante que a câmera foque no centro do personagem independentemente de onde ele inicie a fase
	if player:
		var direcao_camera = -global_transform.basis.z
		if direcao_camera.y != 0:
			var distancia_ate_chao = (player.global_position.y - global_position.y) / direcao_camera.y
			var ponto_foco = global_position + (direcao_camera * distancia_ate_chao)
			offset = global_position - ponto_foco
		else:
			offset = global_position - player.global_position

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
		
		# Define a área de limite com base na configuração escolhida no Inspector
		var limite_atual_x = limite_maximo_pan_x
		var limite_atual_z = limite_maximo_pan_z
		
		if escalar_limites_com_zoom:
			limite_atual_x *= fator_zoom
			limite_atual_z *= fator_zoom
		
		# Restringe a movimentação da câmera ao limite dinâmico do centro original da fase
		posicao_alvo.x = clamp(posicao_alvo.x, posicao_inicial.x - limite_atual_x, posicao_inicial.x + limite_atual_x)
		posicao_alvo.z = clamp(posicao_alvo.z, posicao_inicial.z - limite_atual_z, posicao_inicial.z + limite_atual_z)
		
		# Garante a fixação da altura da câmera
		posicao_alvo.y = posicao_inicial.y
		
		# Interpola a posição copiando e colando de forma suave
		global_position = global_position.lerp(posicao_alvo, velocidade_suavizacao * delta)

func reset_zoom_tutorial():
	fov = fov_inicial
	size = size_inicial
	_atualizar_escala_outline_global() # Se houver função de atualização de outline

func _atualizar_escala_outline_global():
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("_atualizar_escala_outline"):
		player._atualizar_escala_outline(fov if projection == PROJECTION_PERSPECTIVE else size)
