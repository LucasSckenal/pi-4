extends Node

# --- REFERÊNCIAS DOS NÓS ---
@onready var player_hit = $PlayerHit
@onready var player_jump = $PlayerJump
@onready var player_ui_hover = $PlayerUIHover
@onready var player_ui_click = $PlayerUIClick
@onready var player_erro = $PlayerErro
@onready var player_construcao = $PlayerConstrucao
@onready var player_vitoria = $PlayerVitoria
@onready var player_estrela = $PlayerEstrela
@onready var player_venda = $PlayerVenda
@onready var player_new_map = $PlayerNewMap
@onready var player_reroll = $PlayerReroll
@onready var player_defeat = $PlayerDefeat
@onready var enemy_hit = $EnemyHit
@onready var enemy_dead = $EnemyDead
@onready var player_destruicao = $PlayerDestruicao

# Som de virar página (bestiário). Carregado sob demanda: enquanto o arquivo não
# existir, simplesmente não toca (sem erro). Basta soltar pagina.wav/.mp3 em Audio/Sons.
var _player_pagina: AudioStreamPlayer = null
var _stream_pagina: AudioStream = null
var _pagina_buscada: bool = false
const _CAMINHOS_PAGINA := [
	"res://Audio/Sons/pagina.wav", "res://Audio/Sons/pagina.mp3",
	"res://Audio/Sons/page.wav", "res://Audio/Sons/page.mp3",
]

func _ready():
	# 1. Conecta os botões que já iniciam na tela
	_varrer_e_conectar(get_tree().root)

	# 2. Liga o "Radar": Fica de olho em qualquer nó novo que for criado depois
	get_tree().node_added.connect(_on_node_added)

	# 3. Cria o player dedicado para o som de virar página (bestiário)
	_player_pagina = AudioStreamPlayer.new()
	_player_pagina.name = "PlayerPagina"
	add_child(_player_pagina)

# --- O RADAR DE BOTÕES AUTOMÁTICO ---

func _on_node_added(node: Node):
	# Se o nó que acabou de nascer no jogo for qualquer tipo de botão...
	if node is BaseButton:
		_conectar_sinais_do_botao(node)

func _varrer_e_conectar(root_node: Node):
	if root_node is BaseButton:
		_conectar_sinais_do_botao(root_node)
	
	# Faz um loop para olhar todos os filhos dentro da cena
	for child in root_node.get_children():
		_varrer_e_conectar(child)

func _conectar_sinais_do_botao(botao: BaseButton):
	# Verifica se já não está conectado (para evitar tocar áudio duplicado)
	if not botao.mouse_entered.is_connected(tocar_ui_hover):
		botao.mouse_entered.connect(tocar_ui_hover)
		
	if not botao.pressed.is_connected(tocar_ui_click):
		botao.pressed.connect(tocar_ui_click)

# --- VARIÁVEIS DE CONTROLE (O COOLDOWN) ---
var tempo_ultimo_hit = 0
var tempo_ultima_death = 0

# --- FUNÇÕES DOS INIMIGOS ---
func tocar_som_hit():
	var tempo_atual = Time.get_ticks_msec()
	if tempo_atual - tempo_ultimo_hit > 50:
		player_hit.play()
		tempo_ultimo_hit = tempo_atual

func tocar_som_dead():
	var tempo_atual = Time.get_ticks_msec()
	if tempo_atual - tempo_ultima_death > 50:
		enemy_dead.play()
		tempo_ultima_death = tempo_atual

func tocar_enemy_hit():
	enemy_hit.play()


# --- FUNÇÕES DA INTERFACE (UI) ---
func tocar_ui_hover():
	# Uma dica de "juice": variar levemente o tom do hover deixa menos irritante
	player_ui_hover.play()

func tocar_ui_click():
	player_ui_click.play()

# --- FUNÇÕES DO JOGADOR/SISTEMA ---
func tocar_som_jump():
	player_jump.play()

func tocar_erro_compra():
	player_erro.play()

func tocar_construcao():
	player_construcao.play()

func tocar_destruicao():
	player_destruicao.play()

func tocar_vitoria():
	player_vitoria.play()

func tocar_estrela():
	player_estrela.play()

func tocar_venda():
	player_venda.play()

func tocar_new_map():
	player_new_map.play()

func tocar_reroll():
	player_reroll.play()

func tocar_defeat():
	player_defeat.play()



# Som de virar página (bestiário). Lazy: toca só se o arquivo existir.
func tocar_som_pagina():
	if not _pagina_buscada:
		_pagina_buscada = true
		for caminho in _CAMINHOS_PAGINA:
			if ResourceLoader.exists(caminho):
				_stream_pagina = load(caminho)
				break
	if _stream_pagina != null and _player_pagina != null:
		_player_pagina.stream = _stream_pagina
		_player_pagina.play()
