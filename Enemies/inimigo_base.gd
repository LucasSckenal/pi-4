extends CharacterBody3D
class_name InimigoBase 

# ==========================================
# CLASSIFICAÇÃO (NOVO!)
# ==========================================
enum Categoria { NORMAL, MINI_BOSS, BOSS }

@export_category("Identificação do Inimigo")
@export var tipo_inimigo: Categoria = Categoria.NORMAL
@export var nome_inimigo: String = "Monstro Desconhecido"
@export var subtitulo_inimigo: String = ""     ## Linha abaixo do nome na cutscene (ex: "O Destruidor das Planícies")
@export var eh_aereo: bool = false
@export var usar_video_custom := false
@export var video_stream: VideoStream
@export var audio_intro: AudioStream           ## Sting dramático tocado no momento do reveal

@export_category("Comportamento Kamikaze (Quebra-Muro)")
@export var eh_kamikaze: bool = false
@export var raio_explosao: float = 3.0
@export var dano_explosao: int = 50
@export var prioriza_construcoes: bool = true 

# ==========================================
# CONFIGURAÇÕES
# ==========================================
@export_category("Status Básicos")
@export var vida_maxima: int = 100
@export var velocidade: float = 0.5
@export var jump_velocity: float = 4.5
@export var gravity: float = 20.0

@export_category("Combate")
@export var forca_dano: int = 5
@export var distancia_ataque: float = 0.7
@export var tempo_recarga_ataque: float = 1.5
@export var raio_visao_construcao: float = 2.0
@export var raio_visao_aliados: float = 1.0
@export var dist_tornar_random: float = 1.5
@export var quanto_espalhar: float = 0.8

@export_category("Referências Visuais & Som")
@export var modelo_3d: Node3D
@export var animation_player: AnimationPlayer
@export var som_dano_stream: AudioStream = preload("res://Audio/Sons/EnemyHurt.wav")
@export var icone: Texture2D            ## Ícone 2D exibido na tela de "Novo Inimigo"

@export_category("Nomes das Animações")
@export var anim_andar: String = "walk"
@export var anim_atacar: String = "attack-melee-right"
@export var anim_morrer: String = "sit"
@export var anim_explodir: String = "explode"
@export var anim_pos_explosao: String = "post_explode"

var esta_explodindo: bool = false

# ==========================================
# NECROMANTE / INVOCADOR
# ==========================================
@export_category("Poderes de Invocação")
@export var eh_necromancer: bool = false
@export var cena_minion: PackedScene = null 
@export var qtd_minions_por_vez: int = 3
@export var tempo_recarga_invocacao: float = 8.0
@export var raio_de_invocacao: float = 1.5
@export var anim_invocar: String = "summon" 

# --- NOVA VARIÁVEL DE OTIMIZAÇÃO ---
@export var limite_minions_vivos: int = 9 ## Máximo de lacaios vivos AO MESMO TEMPO deste necromante

var pode_invocar: bool = true
var esta_invocando: bool = false
var meus_minions_ativos: Array = [] # Lista para guardar quem ele já invocou

# ==========================================
# VARIÁVEIS INTERNAS
# ==========================================
var vida_atual: int
var esta_morto: bool = false
var alvo_atual: Node3D = null
var pode_atacar: bool = true
var escala_original: Vector3
var posicao_de_spawn: Vector3
var desvio_posicao: Vector3 = Vector3.ZERO

# ── Rota lateral aleatória (faz alguns inimigos irem por outro lado) ──────────
# A chance é definida POR SPAWNER: o spawner seta '_chance_rota_lateral' antes do
# inimigo entrar na árvore. Assim só os inimigos do "spawner A" (que você configurar)
# desviam para um lado aleatório no caminho até a base.
@export var dist_rota_lateral: float = 3.5   # quão "largo" é o desvio lateral
var _chance_rota_lateral: float = 0.0        # 0..1, ajustado pelo spawner
var _rota_pendente: bool = false             # sorteado: vai desviar, mas só depois de sair do spawner
var _rota_ativa: bool = false
var _rota_lado: int = 1
var _rota_waypoint: Vector3 = Vector3.ZERO
var _rota_calculada: bool = false
var _rota_timer: float = 0.0                 # segurança: abandona o desvio se demorar demais

# ── Detector anti-travamento (especialmente para inimigos grandes no spawner) ──
var _stuck_timer: float = 0.0
var _stuck_check_pos: Vector3 = Vector3.ZERO
var _stuck_check_acc: float = 0.0
var _stuck_escape: float = 0.0               # > 0 = empurra direto pra base ignorando avoidance
var tempo_bloqueado: float = 0.0
var _contador_quedas: int = 0
var _timer_re_check: float = 0.0
const RE_CHECK_INTERVALO: float = 0.3
# Tabela de fallback de ícones — nível de classe evita alocação por chamada
const _ICONES: Dictionary = {
	# Mapa 1
	"Orc":                       "res://Icons/OrcPreview.png",
	"Abelha":                    "res://Icons/BeePreview.png",
	"Cogumelão":                 "res://Icons/MushroomPreview.png",
	"Golem de Musgo Ancestral":  "res://Icons/GolemBossPreview.png",
	# Mapa 2
	"Anubis":                    "res://Icons/AnubisPreview.png",
	"Chacal":                    "res://Icons/ChacalPreview.png",
	"Genio":                     "res://Icons/GenioPreview.png",
	"Litch":                     "res://Icons/LichPreview.png",
	"Faraó":                     "res://Icons/FaraoPreview.png",
	"Servo do Deserto":          "res://Icons/AnubisPreview.png",
	# Mapa 3
	"Bruxa":                     "res://Icons/BruxaPreview.png",
	"Bilbo":                     "res://Icons/FrankPreview.png",
	"Abóbora":                   "res://Icons/AboboraPreview.png",
	"Cavaleiro":                 "res://Icons/CavaleiroPreview.png",
	"Aprendiz da Bruxa":         "res://Icons/BruxaPreview.png",
	# Mapa 4
	"Bombardeiro":               "res://Icons/BombardeiroPreview.png",
	"Holandês Voador":           "res://Icons/HolandesPreview.png",
	"Monstro Peixe":             "res://Icons/PeixePreview.png",
	"Tutuba":                    "res://Icons/TubaraoPreview.png",
	# Mapa 5
	"Alexa astronauta":          "res://Icons/AlexaPreview.png",
	"Linigena astronauta":       "res://Icons/AlienPreview.png",
	"Sapao Astronauta":          "res://Icons/SapoPreview.png",
	"Fernando o flamingo":       "res://Icons/FlamingoPreview.png",
	"Cosmic Kraken":             "res://Icons/AlienPreview.png",
	"Tentáculo Cósmico":         "res://Icons/TentaculoPreview.png",
	# Mapa 6
	"Demoniozinho":              "res://Icons/DemoniozinhoPreview.png",
	"Dragao Inicial":            "res://Icons/DragaoBebePreview.png",
	"Dragao Evoluido":           "res://Icons/DragaoJovemPreview.png",
	"Dragao Final":              "res://Icons/DragaoAdultoPreview.png",
	"Lava golem":                "res://Icons/FireGolemPreview.png",
}
var _multiplicador_gelo: float = 1.0
var _gelo_timer: float = 0.0
var _gelo_ativo: bool = false
var _fogo_ativo: bool = false
var _veneno_ativo: bool = false
var _veneno_ticks_restantes: int = 0
var _veneno_dano_tick: int = 0
var _veneno_timer_acum: float = 0.0
var _fogo_ticks_restantes: int = 0

