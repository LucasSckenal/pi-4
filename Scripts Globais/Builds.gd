extends Node3D

# ==========================================
# ÍCONES DE TIPO (substitutos dos emojis)
# ==========================================
const _ICON_TORRE     = preload("res://Assets/Icons/Torre.png")
const _ICON_PICARETA  = preload("res://Assets/Icons/Picareta.png")
const _ICON_CASA      = preload("res://Assets/Icons/Casa.png")
const _ICON_TRIGO     = preload("res://Assets/Icons/Trigo.png")
const _ICON_ESCUDO    = preload("res://Assets/Icons/Escudo.png")
const _ICON_CASTELO   = preload("res://Assets/Icons/Castelo.png")
const _ICON_CRANIO    = preload("res://Assets/Icons/Cranio.png")
const _ICON_GUINDASTE = preload("res://Assets/Icons/Guindaste.png")
const _ICON_CADEADO   = preload("res://Assets/Icons/Cadeado.png")

# ==========================================
# ENUM PARA O TIPO DE CONSTRUÇÃO
# ==========================================
enum TipoConstrucao {
	TORRE,
	MINA,
	CASA,
	MOINHO,
	QUARTEL,
	BASE,
	CALDEIRON   # 6 — Veneno em área, exclusivo Mapa 3
}

# ==========================================
# SHADER DE VIDA CUSTOMIZADA
# ==========================================
const BARRA_VIDA_SHADER = """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, blend_mix;

uniform float u_aspect;
uniform vec4 progress_color : source_color = vec4(0.15, 0.85, 0.20, 1.0);
uniform vec4 background_color : source_color = vec4(0.08, 0.08, 0.08, 0.88);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.9;

const float corner_radius = 0.2;
const float grain_darkness = 0.01;
const vec4 white_color = vec4(1.0);
const float gradient_length = 0.05;
const float star_size = 20.0;
const float border_size = 0.05;
const float edge_softness = 0.01;

float sdBox(in vec2 pos, in vec2 half_size) {
    vec2 d = abs(pos) - half_size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRoundedBox(in vec2 pos, in vec2 half_size, in float r) {
    return sdBox(pos , half_size) - r;
}

float sdStar(in vec2 p, in float r) {
    const float k1x = 0.809016994;
    const float k2x = 0.309016994;
    const float k1y = 0.587785252;
    const float k2y = 0.951056516;
    const float k1z = 0.726542528;
    const vec2  v1  = vec2( k1x,-k1y);
    const vec2  v2  = vec2(-k1x,-k1y);
    const vec2  v3  = vec2( k2x,-k2y);
    p.x = abs(p.x);
    p -= 2.0*max(dot(v1,p),0.0)*v1;
    p -= 2.0*max(dot(v2,p),0.0)*v2;
    p.x = abs(p.x);
    p.y -= r;
    return length(p-v3*clamp(dot(p,v3),0.0,k1z*r)) * sign(p.y*v3.x-p.x*v3.y);
}

void vertex() {
	// Billboard cilíndrico: só gira em torno do Y do mundo — não inclina com a câmera
	// Isso impede que a barra suba ou suma quando o jogador se aproxima
	vec3 world_up  = vec3(0.0, 1.0, 0.0);
	vec3 cam_right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 cam_fwd   = normalize(cross(cam_right, world_up));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(cam_right, 0.0),
		vec4(world_up,  0.0),
		vec4(cam_fwd,   0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
    vec2 aspect = vec2(u_aspect, 1.0);
    vec2 half_size = vec2(0.5, 0.5) * aspect;
    vec2 pos = UV * aspect - half_size;
    float distance = sdRoundedBox(pos, half_size - corner_radius, corner_radius);

    vec4 final_color;
    if (UV.x < progress) {
        final_color = progress_color;
        float position_gradient = UV.x - (progress - gradient_length);
        float normalized_position = clamp(position_gradient / gradient_length, 0.0, 1.0);
        final_color += white_color * normalized_position * 0.2;

        float shift = TIME * 1.5;
        vec2 grid_coord = (UV * aspect * 10.0 + vec2(-shift, shift));
        const mat2 rot36 = mat2(vec2(0.8090, -0.5878), vec2(0.5878, 0.8090));
        grid_coord *= rot36;
        float index_y = floor(grid_coord.y);
        vec2 fraction = fract(grid_coord) - 0.5;
        if (mod(index_y, 2.0) == 1.0) fraction.x = fract(grid_coord.x + 0.5) - 0.5;
        
        if (sdStar(fraction, 0.3) < 0.0) final_color *= 0.93;
    } else {
        final_color = background_color;
    }

    float border_alpha = 1.0 - smoothstep(border_size - edge_softness, border_size, abs(distance));
    final_color = mix(final_color, outline_color, border_alpha);
    float smoothed_alpha = 1.0 - smoothstep(0.0, edge_softness, distance);
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a * smoothed_alpha;
}
"""

# ==========================================
# CONFIGURAÇÕES BÁSICAS (COMUNS A TODOS)
# ==========================================
@export var tipo: TipoConstrucao = TipoConstrucao.TORRE :
	set(valor):
		tipo = valor
		notify_property_list_changed()

@export var custo_moedas: int = 5
@export var vida_maxima: int = 20

# Define a escala padrão aplicada aos modelos 3D instanciados por esta construção.
@export var escala_modelo: Vector3 = Vector3(0.44, 0.44, 0.44)

@export_group("Efeitos Visuais")
@export var espessura_outline_normal: float = 1.0
@export var espessura_outline_hover: float = 3.0

# ==========================================
# CONFIGURAÇÕES ESPECÍFICAS PARA TORRES
# ==========================================
@export_group("Atributos de Torre")
@export var dano: int = 30
@export var tempo_ataque_base: float = 1.5
@export var alcance: float = 10.0
@export var cena_flecha: PackedScene
@export var cena_raio_eletrico: PackedScene
@export var cena_bala_morteiro: PackedScene
@export var tipo_ataque_proprio: String = ""  # "chain_lightning" para Tesla standalone
@export var ponto_de_tiro: NodePath
@export var area_ataque_path: NodePath
@export var indicador_alcance: MeshInstance3D

# ==========================================
# CONFIGURAÇÕES ESPECÍFICAS PARA QUARTEL
# ==========================================
@export_group("Atributos de Quartel")
@export var cena_aliado: PackedScene
@export var numero_aliados_base: int = 1
@export var tempo_respawn: float = 5.0 # Tempo em segundos para respawnar
@export var ponto_spawn_path: NodePath
@onready var sprite_respawn = get_node_or_null("SpriteRespawn")
@onready var barra_respawn = get_node_or_null("RespawnViewport/BarraRespawn")

var soldados_vivos: int = 0 # Controle interno

# ==========================================
# CONFIGURAÇÕES ECONÔMICAS (MINA, CASA, MOINHO)
# ==========================================
@export_group("Atributos Econômicos")
@export var moedas_por_onda: int = 2

# ==========================================
# CONFIGURAÇÕES DE BARRA DE VIDA (OPCIONAL)
# ==========================================
@export_group("Barra de Vida (opcional)")
@export var tem_barra_vida: bool = false
@export var caminho_barra_vida: NodePath
@export var caminho_container_barra: NodePath

# ==========================================
# SISTEMA DE UPGRADES (BASE)
# ==========================================
@export_group("Upgrades Base")
@export var nivel_atual: int = 0
@export var upgrade_custos: Array[int] = []          # Usado se não tiver paths
@export var upgrade_dano_por_nivel: Array[int] = []
@export var upgrade_moedas_por_nivel: Array[int] = []
@export var upgrade_aliados_por_nivel: Array[int] = []
@export var upgrade_velocidade_por_nivel: Array[float] = []
@export var upgrade_alcance_por_nivel: Array[float] = []
@export var upgrade_vida_por_nivel: Array[int] = []
@export var modelos_por_nivel: Array[PackedScene] = []  # Modelos visuais para cada nível

# ==========================================
# SISTEMA DE PATHS (MÚLTIPLOS CAMINHOS)
# ==========================================
@export_group("Sistema de Paths")
@export var tem_paths: bool = false
@export var upgrade_paths: Array[UpgradePathData] = []
var caminho_atual: int = -1  # -1 = nenhum caminho escolhido

# ==========================================
# REFERÊNCIAS
# ==========================================
@onready var ponto_tiro = get_node_or_null(ponto_de_tiro)
@onready var ponto_spawn = get_node_or_null(ponto_spawn_path)
@onready var area_ataque = get_node_or_null(area_ataque_path)
@onready var barra_vida = get_node_or_null(caminho_barra_vida) if tem_barra_vida else null
@onready var container_barra = get_node_or_null(caminho_container_barra) if tem_barra_vida else null
@onready var timer_ataque = get_node_or_null("TimerAtaque") if tipo == TipoConstrucao.TORRE else null
@onready var modelo_anchor = get_node_or_null("ModeloAnchor")  # Nó vazio para conter o modelo 3D

# Hover
var _tween_hover: Tween
var _escalas_base_malhas: Dictionary = {}

# ==========================================
# INFORMAÇÕES DE INTERFACE
# ==========================================
@export_group("Interface")
@export var nome_construcao: String = "Construção"
@export var icone: Texture2D

# ==========================================
# BALANCEAMENTO CUSTOMIZADO (opcional)
# Se preenchido, sobrescreve custo/vida/moedas/dano
# com os valores do CSV usando esse prefixo.
# Ex.: "mercado" lê mercado_custo, mercado_vida, mercado_renda_onda
# ==========================================
@export var chave_csv_prefixo: String = ""

# ==========================================
# VARIÁVEIS DE ESTADO
# ==========================================
var y_inicial: float
var is_fantasma: bool = false
var _caldeiron_timer: float = 0.0
var _inimigos_no_veneno: Array = []  # Inimigos dentro do círculo de veneno
var vida_atual: int
var inimigos_no_alcance = []

# ── Barra de vida 3D (criada por código, funciona em todos os builds) ──────
var _barra_3d_mesh: MeshInstance3D
var _barra_3d_mat: ShaderMaterial

var alvo_atual: Node3D = null
var esta_destruida: bool = false
var _luz_interna: OmniLight3D = null   # acende à noite

# Indicador de upgrade disponível — anel + seta + pontos de luz, criados por código.
# Dois modos: DESTAQUE (anel brilhante + seta ⬆ + pontos) e SUTIL (só anel apagado).
var _indicador_upgrade: Node3D          = null
var _anel_upgrade:      MeshInstance3D  = null
var _mat_anel_upgrade:  StandardMaterial3D = null
var _seta_upgrade:      Node3D          = null
var _pontos_upgrade:    Array           = []   # List[MeshInstance3D]
var _timer_indicador:   float           = 0.0  # Atraso entre checagens (evita overhead a cada frame)

# Valores atuais após upgrades (calculados dinamicamente)
var dano_atual: int
var moedas_por_onda_atual: int
var numero_aliados_atual: int
var tempo_ataque_atual: float
var alcance_atual: float

signal construcao_selecionada(construcao: Node)

