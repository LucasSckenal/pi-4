extends Node3D

signal info_proxima_onda(direcao: String, inimigos: Array, posicao: Vector3)

@export var ondas: Array[WaveData] = []
@export var label_wave: Label

var onda_atual: int = 0
var fila_inimigos: Array[PackedScene] = []
var fila_hp_mult: Array[float] = []  # Multiplicador de HP pareado com fila_inimigos (modo infinito)
var inimigos_restantes: int = 0
var spawning: bool = false

# Pool de inimigos "normais" construído a partir das ondas pré-definidas (para gerar waves procedurais)
var pool_normais: Array[PackedScene] = []
# Boss: primeira cena encontrada nas ondas que seja do tipo BOSS/MINI_BOSS
var cena_boss: PackedScene = null

@onready var timer = $TimerSpawn
@onready var base = get_tree().get_first_node_in_group("Base")

func _ready():
	add_to_group("Spawner")
	GameManager.noite_iniciada.connect(_iniciar_noite)
	timer.timeout.connect(_on_timer_timeout)
	_construir_pool_procedural()
	emitir_info()

func _iniciar_noite(_n):
	if spawning:
		return

	var onda_data: WaveData = null
	if onda_atual < ondas.size():
		onda_data = ondas[onda_atual]
	elif GameManager.modo_infinito:
		onda_data = _gerar_onda_procedural(GameManager.onda_atual)
	else:
		return

	if onda_data == null:
		print("ERRO: Onda ", onda_atual, " é null em ", name)
		return

	var hp_mult_base: float = _calcular_hp_multiplicador(GameManager.onda_atual)

	fila_inimigos.clear()
	fila_hp_mult.clear()
	# Para waves pré-definidas aplica multiplicador_horda; waves procedurais já calculam a quantidade
	var mult_horda: float = GameManager.multiplicador_horda if onda_atual < ondas.size() else 1.0
	for config in onda_data.inimigos:
		if config == null:
			print("ERRO: Config de inimigo null na onda ", onda_atual)
			continue
		var qtd = int(ceil(config.quantidade * mult_horda))
		for i in range(qtd):
			fila_inimigos.append(config.cena)
			fila_hp_mult.append(hp_mult_base)

	inimigos_restantes = fila_inimigos.size()
	print(name, " iniciando noite com ", inimigos_restantes, " inimigos (hp_mult=", hp_mult_base, ")")

	if inimigos_restantes == 0:
		_finalizar_onda()
		return

	spawning = true
	timer.start(onda_data.intervalo)

func _on_timer_timeout():
	if not spawning:
		return
	
	if inimigos_restantes > 0:
		_spawnar_proximo()
	else:
		timer.stop()
		spawning = false
		await get_tree().create_timer(0.5).timeout
		_esperar_limpeza()

func _spawnar_proximo():
	if fila_inimigos.size() == 0:
		return

	var cena = fila_inimigos.pop_front()
	var hp_mult: float = 1.0
	if fila_hp_mult.size() > 0:
		hp_mult = fila_hp_mult.pop_front()
	if cena == null:
		print("ERRO: cena de inimigo null em ", name)
		return

	if not is_inside_tree():
		print("Spawner ", name, " não está na árvore. Cancelando spawn.")
		return

	var inimigo = cena.instantiate()
	# Aplica escala de HP ANTES de adicionar à árvore para que _ready use o valor escalado
	if hp_mult > 1.0 and "vida_maxima" in inimigo:
		inimigo.vida_maxima = int(inimigo.vida_maxima * hp_mult)
	get_tree().current_scene.add_child(inimigo)
	inimigo.global_position = global_position
	inimigos_restantes -= 1
	print(name, " spawnou inimigo. Restam na fila: ", fila_inimigos.size())

func _esperar_limpeza():
	while get_tree().get_nodes_in_group("inimigos").size() > 0:
		await get_tree().create_timer(1.0).timeout
	_finalizar_onda()

func _finalizar_onda():
	print(name, " finalizando onda. Próxima onda: ", onda_atual + 1)
	onda_atual += 1
	
	# EM VEZ DE: GameManager.terminar_onda()
	# AGORA USAMOS A NOVA FUNÇÃO:
	GameManager.registrar_spawner_concluido()
	
	emitir_info()

func emitir_info():
	if onda_atual >= ondas.size():
		info_proxima_onda.emit("", [], global_position)
		return
	
	var onda = ondas[onda_atual]
	if onda == null:
		info_proxima_onda.emit("", [], global_position)
		return
	
	var info = []
	for config in onda.inimigos:
		if config == null:
			continue
		info.append({
			"icone": config.icone,
			"cor": config.cor,
			"qtd": config.quantidade
		})
	var dir = _calcular_direcao()
	info_proxima_onda.emit(dir, info, global_position)

