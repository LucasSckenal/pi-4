extends CanvasLayer

# ==========================================
# REFERÊNCIAS DA INTERFACE
# ==========================================
@onready var label_wave = $InterfacePrincipal/CentroTela/LabelWave
@onready var botao_noite = $InterfacePrincipal/MarginInferior/CenterContainer/BotaoNoite
@onready var label_moedas = $InterfacePrincipal/MarginDireita/VBoxDireita/FundoMoedas/LabelMoedas
@export var cena_carta_ui: PackedScene

@onready var anim_bau = $InterfacePrincipal/MarginDireita/VBoxDireita/ContainerBau/SubViewport/chest2/AnimationPlayer

# ==========================================
# SISTEMA DE UPGRADE
# ==========================================
@onready var menu_upgrade = $InterfacePrincipal/MenuUpgrade
@onready var container_cartas = $InterfacePrincipal/MenuUpgrade/HBoxContainer
@onready var botao_reroll = $InterfacePrincipal/MenuUpgrade/BotaoReroll

# ==========================================
# INDICADORES DE DIREÇÃO
# ==========================================
@onready var container_direcoes = $ContainerDirecoes
@export var cena_enemy_icon: PackedScene
@export var tamanho_container: Vector2 = Vector2(80, 100)  # Tamanho do container de cada direção
@export var margem_borda: float = 20.0  # Distância mínima da borda da tela

var containers_por_direcao = {}

func _ready():
	add_to_group("Interface")
	
	if GameManager.has_signal("mostrar_menu_upgrade"):
		GameManager.mostrar_menu_upgrade.connect(_on_abrir_menu_upgrade)
	
	menu_upgrade.hide()
	
	if label_wave != null:
		label_wave.modulate.a = 0.0
	
	if botao_noite != null:
		if not botao_noite.pressed.is_connected(_on_botao_noite_pressed):
			botao_noite.pressed.connect(_on_botao_noite_pressed)
	
	if botao_reroll != null:
		botao_reroll.pressed.connect(_on_botao_reroll_pressed)
	
	atualizar_moedas()
	verificar_estado_dia_noite()
	
	# Garante que o container_direcoes existe
	if container_direcoes == null:
		container_direcoes = Control.new()
		container_direcoes.name = "ContainerDirecoes"
		add_child(container_direcoes)
	container_direcoes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container_direcoes.z_index = 100
	container_direcoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Carrega a cena do ícone se necessário (ajuste o caminho!)
	if cena_enemy_icon == null:
		cena_enemy_icon = preload("res://Enemys/enemy_icon.tscn")
		if cena_enemy_icon == null:
			print("ERRO: Não foi possível carregar enemy_icon.tscn")
	
	# Conecta aos spawners
	_conectar_spawners()
	get_tree().create_timer(1.0).timeout.connect(_conectar_spawners)
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node.is_in_group("Spawner"):
		_conectar_spawners()

# ==========================================
# FUNÇÕES EXISTENTES
# ==========================================
func verificar_estado_dia_noite():
	if botao_noite != null:
		botao_noite.visible = not GameManager.is_night

func _on_botao_noite_pressed():
	if not GameManager.is_night:
		GameManager.iniciar_noite()