func _ready():

	y_inicial = position.y
	_resolver_icone_construcao()

	if is_fantasma:
		_modo_fantasma()
		return
		
	if modelo_anchor == null:
		modelo_anchor = Node3D.new()
		modelo_anchor.name = "ModeloAnchor"
		add_child(modelo_anchor)
	
	if tipo == TipoConstrucao.BASE:
		nivel_atual = GameManager.nivel_base

	_aplicar_balanceamento_csv()
	_atualizar_valores_pos_upgrades()
	vida_atual = vida_maxima
	_inicializar_barra_vida()
	if tipo == TipoConstrucao.BASE:
		GameManager.vida_base_maxima = vida_maxima
		GameManager.vida_base_atual = vida_atual
	
	# Carrega o modelo do nível atual (se houver)
	_trocar_modelo(nivel_atual)
	if tipo != TipoConstrucao.BASE:
		_criar_indicador_upgrade()
	if sprite_respawn:
		sprite_respawn.visible = false
		
	match tipo:
		TipoConstrucao.TORRE:
			add_to_group("Torres")
			add_to_group("Construcao")
			_configurar_alcance()
			atualizar_status()
			if timer_ataque:
				timer_ataque.start()
			if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
				var _p = upgrade_paths[caminho_atual]
				if "tipo_ataque" in _p and _p.tipo_ataque == "caldeiron_area":
					_criar_circulo_caldeiron(alcance_atual * 0.85)
		TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO:
			add_to_group("Construcao")
			GameManager.onda_terminada.connect(_pagar_recompensa)
		TipoConstrucao.QUARTEL:
			add_to_group("Construcao")
			GameManager.noite_iniciada.connect(_spawn_aliados)
		TipoConstrucao.CALDEIRON:
			add_to_group("Construcao")
			_criar_circulo_caldeiron(Balanceamento.get_float("caldeiron_alcance", 5.0))
		TipoConstrucao.BASE:
			add_to_group("Construcao")
			add_to_group("Base")
			if Global.DEBUG_MODE:
				print("Base principal estabelecida. Nível: ", nivel_atual)
	
	# Luz interna à noite (sem sombras — performance ok no mobile)
	if GameManager.has_signal("noite_iniciada"):
		GameManager.noite_iniciada.connect(_acender_luz_interna)
		GameManager.noite_iniciada.connect(_remover_borda_interagivel)
		
	if GameManager.has_signal("dia_iniciado"):
		GameManager.dia_iniciado.connect(_apagar_luz_interna)
		GameManager.dia_iniciado.connect(_criar_borda_interagivel)
	
	# Aplica a borda interativa no momento do spawn, caso seja de dia
	if not GameManager.is_night:
		_criar_borda_interagivel()

	# Área de clique (se existir)
	if has_node("AreaClique"):
		$AreaClique.input_event.connect(_on_area_clique)
		$AreaClique.mouse_entered.connect(_on_area_clique_mouse_entered)
		$AreaClique.mouse_exited.connect(_on_area_clique_mouse_exited)
		
	# Área de transparência (se existir)
	if has_node("AreaTransparencia"):
		$AreaTransparencia.input_ray_pickable = false
		$AreaTransparencia.body_entered.connect(_on_area_transparencia_body_entered)
		$AreaTransparencia.body_exited.connect(_on_area_transparencia_body_exited)
	
	for corpo in find_children("*", "StaticBody3D"):
		corpo.input_ray_pickable = true # Garante que ele ouve o mouse/touch
		
		if not corpo.input_event.is_connected(_on_area_clique):
			corpo.input_event.connect(_on_area_clique)
		if not corpo.mouse_entered.is_connected(_on_area_clique_mouse_entered):
			corpo.mouse_entered.connect(_on_area_clique_mouse_entered)
		if not corpo.mouse_exited.is_connected(_on_area_clique_mouse_exited):
			corpo.mouse_exited.connect(_on_area_clique_mouse_exited)
	
	# Notifica a interface sobre a existência desta construção após a inicialização dos grupos
	for interface_node in get_tree().get_nodes_in_group("Interface"):
		if interface_node.has_method("_conectar_construcao"):
			interface_node._conectar_construcao(self)
			
	_registrar_escalas_base(self)
	
# ==========================================
# TRAVA CENTRAL DO TUTORIAL
# ==========================================
func _pode_interagir_tutorial() -> bool:
	if GameManager.is_tutorial_ativo:
		var tutorial = get_tree().get_first_node_in_group("TutorialManager")
		if tutorial and tutorial.visible:
			# REGRA 1: Se o tutorial manda clicar na UI, BLOQUEIA o 3D
			if tutorial.alvo_2d_atual != null:
				return false
			# REGRA 2: Se o tutorial manda clicar noutro objeto que não este, BLOQUEIA
			if tutorial.alvo_3d_atual != null and tutorial.alvo_3d_atual != self:
				return false
	return true

func _on_area_clique(_camera, event, _position, _normal, _shape_idx):
	if esta_destruida: return

	var clicou_mouse = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	var tocou_tela = (event is InputEventScreenTouch and event.pressed)

	if clicou_mouse or tocou_tela:
		if Global.DEBUG_MODE and GameManager.has_method("adicionar_log_debug"):
			GameManager.adicionar_log_debug("SUCESSO: Script _on_area_clique rodou em " + name)
			
		if _pode_interagir_tutorial():
			get_viewport().set_input_as_handled()
			construcao_selecionada.emit(self)

			if tipo == TipoConstrucao.TORRE and indicador_alcance and not GameManager.is_night:
				indicador_alcance.visible = true
				if Global.DEBUG_MODE:
					print("Anel foi ligado!")

# ==========================================
# BALANCEAMENTO CSV POR PREFIXO
# Lê custo, vida, dano e moedas_por_onda do
# CSV quando chave_csv_prefixo está definido.
# Também lê valores padrão para tipos comuns.
# ==========================================
func _aplicar_balanceamento_csv() -> void:
	if chave_csv_prefixo != "":
		custo_moedas    = Balanceamento.get_int(chave_csv_prefixo + "_custo",      custo_moedas)
		vida_maxima     = Balanceamento.get_int(chave_csv_prefixo + "_vida",       vida_maxima)
		moedas_por_onda = Balanceamento.get_int(chave_csv_prefixo + "_renda_onda", moedas_por_onda)
		dano            = Balanceamento.get_int(chave_csv_prefixo + "_dano",       dano)

# ==========================================
# SISTEMA DE UPGRADES (LÓGICA PRINCIPAL)
# ==========================================
func _atualizar_valores_pos_upgrades():
	# Se tem paths e já escolheu um caminho, usa os valores do path
	if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
		var path = upgrade_paths[caminho_atual]
		var idx = nivel_atual - 1  # arrays começam em 0 para nível 1
		if idx >= 0:
			dano_atual = dano + (path.dano_por_nivel[idx] if idx < path.dano_por_nivel.size() else 0)
			moedas_por_onda_atual = moedas_por_onda + (path.moedas_por_nivel[idx] if idx < path.moedas_por_nivel.size() else 0)
			numero_aliados_atual = numero_aliados_base + (path.aliados_por_nivel[idx] if idx < path.aliados_por_nivel.size() else 0)
			tempo_ataque_atual = tempo_ataque_base - (path.velocidade_por_nivel[idx] if idx < path.velocidade_por_nivel.size() else 0.0)
			alcance_atual = alcance + (path.alcance_por_nivel[idx] if idx < path.alcance_por_nivel.size() else 0.0)
			vida_maxima += (path.vida_por_nivel[idx] if idx < path.vida_por_nivel.size() else 0)
		else:
			# Nível 0 (antes do primeiro upgrade) – valores base
			dano_atual = dano
			moedas_por_onda_atual = moedas_por_onda
			numero_aliados_atual = numero_aliados_base
			tempo_ataque_atual = tempo_ataque_base
			alcance_atual = alcance
	else:
		# Sem paths ou ainda não escolheu – usa os arrays base
		var idx = nivel_atual - 1
		if idx >= 0:
			dano_atual = dano + (upgrade_dano_por_nivel[idx] if idx < upgrade_dano_por_nivel.size() else 0)
			moedas_por_onda_atual = moedas_por_onda + (upgrade_moedas_por_nivel[idx] if idx < upgrade_moedas_por_nivel.size() else 0)
			numero_aliados_atual = numero_aliados_base + (upgrade_aliados_por_nivel[idx] if idx < upgrade_aliados_por_nivel.size() else 0)
			tempo_ataque_atual = tempo_ataque_base - (upgrade_velocidade_por_nivel[idx] if idx < upgrade_velocidade_por_nivel.size() else 0.0)
			alcance_atual = alcance + (upgrade_alcance_por_nivel[idx] if idx < upgrade_alcance_por_nivel.size() else 0.0)
			vida_maxima += (upgrade_vida_por_nivel[idx] if idx < upgrade_vida_por_nivel.size() else 0)
		else:
			# Nível 0
			dano_atual = dano
			moedas_por_onda_atual = moedas_por_onda
			numero_aliados_atual = numero_aliados_base
			tempo_ataque_atual = tempo_ataque_base
			alcance_atual = alcance
	
	# Garante valores mínimos
	tempo_ataque_atual = max(0.1, tempo_ataque_atual)

func get_custo_proximo_upgrade() -> int:
	# Retorna o custo do próximo upgrade, ou -1 se não houver
	if tem_paths:
		if caminho_atual == -1:
			# Primeira escolha: retorna o menor custo entre os caminhos?
			# Melhor deixar a UI lidar com múltiplos.
			# Para compatibilidade, retorna -1, indicando que há múltiplas opções.
			return -1
		else:
			var path = upgrade_paths[caminho_atual]
			if nivel_atual < path.custos.size():
				return path.custos[nivel_atual]
	else:
		if nivel_atual < upgrade_custos.size():
			return upgrade_custos[nivel_atual]
	return -1