# ── Otimizações de runtime ─────────────────────────────────────────────
var _fogo_dano_tick: int = 0          # dano por tick de queimadura (sem timers)
var _fogo_timer_acum: float = 0.0     # acumulador de tempo entre ticks
var _mat_flash: StandardMaterial3D = null  # material de hit-flash pré-criado
var _meshes_modelo: Array = []        # cache de MeshInstance3D do modelo
var _flash_tween: Tween = null         # tween do flash (para poder matar o anterior)
var _cache_construcoes_aereo: Array = []   # cache da lista de construções (aéreos)
var _timer_cache_construcoes: float = 0.0  # throttle do cache de construções
var _mat_dither: ShaderMaterial = null     # material de dithering pré-criado (transparência)

@export_category("Limites do Mapa")
@export var limite_queda_y: float = -20.0
@export var limite_respawn_queda: int = 3

@onready var nav_agent = $NavigationAgent3D

# --- VARIÁVEIS DO BOSS ---
var canvas_boss: CanvasLayer = null
var barra_vida_boss: ProgressBar = null
var barra_fantasma: ProgressBar = null  # A barra que "persegue" a vida real
var label_vida: Label = null

# ==========================================
# BARRA DE VIDA PERSONALIZADA DO BOSS
# ==========================================
@export_category("Interface do Boss")
## Retrato exibido à esquerda da barra (rosto/ícone do boss)
@export var retrato_boss: Texture2D = null
## Imagem de moldura da barra (quadro de madeira, pedra, etc.)
@export var textura_moldura_boss: Texture2D = null
## Cor da barra de vida (verde para pirata, vermelho para golem, etc.)
@export var cor_barra_boss: Color = Color(0.85, 0.05, 0.05)
## Escala de largura máxima da interface em relação à tela (0.1 a 1.0)
@export_range(0.1, 1.0) var escala_tamanho_boss: float = 0.32
## Posição do canto superior-esquerdo do quadro (já descontado o padding transparente),
## em fração da tela (x, y). (0,0) = encostado no canto. Aceita valores negativos.
@export var pos_boss: Vector2 = Vector2(0.33, 0.10)

## Ajuste extra do tamanho (largura, altura) APENAS do preenchimento da barra, sem afetar a textura da moldura
@export var ajuste_tamanho_preenchimento: Vector2 = Vector2.ZERO

## Posições/tamanhos (em fração 0..1 da interface) de cada parte — permitem mover
## RETRATO, MOLDURA e BARRA separadamente para montar barras padrão ou customizadas.
## Rect2(x, y, largura, altura).
@export_group("Posicionamento (fração 0..1)")
## Onde fica o retrato do boss (só aparece se 'retrato_boss' tiver textura)
@export var retrato_rect: Rect2 = Rect2(0.015, 0.10, 0.17, 0.80)
## Onde fica a moldura/quadro. Padrão = ocupa toda a interface.
@export var moldura_rect: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
## Onde fica a barra de vida (faixa colorida) dentro da interface.
@export var barra_rect: Rect2 = Rect2(0.22, 0.54, 0.68, 0.29)
@export_group("")

## Porcentagem inicial visual desta forma na barra do chefe (ex: 100.0 para forma 1, 66.6 para forma 2)
@export_range(0.0, 100.0) var limite_visual_max: float = 100.0
## Porcentagem final visual desta forma na barra do chefe (ex: 66.6 para forma 1, 33.3 para forma 2)
@export_range(0.0, 100.0) var limite_visual_min: float = 0.0

## Exibir texto de porcentagem na barra de vida
@export var mostrar_porcentagem_vida: bool = false
## Tamanho da fonte da porcentagem
@export var tamanho_fonte_porcentagem: int = 28
## Cor da fonte da porcentagem
@export var cor_fonte_porcentagem: Color = Color.BLACK
## Porcentagem para cada separador visual na barra (ex: 25.0). 0 para desativar.
@export_range(0.0, 50.0) var separacao_porcentagem_boss: float = 25.0

# ==========================================
# DICAS PARA A TELA DE NOVO INIMIGO
# ==========================================
@export_category("Dicas do Inimigo (Tutorial)")
@export_multiline var dica_tutorial: String = "Inimigo padrão.\nDestrua-o rapidamente."
@export var status_velocidade: String = "MÉDIA"
@export var status_vida: String = "MÉDIA"
# ------------------------------------------

func _ready():
	add_to_group("inimigos")
	# Aplica multiplicadores globais do CSV (preserva valores-base definidos por cena)
	_aplicar_balanceamento()
	vida_atual = vida_maxima
	
	# Desativa a colisão física contra qualquer entidade no grupo "Player"
	var jogadores = get_tree().get_nodes_in_group("Player")
	for jogador in jogadores:
		if jogador is PhysicsBody3D or jogador is CSGShape3D:
			add_collision_exception_with(jogador)
	
	desvio_posicao = Vector3(randf_range(-quanto_espalhar, quanto_espalhar), 0, randf_range(-quanto_espalhar, quanto_espalhar))

	# Rota lateral: só os inimigos cujo spawner pediu (chance > 0) desviam para um lado aleatório.
	# Fica PENDENTE: só ativa depois que o inimigo sai da aglomeração do spawner (evita travar lá).
	if not eh_aereo and randf() < _chance_rota_lateral:
		_rota_pendente = true
		_rota_lado = 1 if randf() < 0.5 else -1

	if modelo_3d:
		escala_original = modelo_3d.scale
	else:
		escala_original = scale 
		
	if nav_agent:
		nav_agent.path_desired_distance    = 0.5
		nav_agent.target_desired_distance  = 0.5
		# Avoidance RVO — impede que os inimigos se empilhem uns nos outros
		nav_agent.avoidance_enabled        = true
		nav_agent.radius                   = 0.1
		nav_agent.neighbor_distance        = 1.5  # Era 0.2 — muito apertado, causava empilhamento
		nav_agent.time_horizon_agents      = 0.3
		nav_agent.time_horizon_obstacles   = 0.0
		nav_agent.max_speed                = 10.0
		nav_agent.keep_y_velocity          = true
		nav_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)

	_configurar_sensor_transparencia()

	# ── Pré-cria caches de runtime ──────────────────────────────────────────
	# Material de hit-flash reutilizado em cada receber_dano (sem new() por hit)
	_mat_flash = StandardMaterial3D.new()
	_mat_flash.transparency             = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_flash.emission_enabled         = true
	_mat_flash.emission                 = Color.WHITE
	_mat_flash.emission_energy_multiplier = 2.0
	_mat_flash.albedo_color             = Color(1, 1, 1, 0)
	# Lista de meshes do modelo (evita find_children() em receber_dano e _atualizar_tints)
	if modelo_3d:
		_meshes_modelo = modelo_3d.find_children("*", "MeshInstance3D")

	# posicao_de_spawn: o spawner seta global_position APÓS _ready(), então usamos
	# call_deferred para capturar o valor correto no próximo frame
	(func(): posicao_de_spawn = global_position).call_deferred()

	if tipo_inimigo == Categoria.BOSS:
		# Só toca a cutscene de reveal se o boss tiver um vídeo configurado.
		# Formas sem vídeo (ex.: dragão inicial/evoluído) não mostram tela preta —
		# vão direto para a barra de vida de boss.
		if video_stream != null and not Global.inimigos_descobertos.has(nome_inimigo):
			await _tocar_cutscene()
		else:
			_criar_interface_do_boss()

	elif tipo_inimigo == Categoria.MINI_BOSS:
		if modelo_3d:
			modelo_3d.scale = escala_original * 1.3 
				
	if not Global.inimigos_descobertos.has(nome_inimigo):
		Global.inimigos_descobertos.append(nome_inimigo)
		Global.salvar_progresso() 
		
		if InputMap.has_action("passar_onda"):
			TelaAvisoInimigo.mostrar_novo_inimigo(
				nome_inimigo,
				dica_tutorial,
				_obter_icone_aviso(),
				status_velocidade,
				status_vida
			)

