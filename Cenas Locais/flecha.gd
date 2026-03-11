extends Area3D

var velocidade: float = 15.0
var dano: int = 30
var alvo: Node3D = null

func _ready():
	# Conecta o sinal de bater em algo
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Se o alvo ainda existe (não morreu pra outra torre), persegue ele!
	if is_instance_valid(alvo):
		# Olha para o inimigo
		look_at(alvo.global_position, Vector3.UP)
		# Voa para frente (o eixo -Z que acabamos de alinhar!)
		global_position += transform.basis.z * -velocidade * delta
	else:
		# Se o inimigo morreu no meio do caminho, a flecha some
		queue_free()

func _on_body_entered(body):
	# Se a flecha bateu exatamente no alvo que ela estava seguindo
	if body == alvo:
		if body.has_method("receber_dano"):
			body.receber_dano(dano)
		
		# Destrói a flecha depois de bater
		queue_free()