func get_opcoes_proximo_upgrade() -> Array:
	var opcoes = []
	var escala_perfeita_ui = _calcular_escala_ideal_para_ui()

	if tem_paths and caminho_atual == -1:
		# Primeira escolha: todos os caminhos da fase atual (bloqueados ou não)
		for i in range(upgrade_paths.size()):
			var path = upgrade_paths[i]
			if path and path.custos.size() > 0:
				# Filtro de fase: oculta paths de outros mapas
				var fase_min: int = path.get("fase_minima") if "fase_minima" in path else 0
				var fase_max: int = path.get("fase_maxima") if "fase_maxima" in path else 0
				if fase_min > 0 and GameManager.fase_atual < fase_min:
					continue
				if fase_max > 0 and GameManager.fase_atual > fase_max:
					continue

				# Verifica se está bloqueado por nivel_base_minimo
				var nivel_min: int = path.get("nivel_base_minimo") if "nivel_base_minimo" in path else 0
				var bloqueado: bool = nivel_min > 0 and GameManager.nivel_base < nivel_min

				var nome_path = path.nome
				if nome_path == null or nome_path == "":
					nome_path = "Caminho " + str(i + 1)

				var escala_deste_path = _calcular_escala_ideal_para_ui(path)

				var modelo_correto = null
				if path.modelos_por_nivel.size() > 0:
					modelo_correto = path.modelos_por_nivel[0]

				var icone_path = path.icone if path.icone != null else _icone_por_path_nome(nome_path)
				opcoes.append({
					"index": i,
					"nome": nome_path,
					"icone": icone_path,
					"custo": path.custos[0],
					"beneficio": _descrever_beneficio(path, 0),
					"descricoes": _gerar_descricoes(path, 0),
					"cor": _get_cor_path(i, path),
					"modelo_3d": modelo_correto,
					"escala_modelo": escala_deste_path,
					"bloqueado": bloqueado,
					"motivo_bloqueio": "Base nível %d necessário" % nivel_min if bloqueado else ""
				})
	elif tem_paths and caminho_atual >= 0:
		# Já tem caminho: próximo nível desse caminho
		var path = upgrade_paths[caminho_atual]
		var prox_nivel = nivel_atual
		if path and prox_nivel < path.custos.size():
			var nome_path = path.nome
			if nome_path == null or nome_path == "":
				nome_path = "Upgrade"
			
			var escala_deste_path = _calcular_escala_ideal_para_ui(path)
			
			# Pega o modelo do PRÓXIMO NÍVEL exato! Fallback: último disponível
			var modelo_correto = null
			if prox_nivel < path.modelos_por_nivel.size():
				modelo_correto = path.modelos_por_nivel[prox_nivel]
			if modelo_correto == null and path.modelos_por_nivel.size() > 0:
				modelo_correto = path.modelos_por_nivel[path.modelos_por_nivel.size() - 1]

			var icone_path2 = path.icone if path.icone != null else _icone_por_path_nome(nome_path)
			opcoes.append({
				"index": caminho_atual,
				"nome": nome_path,
				"icone": icone_path2,
				"custo": path.custos[prox_nivel],
				"beneficio": _descrever_beneficio(path, prox_nivel),
				"descricoes": _gerar_descricoes(path, prox_nivel),
				"cor": _get_cor_path(caminho_atual, path),
				"modelo_3d": modelo_correto,
				"escala_modelo": escala_deste_path
			})
	else:
		# Sem paths: opção única (upgrade linear)
		var custo = get_custo_proximo_upgrade()
		if custo != -1:

			# Pega o modelo do PRÓXIMO NÍVEL na lista geral. Fallback: último disponível ou cena atual
			var modelo_correto = null
			if nivel_atual < modelos_por_nivel.size():
				modelo_correto = modelos_por_nivel[nivel_atual]
			if modelo_correto == null and modelos_por_nivel.size() > 0:
				modelo_correto = modelos_por_nivel[modelos_por_nivel.size() - 1]
			if modelo_correto == null and scene_file_path != "":
				modelo_correto = ResourceLoader.load(scene_file_path)

			var opcao_entry = {
				"index": 0,
				"nome": nome_construcao if nome_construcao != "" else "Upgrade",
				"icone": _icone_para_modelo_upgrade(modelo_correto),
				"custo": custo,
				"beneficio": _descrever_beneficio_simples(),
				"descricoes": _gerar_descricoes_simples(),
				"cor": _get_cor_path(0, null),
				"modelo_3d": modelo_correto,
				"escala_modelo": escala_perfeita_ui
			}
			if tipo == TipoConstrucao.BASE:
				opcao_entry["desbloqueios"] = _get_desbloqueios_base(nivel_atual + 1)
			opcoes.append(opcao_entry)
	return opcoes

func _get_desbloqueios_base(proximo_nivel: int) -> Array:
	var items: Array = []

	# Novos lotes de construção
	if is_inside_tree():
		var slots_novos = 0
		for slot in get_tree().get_nodes_in_group("BuildSlots"):
			if slot.get("nivel_necessario") == proximo_nivel:
				slots_novos += 1
		if slots_novos > 0:
			items.append({"emoji": "", "nome": "+%d lotes" % slots_novos,
				"icone_2d": _ICON_CADEADO, "modelo_3d": null, "escala_modelo": Vector3.ONE})

	# Novas construções disponíveis no próximo nível
	var construcoes_nivel: Array = GameManager.construcoes_permitidas_na_fase.get(proximo_nivel, [])
	for cena in construcoes_nivel:
		if cena == null: continue
		var inst = cena.instantiate()
		if inst.has_method("_resolver_icone_construcao"):
			inst._resolver_icone_construcao()
		var nome: String = inst.get("nome_construcao") if "nome_construcao" in inst else ""
		if nome == "" or nome == "Construção": nome = cena.resource_path.get_file().get_basename().capitalize()
		var t: int   = inst.get("tipo")  if "tipo"  in inst else -1
		var icone_2d = inst.get("icone") if "icone" in inst else null
		inst.free()
		items.append({"emoji": "", "nome": nome,
			"icone_2d": icone_2d if icone_2d != null else _icone_tipo_build(t),
			"modelo_3d": cena, "escala_modelo": _escala_por_tipo_build(t)})

	# Torres especiais que requerem exatamente este nível de base
	if is_inside_tree():
		var _vistos: Array = []
		for tower in get_tree().get_nodes_in_group("Torres"):
			if not is_instance_valid(tower): continue
			if not tower.get("tem_paths"): continue
			for path in tower.upgrade_paths:
				var nivel_min: int = path.get("nivel_base_minimo") if "nivel_base_minimo" in path else 0
				if nivel_min != proximo_nivel: continue
				var fase_min: int = path.get("fase_minima") if "fase_minima" in path else 0
				var fase_max: int = path.get("fase_maxima") if "fase_maxima" in path else 0
				if fase_min > 0 and GameManager.fase_atual < fase_min: continue
				if fase_max > 0 and GameManager.fase_atual > fase_max: continue
				var nome_path: String = path.nome if path.nome and path.nome != "" else "Torre Especial"
				if nome_path in _vistos: continue
				_vistos.append(nome_path)
				var modelo_path = path.modelos_por_nivel[0] if path.modelos_por_nivel.size() > 0 else null
				var icone_path: Texture2D = path.icone if ("icone" in path and path.icone != null) else null
				if icone_path == null:
					icone_path = _icone_por_path_nome(nome_path)
				if icone_path == null and modelo_path != null:
					icone_path = _icone_para_modelo_upgrade(modelo_path)
				items.append({"emoji": "", "nome": nome_path,
					"icone_2d": icone_path if icone_path != null else _ICON_TORRE,
					"modelo_3d": modelo_path, "escala_modelo": _escala_por_tipo_build(0)})

	return items

func _icone_tipo_build(t: int) -> Texture2D:
	match t:
		0: return _ICON_TORRE
		1: return _ICON_PICARETA
		2: return _ICON_CASA
		3: return _ICON_TRIGO
		4: return _ICON_ESCUDO
		5: return _ICON_CASTELO
		6: return _ICON_CRANIO
		_: return _ICON_GUINDASTE

func _escala_por_tipo_build(t: int) -> Vector3:
	match t:
		0: return Vector3(0.5, 0.5, 0.5)
		1: return Vector3(1.2, 1.2, 1.2)
		2: return Vector3(1.2, 1.2, 1.2)
		3: return Vector3(0.8, 0.8, 0.8)
		4: return Vector3(0.5, 0.5, 0.5)
		_: return Vector3(0.8, 0.8, 0.8)

func _resolver_icone_construcao() -> void:
	if icone != null: return
	if tipo == TipoConstrucao.BASE:
		_atualizar_icone_base()
		return
	match scene_file_path:
		"res://Builds/tower.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoTorre.png")
		"res://Builds/mill.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoMoinho.png")
		"res://Builds/caldeiron.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoBruxa.png")
		"res://Builds/mina.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoMina.png")
		"res://Builds/quartel.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoQuartel.png")
		"res://Builds/house.tscn", "res://Builds/casebre.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoCasa.png")
		"res://Builds/casa_classe_media.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoCasa3.png")
		"res://Builds/mercadinho_egipcio.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoDeserto.png")
		"res://Builds/taverna_dos_piratas.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoPirata.png")
		"res://Builds/torre_de_tesla.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoScifi.png")
		"res://Builds/torre_de_fogo.tscn":
			icone = preload("res://Assets/Construcoes/ConstrucaoCovil.png")

## Chamado por GameManager.carregar_fase() DEPOIS de fase_atual ser actualizado.
## Corrige o bug onde a base mostrava o ícone da fase anterior.
func _atualizar_icone_base() -> void:
	if tipo != TipoConstrucao.BASE: return
	match GameManager.fase_atual:
		1: icone = preload("res://Assets/Construcoes/BaseCastelo2.png")
		2: icone = preload("res://Assets/Construcoes/BaseDeserto.png")
		3: icone = preload("res://Assets/Construcoes/BaseBruxa.png")
		4: icone = preload("res://Assets/Construcoes/BasePirata.png")
		5: icone = preload("res://Assets/Construcoes/BaseScifi2.png")
		6: icone = preload("res://Assets/Construcoes/BaseCovil.png")

## Resolve o ícone 2D exibido no card de upgrade para o próximo nível.
## Mapeamentos explícitos têm prioridade; .tscn genérico usa Builds.gd;
## qualquer outra coisa cai no ícone base da própria construção.
func _icone_para_modelo_upgrade(modelo: PackedScene) -> Texture2D:
	if modelo == null:
		return icone
	# ── Mapeamento explícito por caminho (máxima prioridade) ──────────
	match modelo.resource_path:
		# Castelo (BASE) — níveis 1 e 2
		"res://Medieval/buildings/blue/building_barracks_blue.gltf":
			return preload("res://Assets/Construcoes/BaseCastelo2.png")
		"res://Medieval/buildings/blue/building_castle_blue.gltf":
			return preload("res://Assets/Construcoes/BaseCastelo3.png")
		# Moinho — nível 1
		"res://Medieval/buildings/blue/building_windmill_blue.gltf":
			return preload("res://Assets/Construcoes/ConstrucaoMoinho2.png")
		# Casa — níveis 1 e 2
		"res://Builds/casa_classe_media.tscn":
			return preload("res://Assets/Construcoes/ConstrucaoCasa2.png")
		"res://Builds/casebre.tscn":
			return preload("res://Assets/Construcoes/ConstrucaoCasa3.png")
	# ── .tscn genérico com Builds.gd: instancia, resolve e descarta ───
	if modelo.resource_path.ends_with(".tscn"):
		var inst = modelo.instantiate()
		var res: Texture2D = null
		if inst.has_method("_resolver_icone_construcao"):
			inst._resolver_icone_construcao()
			res = inst.get("icone") if "icone" in inst else null
		inst.free()
		return res if res != null else icone
	# ── Fallback: ícone base da construção atual ───────────────────────
	return icone

func _icone_por_path_nome(nome: String) -> Texture2D:
	match nome:
		"Morteiro":      return preload("res://Assets/Construcoes/ConstrucaoTorre2A.png")
		"Sniper":        return preload("res://Assets/Construcoes/ConstrucaoTorre2B.png")
		"Caldeirão":     return preload("res://Assets/Construcoes/ConstrucaoBruxa.png")
		"Torre de Fogo": return preload("res://Assets/Construcoes/ConstrucaoCovil.png")
		"Tesla":         return preload("res://Assets/Construcoes/ConstrucaoScifi.png")
		_: return null

func _calcular_escala_ideal_para_ui(path_data: Resource = null) -> Vector3:
	# 1. Tenta pegar a escala específica definida no PathData (se existir no futuro)
	if path_data and path_data.get("escala_ui_customizada") != null:
		return path_data.escala_ui_customizada
		
	# 2. Senão, calcula baseado no Tipo de Construção (Enum do Builds.gd)
	var tipo_construcao = self.tipo 
	
	# Valores base sugeridos (Ajuste aqui conforme necessário)
	var escala_padrao_pequena = Vector3(1.2, 1.2, 1.2) # Bom para Casas
	var escala_padrao_media = Vector3(0.8, 0.8, 0.8)   # Bom para Minas/Moinhos
	var escala_padrao_grande = Vector3(0.5, 0.5, 0.5)  # Bom para Torres/Quartéis
	
	match tipo_construcao:
		0: # TORRE
			return escala_padrao_grande
		1: # MINA
			return escala_padrao_pequena
		2: # CASA
			return escala_padrao_pequena
		3: # MOINHO
			return escala_padrao_media
		4: # QUARTEL
			return escala_padrao_grande
		5: # BASE — modelos gltf grandes precisam de escala bem menor
			return escala_modelo * 0.5
		_:
			return Vector3(1, 1, 1) # Fallback seguro

