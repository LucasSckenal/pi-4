extends Camera3D

@export var player: Node3D

## Limites simétricos (retrocompatibilidade). Se os limites direcionais abaixo
## forem 0, estes valores são usados para ambos os lados do eixo.
@export var limite_maximo_pan_x: float = 4.0
@export var limite_maximo_pan_z: float = 8.0

@export_group("Limites Direcionais (manuais)")
## Quando > 0, sobrescreve limite_maximo_pan_* para aquele lado específico.
## Permite ajustar cada borda do mapa independentemente (X- ≠ X+, Z- ≠ Z+).
@export var limite_x_negativo: float = 0.0
@export var limite_x_positivo: float = 0.0
@export var limite_z_negativo: float = 0.0
@export var limite_z_positivo: float = 0.0

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
		
		# Limites por lado: usa o direcional se definido (>0), senão cai no simétrico.
		var lim_x_neg = limite_x_negativo if limite_x_negativo > 0.0 else limite_maximo_pan_x
		var lim_x_pos = limite_x_positivo if limite_x_positivo > 0.0 else limite_maximo_pan_x
		var lim_z_neg = limite_z_negativo if limite_z_negativo > 0.0 else limite_maximo_pan_z
		var lim_z_pos = limite_z_positivo if limite_z_positivo > 0.0 else limite_maximo_pan_z

		if escalar_limites_com_zoom:
			lim_x_neg *= fator_zoom
			lim_x_pos *= fator_zoom
			lim_z_neg *= fator_zoom
			lim_z_pos *= fator_zoom

		# Restringe a movimentação da câmera ao limite dinâmico do centro original da fase
		posicao_alvo.x = clamp(posicao_alvo.x, posicao_inicial.x - lim_x_neg, posicao_inicial.x + lim_x_pos)
		posicao_alvo.z = clamp(posicao_alvo.z, posicao_inicial.z - lim_z_neg, posicao_inicial.z + lim_z_pos)
		
		# Garante a fixação da altura da câmera
		posicao_alvo.y = posicao_inicial.y
		
		# Interpola a posição copiando e colando de forma suave
		global_position = global_position.lerp(posicao_alvo, velocidade_suavizacao * delta)

func reset_zoom_tutorial():
	fov = fov_inicial
	size = size_inicial
	_atualizar_escala_outline_global() # Se houver função de atualização de outline

func _atualizar_escala_outline_global():
	if player and player.has_method("_atualizar_escala_outline"):
		player._atualizar_escala_outline(fov if projection == PROJECTION_PERSPECTIVE else size)
