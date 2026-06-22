extends Area3D

var velocidade: float = 15.0
var dano: int = 30
var alvo: Node3D = null
var _ja_acertou: bool = false

func _ready():
	# Conecta o sinal de bater em algo
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Se o alvo morreu (pra outra torre), a flecha some
	if not is_instance_valid(alvo):
		queue_free()
		return

	var pos_alvo := _get_posicao_alvo()
	var para_alvo := pos_alvo - global_position

	# Acerto por PROXIMIDADE — checado ANTES de mover/olhar. A flecha é movida em
	# _process, então o body_entered do Area3D pode "atravessar" (tunneling) inimigos
	# entre os ticks de física. Esta checagem garante o acerto mesmo que a colisão
	# ou o look_at falhem (caso dos dragões grandes aproximados quase na vertical).
	if para_alvo.length() < 0.9:
		_acertar(alvo)
		return

	var dir := para_alvo.normalized()
	# Protege o look_at: ele dá erro (e trava o _process) se a direção for quase
	# paralela ao eixo UP (flecha quase em cima/embaixo do alvo). Nesse caso, voa direto.
	if abs(dir.dot(Vector3.UP)) < 0.99:
		look_at(pos_alvo, Vector3.UP)
		global_position += -global_transform.basis.z * velocidade * delta
	else:
		global_position += dir * velocidade * delta

func _get_posicao_alvo() -> Vector3:
	if is_instance_valid(alvo) and alvo.has_method("get_ponto_alvo") and alvo.is_inside_tree():
		return alvo.get_ponto_alvo()
	return alvo.global_position

func _on_body_entered(body):
	if body == alvo:
		_acertar(body)

func _acertar(body) -> void:
	if _ja_acertou or not is_instance_valid(body):
		return
	_ja_acertou = true

	var dano_total = dano
	if GameManager.bonus_dano_chefe > 0 and body.is_in_group("Chefe"):
		dano_total += GameManager.bonus_dano_chefe
	# DANO_AEREO: dano extra contra voadores
	if GameManager.bonus_dano_aereo > 0 and body.get("eh_aereo"):
		dano_total += GameManager.bonus_dano_aereo
	# EXECUCAO: dano extra contra inimigos com pouca vida
	if GameManager.bonus_execucao > 0 and "vida_atual" in body and "vida_maxima" in body \
			and body.vida_maxima > 0 and body.vida_atual <= body.vida_maxima * 0.4:
		dano_total += GameManager.bonus_execucao
	# CRITICO: chance de dano dobrado
	var foi_critico := false
	if GameManager.chance_critico > 0.0 and randf() < GameManager.chance_critico:
		dano_total *= 2
		foi_critico = true
	if body.has_method("receber_dano"):
		body.receber_dano(dano_total, "torre", foi_critico)

	_tentar_aplicar_gelo(body)

	if GameManager.dano_inflamavel > 0:
		_aplicar_queimadura(body)
	if GameManager.dano_veneno > 0 and body.has_method("iniciar_veneno"):
		body.iniciar_veneno(GameManager.dano_veneno)
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