func _descrever_beneficio(path: UpgradePathData, nivel: int) -> String:
	var partes = []
	if nivel < path.dano_por_nivel.size() and path.dano_por_nivel[nivel] != 0:
		partes.append("Dano +%d" % path.dano_por_nivel[nivel])
	if nivel < path.moedas_por_nivel.size() and path.moedas_por_nivel[nivel] != 0:
		partes.append("Moedas +%d" % path.moedas_por_nivel[nivel])
	if nivel < path.aliados_por_nivel.size() and path.aliados_por_nivel[nivel] != 0:
		partes.append("Aliados +%d" % path.aliados_por_nivel[nivel])
	if nivel < path.velocidade_por_nivel.size() and path.velocidade_por_nivel[nivel] != 0:
		partes.append("Vel. -%.2f" % path.velocidade_por_nivel[nivel])
	if nivel < path.alcance_por_nivel.size() and path.alcance_por_nivel[nivel] != 0:
		partes.append("Alcance +%.1f" % path.alcance_por_nivel[nivel])
	if nivel < path.vida_por_nivel.size() and path.vida_por_nivel[nivel] != 0:
		partes.append("Vida +%d" % path.vida_por_nivel[nivel])
	if partes.size() == 0:
		return "Melhora geral"
	return " | ".join(partes)

func _descrever_beneficio_simples() -> String:
	# Para upgrades sem path, descreve com base nos arrays base
	var nivel = nivel_atual
	var partes = []
	if nivel < upgrade_dano_por_nivel.size() and upgrade_dano_por_nivel[nivel] != 0:
		partes.append("Dano +%d" % upgrade_dano_por_nivel[nivel])
	if nivel < upgrade_moedas_por_nivel.size() and upgrade_moedas_por_nivel[nivel] != 0:
		partes.append("Moedas +%d" % upgrade_moedas_por_nivel[nivel])
	if nivel < upgrade_aliados_por_nivel.size() and upgrade_aliados_por_nivel[nivel] != 0:
		partes.append("Aliados +%d" % upgrade_aliados_por_nivel[nivel])
	if nivel < upgrade_velocidade_por_nivel.size() and upgrade_velocidade_por_nivel[nivel] != 0:
		partes.append("Vel. -%.2f" % upgrade_velocidade_por_nivel[nivel])
	if nivel < upgrade_alcance_por_nivel.size() and upgrade_alcance_por_nivel[nivel] != 0:
		partes.append("Alcance +%.1f" % upgrade_alcance_por_nivel[nivel])
	if nivel < upgrade_vida_por_nivel.size() and upgrade_vida_por_nivel[nivel] != 0:
		partes.append("Vida +%d" % upgrade_vida_por_nivel[nivel])
	if partes.size() == 0:
		return "Melhora geral"
	return " | ".join(partes)

# Retorna até 3 descrições visuais sem números para um path específico.
func _gerar_descricoes(path: UpgradePathData, nivel: int) -> Array:
	if "descricoes" in path and path.descricoes.size() > 0:
		return path.descricoes.duplicate()

	var desc: Array = []

	if nivel < path.dano_por_nivel.size() and path.dano_por_nivel[nivel] > 0:
		desc.append("Mais dano")
	if nivel < path.vida_por_nivel.size() and path.vida_por_nivel[nivel] > 0:
		desc.append("Mais resistência")
	if nivel < path.alcance_por_nivel.size() and path.alcance_por_nivel[nivel] > 0:
		desc.append("Maior alcance")
	if nivel < path.moedas_por_nivel.size() and path.moedas_por_nivel[nivel] > 0:
		desc.append("Mais ouro")
	if nivel < path.aliados_por_nivel.size() and path.aliados_por_nivel[nivel] > 0:
		desc.append("Mais soldados")
	if "tipo_ataque" in path and path.tipo_ataque == "chain_lightning":
		desc.append("Dano em cadeia")
	if nivel < path.velocidade_por_nivel.size():
		var vel: float = path.velocidade_por_nivel[nivel]
		if vel > 0.8:
			desc.append("Cadência reduzida")
		elif vel > 0.0:
			desc.append("Mais devagar")
		elif vel < 0.0:
			desc.append("Mais rápido")

	var fallbacks = ["Melhora geral", "Potência extra", "Eficiência"]
	var fi = 0
	while desc.size() < 3:
		desc.append(fallbacks[fi % fallbacks.size()])
		fi += 1

	return desc.slice(0, 3)

# Descrições descritivas para upgrades sem path (arrays base da construção).
func _gerar_descricoes_simples() -> Array:
	var nivel = nivel_atual
	var desc: Array = []

	if nivel < upgrade_dano_por_nivel.size() and upgrade_dano_por_nivel[nivel] != 0:
		desc.append("Mais dano")
	if nivel < upgrade_vida_por_nivel.size() and upgrade_vida_por_nivel[nivel] != 0:
		desc.append("Mais resistência")
	if nivel < upgrade_alcance_por_nivel.size() and upgrade_alcance_por_nivel[nivel] != 0:
		desc.append("Maior alcance")
	if nivel < upgrade_moedas_por_nivel.size() and upgrade_moedas_por_nivel[nivel] != 0:
		desc.append("Mais ouro")
	if nivel < upgrade_aliados_por_nivel.size() and upgrade_aliados_por_nivel[nivel] != 0:
		desc.append("Mais soldados")
	if nivel < upgrade_velocidade_por_nivel.size() and upgrade_velocidade_por_nivel[nivel] > 0:
		desc.append("Mais devagar")
	elif nivel < upgrade_velocidade_por_nivel.size() and upgrade_velocidade_por_nivel[nivel] < 0:
		desc.append("Mais rápido")

	var fallbacks = ["Melhora geral", "Potência extra", "Eficiência"]
	var fi = 0
	while desc.size() < 3:
		desc.append(fallbacks[fi % fallbacks.size()])
		fi += 1

	return desc.slice(0, 3)

# Retorna a cor padrão para o card de upgrade baseada no índice do path.
func _get_cor_path(index: int, path) -> Color:
	if path != null and "cor" in path:
		var c = path.get("cor")
		if c != null and c is Color and (c as Color).a > 0.01:
			return c as Color
	const CORES = [
		Color(0.13, 0.62, 0.22, 1.0),  # Verde
		Color(0.12, 0.42, 0.82, 1.0),  # Azul
		Color(0.45, 0.15, 0.72, 1.0),  # Roxo
		Color(0.78, 0.52, 0.08, 1.0),  # Dourado
	]
	return CORES[index % CORES.size()]

# Registra as escalas iniciais das malhas nativas da cena para a animação de hover
func _registrar_escalas_base(no: Node):
	if no is MeshInstance3D:
		if no != indicador_alcance and no != _anel_upgrade and no.name != "BarraVidaShader" and no.name != "CirculoVeneno":
			_escalas_base_malhas[no] = no.scale
			
	for filho in no.get_children():
		if filho == modelo_anchor or filho.name == "IndicadorUpgrade" or filho.name == "RespawnViewport":
			continue
		_registrar_escalas_base(filho)

func aplicar_upgrade(index: int = 0) -> bool:
	# index é o índice do caminho escolhido (usado apenas se tem_paths e caminho_atual == -1)
	if tem_paths and caminho_atual == -1:
		# Primeira escolha de caminho
		if index < 0 or index >= upgrade_paths.size():
			return false
		var path = upgrade_paths[index]
		var custo = path.custos[0] if path.custos.size() > 0 else 0
		if GameManager.gastar_moedas(custo):
			caminho_atual = index
			nivel_atual = 1
			_atualizar_valores_pos_upgrades()
			_trocar_modelo(nivel_atual)
			_atualizar_barra_3d()   # restaura visibilidade após troca de modelo
			if tipo == TipoConstrucao.BASE:
				GameManager.nivel_base = nivel_atual
				GameManager.upgrade_base_aplicado.emit()
			if tipo == TipoConstrucao.TORRE:
				_configurar_alcance()
				if "tipo_ataque" in path and path.tipo_ataque == "caldeiron_area":
					_criar_circulo_caldeiron(alcance_atual * 0.85)
				atualizar_status()
			if Global.DEBUG_MODE:
				print("%s escolheu caminho %s e subiu para nível 1" % [name, path.nome])
			return true
		else:
			return false
	else:
		# Upgrade normal (com ou sem path já escolhido)
		var custo = get_custo_proximo_upgrade()
		if custo == -1:
			return false
		if GameManager.gastar_moedas(custo):
			nivel_atual += 1
			_atualizar_valores_pos_upgrades()
			_trocar_modelo(nivel_atual)
			_atualizar_barra_3d()   # restaura visibilidade após troca de modelo
			if tipo == TipoConstrucao.BASE:
				GameManager.nivel_base = nivel_atual
				GameManager.upgrade_base_aplicado.emit()
			if tipo == TipoConstrucao.TORRE:
				_configurar_alcance()
				atualizar_status()
			if Global.DEBUG_MODE:
				print("%s upgrade para nível %d" % [name, nivel_atual])
			return true
	return false

func _trocar_modelo(nivel: int):
	# Evita processamento de nível zerado antes da hora (Suprime o aviso "Nenhum modelo...")
	if nivel <= 0:
		return
		
	# Remove modelo antigo
	for child in modelo_anchor.get_children():
		child.queue_free()
	
	# Escolhe o modelo baseado na configuração
	var modelo_scene = null
	if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
		var path = upgrade_paths[caminho_atual]
		var idx = nivel - 1
		if idx >= 0 and idx < path.modelos_por_nivel.size():
			modelo_scene = path.modelos_por_nivel[idx]
	else:
		var idx = nivel - 1
		if idx >= 0 and idx < modelos_por_nivel.size():
			modelo_scene = modelos_por_nivel[idx]
	
	# Aplica o modelo
	if modelo_scene:
		var modelo = modelo_scene.instantiate()
		if "is_modo_upgrade" in modelo:
			modelo.is_modo_upgrade = true
		elif "is_fantasma" in modelo:
			modelo.is_fantasma = true
		modelo_anchor.add_child(modelo)
		modelo.scale = escala_modelo
		
		# Tornando staticbody em um botão
		for corpo in modelo.find_children("*", "StaticBody3D"):
			corpo.input_ray_pickable = true
			if not corpo.input_event.is_connected(_on_area_clique):
				corpo.input_event.connect(_on_area_clique)
			if not corpo.mouse_entered.is_connected(_on_area_clique_mouse_entered):
				corpo.mouse_entered.connect(_on_area_clique_mouse_entered)
			if not corpo.mouse_exited.is_connected(_on_area_clique_mouse_exited):
				corpo.mouse_exited.connect(_on_area_clique_mouse_exited)
		
		# Esconde as malhas da torre base para evitar sobreposição
		_esconder_malhas_originais(self)
		
		# Aplica a borda de interatividade no novo modelo instanciado, caso esteja de dia
		if not GameManager.is_night and not is_fantasma:
			_atualizar_segundo_next_pass(modelo, true)
	else:
		push_warning(name + ": Nenhum modelo configurado para o nível " + str(nivel))