func _aplicar_balanceamento() -> void:
	vida_maxima = int(vida_maxima * Balanceamento.get_float("inimigo_mult_vida",        1.0))
	velocidade  = velocidade      * Balanceamento.get_float("inimigo_mult_velocidade",   1.0)
	forca_dano  = int(forca_dano  * Balanceamento.get_float("inimigo_mult_dano",         1.0))

# Devolve o ícone 2D a exibir na TelaAvisoInimigo.
# Prioridade: @export icone (definido no editor) → tabela de fallback por nome.
func _obter_icone_aviso() -> Texture2D:
	if icone != null:
		return icone
	# Tabela de fallback — cobre todos os inimigos que não têm o export setado no editor
	if _ICONES.has(nome_inimigo):
		var caminho: String = _ICONES[nome_inimigo]
		if ResourceLoader.exists(caminho):
			return load(caminho)
	return null

func _physics_process(delta):
	if esta_morto: return
	if _gelo_timer > 0.0:
		_gelo_timer -= delta
		if _gelo_timer <= 0.0:
			_multiplicador_gelo = 1.0
			_gelo_ativo = false
			_atualizar_tints()

	# Queimadura via acumulador (sem create_timer por tick)
	if _fogo_ativo and _fogo_ticks_restantes > 0:
		_fogo_timer_acum += delta
		if _fogo_timer_acum >= 1.0:
			_fogo_timer_acum -= 1.0
			receber_dano(_fogo_dano_tick, "fogo")
			_fogo_ticks_restantes -= 1
			if _fogo_ticks_restantes <= 0:
				_fogo_ativo = false
				_atualizar_tints()

	# Veneno (VENENO) — dano ao longo do tempo, mais lento e duradouro que o fogo
	if _veneno_ativo and _veneno_ticks_restantes > 0:
		_veneno_timer_acum += delta
		if _veneno_timer_acum >= 1.0:
			_veneno_timer_acum -= 1.0
			receber_dano(_veneno_dano_tick)
			_veneno_ticks_restantes -= 1
			if _veneno_ticks_restantes <= 0:
				_veneno_ativo = false
				_atualizar_tints()

	if global_position.y < limite_queda_y:
		_contador_quedas += 1
		if _contador_quedas <= limite_respawn_queda:
			global_position = posicao_de_spawn
			velocity = Vector3.ZERO
		else:
			morrer()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if eh_necromancer and esta_invocando:
		move_and_slide()
		return
		
	if eh_necromancer and pode_invocar and is_on_floor() and alvo_atual:
		invocar_minions()
		return 
		
	if alvo_atual == null or not is_instance_valid(alvo_atual) or \
	   (alvo_atual.get("esta_destruida") == true):
		# Throttle: evita 40 get_nodes_in_group simultâneos quando um alvo morre
		_timer_re_check -= delta
		if _timer_re_check <= 0.0:
			alvo_atual = procurar_novo_alvo()
			_timer_re_check = RE_CHECK_INTERVALO
	elif alvo_atual.is_in_group("Castelo") or alvo_atual.is_in_group("Base"):
		_timer_re_check -= delta
		if _timer_re_check <= 0.0:
			_timer_re_check = RE_CHECK_INTERVALO
			var candidato = procurar_novo_alvo()
			if is_instance_valid(candidato) and \
			   not candidato.is_in_group("Castelo") and \
			   not candidato.is_in_group("Base"):
				alvo_atual = candidato

	# ── Inimigos aéreos — voam direto ao alvo, ignoram NavMesh ───────────────
	if eh_aereo:
		# Mantém a altitude do ponto de spawn (sem gravidade, sem raycast)
		# O level designer controla a altura pelo Y do spawner
		var diff: float = global_position.y - posicao_de_spawn.y
		if diff > 0.1:
			velocity.y = -clamp(diff * 5.0, 2.0, 18.0)  # desce para o spawn
		elif diff < -0.1:
			velocity.y =  clamp(-diff * 5.0, 2.0, 18.0) # sobe para o spawn
		else:
			velocity.y = 0.0

		# Construções têm prioridade sobre Base/Castelo — sem limite de raio
		# (aéreos voam até qualquer ponto do mapa)
		# Actualiza o cache de construções a cada 0.5 s (evita get_nodes_in_group todo frame)
		_timer_cache_construcoes -= delta
		if _timer_cache_construcoes <= 0.0:
			_timer_cache_construcoes = 1.5  # Era 0.5 — aumentado para reduzir queries com muitos aéreos
			_cache_construcoes_aereo = get_tree().get_nodes_in_group("Construcao")

		var alvo_eh_base = alvo_atual == null \
			or alvo_atual.is_in_group("Base") \
			or alvo_atual.is_in_group("Castelo")
		if alvo_eh_base:
			var melhor_c: Node = null
			var menor_d := INF
			for c in _cache_construcoes_aereo:
				if not is_instance_valid(c): continue
				if "esta_destruida" in c and c.esta_destruida: continue
				if "vida_atual" in c and c.vida_atual <= 0: continue
				var d = global_position.distance_to(c.global_position)
				if d < menor_d:
					menor_d = d
					melhor_c = c
			if melhor_c:
				alvo_atual = melhor_c

		if alvo_atual and not esta_morto:
			var alvo_pos  = alvo_atual.global_position
			var dist_xz   = Vector2(global_position.x - alvo_pos.x,
									global_position.z - alvo_pos.z).length()
			var dir_xz    = Vector3(alvo_pos.x - global_position.x, 0.0,
									alvo_pos.z - global_position.z).normalized()
			var vel_aplic = velocidade * max(0.1, _multiplicador_gelo)

			if dist_xz > distancia_ataque:
				velocity.x = dir_xz.x * vel_aplic
				velocity.z = dir_xz.z * vel_aplic
				var look_dir = Vector2(dir_xz.z, dir_xz.x)
				rotation.y  = lerp_angle(rotation.y, look_dir.angle(), 10 * delta)
				if animation_player and animation_player.has_animation(anim_andar):
					animation_player.play(anim_andar)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
				atacar()
		move_and_slide()
		return

	var usando_avoidance = false

	if alvo_atual and nav_agent:
		var alvo_pos = alvo_atual.global_position
		var dist = global_position.distance_to(alvo_pos)
		var dist_xz = Vector2(global_position.x - alvo_pos.x, global_position.z - alvo_pos.z).length()

		if dist < dist_tornar_random:
			alvo_pos += desvio_posicao

		var indo_para_base := alvo_atual.is_in_group("Castelo") or alvo_atual.is_in_group("Base")

		# Só ativa o desvio lateral DEPOIS que o inimigo saiu da aglomeração do spawner.
		# Evita que inimigos grandes (ex.: Franke) entalem tentando fanar pro lado no spawn.
		if _rota_pendente and indo_para_base and posicao_de_spawn.distance_to(global_position) > 3.5:
			_rota_pendente = false
			_rota_ativa = true

		# ── Detector anti-travamento ────────────────────────────────────────────
		# Se mal se mexeu por ~2 s enquanto deveria estar andando, dispara um "escape".
		_stuck_check_acc += delta
		if _stuck_check_acc >= 0.5:
			if global_position.distance_to(_stuck_check_pos) < 0.25 and dist_xz > distancia_ataque:
				_stuck_timer += _stuck_check_acc
			else:
				_stuck_timer = 0.0
			_stuck_check_pos = global_position
			_stuck_check_acc = 0.0
			if _stuck_timer >= 2.0:
				_rota_ativa = false
				_rota_pendente = false
				_stuck_escape = 1.0          # empurra direto pra base por 1 s
				_stuck_timer = 0.0

		# Escape: empurra direto rumo à base, ignorando o avoidance, para desentalar.
		if _stuck_escape > 0.0:
			_stuck_escape -= delta
			var dir_esc := alvo_atual.global_position - global_position
			dir_esc.y = 0.0
			if dir_esc.length() > 0.01:
				dir_esc = dir_esc.normalized()
				var vel_esc: float = velocidade * max(0.1, _multiplicador_gelo)
				velocity.x = dir_esc.x * vel_esc
				velocity.z = dir_esc.z * vel_esc
				rotation.y = lerp_angle(rotation.y, Vector2(dir_esc.z, dir_esc.x).angle(), 10 * delta)
			if (is_on_floor() or eh_aereo) and animation_player and animation_player.has_animation(anim_andar):
				animation_player.play(anim_andar)
			move_and_slide()
			return

		# Rota lateral: enquanto vai para a BASE, mira um waypoint deslocado p/ um lado.
		# Faz a NavMesh rotear por outro caminho. Some quando chega perto do waypoint
		# OU se demorar demais (segurança contra waypoint fora da NavMesh = inimigo travado).
		if _rota_ativa and indo_para_base:
			if not _rota_calculada:
				_rota_waypoint = _calcular_waypoint_lateral(alvo_pos)
				_rota_calculada = true
			_rota_timer += delta
			if _rota_timer < 4.0 and global_position.distance_to(_rota_waypoint) > 2.5:
				alvo_pos = _rota_waypoint
			else:
				_rota_ativa = false   # chegou ao desvio (ou esgotou o tempo) → segue normal para a base

		nav_agent.target_position = alvo_pos
		
		# Verifica fisicamente se colidiu com o alvo (especialmente útil para construções grandes)
		var encostado_no_alvo = false
		if is_on_wall():
			for i in get_slide_collision_count():
				var colisao = get_slide_collision(i)
				if colisao:
					var colisor = colisao.get_collider()
					if not is_instance_valid(colisor): continue
					# Verifica se o colisor É o alvo ou um filho dele (StaticBody3D, etc.)
					var pertence_ao_alvo = (colisor == alvo_atual)
					if not pertence_ao_alvo and is_instance_valid(alvo_atual):
						var no_pai = colisor.get_parent()
						while is_instance_valid(no_pai) and no_pai != get_tree().root:
							if no_pai == alvo_atual:
								pertence_ao_alvo = true
								break
							no_pai = no_pai.get_parent()
					if pertence_ao_alvo or (colisor.is_in_group("Construcao") and alvo_atual.is_in_group("Construcao")):
						encostado_no_alvo = true
						break

		if dist_xz > distancia_ataque and not encostado_no_alvo:
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var dir = (next_pos - global_position).normalized()

				if is_on_floor() and is_on_wall():
					var eh_barreira: bool = false
					for i in get_slide_collision_count():
						var colisao = get_slide_collision(i)
						var colisor = colisao.get_collider()

						if colisor and (colisor.is_in_group("Barreiras") or colisor.is_in_group("Castelo") or colisor.is_in_group("inimigos") or colisor == alvo_atual):
							eh_barreira = true
							break

					if not eh_barreira:
						velocity.y = jump_velocity

				var vel_aplicada = velocidade * max(0.1, _multiplicador_gelo)

				# Passa 0 no eixo Y para o Avoidance calcular com segurança no plano XZ
				var vel_desejada = Vector3(dir.x * vel_aplicada, 0, dir.z * vel_aplicada)
				nav_agent.set_velocity(vel_desejada)
				usando_avoidance = true

				var look_dir = Vector2(dir.z, dir.x)
				rotation.y = lerp_angle(rotation.y, look_dir.angle(), 10 * delta)

				if (is_on_floor() or eh_aereo) and animation_player and animation_player.has_animation(anim_andar):
					animation_player.play(anim_andar)
			else:
				# NavMesh sem caminho válido. Se estávamos desviando, o waypoint lateral
				# provavelmente é inalcançável → abandona o desvio e mira a base direto.
				if _rota_ativa:
					_rota_ativa = false
					alvo_pos = alvo_atual.global_position
				# base bloqueada — avança diretamente
				var vel_aplicada = velocidade * max(0.1, _multiplicador_gelo)
				var dir_direto = Vector3(alvo_pos.x - global_position.x, 0.0,
					alvo_pos.z - global_position.z).normalized()
				velocity.x = dir_direto.x * vel_aplicada
				velocity.z = dir_direto.z * vel_aplicada
				var look_dir = Vector2(dir_direto.z, dir_direto.x)
				rotation.y = lerp_angle(rotation.y, look_dir.angle(), 10 * delta)
				if is_on_floor() and animation_player and animation_player.has_animation(anim_andar):
					animation_player.play(anim_andar)
		else:
			# Comunica ao sistema RVO que a entidade parou, evitando tremulações de rota
			nav_agent.set_velocity(Vector3.ZERO)
			usando_avoidance = true
			atacar()

	if not usando_avoidance:
		move_and_slide()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3):
	if esta_morto: return
	# Aplica apenas o desvio horizontal, preservando a gravidade e o pulo nativos no Y
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()

