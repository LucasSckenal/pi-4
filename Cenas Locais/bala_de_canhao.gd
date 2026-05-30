extends Area3D

var velocidade: float = 5.0
var dano: int = 30
var raio_explosao: float = 1.3
var alvo: Node3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	var modelo = preload("res://Towers/weapon-ammo-cannonball.glb").instantiate()
	modelo.scale = Vector3(0.3, 0.3, 0.3)
	add_child(modelo)

func _process(delta):
	if is_instance_valid(alvo):
		var pos_alvo := _get_posicao_alvo()
		var direcao := (pos_alvo - global_position).normalized()
		global_position += direcao * velocidade * delta
	else:
		queue_free()

func _get_posicao_alvo() -> Vector3:
	if is_instance_valid(alvo) and alvo.has_method("get_ponto_alvo"):
		return alvo.get_ponto_alvo()
	return alvo.global_position

func _on_body_entered(body):
	if body == alvo:
		_explodir(body)

func _explodir(alvo_direto: Node3D) -> void:
	var dano_total: int = dano
	if GameManager.bonus_dano_chefe > 0 and alvo_direto.is_in_group("Chefe"):
		dano_total += GameManager.bonus_dano_chefe
	if alvo_direto.has_method("receber_dano"):
		alvo_direto.receber_dano(dano_total)
	_tentar_aplicar_gelo(alvo_direto)
	if GameManager.dano_inflamavel > 0:
		_aplicar_queimadura(alvo_direto)

	var pos_explosao := global_position
	var processados: Array = [alvo_direto]
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not is_instance_valid(inimigo): continue
		if inimigo in processados: continue
		processados.append(inimigo)
		if pos_explosao.distance_to(inimigo.global_position) > raio_explosao:
			continue
		var dano_splash: int = dano
		if GameManager.bonus_dano_chefe > 0 and inimigo.is_in_group("Chefe"):
			dano_splash += GameManager.bonus_dano_chefe
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(dano_splash)
		_tentar_aplicar_gelo(inimigo)
		if GameManager.dano_inflamavel > 0:
			_aplicar_queimadura(inimigo)

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