func _calcular_direcao() -> String:
	if not base:
		return "?"
	var diff = global_position - base.global_position
	var ang = atan2(diff.x, diff.z)
	if abs(ang) < 0.785:
		return "Norte"
	elif ang >= 0.785 and ang < 2.356:
		return "Leste"
	elif ang <= -0.785 and ang > -2.356:
		return "Oeste"
	else:
		return "Sul"

func restaurar_onda_do_save():
	onda_atual = GameManager.onda_atual - 1
	emitir_info()
	print(name, " sincronizou a onda do save! Preparado para a onda: ", GameManager.onda_atual)


# ==========================================
# MODO INFINITO — POOL + GERAÇÃO PROCEDURAL
# ==========================================
func _construir_pool_procedural() -> void:
	pool_normais.clear()
	cena_boss = null
	var vistos: Dictionary = {}

	for onda in ondas:
		if onda == null: continue
		for config in onda.inimigos:
			if config == null or config.cena == null: continue
			var chave = config.cena.resource_path
			if vistos.has(chave): continue
			vistos[chave] = true

			# Detecta boss olhando a cena instanciada (uma vez só, descartada logo após)
			var instancia = config.cena.instantiate()
			var eh_boss: bool = false
			if "tipo_inimigo" in instancia:
				eh_boss = (instancia.tipo_inimigo == InimigoBase.Categoria.BOSS \
					or instancia.tipo_inimigo == InimigoBase.Categoria.MINI_BOSS)
			instancia.free()

			if eh_boss:
				if cena_boss == null:
					cena_boss = config.cena
			else:
				pool_normais.append(config.cena)

	# Fallback: se nenhum boss foi encontrado, usa qualquer inimigo como "boss" (escalado)
	if cena_boss == null and pool_normais.size() > 0:
		cena_boss = pool_normais[0]


func _calcular_hp_multiplicador(onda_global: int) -> float:
	if not GameManager.modo_infinito:
		return 1.0
	# Escala linear leve a partir da onda 6
	return 1.0 + max(0, onda_global - 5) * 0.15


func _gerar_onda_procedural(onda_global: int) -> WaveData:
	if pool_normais.size() == 0 and cena_boss == null:
		return null

	# Seed determinística por onda para que os 3 spawners usem distribuições coerentes
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(onda_global) + "_" + name)

	var eh_onda_boss: bool = (onda_global % 5 == 0)

	# Quantidade total de inimigos POR SPAWNER (cap para não lotar a tela)
	# onda 6 ~3, onda 10 ~4, onda 20 ~7, máximo 8 por spawner
	var qtd_por_spawner: int = clamp(3 + int(floor(onda_global / 4.0)), 3, 8)
	if eh_onda_boss:
		qtd_por_spawner = max(2, qtd_por_spawner - 2)  # Reduz trash quando vem boss

	var onda_data = WaveData.new()
	onda_data.nome_da_onda = "Onda Infinita %d" % onda_global
	onda_data.intervalo = max(0.6, 2.0 - onda_global * 0.05)
	# Não atribuímos onda_data.inimigos diretamente — usamos só .append()
	# porque o campo é Array[InimigoConfig] tipado

	# Escolhe 2-3 tipos aleatórios do pool
	if pool_normais.size() > 0:
		var num_tipos: int = min(rng.randi_range(2, 3), pool_normais.size())
		var pool_copia = pool_normais.duplicate()
		pool_copia.shuffle()
		var tipos_escolhidos = pool_copia.slice(0, num_tipos)

		var restante = qtd_por_spawner
		for i in range(tipos_escolhidos.size()):
			var cfg = InimigoConfig.new()
			cfg.cena = tipos_escolhidos[i]
			if i == tipos_escolhidos.size() - 1:
				cfg.quantidade = max(1, restante)
			else:
				cfg.quantidade = max(1, rng.randi_range(1, restante - (tipos_escolhidos.size() - i - 1)))
			restante -= cfg.quantidade
			onda_data.inimigos.append(cfg)

	# Boss: apenas o primeiro spawner spawna o boss para não vir 3 bosses
	if eh_onda_boss and cena_boss != null:
		var spawners = get_tree().get_nodes_in_group("Spawner")
		if spawners.size() > 0 and spawners[0] == self:
			var cfg_boss = InimigoConfig.new()
			cfg_boss.cena = cena_boss
			cfg_boss.quantidade = 1
			onda_data.inimigos.append(cfg_boss)

	return onda_data