# Ponto deslocado para um lado, no meio do caminho até a base, snapado na NavMesh.
# Faz o inimigo "abrir" para a esquerda/direita antes de seguir para a base.
func _calcular_waypoint_lateral(base_pos: Vector3) -> Vector3:
	var dir := base_pos - global_position
	dir.y = 0.0
	if dir.length() < 0.1:
		return base_pos
	dir = dir.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x)   # perpendicular no plano XZ
	var meio := (global_position + base_pos) * 0.5
	var ponto := meio + perp * float(_rota_lado) * dist_rota_lateral
	# Garante que o ponto está sobre a NavMesh (senão o caminho falha)
	var mapa_nav := get_world_3d().navigation_map
	if mapa_nav.is_valid():
		ponto = NavigationServer3D.map_get_closest_point(mapa_nav, ponto)
	return ponto

func procurar_novo_alvo():
	var aliados = get_tree().get_nodes_in_group("aliados")
	var construcoes = get_tree().get_nodes_in_group("Construcao")
	var melhor_alvo = null
	var menor_dist = 1000.0 
	
	for aliado in aliados:
		if is_instance_valid(aliado):
			if "vida_atual" in aliado and aliado.vida_atual <= 0: continue 
			var d = global_position.distance_to(aliado.global_position)
			if d <= raio_visao_aliados and d < menor_dist:
				menor_dist = d
				melhor_alvo = aliado
	if melhor_alvo: return melhor_alvo
		
	menor_dist = 1000.0 
	for c in construcoes:
		if is_instance_valid(c):
			if "esta_destruida" in c and c.esta_destruida: continue
			if "vida_atual" in c and c.vida_atual <= 0: continue 
			var d = global_position.distance_to(c.global_position)
			if d <= raio_visao_construcao and d < menor_dist:
				menor_dist = d
				melhor_alvo = c
	if melhor_alvo: return melhor_alvo

	var base_principal = get_tree().get_first_node_in_group("Castelo")
	if not base_principal:
		base_principal = get_tree().get_first_node_in_group("Base")
	return base_principal

