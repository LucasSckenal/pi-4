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
		var pos_alvo := _get_posicao_alvo()
		# Olha para o inimigo
		look_at(pos_alvo, Vector3.UP)
		# Voa para frente (o eixo -Z que acabamos de alinhar!)
		global_position += transform.basis.z * -velocidade * delta
	else:
		# Se o inimigo morreu no meio do caminho, a flecha some
		queue_free()

func _get_posicao_alvo() -> Vector3:
	if is_instance_valid(alvo) and alvo.has_method("get_ponto_alvo"):
		return alvo.get_ponto_alvo()
	return alvo.global_position

func _on_body_entered(body):
	if body == alvo:
		var dano_total = dano
		if GameManager.bonus_dano_chefe > 0 and body.is_in_group("Chefe"):
			dano_total += GameManager.bonus_dano_chefe
		if body.has_method("receber_dano"):
			body.receber_dano(dano_total)

		_tentar_aplicar_gelo(body)

		if GameManager.dano_inflamavel > 0:
			_aplicar_queimadura(body)
		if GameManager.bonus_ricochete > 0:
			_ricochetar(body)

		queue_free()

func _tentar_aplicar_gelo(alvo_hit: Node) -> void:
	if GameManager.multiplicador_velocidade_inimigo < 1.0 and alvo_hit.has_method("aplicar_gelo"):
		alvo_hit.aplicar_gelo()

func _aplicar_queimadura(alvo_queimado: Node) -> void:
	if alvo_queimado.has_method("iniciar_queimadura"):
		alvo_queimado.iniciar_queimadura(GameManager.dano_inflamavel)
		return
	var dano_tick = GameManager.dano_inflamavel
	for i in range(3):
		get_tree().create_timer(float(i + 1) * 1.0).timeout.connect(func():
			if is_instance_valid(alvo_queimado) and alvo_queimado.has_method("receber_dano"):
				alvo_queimado.receber_dano(dano_tick)
		)

func _ricochetar(primeiro_alvo: Node3D) -> void:
	var todos = get_tree().get_nodes_in_group("inimigos")
	if todos.is_empty():
		todos = get_tree().get_nodes_in_group("Inimigos")
	var atingidos := [primeiro_alvo]
	var ultimo: Node3D = primeiro_alvo
	for _salto in range(GameManager.bonus_ricochete):
		var proximo: Node3D = null
		var menor_dist: float = 6.0
		for inimigo in todos:
			if not is_instance_valid(inimigo): continue
			if inimigo in atingidos: continue
			var dist = ultimo.global_position.distance_to(inimigo.global_position)
			if dist < menor_dist:
				menor_dist = dist
				proximo = inimigo
		if proximo == null:
			break
		atingidos.append(proximo)
		if proximo.has_method("receber_dano"):
			@warning_ignore("integer_division")
			proximo.receber_dano(max(1, dano / 2))
		_tentar_aplicar_gelo(proximo)
		ultimo = proximo