# Nova função para ocultar o modelo 3D original que veio do .glb
func _esconder_malhas_originais(no: Node):
	for filho in no.get_children():
		if filho == modelo_anchor:
			continue

		# Protege o anel de alcance
		if indicador_alcance and filho == indicador_alcance:
			continue

		# Protege a barra de vida 3D — sem isso, qualquer _trocar_modelo()
		# a apaga e ela só volta no próximo receber_dano()
		if is_instance_valid(_barra_3d_mesh) and filho == _barra_3d_mesh:
			continue

		if filho is MeshInstance3D:
			filho.hide()
		elif filho.get_child_count() > 0:
			_esconder_malhas_originais(filho)

# ==========================================
# DEMAIS FUNÇÕES (MANTIDAS IGUAIS)
# ==========================================
func _modo_fantasma():
	set_process(false)  # Fantasma não precisa de _process — evita custo por frame
	for child in get_children():
		_desativar_fantasma(child)
	if timer_ataque:
		timer_ataque.stop()
	if container_barra:
		container_barra.visible = false

func _desativar_fantasma(no: Node):
	if no is MeshInstance3D:
		no.transparency = 0.5
	elif no is CollisionObject3D:
		no.collision_layer = 0
		no.collision_mask = 0
	elif no is CollisionShape3D or no is CollisionPolygon3D:
		no.set_deferred("disabled", true)
	elif no is NavigationObstacle3D:
		no.avoidance_enabled = false
	for filho in no.get_children():
		_desativar_fantasma(filho)

func _inicializar_barra_vida():
	if tem_barra_vida and barra_vida and container_barra:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		container_barra.visible = false
	_criar_barra_3d()

# ─────────────────────────────────────────────────────────────────────────────
# NOVA BARRA DE VIDA 3D COM SHADER CUSTOMIZADA
# ─────────────────────────────────────────────────────────────────────────────
func _criar_barra_3d() -> void:
	if is_instance_valid(_barra_3d_mesh):
		_barra_3d_mesh.queue_free()

	var e_base : bool  = (tipo == TipoConstrucao.BASE)
	var bar_w  : float = 4.5 if e_base else 0.8
	var bar_h  : float = 0.45 if e_base else 0.12
	# Posição ajustada acima de cada tipo de construção
	var bar_y: float
	match tipo:
		TipoConstrucao.BASE:
			bar_y = 4.0
		TipoConstrucao.TORRE:
			bar_y = 3.2
		TipoConstrucao.QUARTEL, TipoConstrucao.CALDEIRON:
			bar_y = 2.6
		_: # CASA, MINA, MOINHO
			bar_y = 2.0

	_barra_3d_mesh = MeshInstance3D.new()
	_barra_3d_mesh.name = "BarraVidaShader"
	var quad := QuadMesh.new()
	quad.size = Vector2(bar_w, bar_h)
	_barra_3d_mesh.mesh = quad
	
	_barra_3d_mat = ShaderMaterial.new()
	_barra_3d_mat.shader = Shader.new()
	_barra_3d_mat.shader.code = BARRA_VIDA_SHADER
	_barra_3d_mat.set_shader_parameter("u_aspect", bar_w / bar_h)
	
	_barra_3d_mesh.material_override = _barra_3d_mat
	_barra_3d_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_barra_3d_mesh.sorting_offset = 10.0 # Garante que desenha na frente de outros efeitos
	
	add_child(_barra_3d_mesh)
	_barra_3d_mesh.position = Vector3(0.0, bar_y, 0.0)
	_barra_3d_mesh.visible = e_base
	
	_atualizar_barra_3d()

func _atualizar_barra_3d() -> void:
	if not is_instance_valid(_barra_3d_mesh) or not _barra_3d_mat:
		return

	var ratio : float = clamp(float(vida_atual) / float(vida_maxima), 0.0, 1.0)
	_barra_3d_mat.set_shader_parameter("progress", ratio)
	
	# Cores baseadas na porcentagem de vida
	var cor_v = Color(0.15, 0.85, 0.20, 1.0)
	if ratio <= 0.25:
		cor_v = Color(0.90, 0.15, 0.10, 1.0)
	elif ratio <= 0.5:
		cor_v = Color(0.95, 0.75, 0.10, 1.0)
	_barra_3d_mat.set_shader_parameter("progress_color", cor_v)

	if tipo != TipoConstrucao.BASE:
		_barra_3d_mesh.visible = (ratio < 1.0)

func _aplicar_bonus_vida(delta: int):
	if tipo != TipoConstrucao.BASE: return
	vida_maxima = max(1, vida_maxima + delta)
	vida_atual  = clamp(vida_atual + max(0, delta), 1, vida_maxima)
	if tem_barra_vida and barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
	_atualizar_barra_3d()

func _configurar_alcance():
	var alcance_efetivo = alcance_atual + GameManager.bonus_alcance
	if area_ataque and area_ataque.has_node("CollisionShape3D"):

		# 1. CONSRETA O BUG DO CLIQUE: O mouse vai ignorar essa área gigante
		area_ataque.input_ray_pickable = false

		# 2. CONSERTA O BUG DE ATIRAR LONGE: Separa a área de cada torre
		var shape_original = area_ataque.get_node("CollisionShape3D").shape
		var shape_unica = shape_original.duplicate() # <- A mágica acontece aqui!
		area_ataque.get_node("CollisionShape3D").shape = shape_unica

		if shape_unica is SphereShape3D or shape_unica is CylinderShape3D:
			shape_unica.radius = alcance_efetivo

		if Global.DEBUG_MODE:
			print("Alcance da torre ajustado para: ", alcance_efetivo)

	# 3. FAZ O ANEL APARECER NO TAMANHO CERTO
	if indicador_alcance:
		indicador_alcance.scale = Vector3(alcance_efetivo * 2, 1, alcance_efetivo * 2)

# ==========================================
# SISTEMA DE ATAQUE (TORRE)
# ==========================================
func _on_area_ataque_body_entered(body):
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	if body.is_in_group("inimigos"):
		if not body in inimigos_no_alcance:
			inimigos_no_alcance.append(body)

func _on_area_ataque_body_exited(body):
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)

func _process(delta):
	# Indicador de upgrade: checa a cada 0.5 s (evita custo por frame)
	if not is_fantasma and _indicador_upgrade:
		_timer_indicador -= delta
		if _timer_indicador <= 0.0:
			_timer_indicador = 0.5
			_atualizar_indicador_upgrade()

	# Caldeirão — ataque em área periódico durante a noite
	if tipo == TipoConstrucao.CALDEIRON and not is_fantasma and not esta_destruida:
		if GameManager.is_night:
			_caldeiron_timer += delta
			var intervalo: float = Balanceamento.get_float("caldeiron_intervalo", 3.0)
			if _caldeiron_timer >= intervalo:
				_caldeiron_timer = 0.0
				_caldeiron_atacar_area()
		return

	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	# Purga inimigos inválidos sem alocar array novo (evita filter() GC por frame)
	for i in range(inimigos_no_alcance.size() - 1, -1, -1):
		if not is_instance_valid(inimigos_no_alcance[i]):
			inimigos_no_alcance.remove_at(i)
	alvo_atual = inimigos_no_alcance.front() if inimigos_no_alcance.size() > 0 else null

func _caldeiron_atacar_area() -> void:
	var dano_base: int = max(1, dano_atual + GameManager.bonus_dano)
	# Purga em-lugar (sem filter() → sem alocação por tick)
	for i in range(_inimigos_no_veneno.size() - 1, -1, -1):
		var e = _inimigos_no_veneno[i]
		if not is_instance_valid(e) or e.get("esta_morto", false):
			_inimigos_no_veneno.remove_at(i)
	for inimigo in _inimigos_no_veneno:
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(dano_base)

func _caldeiron_atacar_area_torre() -> void:
	var dano_base: int = max(1, dano_atual + GameManager.bonus_dano)
	for i in range(inimigos_no_alcance.size() - 1, -1, -1):
		if not is_instance_valid(inimigos_no_alcance[i]):
			inimigos_no_alcance.remove_at(i)
	for inimigo in inimigos_no_alcance:
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(dano_base)

# Chamado quando um corpo entra no círculo de veneno
func _on_veneno_entrou(corpo: Node3D) -> void:
	if not corpo.is_in_group("inimigos"):
		return
	if corpo in _inimigos_no_veneno:
		return
	_inimigos_no_veneno.append(corpo)
	if corpo.has_method("iniciar_veneno"):
		corpo.iniciar_veneno()

func _on_veneno_saiu(corpo: Node3D) -> void:
	_inimigos_no_veneno.erase(corpo)
	if is_instance_valid(corpo) and corpo.has_method("parar_veneno"):
		corpo.parar_veneno()