func atacar():
	if eh_necromancer:
		return
	if eh_kamikaze:
		_explodir()
		return

	if pode_atacar and alvo_atual:
		pode_atacar = false
		if animation_player and animation_player.has_animation(anim_atacar):
			animation_player.play(anim_atacar)
			SFXManager.tocar_enemy_hit()
		if alvo_atual.has_method("receber_dano"):
			alvo_atual.receber_dano(forca_dano)

		await get_tree().create_timer(tempo_recarga_ataque).timeout
		pode_atacar = true

func receber_dano(qtd, origem = "torre", critico := false):
	if esta_morto: return

	if eh_aereo and origem == "player":
		return

	vida_atual -= qtd
	_mostrar_dano_flutuante(int(qtd), origem, critico)
	
	if barra_vida_boss:
		var original_pos = canvas_boss.get_child(0).position
		var tw_shake = create_tween()
		for i in range(4):
			var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
			tw_shake.tween_property(canvas_boss.get_child(0), "position", original_pos + offset, 0.05)
		tw_shake.tween_property(canvas_boss.get_child(0), "position", original_pos, 0.05)

		# Calcula a porcentagem de vida e interpola na escala visual delimitada do boss
		var pct_vida: float = max(float(vida_atual) / float(vida_maxima), 0.0)
		var valor_visual: float = lerp(limite_visual_min, limite_visual_max, pct_vida)

		var tw_barra = create_tween()
		tw_barra.tween_property(barra_vida_boss, "value", valor_visual, 0.1).set_trans(Tween.TRANS_QUINT)
		
		var tw_fantasma = create_tween()
		tw_fantasma.tween_interval(0.4) 
		tw_fantasma.tween_property(barra_fantasma, "value", valor_visual, 0.8).set_trans(Tween.TRANS_SINE)
	
	if som_dano_stream:
		SFXManager.tocar_som_hit()
	
	if modelo_3d:
		# Bump de escala no impacto
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(modelo_3d, "scale", escala_original * 1.2, 0.1)
		tw.chain().tween_property(modelo_3d, "scale", escala_original, 0.1)
		# Flash de hit com material pré-criado (sem find_children nem StandardMaterial3D.new() por hit)
		if _mat_flash:
			if _flash_tween and _flash_tween.is_valid():
				_flash_tween.kill()
			_mat_flash.albedo_color = Color(1, 1, 1, 0.6)
			for child in _meshes_modelo:
				if is_instance_valid(child):
					child.material_overlay = _mat_flash
			_flash_tween = create_tween()
			_flash_tween.tween_property(_mat_flash, "albedo_color:a", 0.0, 0.15)
			_flash_tween.tween_callback(func(): if is_instance_valid(self): _atualizar_tints())

	if vida_atual <= 0: morrer()
	
func invocar_minions():
	if cena_minion == null:
		push_warning("Necromante tentou invocar, mas não há cena configurada!")
		pode_invocar = false 
		return
	
	var minions_vivos = []
	for minion in meus_minions_ativos:
		if is_instance_valid(minion) and not minion.get("esta_morto"):
			minions_vivos.append(minion)
	meus_minions_ativos = minions_vivos
	
	if meus_minions_ativos.size() >= limite_minions_vivos:
		await get_tree().create_timer(tempo_recarga_invocacao).timeout
		pode_invocar = true
		return
		
	pode_invocar = false
	esta_invocando = true
	
	velocity.x = 0
	velocity.z = 0
	
	if animation_player and animation_player.has_animation(anim_invocar):
		animation_player.play(anim_invocar)
		await get_tree().create_timer(1.0).timeout 
		
	if esta_morto: 
		return

	var nav_map = get_world_3d().navigation_map
	
	var vagas_livres = limite_minions_vivos - meus_minions_ativos.size()
	var qtd_a_invocar = min(qtd_minions_por_vez, vagas_livres)

	for i in range(qtd_a_invocar):
		var minion = cena_minion.instantiate()
		get_parent().add_child(minion)
		
		var angulo = (PI * 2 / qtd_a_invocar) * i
		var offset = Vector3(cos(angulo), 0, sin(angulo)) * raio_de_invocacao
		var posicao_desejada = global_position + offset
		
		var posicao_segura = NavigationServer3D.map_get_closest_point(nav_map, posicao_desejada)
		minion.global_position = posicao_segura
		
		meus_minions_ativos.append(minion)

	esta_invocando = false
	await get_tree().create_timer(tempo_recarga_invocacao).timeout
	pode_invocar = true