func mostrar_wave_na_tela(texto: String):
	if label_wave == null: return
	label_wave.text = texto
	var tween = create_tween()
	tween.tween_property(label_wave, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(label_wave, "modulate:a", 0.0, 1.0)

func atualizar_moedas():
	if label_moedas != null: 
		label_moedas.text = "💰 " + str(GameManager.moedas)

func animar_bau_abrindo():
	if anim_bau != null:
		anim_bau.play("open") 
		await get_tree().create_timer(1.0).timeout 
		anim_bau.play_backwards("open")

func _on_abrir_menu_upgrade(cartas_sorteadas):
	for crianca in container_cartas.get_children():
		crianca.queue_free()
	menu_upgrade.show()
	get_tree().paused = true
	for dados in cartas_sorteadas:
		if cena_carta_ui != null:
			var nova_carta = cena_carta_ui.instantiate()
			container_cartas.add_child(nova_carta)
			if nova_carta.has_method("configurar"):
				nova_carta.configurar(dados) 
			nova_carta.pressed.connect(_ao_escolher_upgrade.bind(dados))
	if botao_reroll != null:
		botao_reroll.disabled = GameManager.reroll_usado
		if GameManager.moedas < GameManager.custo_reroll:
			botao_reroll.modulate = Color(0.5, 0.5, 0.5)
		else:
			botao_reroll.modulate = Color(1, 1, 1)

func _ao_escolher_upgrade(dados):
	GameManager.aplicar_upgrade(dados)
	menu_upgrade.hide()
	get_tree().paused = false

func _on_botao_reroll_pressed():
	GameManager.rerolar_cartas()

# ==========================================
# FUNÇÕES DOS INDICADORES DE DIREÇÃO
# ==========================================
func _conectar_spawners():
	var spawners = get_tree().get_nodes_in_group("Spawner")
	print("HUD: tentando conectar a ", spawners.size(), " spawners")
	for spawner in spawners:
		if not spawner.is_connected("info_proxima_onda", _on_info_spawner):
			spawner.connect("info_proxima_onda", _on_info_spawner)
			print("HUD conectada ao spawner: ", spawner.name)
			spawner.emitir_info()

func _on_info_spawner(direcao: String, inimigos: Array, posicao_mundo: Vector3):
	print("HUD recebeu: direcao=", direcao, " inimigos=", inimigos, " pos=", posicao_mundo)
	
	# Remove container antigo dessa direção
	if containers_por_direcao.has(direcao):
		containers_por_direcao[direcao].queue_free()
		containers_por_direcao.erase(direcao)
	
	# Se não há inimigos ou direção vazia, apenas remove e sai
	if direcao == "" or inimigos.size() == 0:
		return
	
	# Verifica se a cena do ícone está carregada
	if cena_enemy_icon == null:
		print("ERRO: cena_enemy_icon é null")
		return
	
	# Cria um container principal (transparente) para esta direção
	var container_dir = Control.new()
	container_dir.name = "Direcao_" + direcao
	container_direcoes.add_child(container_dir)
	
	# Calcula a posição na borda baseada na posição do spawner
	var pos_tela = _calcular_posicao_borda(posicao_mundo, tamanho_container)
	container_dir.position = pos_tela
	container_dir.size = tamanho_container
	
	# Cria um VBoxContainer para empilhar os ícones verticalmente
	var vbox = VBoxContainer.new()
	vbox.size = tamanho_container
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 5)
	container_dir.add_child(vbox)
	
	# Adiciona os ícones dos inimigos
	for info in inimigos:
		var icon = cena_enemy_icon.instantiate()
		vbox.add_child(icon)
		if icon.has_method("configurar"):
			icon.configurar(info.get("icone"), info.get("cor"), info.qtd)
		else:
			print("ERRO: enemy_icon não tem método configurar")
	
	# Armazena o container
	containers_por_direcao[direcao] = container_dir
	print("Container criado para ", direcao, " com ", inimigos.size(), " ícones")

func _calcular_posicao_borda(posicao_mundo: Vector3, tamanho: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(100, 100)
	
	var pos_tela = camera.unproject_position(posicao_mundo)
	var viewport_size = get_viewport().get_visible_rect().size
	var centro = viewport_size / 2
	
	var dir = pos_tela - centro
	if dir.length() < 0.001:
		dir = Vector2(0, -1)
	
	dir = dir.normalized()
	
	var t_x = INF
	var t_y = INF
	if dir.x > 0:
		t_x = (viewport_size.x - centro.x) / dir.x
	elif dir.x < 0:
		t_x = -centro.x / dir.x
	
	if dir.y > 0:
		t_y = (viewport_size.y - centro.y) / dir.y
	elif dir.y < 0:
		t_y = -centro.y / dir.y
	
	var t = min(t_x, t_y)
	var ponto_borda = centro + dir * t
	
	# Aplica margem
	var metade = tamanho / 2
	var min_x = metade.x + margem_borda
	var max_x = viewport_size.x - metade.x - margem_borda
	var min_y = metade.y + margem_borda
	var max_y = viewport_size.y - metade.y - margem_borda
	
	ponto_borda.x = clamp(ponto_borda.x, min_x, max_x)
	ponto_borda.y = clamp(ponto_borda.y, min_y, max_y)
	
	return ponto_borda - metade