func _mat_circulo(cor: Color, emission_energy: float = 0.0, fill: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = -2
	m.albedo_color = cor
	if fill:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = Color(cor.r, cor.g, cor.b)
		m.emission_energy_multiplier = emission_energy
	return m

func _criar_circulo_caldeiron(raio: float = 4.5) -> void:
	if get_node_or_null("CirculoVeneno") != null:
		return

	var raiz := Node3D.new()
	raiz.name = "CirculoVeneno"

	# ── 1. Pool de veneno — PlaneMesh com shader animado ─────────────────
	var pool_inst := MeshInstance3D.new()
	var pool_mesh := PlaneMesh.new()
	pool_mesh.size = Vector2(raio * 2.0, raio * 2.0)
	pool_inst.mesh = pool_mesh
	pool_inst.position = Vector3(0, 0.02, 0)

	var mat_pool := ShaderMaterial.new()
	mat_pool.shader = preload("res://Shaders/veneno_circulo.gdshader")
	mat_pool.set_shader_parameter("velocidade",  1.6)
	mat_pool.set_shader_parameter("num_aneis",   4.0)
	mat_pool.set_shader_parameter("cor_interna", Color(0.02, 0.38, 0.05))
	mat_pool.set_shader_parameter("cor_borda",   Color(0.22, 1.00, 0.28))
	mat_pool.set_shader_parameter("intensidade", 1.4)
	pool_inst.material_override = mat_pool
	raiz.add_child(pool_inst)

	# ── 2. Anel de borda emissivo (único, pulsante) ───────────────────────
	var borda_inst := MeshInstance3D.new()
	var borda_mesh := TorusMesh.new()
	borda_mesh.outer_radius  = raio
	borda_mesh.inner_radius  = raio - 0.14
	borda_mesh.ring_segments = 6
	borda_mesh.rings         = 72
	borda_inst.mesh  = borda_mesh
	borda_inst.scale = Vector3(1.0, 0.08, 1.0)
	borda_inst.material_override = _mat_circulo(Color(0.20, 1.00, 0.28), 3.5)
	raiz.add_child(borda_inst)

	var tw_borda := borda_inst.create_tween().set_loops()
	tw_borda.tween_property(borda_inst, "material_override:emission_energy_multiplier",
		7.0, 1.3).set_trans(Tween.TRANS_SINE)
	tw_borda.tween_property(borda_inst, "material_override:emission_energy_multiplier",
		2.0, 1.3).set_trans(Tween.TRANS_SINE)

	# ── 3. Bolhas borbulhando (partículas pequenas que sobem) ─────────────
	var bolhas := CPUParticles3D.new()
	raiz.add_child(bolhas)
	bolhas.amount                = 40
	bolhas.lifetime              = 2.2
	bolhas.emitting              = true
	bolhas.one_shot              = false
	bolhas.explosiveness         = 0.0
	bolhas.emission_shape        = CPUParticles3D.EMISSION_SHAPE_SPHERE
	bolhas.emission_sphere_radius = raio * 0.80
	bolhas.direction             = Vector3(0.0, 1.0, 0.0)
	bolhas.spread                = 10.0
	bolhas.gravity               = Vector3(0.0, 0.4, 0.0)
	bolhas.initial_velocity_min  = 0.25
	bolhas.initial_velocity_max  = 0.90
	bolhas.scale_amount_min      = 0.04
	bolhas.scale_amount_max      = 0.13
	bolhas.color                 = Color(0.25, 1.00, 0.20, 0.90)
	bolhas.position              = Vector3(0.0, 0.05, 0.0)

	# ── 4. Névoa tóxica (partículas maiores, mais lentas e translúcidas) ──
	var nevoa := CPUParticles3D.new()
	raiz.add_child(nevoa)
	nevoa.amount                 = 20
	nevoa.lifetime               = 4.0
	nevoa.emitting               = true
	nevoa.one_shot               = false
	nevoa.explosiveness          = 0.0
	nevoa.emission_shape         = CPUParticles3D.EMISSION_SHAPE_SPHERE
	nevoa.emission_sphere_radius  = raio * 0.65
	nevoa.direction              = Vector3(0.0, 1.0, 0.0)
	nevoa.spread                 = 35.0
	nevoa.gravity                = Vector3(0.0, 0.15, 0.0)
	nevoa.initial_velocity_min   = 0.10
	nevoa.initial_velocity_max   = 0.40
	nevoa.scale_amount_min       = 0.22
	nevoa.scale_amount_max       = 0.48
	nevoa.color                  = Color(0.10, 0.65, 0.15, 0.30)
	nevoa.position               = Vector3(0.0, 0.10, 0.0)

	# ── 5. Luz verde ambiente pulsante ────────────────────────────────────
	var luz := OmniLight3D.new()
	raiz.add_child(luz)
	luz.position     = Vector3(0.0, 0.4, 0.0)
	luz.light_color  = Color(0.15, 1.00, 0.25)
	luz.light_energy = 1.2
	luz.omni_range   = raio * 1.5

	var tw_luz := luz.create_tween().set_loops()
	tw_luz.tween_property(luz, "light_energy", 2.6, 2.0).set_trans(Tween.TRANS_SINE)
	tw_luz.tween_property(luz, "light_energy", 0.7, 2.0).set_trans(Tween.TRANS_SINE)

	# ── Area3D para detectar inimigos ────────────────────────────────────────
	var area := Area3D.new()
	area.name = "AreaVeneno"
	area.collision_layer = 0
	area.collision_mask  = 0xFFFFFFFF
	var col := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = raio
	col.shape = esfera
	area.add_child(col)
	area.body_entered.connect(_on_veneno_entrou)
	area.body_exited.connect(_on_veneno_saiu)
	raiz.add_child(area)

	add_child(raiz)
	_fixar_circulo_no_chao.call_deferred(raiz)

func _fixar_circulo_no_chao(raiz: Node3D) -> void:
	if not is_inside_tree(): return
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 3.0, 0),
		global_position + Vector3(0, -8.0, 0)
	)
	var exclusoes: Array[RID] = []
	for corpo in find_children("*", "CollisionObject3D"):
		exclusoes.append(corpo.get_rid())
	query.exclude = exclusoes
	var resultado := space.intersect_ray(query)
	if resultado:
		raiz.global_position.y = resultado["position"].y + 0.03

# ──────────────────────────────────────────────────────────────────────────────
# INDICADOR DE UPGRADE DISPONÍVEL
# • Modo DESTAQUE  — anel brilhante + ícone animado + pontos flutuantes
# • Modo SUTIL     — só o anel, 25 % de opacidade (não polui a tela)
# A construção em destaque é calculada pelo GameManager a cada 1 s
# usando a mesma lógica do ConselheiroIA (torres têm prioridade).
# ──────────────────────────────────────────────────────────────────────────────
func _criar_indicador_upgrade() -> void:
	var container := Node3D.new()
	container.name    = "IndicadorUpgrade"
	container.visible = false
	add_child(container)
	_indicador_upgrade = container

	# Material próprio do anel (precisamos alterar opacidade/emissão em runtime)
	_mat_anel_upgrade = StandardMaterial3D.new()
	_mat_anel_upgrade.albedo_color               = Color(0.1, 0.95, 0.22, 0.92)
	_mat_anel_upgrade.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_anel_upgrade.emission_enabled           = true
	_mat_anel_upgrade.emission                   = Color(0.1, 0.95, 0.22)
	_mat_anel_upgrade.emission_energy_multiplier = 2.5
	_mat_anel_upgrade.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_anel_upgrade.cull_mode                  = BaseMaterial3D.CULL_DISABLED

	# Material dos pontos de luz (compartilhado — animação via scale)
	var mat_pontos := StandardMaterial3D.new()
	mat_pontos.albedo_color               = Color(0.15, 1.0, 0.25)
	mat_pontos.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_pontos.emission_enabled           = true
	mat_pontos.emission                   = Color(0.15, 1.0, 0.25)
	mat_pontos.emission_energy_multiplier = 3.5

	# ── Anel fino giratório no chão ──────────────────────────────────────────
	_anel_upgrade = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius  = 0.58
	torus.outer_radius  = 0.70
	torus.rings         = 32
	torus.ring_segments = 8
	_anel_upgrade.mesh             = torus
	_anel_upgrade.material_override = _mat_anel_upgrade
	_anel_upgrade.cast_shadow      = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
	_anel_upgrade.position.y       = 0.05
	container.add_child(_anel_upgrade)

	# ── Badge com ícone 2D mapeado em 3D ─────────────────────────────────────
	_seta_upgrade          = Sprite3D.new()
	_seta_upgrade.name     = "BadgeSeta"
	_seta_upgrade.texture  = preload("res://Icons/upgrading_icon.png")
	_seta_upgrade.position = Vector3(0.0, 0.3, 0.0)
	_seta_upgrade.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_seta_upgrade.no_depth_test = true
	_seta_upgrade.render_priority = 10
	_seta_upgrade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_seta_upgrade.pixel_size = 0.0015 # Tamanho do pixel pode ser ajustado conforme a resolução da imagem
	_seta_upgrade.visible  = false
	container.add_child(_seta_upgrade)

	# ── 3 pontos de luz flutuantes entre edifício e seta ─────────────────────
	_pontos_upgrade = []
	for y: float in [0.12, 0.25, 0.38]:
		var ponto := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.04
		esfera.height = 0.08
		ponto.mesh             = esfera
		ponto.material_override = mat_pontos
		ponto.cast_shadow      = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
		ponto.position.y       = y
		ponto.scale            = Vector3.ONE * 0.3  # começa pequeno; tween de escala
		ponto.visible          = false
		container.add_child(ponto)
		_pontos_upgrade.append(ponto)

	_animar_indicador_upgrade()

# Inicia as animações contínuas — ficam rodando mesmo quando o container está
# invisível (nenhum custo visual) e retomam naturalmente ao se tornar visível.
func _animar_indicador_upgrade() -> void:
	# Anel gira 360° a cada 4 s (sempre ativo)
	if is_instance_valid(_anel_upgrade):
		var tw_ring := create_tween().set_loops()
		tw_ring.tween_property(_anel_upgrade, "rotation:y", TAU, 4.0)\
			.from(0.0).set_trans(Tween.TRANS_LINEAR)

	# Seta sobe e desce suavemente
	if is_instance_valid(_seta_upgrade):
		var y0 := _seta_upgrade.position.y
		var tw_seta := create_tween().set_loops()
		tw_seta.tween_property(_seta_upgrade, "position:y", y0 + 0.22, 0.60)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_seta.tween_property(_seta_upgrade, "position:y", y0, 0.60)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Pontos pulsam em cascata (crescem/encolhem via scale)
	for i in _pontos_upgrade.size():
		var ponto: Node3D = _pontos_upgrade[i]
		if not is_instance_valid(ponto):
			continue
		if i == 0:
			var tw_p := create_tween().set_loops()
			tw_p.tween_property(ponto, "scale", Vector3.ONE * 1.3, 0.38)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_p.tween_property(ponto, "scale", Vector3.ONE * 0.25, 0.38)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			# Defasagem inicial via timer — mantém período igual entre os pontos
			get_tree().create_timer(i * 0.25).timeout.connect(func():
				if not is_instance_valid(ponto):
					return
				var tw_p2 := ponto.create_tween().set_loops()
				tw_p2.tween_property(ponto, "scale", Vector3.ONE * 1.3, 0.38)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tw_p2.tween_property(ponto, "scale", Vector3.ONE * 0.25, 0.38)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			)

func _atualizar_indicador_upgrade() -> void:
	if not is_instance_valid(_indicador_upgrade):
		return
		
	# Esconde durante a noite ou se a construção foi destruída
	if esta_destruida or GameManager.is_night or not _pode_fazer_upgrade():
		_indicador_upgrade.visible = false
		_set_borda_destaque(false)
		# Força o material a estado inativo para evitar bugs visuais de transição entre dias
		if is_instance_valid(_mat_anel_upgrade):
			_mat_anel_upgrade.albedo_color = Color(0.1, 0.95, 0.22, 0.0)
			_mat_anel_upgrade.emission_energy_multiplier = 0.0
		return

	_indicador_upgrade.visible = true

	# Decide o modo: DESTAQUE (esta construção) ou SUTIL (as demais)
	var eh_destaque: bool = (GameManager.construcao_destaque_upgrade == self)

	# Escala do container: tamanho normal no destaque, menor no sutil
	_indicador_upgrade.scale = Vector3.ONE if eh_destaque else Vector3.ONE * 0.65

	# Borda verde ao redor do modelo da construção em destaque
	_set_borda_destaque(eh_destaque)

	# Seta e pontos: visíveis só no destaque
	if is_instance_valid(_seta_upgrade):
		_seta_upgrade.visible = eh_destaque
	for p: Node3D in _pontos_upgrade:
		if is_instance_valid(p):
			p.visible = eh_destaque

	# Anel: sempre visível, mas opacidade/emissão mudam conforme o modo
	if is_instance_valid(_mat_anel_upgrade):
		if eh_destaque:
			_mat_anel_upgrade.albedo_color               = Color(0.1, 0.95, 0.22, 0.92)
			_mat_anel_upgrade.emission_energy_multiplier = 2.5
		else:
			_mat_anel_upgrade.albedo_color               = Color(0.1, 0.95, 0.22, 0.25)
			_mat_anel_upgrade.emission_energy_multiplier = 0.6

# Aplica ou remove a borda verde nos modelos 3D da construção em destaque.
# Usa o parâmetro _Color do Outline.gdshader (next_pass) para colorir o contorno.
func _set_borda_destaque(ativo: bool) -> void:
	var espessura: float = 5.0 if ativo else espessura_outline_normal
	var cor: Color = Color(0.0, 0.62, 0.10, 1.0) if ativo else Color(0.0, 0.0, 0.0, 1.0)
	_aplicar_borda_colorida(self, espessura, cor)

func _aplicar_borda_colorida(no: Node, espessura: float, cor: Color) -> void:
	if no is MeshInstance3D:
		var material = no.get_active_material(0)
		if material and material.next_pass and material.next_pass is ShaderMaterial:
			var mat_override = no.get_surface_override_material(0)
			if mat_override == null:
				mat_override = material.duplicate(true)
				no.set_surface_override_material(0, mat_override)
			mat_override.next_pass.set_shader_parameter("scale", espessura)
			mat_override.next_pass.set_shader_parameter("_Color", cor)
	for filho in no.get_children():
		_aplicar_borda_colorida(filho, espessura, cor)