func morrer():
	esta_morto = true
	velocity = Vector3.ZERO
	SFXManager.tocar_som_dead()
	
	if nav_agent:
		nav_agent.set_velocity(Vector3.ZERO)
	remove_from_group("inimigos")
	remove_from_group("Chefe")  # bosses (ex.: Kraken) saem do grupo já na morte, senão a wave nunca termina
	GameManager.inimigo_morreu.emit()  # Notifica spawners (substitui polling de grupo)
	GameManager.registrar_inimigo_morto()  # estatística (também paga o OURO_ABATE)
	# OURO_ABATE: indicador visual de moeda ganha no abate
	if GameManager.moedas_por_abate > 0:
		_mostrar_moeda_flutuante(GameManager.moedas_por_abate)
	_explosao_morte()  # partícula de "poof" na morte
	# EXPLOSAO_INIMIGO: ao morrer, fere os inimigos por perto (efeito dominó)
	if GameManager.dano_explosao_inimigo > 0:
		_explodir_em_inimigos()

	if GameManager.modo_infinito:
		var drop: int = 1
		match tipo_inimigo:
			Categoria.MINI_BOSS: drop = 5
			Categoria.BOSS: drop = 15
			_: drop = 1
		GameManager.moedas += drop
		get_tree().call_group("Interface", "atualizar_moedas")

	if $CollisionShape3D:
		$CollisionShape3D.set_deferred("disabled", true)
		
	if $SensorAtaque:
		$SensorAtaque.set_deferred("monitoring", false)
		$SensorAtaque.set_deferred("monitorable", false)
		
	if animation_player and animation_player.has_animation(anim_morrer):
		animation_player.play(anim_morrer)
		
	if canvas_boss:
		var tw_boss = create_tween()
		tw_boss.tween_interval(1.5)
		tw_boss.tween_property(canvas_boss.get_child(0), "modulate:a", 0.01, 1.0)
		tw_boss.finished.connect(canvas_boss.queue_free)
	
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
	tw.tween_callback(queue_free)

# ==========================================
# JUICE: número de dano flutuante + partícula de morte
# ==========================================
# Escala do número de dano POR FASE (ajuste manual aqui). 1.0 = padrão.
# Mapas maiores (ex.: 5) costumam precisar de números maiores para ficarem legíveis.
const ESCALA_DANO_POR_FASE := {1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0, 5: 1.6, 6: 1.0}

func _mostrar_dano_flutuante(qtd: int, origem: String = "torre", critico: bool = false) -> void:
	if qtd <= 0:
		return
	if not Global.numeros_dano_ativo:
		return
	var pai = get_parent()
	if not is_instance_valid(pai):
		return
	var escala_fase: float = float(ESCALA_DANO_POR_FASE.get(GameManager.fase_atual, 1.0))
	var lbl := Label3D.new()
	lbl.text = (str(qtd) + "!") if critico else str(qtd)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.fixed_size = false  # escala com a distância da câmera (senão fica gigante)
	lbl.pixel_size = 0.007 * escala_fase * (1.3 if critico else 1.0)  # crítico um pouco maior
	lbl.font_size = 36
	lbl.outline_size = 12
	lbl.outline_modulate = Color(0, 0, 0, 0.9)
	if critico:
		lbl.modulate = Color(1.0, 0.18, 0.12)   # vermelho de crítico
		lbl.rotation_degrees.z = -12.0           # leve inclinação
	else:
		# Cor por origem: fogo=laranja, gelo=azul, senão dourado
		match origem:
			"fogo": lbl.modulate = Color(1.0, 0.55, 0.15)
			"gelo": lbl.modulate = Color(0.55, 0.85, 1.0)
			_:      lbl.modulate = Color(1.0, 0.93, 0.45)
	pai.add_child(lbl)
	lbl.global_position = global_position + Vector3(randf_range(-0.25, 0.25), 1.1, 0)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y + 0.9, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

# OURO_ABATE: mostra "+N" dourado subindo quando o inimigo é derrotado com a carta ativa.
func _mostrar_moeda_flutuante(qtd: int) -> void:
	if qtd <= 0:
		return
	var pai = get_parent()
	if not is_instance_valid(pai):
		return
	var escala_fase: float = float(ESCALA_DANO_POR_FASE.get(GameManager.fase_atual, 1.0))
	var lbl := Label3D.new()
	lbl.text = "+%d" % qtd
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.fixed_size = false
	lbl.pixel_size = 0.0075 * escala_fase
	lbl.font_size = 34
	lbl.outline_size = 12
	lbl.outline_modulate = Color(0.15, 0.10, 0.0, 0.9)
	lbl.modulate = Color(1.0, 0.84, 0.20)   # dourado de moeda
	pai.add_child(lbl)
	lbl.global_position = global_position + Vector3(randf_range(-0.2, 0.2), 1.5, 0)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y + 1.1, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

func _explodir_em_inimigos() -> void:
	# EXPLOSAO_INIMIGO: fere os inimigos por perto ao morrer
	var raio := 3.0
	for outro in get_tree().get_nodes_in_group("inimigos"):
		if outro == self or not is_instance_valid(outro):
			continue
		if global_position.distance_to(outro.global_position) <= raio and outro.has_method("receber_dano"):
			outro.receber_dano(GameManager.dano_explosao_inimigo, "fogo")

func _explosao_morte() -> void:
	var pai = get_parent()
	if not is_instance_valid(pai):
		return
	var p := CPUParticles3D.new()
	var m := SphereMesh.new()
	m.radius = 0.06
	m.height = 0.12
	m.radial_segments = 6
	m.rings = 3
	p.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.9, 0.82, 0.6)  # poeira
	p.material_override = mat
	p.local_coords = true  # emite no frame do nó (senão a 1ª leva sai na origem do mapa)
	p.emitting = false
	p.one_shot = true
	p.amount = 12
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.spread = 80.0
	p.gravity = Vector3(0, -7, 0)
	p.initial_velocity_min = 2.2
	p.initial_velocity_max = 4.8
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	# Captura a posição antes de adicionar à árvore para garantir o ponto certo
	var pos_morte := global_position + Vector3(0, 0.4, 0)
	pai.add_child(p)
	p.global_position = pos_morte
	# Dispara só no próximo frame, já com a transform aplicada
	p.restart()
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(p.lifetime + 0.3)
	tw.tween_callback(p.queue_free)

# ==========================================
# GERAÇÃO DA INTERFACE DO BOSS
# ==========================================
# Posiciona um Control dentro da interface do boss a partir de um Rect2 em frações (0..1).
func _aplicar_rect_boss(ctrl: Control, r: Rect2, largura: float, altura: float) -> void:
	ctrl.set_anchor(SIDE_LEFT,   0.0)
	ctrl.set_anchor(SIDE_TOP,    0.0)
	ctrl.set_anchor(SIDE_RIGHT,  0.0)
	ctrl.set_anchor(SIDE_BOTTOM, 0.0)
	ctrl.offset_left   = r.position.x * largura
	ctrl.offset_top    = r.position.y * altura
	ctrl.offset_right  = (r.position.x + r.size.x) * largura
	ctrl.offset_bottom = (r.position.y + r.size.y) * altura

func _criar_interface_do_boss() -> void:
	canvas_boss = CanvasLayer.new()
	canvas_boss.layer = 10
	add_child(canvas_boss)

	# ── Calcula o tamanho do container proporcional à textura ──────────
	# O container tem o MESMO aspecto da imagem → STRETCH_SCALE não distorce
	var tex_size := Vector2(900.0, 180.0)   # fallback caso não haja textura
	if textura_moldura_boss:
		tex_size = Vector2(textura_moldura_boss.get_width(), textura_moldura_boss.get_height())

	var vp_size  := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280.0, 720.0)
	var max_w: float = vp_size.x * escala_tamanho_boss
	var escala: float = min(max_w / tex_size.x, 1.0)       # nunca amplia além do tamanho real
	var w: float = tex_size.x * escala
	var h: float = tex_size.y * escala

	# Padding transparente da imagem (muitas têm uma borda vazia em cima/à esquerda).
	# Descontamos para o quadro encostar de verdade no canto, sem espaço morto.
	var pad := Vector2.ZERO
	if textura_moldura_boss:
		var img := textura_moldura_boss.get_image()
		if img:
			if img.is_compressed():
				img.decompress()
			var usado := img.get_used_rect()
			if usado.size.x > 0 and usado.size.y > 0:
				pad.x = float(usado.position.x) / tex_size.x
				pad.y = float(usado.position.y) / tex_size.y

	# Container raiz — posicionado pelo canto superior-esquerdo (export 'pos_boss').
	var px := vp_size.x * pos_boss.x - pad.x * w
	var py := vp_size.y * pos_boss.y - pad.y * h
	var root := Control.new()
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	root.set_anchor(SIDE_LEFT,   0.0)
	root.set_anchor(SIDE_RIGHT,  0.0)
	root.set_anchor(SIDE_TOP,    0.0)
	root.set_anchor(SIDE_BOTTOM, 0.0)
	root.offset_left   = px
	root.offset_right  = px + w
	root.offset_top    = py
	root.offset_bottom = py + h
	canvas_boss.add_child(root)

	# ── Moldura (quadro de madeira/pedra) — posicionável via moldura_rect ──
	if textura_moldura_boss:
		var frame := TextureRect.new()
		frame.texture      = textura_moldura_boss
		# IGNORE_SIZE: o quadro respeita o rect (w×h) em vez do tamanho nativo da imagem.
		# Sem isso a moldura renderiza maior que o root e o slot desalinha da barra.
		frame.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		_aplicar_rect_boss(frame, moldura_rect, w, h)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(frame)

	# ── Retrato do boss — desenhado separadamente, posicionável via retrato_rect ──
	if retrato_boss:
		var retr := TextureRect.new()
		retr.texture      = retrato_boss
		_aplicar_rect_boss(retr, retrato_rect, w, h)
		retr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(retr)

	# ── Âncoras da barra dentro da interface (frações vindas de barra_rect) ──
	var BAR_L := barra_rect.position.x
	var BAR_R := barra_rect.position.x + barra_rect.size.x
	var BAR_T := barra_rect.position.y
	var BAR_B := barra_rect.position.y + barra_rect.size.y

	# ── Barra fantasma (branca, lag ~0.4 s atrás da vida real) ────────
	var sty_ghost := StyleBoxFlat.new()
	sty_ghost.bg_color = Color(1.0, 1.0, 1.0, 0.40)
	sty_ghost.set_corner_radius_all(6)

	barra_fantasma = ProgressBar.new()
	barra_fantasma.set_anchor(SIDE_LEFT,   BAR_L)
	barra_fantasma.set_anchor(SIDE_RIGHT,  BAR_R)
	barra_fantasma.set_anchor(SIDE_TOP,    BAR_T)
	barra_fantasma.set_anchor(SIDE_BOTTOM, BAR_B)
	barra_fantasma.offset_left   = -ajuste_tamanho_preenchimento.x / 2.0
	barra_fantasma.offset_right  = ajuste_tamanho_preenchimento.x / 2.0
	barra_fantasma.offset_top    = -ajuste_tamanho_preenchimento.y / 2.0
	barra_fantasma.offset_bottom = ajuste_tamanho_preenchimento.y / 2.0
	barra_fantasma.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	barra_fantasma.max_value       = 100.0
	barra_fantasma.value           = limite_visual_max
	barra_fantasma.show_percentage = false
	barra_fantasma.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	barra_fantasma.add_theme_stylebox_override("fill",       sty_ghost)
	root.add_child(barra_fantasma)

	# ── Barra de vida real (cor definida pelo export cor_barra_boss) ───
	var sty_fill := StyleBoxFlat.new()
	sty_fill.bg_color        = cor_barra_boss
	sty_fill.set_corner_radius_all(6)
	sty_fill.border_width_top = 2
	sty_fill.border_color     = cor_barra_boss.lightened(0.40)

	barra_vida_boss = ProgressBar.new()
	barra_vida_boss.set_anchor(SIDE_LEFT,   BAR_L)
	barra_vida_boss.set_anchor(SIDE_RIGHT,  BAR_R)
	barra_vida_boss.set_anchor(SIDE_TOP,    BAR_T)
	barra_vida_boss.set_anchor(SIDE_BOTTOM, BAR_B)
	barra_vida_boss.offset_left   = -ajuste_tamanho_preenchimento.x / 2.0
	barra_vida_boss.offset_right  = ajuste_tamanho_preenchimento.x / 2.0
	barra_vida_boss.offset_top    = -ajuste_tamanho_preenchimento.y / 2.0
	barra_vida_boss.offset_bottom = ajuste_tamanho_preenchimento.y / 2.0
	barra_vida_boss.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	barra_vida_boss.max_value       = 100.0
	barra_vida_boss.value           = limite_visual_max
	barra_vida_boss.show_percentage = mostrar_porcentagem_vida
	barra_vida_boss.add_theme_font_size_override("font_size", tamanho_fonte_porcentagem)
	barra_vida_boss.add_theme_color_override("font_color", cor_fonte_porcentagem)
	barra_vida_boss.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	barra_vida_boss.add_theme_stylebox_override("fill",       sty_fill)
	root.add_child(barra_vida_boss)

	if separacao_porcentagem_boss > 0.0:
		var num_separadores = int(100.0 / separacao_porcentagem_boss)
		for i in range(1, num_separadores):
			var pct = (i * separacao_porcentagem_boss) / 100.0
			if pct >= 1.0: break
			
			var separador = ColorRect.new()
			separador.color = Color(0.1, 0.1, 0.1, 0.7)
			separador.set_anchor(SIDE_LEFT, pct)
			separador.set_anchor(SIDE_RIGHT, pct)
			separador.set_anchor(SIDE_TOP, 0.0)
			separador.set_anchor(SIDE_BOTTOM, 1.0)
			separador.offset_left = -1.5
			separador.offset_right = 1.5
			separador.offset_top = 0.0
			separador.offset_bottom = 0.0
			separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
			barra_vida_boss.add_child(separador)

	# Pulso de brilho suave na barra
	var tw_glow := create_tween().set_loops()
	tw_glow.tween_property(barra_vida_boss, "modulate:v", 1.30, 0.7).set_trans(Tween.TRANS_SINE)
	tw_glow.tween_property(barra_vida_boss, "modulate:v", 1.00, 0.7).set_trans(Tween.TRANS_SINE)

func _explodir():
	if esta_explodindo: return
	esta_explodindo = true
	velocidade = 0.0 
	
	if animation_player and animation_player.has_animation(anim_explodir):
		animation_player.play(anim_explodir)
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout 
		
	_criar_efeito_explosao()
	
	var alvos_potenciais = get_tree().get_nodes_in_group("Construcao")
	if not prioriza_construcoes:
		alvos_potenciais.append_array(get_tree().get_nodes_in_group("Player"))
		
	for alvo in alvos_potenciais:
		if is_instance_valid(alvo) and alvo.has_method("receber_dano"):
			var distancia = global_position.distance_to(alvo.global_position)
			if distancia <= raio_explosao:
				alvo.receber_dano(dano_explosao)
				
	if animation_player and animation_player.has_animation(anim_pos_explosao):
		animation_player.play(anim_pos_explosao)
		await animation_player.animation_finished
				
	queue_free()
	