# Retorna true se há pelo menos um upgrade acessível com as moedas atuais.
func _pode_fazer_upgrade() -> bool:
	# Caminho não escolhido ainda: verifica o caminho mais barato disponível
	if tem_paths and caminho_atual == -1:
		for path in upgrade_paths:
			if not path or path.custos.size() == 0:
				continue
			var fase_min: int = path.get("fase_minima") if "fase_minima" in path else 0
			var fase_max: int = path.get("fase_maxima") if "fase_maxima" in path else 0
			if fase_min > 0 and GameManager.fase_atual < fase_min:
				continue
			if fase_max > 0 and GameManager.fase_atual > fase_max:
				continue
			var nivel_min: int = path.get("nivel_base_minimo") if "nivel_base_minimo" in path else 0
			if nivel_min > 0 and GameManager.nivel_base < nivel_min:
				continue
			if GameManager.moedas >= path.custos[0]:
				return true
		return false
	# Caminho já escolhido ou upgrades lineares
	var custo: int = get_custo_proximo_upgrade()
	return custo > 0 and GameManager.moedas >= custo

func _on_timer_ataque_timeout():
	if tipo != TipoConstrucao.TORRE or is_fantasma or esta_destruida: return
	if alvo_atual != null and is_instance_valid(alvo_atual):
		atacar()

func atacar():
	if not is_instance_valid(alvo_atual):
		return

	# Verifica se o caminho atual usa ataque especial
	var tipo_atq: String = tipo_ataque_proprio
	if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
		var path = upgrade_paths[caminho_atual]
		if path.tipo_ataque != "":
			tipo_atq = path.tipo_ataque

	if tipo_atq == "chain_lightning":
		_atacar_chain_lightning()
		return

	if tipo_atq == "fire_laser":
		_atacar_fire_laser()
		return

	if tipo_atq == "morteiro":
		_atacar_morteiro()
		return

	if tipo_atq == "caldeiron_area":
		_caldeiron_atacar_area_torre()
		return

	# Ataque normal com flecha
	if cena_flecha == null:
		return
	var flecha = cena_flecha.instantiate()
	get_tree().root.add_child(flecha)
	flecha.global_position = ponto_tiro.global_position if ponto_tiro else global_position + Vector3(0, 1.5, 0)
	flecha.dano = max(1, dano_atual + GameManager.bonus_dano)
	flecha.alvo = alvo_atual

# ==========================================
# ATAQUE TESLA — Corrente elétrica em cadeia
# ==========================================
func _atacar_chain_lightning():
	if not is_instance_valid(alvo_atual):
		return

	var num_saltos: int   = Balanceamento.get_int("tesla_chain_jumps", 2) + GameManager.bonus_ricochete
	var raio_chain: float = Balanceamento.get_float("tesla_chain_raio", 4.0)
	var mult_dano: float  = Balanceamento.get_float("tesla_chain_mult", 0.6)

	var dano_base: int = max(1, dano_atual + GameManager.bonus_dano)
	if GameManager.bonus_dano_chefe > 0 and alvo_atual.is_in_group("Chefe"):
		dano_base += GameManager.bonus_dano_chefe

	# Ponto de origem do raio (topo da tesla ou posição genérica)
	var pos_origem: Vector3 = global_position + Vector3(0, 0.8, 0)

	# Dano + efeito no alvo primário
	if alvo_atual.has_method("receber_dano"):
		alvo_atual.receber_dano(dano_base)
	_spawnar_raio(pos_origem, alvo_atual.global_position)

	# Coleta todos os inimigos no mapa para busca de cadeia
	var todos_inimigos: Array = get_tree().get_nodes_in_group("inimigos")

	var alvos_atingidos: Array = [alvo_atual]
	var alvo_prev: Node3D = alvo_atual
	var dano_chain: float = float(dano_base)

	for _salto in range(num_saltos):
		dano_chain *= mult_dano
		var proximo: Node3D = null
		var menor_dist: float = raio_chain

		for inimigo in todos_inimigos:
			if not is_instance_valid(inimigo): continue
			if inimigo in alvos_atingidos: continue
			var dist: float = alvo_prev.global_position.distance_to(inimigo.global_position)
			if dist < menor_dist:
				menor_dist = dist
				proximo = inimigo

		if proximo == null:
			break

		alvos_atingidos.append(proximo)
		if proximo.has_method("receber_dano"):
			proximo.receber_dano(max(1, int(dano_chain)))
		_spawnar_raio(alvo_prev.global_position, proximo.global_position)
		alvo_prev = proximo

func _spawnar_raio(origem: Vector3, destino: Vector3) -> void:
	if cena_raio_eletrico == null:
		return
	var raio = cena_raio_eletrico.instantiate()
	get_tree().root.add_child(raio)
	raio.configurar(origem, destino)

# ==========================================
# ATAQUE FIRE LASER — Queima contínua em múltiplos alvos
# Acerta até torre_fogo_max_alvos inimigos mais próximos no alcance.
# Dano por disparo = dano_atual (o ramp-up é simulado pela cadência — quanto mais
# rápido o timer, mais DPS efetivo conforme upgrades de velocidade são aplicados).
# ==========================================
func _atacar_fire_laser() -> void:
	var max_alvos_fogo: int = Balanceamento.get_int("torre_fogo_max_alvos", 3)
	var dano_base: int = max(1, dano_atual + GameManager.bonus_dano)

	# Coleta inimigos no alcance e ordena do mais próximo ao mais distante
	var todos: Array = get_tree().get_nodes_in_group("inimigos")
	var em_alcance: Array = []
	for inimigo in todos:
		if not is_instance_valid(inimigo): continue
		if inimigo.get("esta_morto") == true: continue
		# Distância XZ para detectar aéreos em altitudes diferentes
		var dist_xz: float = Vector2(global_position.x - inimigo.global_position.x,
			global_position.z - inimigo.global_position.z).length()
		if dist_xz <= alcance_atual:
			em_alcance.append(inimigo)
	em_alcance.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var da = Vector2(global_position.x - a.global_position.x, global_position.z - a.global_position.z).length()
		var db = Vector2(global_position.x - b.global_position.x, global_position.z - b.global_position.z).length()
		return da < db)

	# Aplica dano nos primeiros max_alvos_fogo
	var atingidos: int = 0
	for inimigo in em_alcance:
		if atingidos >= max_alvos_fogo:
			break
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(dano_base)
		atingidos += 1

# ==========================================
# ATAQUE MORTEIRO — Projétil com explosão em área
# ==========================================
func _atacar_morteiro() -> void:
	if not is_instance_valid(alvo_atual):
		return
	if cena_bala_morteiro == null:
		return
	var bala = cena_bala_morteiro.instantiate()
	get_tree().root.add_child(bala)
	bala.global_position = global_position + Vector3(0, 1.4, 0)
	bala.dano = max(1, dano_atual + GameManager.bonus_dano)
	bala.alvo = alvo_atual

# ==========================================
# SISTEMA ECONÔMICO (MINA, CASA, MOINHO)
# ==========================================
func _pagar_recompensa():
	if is_fantasma or esta_destruida: return
	var _ondas_restantes = GameManager.onda_atual # (IMPORTANTE) Talvez avisar o jogador ou mostrar no label da onda atual como "X/5"
	var bonus_onda = max(1, 6 - GameManager.onda_atual)  # Ajuste conforme balanceamento
	
	var moedas_geradas = moedas_por_onda_atual + bonus_onda
	GameManager.moedas += moedas_geradas

	if Global.DEBUG_MODE:
		print("%s gerou %d moedas" % [name, moedas_geradas])
	get_tree().call_group("Interface", "atualizar_moedas")
	if tipo == TipoConstrucao.MOINHO:
		get_tree().call_group("Interface", "animar_bau_abrindo")

# ==========================================
# SISTEMA DO QUARTEL (SPAWN DE ALIADOS)
# ==========================================
func _spawn_aliados(_onda_atual):
	if is_fantasma or esta_destruida or cena_aliado == null:
		return
		
	# Trava de segurança: só spawna o que falta para completar o limite
	var quantidade_para_spawnar = numero_aliados_atual - soldados_vivos
	if quantidade_para_spawnar <= 0:
		return
		
	for i in range(quantidade_para_spawnar):
		_criar_um_aliado()

func _criar_um_aliado():
	var aliado = cena_aliado.instantiate()
	get_tree().current_scene.add_child(aliado)
	
	# 1. Pega a posição base
	var posicao_base = global_position
	if ponto_spawn:
		posicao_base = ponto_spawn.global_position
		
	# 2. Sorteia um ponto ao redor
	var pos_aleatoria = posicao_base + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	
	# 3. Raio da Física (RayCast)
	var espaco_fisica = get_world_3d().direct_space_state
	var origem_raio = pos_aleatoria + Vector3(0, 5.0, 0)
	var destino_raio = pos_aleatoria + Vector3(0, -10.0, 0)
	var query = PhysicsRayQueryParameters3D.create(origem_raio, destino_raio)
	
	var colisao = espaco_fisica.intersect_ray(query)
	
	# 4. Posiciona o soldado (Validação de terreno)
	if colisao:
		# Se colidir com água, tenta centralizar no ponto de spawn original
		if colisao.collider.is_in_group("Agua"):
			aliado.global_position = posicao_base
		else:
			aliado.global_position = colisao.position
	else:
		aliado.global_position = pos_aleatoria
	
	aliado.add_to_group("aliados")
	soldados_vivos += 1
	
	if aliado.has_signal("morreu"):
		aliado.morreu.connect(_on_aliado_morreu)

func _on_aliado_morreu(_aliado_morto: Node):
	soldados_vivos -= 1
	
	# 1. MOSTRA A BARRA E INICIA A ANIMAÇÃO
	if sprite_respawn and barra_respawn:
		sprite_respawn.visible = true
		barra_respawn.value = 0.0
		
		var tween = create_tween()
		tween.tween_property(barra_respawn, "value", 100.0, tempo_respawn)
	
	# 2. AGUARDA O TEMPO DO TIMER DO JOGO
	await get_tree().create_timer(tempo_respawn).timeout
	
	# 3. VERIFICA SE A CONSTRUÇÃO AINDA EXISTE E NÃO ESTÁ DESTRUÍDA
	if not is_instance_valid(self) or esta_destruida or soldados_vivos >= numero_aliados_atual:
		return
	
	# 4. CRIA O NOVO SOLDADO
	_criar_um_aliado()
	
	# 5. ESCONDE A BARRA (Apenas se o quartel estiver com todos os soldados vivos novamente)
	if sprite_respawn and soldados_vivos >= numero_aliados_atual:
		sprite_respawn.visible = false

# ==========================================
# SISTEMA DE DANO (COMUM A TODOS)
# ==========================================
func receber_dano(quantidade: int):
	if is_fantasma or esta_destruida: return
	vida_atual -= quantidade
	if tem_barra_vida and container_barra:
		container_barra.visible = true
		if barra_vida:
			barra_vida.value = vida_atual
	_atualizar_barra_3d()

	if GameManager.bonus_espinho > 0 and quantidade > 0:
		_aplicar_espinho()

	if tipo == TipoConstrucao.BASE:
		GameManager.vida_base_atual = vida_atual
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", y_inicial + 0.15, 0.05)
	tween.tween_property(self, "position:y", y_inicial, 0.05)
	
	if vida_atual <= 0:
		destruir()

func destruir():
	if Global.DEBUG_MODE:
		print("%s destruída!" % name)
	if tipo == TipoConstrucao.BASE:
		GameManager.acionar_game_over()
		return

	esta_destruida = true
	if is_instance_valid(_indicador_upgrade):
		_indicador_upgrade.visible = false
	visible = false 
	
	# Remove do grupo para os Orcs pararem de focar nela
	remove_from_group("Construcao")
	
	# Desconectar sinais para evitar chamadas após destruição
	if tipo in [TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO, TipoConstrucao.CALDEIRON]:
		if GameManager.onda_terminada.is_connected(_pagar_recompensa):
			GameManager.onda_terminada.disconnect(_pagar_recompensa)
	elif tipo == TipoConstrucao.QUARTEL:
		if GameManager.noite_iniciada.is_connected(_spawn_aliados):
			GameManager.noite_iniciada.disconnect(_spawn_aliados)
	
	if timer_ataque:
		timer_ataque.stop()
		
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)
		
	if not GameManager.onda_terminada.is_connected(reviver):
		GameManager.onda_terminada.connect(reviver)

func _aplicar_espinho() -> void:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	for inimigo in inimigos:
		if is_instance_valid(inimigo) and global_position.distance_to(inimigo.global_position) <= 3.0:
			if inimigo.has_method("receber_dano"):
				inimigo.receber_dano(GameManager.bonus_espinho)

func reviver():
	if Global.DEBUG_MODE:
		print("%s reconstruída!" % name)
	esta_destruida = false
	visible = true
	vida_atual = vida_maxima
	# Cancela qualquer tween de dano que tenha ficado pendente e garante
	# que a construção volta à altura correta (evita o bug de underground).
	position.y = y_inicial
	
	# MOSTRA AOS ORCS NOVAMENTE
	add_to_group("Construcao")
	
	# Reconectar sinais específicos
	match tipo:
		TipoConstrucao.MINA, TipoConstrucao.CASA, TipoConstrucao.MOINHO:
			if not GameManager.onda_terminada.is_connected(_pagar_recompensa):
				GameManager.onda_terminada.connect(_pagar_recompensa)
		TipoConstrucao.CALDEIRON:
			_caldeiron_timer = 0.0  # Reseta o timer ao reviver
		TipoConstrucao.QUARTEL:
			if not GameManager.noite_iniciada.is_connected(_spawn_aliados):
				GameManager.noite_iniciada.connect(_spawn_aliados)
	
	_inicializar_barra_vida()
	
	if timer_ataque and tipo == TipoConstrucao.TORRE:
		timer_ataque.start()
		
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", false)
		
	if GameManager.onda_terminada.is_connected(reviver):
		GameManager.onda_terminada.disconnect(reviver)

# ==========================================
# BUFFS GLOBAIS (apenas para TORRE)
# ==========================================
func atualizar_status():
	if tipo == TipoConstrucao.TORRE and timer_ataque:
		var tempo_com_upgrade = tempo_ataque_atual
		var tempo_final = tempo_com_upgrade / (1.0 + GameManager.bonus_velocidade_ataque)
		timer_ataque.wait_time = max(0.1, tempo_final)
		if GameManager.bonus_alcance > 0.0:
			_configurar_alcance()

func curar_totalmente():
	vida_atual = vida_maxima
	if tem_barra_vida and barra_vida:
		barra_vida.value = vida_atual
	if tem_barra_vida and container_barra:
		container_barra.visible = false
	if tipo == TipoConstrucao.BASE:
		GameManager.vida_base_atual = vida_atual
	_atualizar_barra_3d()
	if Global.DEBUG_MODE:
		print("%s curada!" % name)

# ==========================================
# TRANSPARÊNCIA
# ==========================================
func _on_area_transparencia_body_entered(body):
	if body.is_in_group("Player"):
		_set_transparencia(self, 0.25)

func _on_area_transparencia_body_exited(body):
	if body.is_in_group("Player"):
		_set_transparencia(self, 0.0)

func esconder_indicador():
	if indicador_alcance:
		indicador_alcance.visible = false
		
# ==========================================
# LUZ INTERNA À NOITE
# ==========================================
func _acender_luz_interna(_onda: int = 0) -> void:
	if is_instance_valid(_luz_interna) or esta_destruida:
		return
	_luz_interna = OmniLight3D.new()
	_luz_interna.light_color = Color(1.0, 0.55, 0.10) # âmbar quente
	_luz_interna.light_energy = 0.0
	_luz_interna.omni_range = 1
	_luz_interna.shadow_enabled = false # sem sombras = sem custo extra
	add_child(_luz_interna)
	_luz_interna.position = Vector3(0.0, 1.2, 0.0)
	var tw := create_tween()
	tw.tween_property(_luz_interna, "light_energy", 0.8, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _apagar_luz_interna(_onda: int = 0) -> void:
	if not is_instance_valid(_luz_interna):
		return
	var luz := _luz_interna
	_luz_interna = null
	var tw := create_tween()
	tw.tween_property(luz, "light_energy", 0.0, 0.5) \
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(luz.queue_free)

# ==========================================
# BORDA INTERAGIVEL COM CONTEXTO
# ==========================================
func _criar_borda_interagivel(_onda: int = 0) -> void:
	if esta_destruida: return
	_atualizar_segundo_next_pass(self, true)

func _remover_borda_interagivel(_onda: int = 0) -> void:
	_atualizar_segundo_next_pass(self, false)

# Percorre os nós recursivamente para injetar ou remover o segundo Next Pass de interatividade
func _atualizar_segundo_next_pass(no: Node, ativo: bool) -> void:
	if no is MeshInstance3D:
		var material = no.get_active_material(0)
		if material:
			var mat_override = no.get_surface_override_material(0)
			if mat_override == null:
				mat_override = material.duplicate(true)
				no.set_surface_override_material(0, mat_override)
				
			var primeiro_pass = mat_override.next_pass
			
			if primeiro_pass == null:
				primeiro_pass = ShaderMaterial.new()
				primeiro_pass.shader = preload("res://Shaders/outline.gdshader")
				primeiro_pass.set_shader_parameter("weight", 0.01)
				primeiro_pass.set_shader_parameter("color", Color.BLACK)
				mat_override.next_pass = primeiro_pass
			else:
				if not primeiro_pass.is_local_to_scene and primeiro_pass.resource_path != "":
					primeiro_pass = primeiro_pass.duplicate(true)
					mat_override.next_pass = primeiro_pass
			
			if ativo:
				if primeiro_pass.next_pass == null:
					var material_borda = ShaderMaterial.new()
					material_borda.shader = preload("res://Shaders/outline.gdshader")
					material_borda.set_shader_parameter("weight", 0.025)
					material_borda.set_shader_parameter("color", Color.WHITE)
					
					primeiro_pass.next_pass = material_borda
			else:
				primeiro_pass.next_pass = null

	for filho in no.get_children():
		if filho == _indicador_upgrade or filho == indicador_alcance or filho.name == "CirculoVeneno" or filho.name == "BarraVidaShader":
			continue
		_atualizar_segundo_next_pass(filho, ativo)

# ==========================================
# SISTEMA DE VENDA
# ==========================================

## Retorna o valor de venda: metade do total investido (construção + upgrades pagos).
func get_valor_venda() -> int:
	var total: int = custo_moedas
	if tem_paths and caminho_atual >= 0 and caminho_atual < upgrade_paths.size():
		var path = upgrade_paths[caminho_atual]
		for i in range(mini(nivel_atual, path.custos.size())):
			total += path.custos[i]
	elif not tem_paths:
		for i in range(mini(nivel_atual, upgrade_custos.size())):
			total += upgrade_custos[i]
	return round(total) / 2

func vender_construcao():
	# SISTEMA DE PROTEÇÃO: Impede vender a base principal
	if tipo == TipoConstrucao.BASE:
		if Global.DEBUG_MODE:
			print("Operação cancelada: A Base não pode ser vendida!")
		return

	GameManager.adicionar_moedas(get_valor_venda())
	queue_free()

# ==========================================
# EFEITOS VISUAIS E HOVER
# ==========================================
func _on_area_clique_mouse_entered():
	if esta_destruida or is_fantasma or GameManager.is_night: return
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	
	if Global.DEBUG_MODE and GameManager.has_method("adicionar_log_debug"):
		GameManager.adicionar_log_debug("SUCESSO: mouse_entered rodou em " + name)

	if _tween_hover and _tween_hover.is_running():
		_tween_hover.kill()
		
	_tween_hover = create_tween().set_parallel(true)
	
	# Anima as malhas originais (usadas no nível 0)
	for malha in _escalas_base_malhas.keys():
		if is_instance_valid(malha) and malha.visible:
			_tween_hover.tween_property(malha, "scale", _escalas_base_malhas[malha] * 1.08, 0.15).set_trans(Tween.TRANS_SINE)
			
	# Anima o container de upgrades (usado no nível 1 em diante)
	if is_instance_valid(modelo_anchor):
		_tween_hover.tween_property(modelo_anchor, "scale", Vector3(1.08, 1.08, 1.08), 0.15).set_trans(Tween.TRANS_SINE)

func _on_area_clique_mouse_exited():
	if esta_destruida or is_fantasma:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
		
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	if _tween_hover and _tween_hover.is_running():
		_tween_hover.kill()
		
	_tween_hover = create_tween().set_parallel(true)
	
	for malha in _escalas_base_malhas.keys():
		if is_instance_valid(malha):
			_tween_hover.tween_property(malha, "scale", _escalas_base_malhas[malha], 0.15).set_trans(Tween.TRANS_SINE)
			
	if is_instance_valid(modelo_anchor):
		_tween_hover.tween_property(modelo_anchor, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_SINE)
	
	if GameManager.construcao_destaque_upgrade == self \
	   and is_instance_valid(_indicador_upgrade) and _indicador_upgrade.visible \
	   and not GameManager.is_night:
		_set_borda_destaque(true)
	else:
		_set_borda_destaque(false)
		
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# Varre os nós filhos para encontrar malhas e altera o parâmetro do shader
func _aplicar_outline_malhas(no: Node, espessura: float):
	if no is MeshInstance3D:
		var material = no.get_active_material(0)
		if material and material.next_pass and material.next_pass is ShaderMaterial:
			# Força a individualidade do material via código caso a engine ignore o Local to Scene
			var mat_override = no.get_surface_override_material(0)
			if mat_override == null:
				mat_override = material.duplicate(true)
				no.set_surface_override_material(0, mat_override)
			mat_override.next_pass.set_shader_parameter("scale", espessura)
			
	for filho in no.get_children():
		_aplicar_outline_malhas(filho, espessura)

func _set_transparencia(no: Node, valor: float):
	if no is MeshInstance3D:
		if valor > 0.0:
			# Criamos o material de dithering
			var mat_dither = ShaderMaterial.new()
			mat_dither.shader = preload("res://Shaders/dithering_effect.gdshader")
			
			# Pegamos o material original para extrair a textura
			var mat_original = no.get_active_material(0)
			if mat_original and "albedo_texture" in mat_original:
				var tex = mat_original.albedo_texture
				mat_dither.set_shader_parameter("albedo_texture", tex)
			
			# Define o nível de transparência na matriz
			mat_dither.set_shader_parameter("alpha_threshold", valor)
			
			no.material_override = mat_dither
		else:
			# Remove o override e volta ao normal (com outline)
			no.material_override = null
				
	for filho in no.get_children():
		if filho == _indicador_upgrade: continue
		if filho == indicador_alcance: continue
		if filho.name == "CirculoVeneno": continue
		_set_transparencia(filho, valor)