func _criar_efeito_explosao():
	var node_explosao = Node3D.new()
	get_tree().current_scene.add_child(node_explosao)
	node_explosao.global_position = global_position

	var luz = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.4, 0.0) 
	luz.light_energy = 8.0 
	luz.omni_range = raio_explosao * 2.5
	node_explosao.add_child(luz)

	var mesh_esfera = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	mesh_esfera.mesh = sphere
	
	var mat_esfera = StandardMaterial3D.new()
	mat_esfera.albedo_color = Color(1.0, 0.1, 0.0, 0.9) 
	mat_esfera.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_esfera.emission_enabled = true
	mat_esfera.emission = Color(1.0, 0.3, 0.0) 
	mat_esfera.emission_energy_multiplier = 4.0
	sphere.surface_set_material(0, mat_esfera)
	node_explosao.add_child(mesh_esfera)

	var tween = get_tree().create_tween()
	var tamanho_final = raio_explosao * 2.0
	var tempo_explosao = 0.6 

	tween.tween_property(mesh_esfera, "scale", Vector3(tamanho_final, tamanho_final, tamanho_final), tempo_explosao).from(Vector3.ZERO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat_esfera, "albedo_color:a", 0.0, tempo_explosao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(luz, "light_energy", 0.0, tempo_explosao * 0.7)

	tween.tween_callback(node_explosao.queue_free)

func _tocar_cutscene():
	# Sem vídeo configurado: pula a cutscene (evita tela preta) e vai direto à interface.
	if video_stream == null:
		_criar_interface_do_boss()
		return
	var cutscene = preload("res://Cenas Locais/boss_intro.tscn").instantiate()
	get_tree().current_scene.add_child(cutscene)

	cutscene.reproduzir_stream(video_stream, nome_inimigo, subtitulo_inimigo, audio_intro)

	await cutscene.cutscene_finished

	_criar_interface_do_boss()

# ==========================================
# SENSOR DE TRANSPARÊNCIA — criação automática
# Garante que TODOS os inimigos tenham o sensor, mesmo sem ele no .tscn.
# Para cenas que já têm (ex.: Orc), apenas assegura que os sinais estão ligados.
# ==========================================
func _configurar_sensor_transparencia() -> void:
	var sensor: Area3D = get_node_or_null("SensorTransparencia")
	if sensor:
		# Já existe — garante que os sinais estão conectados
		if not sensor.body_entered.is_connected(_on_area_transparencia_body_entered):
			sensor.body_entered.connect(_on_area_transparencia_body_entered)
		if not sensor.body_exited.is_connected(_on_area_transparencia_body_exited):
			sensor.body_exited.connect(_on_area_transparencia_body_exited)
		return

	# Cria dinamicamente para inimigos que ainda não têm o nó na cena
	sensor = Area3D.new()
	sensor.name = "SensorTransparencia"
	add_child(sensor)

	var col_shape := CollisionShape3D.new()
	var col_principal: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if col_principal and col_principal.shape:
		col_shape.shape     = col_principal.shape.duplicate()
		col_shape.transform = col_principal.transform
	else:
		# Fallback: cápsula genérica caso não exista CollisionShape3D raiz
		var caps := CapsuleShape3D.new()
		caps.radius = 0.3
		caps.height = 0.6
		col_shape.shape = caps

	sensor.add_child(col_shape)
	sensor.body_entered.connect(_on_area_transparencia_body_entered)
	sensor.body_exited.connect(_on_area_transparencia_body_exited)

# ==========================================
# EFEITO DE DITHERING (TRANSPARÊNCIA VISUAL)
# ==========================================
# EFEITOS VISUAIS DE STATUS (GELO / FOGO)
# ==========================================
func aplicar_gelo() -> void:
	if GameManager.multiplicador_velocidade_inimigo >= 1.0: return
	_multiplicador_gelo = GameManager.multiplicador_velocidade_inimigo
	_gelo_timer = 3.0
	if not _gelo_ativo:
		_gelo_ativo = true
		_atualizar_tints()

func iniciar_queimadura(dano_tick: int) -> void:
	# Reinicia o acumulador — o _physics_process aplica os ticks sem create_timer
	_fogo_dano_tick       = dano_tick
	_fogo_ticks_restantes = 3
	_fogo_timer_acum      = 0.0
	if not _fogo_ativo:
		_fogo_ativo = true
		_atualizar_tints()

func iniciar_veneno(dano_tick: int = 0) -> void:
	if dano_tick <= 0:
		return
	_veneno_dano_tick       = dano_tick
	_veneno_ticks_restantes = 4
	_veneno_timer_acum      = 0.0
	if not _veneno_ativo:
		_veneno_ativo = true
		_atualizar_tints()

func parar_veneno() -> void:
	if _veneno_ativo:
		_veneno_ativo = false
		_atualizar_tints()

func _atualizar_tints() -> void:
	var _raiz: Node = modelo_3d if modelo_3d else self
	var mat: StandardMaterial3D = null
	if _gelo_ativo or _fogo_ativo or _veneno_ativo:
		mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if _gelo_ativo and _fogo_ativo:
			mat.albedo_color = Color(0.7, 0.3, 1.0, 0.40)
		elif _fogo_ativo:
			mat.albedo_color = Color(1.0, 0.35, 0.05, 0.40)
		elif _gelo_ativo:
			mat.albedo_color = Color(0.25, 0.65, 1.0, 0.35)
		else:
			mat.albedo_color = Color(0.2, 0.9, 0.2, 0.40)
	# Usa cache de meshes do _ready() — sem find_children() por mudança de status
	for mesh in _meshes_modelo:
		if is_instance_valid(mesh):
			mesh.material_overlay = mat

# ==========================================
func _set_transparencia(no: Node, valor: float):
	if no is MeshInstance3D:
		if valor > 0.0:
			# Cria o ShaderMaterial uma vez, reutiliza nas chamadas seguintes
			if _mat_dither == null:
				_mat_dither = ShaderMaterial.new()
				_mat_dither.shader = preload("res://Shaders/dithering_effect.gdshader")
				var mat_original = no.get_active_material(0)
				if mat_original and "albedo_texture" in mat_original:
					_mat_dither.set_shader_parameter("albedo_texture", mat_original.albedo_texture)
			_mat_dither.set_shader_parameter("alpha_threshold", valor)
			no.material_override = _mat_dither
		else:
			no.material_override = null

	for filho in no.get_children():
		_set_transparencia(filho, valor)

func _on_area_transparencia_body_entered(body):
	if body.is_in_group("Player"):
		if modelo_3d:
			_set_transparencia(modelo_3d, 0.25)
		else:
			_set_transparencia(self, 0.25)

func _on_area_transparencia_body_exited(body):
	if body.is_in_group("Player"):
		if modelo_3d:
			_set_transparencia(modelo_3d, 0.0)
		else:
			_set_transparencia(self, 0.0)
