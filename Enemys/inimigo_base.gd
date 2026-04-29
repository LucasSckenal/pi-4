extends CharacterBody3D
class_name InimigoBase 

# ==========================================
# CLASSIFICAÇÃO (NOVO!)
# ==========================================
enum Categoria { NORMAL, MINI_BOSS, BOSS }

@export_category("Identificação do Inimigo")
@export var tipo_inimigo: Categoria = Categoria.NORMAL
@export var nome_inimigo: String = "Monstro Desconhecido"
@export var eh_aereo: bool = false
@export_category("Comportamento Kamikaze (Quebra-Muro)")
@export var eh_kamikaze: bool = false
@export var raio_explosao: float = 3.0
@export var dano_explosao: int = 50
@export var prioriza_construcoes: bool = true # Se true, ele ignora tropas do jogador no caminho
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
@export var som_dano_stream: AudioStream 

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
var tempo_bloqueado: float = 0.0
var _contador_quedas: int = 0
var _timer_re_check: float = 0.0
const RE_CHECK_INTERVALO: float = 0.3

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
# DICAS PARA A TELA DE NOVO INIMIGO
# ==========================================
@export_category("Dicas do Inimigo (Tutorial)")
@export_multiline var dica_tutorial: String = "Inimigo padrão. Destrua-o rapidamente."
@export var status_velocidade: String = "MÉDIA"
@export var status_vida: String = "MÉDIA"
# ------------------------------------------

func _ready():
	add_to_group("inimigos")
	# Aplica multiplicadores globais do CSV (preserva valores-base definidos por cena)
	_aplicar_balanceamento()
	vida_atual = vida_maxima
	
	# Posição de desvio gerada para o cerco ao alvo
	desvio_posicao = Vector3(randf_range(-quanto_espalhar, quanto_espalhar), 0, randf_range(-quanto_espalhar, quanto_espalhar))
	
	if modelo_3d:
		escala_original = modelo_3d.scale
	else:
		escala_original = scale 
		
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.5
		
	# ==========================================
	# TELA DE AVISO (TUTORIAL / ENCYCLOPEDIA)
	# ==========================================
	# Se o nome do inimigo ainda não estiver na lista do GameManager:
	if not Global.inimigos_descobertos.has(nome_inimigo):
	# Adiciona à lista para não mostrar de novo na próxima vez
		Global.inimigos_descobertos.append(nome_inimigo)
		
		# Salva imediatamente no ficheiro .cfg para o jogador não perder a descoberta!
		Global.salvar_progresso() 
		
		# Chama o Autoload da nossa tela 3D
		if InputMap.has_action("passar_onda"): # Apenas um safety check leve
			TelaAvisoInimigo.mostrar_novo_inimigo(
				nome_inimigo, 
				dica_tutorial, 
				modelo_3d, 
				status_velocidade, 
				status_vida
			)
		
	# SE FOR UM BOSS, CRIA A BARRA DE VIDA NA TELA
	if tipo_inimigo == Categoria.BOSS:
		_criar_interface_do_boss()
		
	# SE FOR MINI BOSS, PODEMOS DEIXÁ-LO UM POUCO MAIOR AUTOMATICAMENTE (Opcional)
	elif tipo_inimigo == Categoria.MINI_BOSS:
		if modelo_3d:
			modelo_3d.scale = escala_original * 1.3 # Fica 30% maior
			
	

# ==========================================
# BALANCEAMENTO (multiplicadores globais do CSV)
# Os @export vars vêm do inspector (customizados por cena).
# O CSV aplica um multiplicador em cima disso — sem quebrar
# configs de boss, mini-boss ou qualquer inimigo especial.
# ==========================================
func _aplicar_balanceamento() -> void:
	vida_maxima = int(vida_maxima * Balanceamento.get_float("inimigo_mult_vida",        1.0))
	velocidade  = velocidade      * Balanceamento.get_float("inimigo_mult_velocidade",   1.0)
	forca_dano  = int(forca_dano  * Balanceamento.get_float("inimigo_mult_dano",         1.0))

func _physics_process(delta):
	if esta_morto: return

	# Resgate de entidade que caiu do mapa
	if global_position.y < limite_queda_y:
		_contador_quedas += 1
		if _contador_quedas <= limite_respawn_queda:
			global_position = posicao_de_spawn
			velocity = Vector3.ZERO
		else:
			morrer()
		return

	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# --- NOVA LÓGICA: SE ESTIVER INVOCANDO, NÃO FAZ MAIS NADA ---
	if eh_necromancer and esta_invocando:
		move_and_slide()
		return
		
	# --- NOVA LÓGICA: CHECAGEM PARA INVOCAR ---
	if eh_necromancer and pode_invocar and is_on_floor() and alvo_atual:
		invocar_minions()
		return # Interrompe este frame para ele não tentar andar e invocar ao mesmo
		
	# 2. IA de Alvo
	if alvo_atual == null or not is_instance_valid(alvo_atual) or \
	   (alvo_atual.get("esta_destruida") == true):
		alvo_atual = procurar_novo_alvo()
		_timer_re_check = 0.0
	elif alvo_atual.is_in_group("Castelo") or alvo_atual.is_in_group("Base"):
		# Está indo para a base — verifica periodicamente se há construções mais perto
		_timer_re_check -= delta
		if _timer_re_check <= 0.0:
			_timer_re_check = RE_CHECK_INTERVALO
			var candidato = procurar_novo_alvo()
			# Só troca se encontrou uma construção/aliado (não a própria base)
			if is_instance_valid(candidato) and \
			   not candidato.is_in_group("Castelo") and \
			   not candidato.is_in_group("Base"):
				alvo_atual = candidato

	if alvo_atual == null or not is_instance_valid(alvo_atual) or esta_morto:
		alvo_atual = procurar_novo_alvo()
		
	# 3. Movimento
	if alvo_atual and nav_agent:
		var alvo_pos = alvo_atual.global_position
		var dist = global_position.distance_to(alvo_pos)
		# Distância horizontal (XZ) para não falhar contra bases elevadas no mapa
		var dist_xz = Vector2(global_position.x - alvo_pos.x, global_position.z - alvo_pos.z).length()

		# Descentraliza o alvo apenas a curtas distâncias para cercar as construções
		if dist < dist_tornar_random:
			alvo_pos += desvio_posicao

		nav_agent.target_position = alvo_pos

		if dist_xz > distancia_ataque:
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var dir = (next_pos - global_position).normalized()
				
				# PULO AUTOMÁTICO
				if is_on_floor() and is_on_wall():
					var eh_barreira: bool = false
					for i in get_slide_collision_count():
						var colisao = get_slide_collision(i)
						var colisor = colisao.get_collider()
						
						# Verifica se a entidade colidida exige a interrupção do pulo
						if colisor and (colisor.is_in_group("Barreiras") or colisor.is_in_group("Castelo") or colisor.is_in_group("inimigos") or colisor == alvo_atual):
							eh_barreira = true
							break
					
					if not eh_barreira:
						velocity.y = jump_velocity
				
				var vel_aplicada = velocidade * max(0.1, GameManager.multiplicador_velocidade_inimigo)
				velocity.x = dir.x * vel_aplicada
				velocity.z = dir.z * vel_aplicada
				
				# ROTAÇÃO
				var look_dir = Vector2(velocity.z, velocity.x)
				rotation.y = lerp_angle(rotation.y, look_dir.angle(), 10 * delta)
				
				if is_on_floor() and animation_player and animation_player.has_animation(anim_andar): 
					animation_player.play(anim_andar)
		else:
			velocity.x = 0
			velocity.z = 0
			atacar()

	move_and_slide()

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

	# Fallback: tenta "Castelo" (castle.gd) e depois "Base" (Builds.gd/BarcoBase)
	# pois mapas diferentes usam grupos distintos para a base principal.
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
		if alvo_atual.has_method("receber_dano"):
			alvo_atual.receber_dano(forca_dano)
		
		await get_tree().create_timer(tempo_recarga_ataque).timeout
		pode_atacar = true

func receber_dano(qtd, origem = "torre"):
	if esta_morto: return
	
	# Se o inimigo for aéreo e a origem for o player, ignoramos o dano
	if eh_aereo and origem == "player":
		# Opcional: criar um efeito visual de "Miss" aqui
		return 

	vida_atual -= qtd
	
	# Atualiza a barra do Boss se ela existir
	if barra_vida_boss:
		# 1. Shake na barra (Tremidinha de impacto)
		var original_pos = canvas_boss.get_child(0).position
		var tw_shake = create_tween()
		for i in range(4):
			var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
			tw_shake.tween_property(canvas_boss.get_child(0), "position", original_pos + offset, 0.05)
		tw_shake.tween_property(canvas_boss.get_child(0), "position", original_pos, 0.05)

		# 2. Tween da Barra Principal (Rápido)
		var tw_barra = create_tween()
		tw_barra.tween_property(barra_vida_boss, "value", vida_atual, 0.1).set_trans(Tween.TRANS_QUINT)
		
		# 3. Tween da Barra Fantasma (Lento, com atraso)
		var tw_fantasma = create_tween()
		tw_fantasma.tween_interval(0.4) # Espera um pouco antes de cair
		tw_fantasma.tween_property(barra_fantasma, "value", vida_atual, 0.8).set_trans(Tween.TRANS_SINE)
	
	# Efeitos de som e visual (seu código original)
	if som_dano_stream:
		var som_hit = AudioStreamPlayer3D.new()
		som_hit.stream = som_dano_stream
		som_hit.volume_db = -25
		add_child(som_hit)
		som_hit.play()
		som_hit.finished.connect(som_hit.queue_free)
	
	# Feedback visual de piscar (seu código original) 
	if modelo_3d:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(modelo_3d, "scale", escala_original * 1.2, 0.1)
		tw.chain().tween_property(modelo_3d, "scale", escala_original, 0.1)
	
	if vida_atual <= 0: morrer()
	
	if modelo_3d:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(modelo_3d, "scale", escala_original * 1.2, 0.1)
		tw.chain().tween_property(modelo_3d, "scale", escala_original, 0.1)
		
		for child in modelo_3d.find_children("*", "MeshInstance3D"):
			var mat = child.get_active_material(0)
			if mat is StandardMaterial3D:
				var mat_local = mat.duplicate()
				child.set_surface_override_material(0, mat_local)
				mat_local.emission_enabled = true
				mat_local.emission = Color.WHITE
				mat_local.emission_energy_multiplier = 2.0
				
				var tw_color = create_tween()
				tw_color.tween_property(mat_local, "emission_energy_multiplier", 0.0, 0.2)
	
	if vida_atual <= 0: morrer()
	
func invocar_minions():
	if cena_minion == null:
		push_warning("Necromante tentou invocar, mas não há cena configurada!")
		pode_invocar = false 
		return
	
	# --- 1. LIMPEZA DA LISTA (OTIMIZAÇÃO) ---
	# Remove da lista os minions que já foram destruídos ou marcados como mortos
	var minions_vivos = []
	for minion in meus_minions_ativos:
		if is_instance_valid(minion) and not minion.get("esta_morto"):
			minions_vivos.append(minion)
	meus_minions_ativos = minions_vivos
	
	# --- 2. TRAVA DO LIMITE ---
	# Se já atingiu o limite, cancela a invocação neste turno
	if meus_minions_ativos.size() >= limite_minions_vivos:
		await get_tree().create_timer(tempo_recarga_invocacao).timeout
		pode_invocar = true
		return
		
	# --- 3. INÍCIO DO RITUAL ---
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
	
	# Calcula quantos ele PODE invocar agora (para não passar do limite sem querer)
	var vagas_livres = limite_minions_vivos - meus_minions_ativos.size()
	var qtd_a_invocar = min(qtd_minions_por_vez, vagas_livres)

	# --- 4. GERAÇÃO SEGURA ---
	for i in range(qtd_a_invocar):
		var minion = cena_minion.instantiate()
		get_parent().add_child(minion)
		
		var angulo = (PI * 2 / qtd_a_invocar) * i
		var offset = Vector3(cos(angulo), 0, sin(angulo)) * raio_de_invocacao
		var posicao_desejada = global_position + offset
		
		var posicao_segura = NavigationServer3D.map_get_closest_point(nav_map, posicao_desejada)
		minion.global_position = posicao_segura
		
		# Adiciona o novo recruta na "lista de chamada" do Necromante
		meus_minions_ativos.append(minion)

	esta_invocando = false
	await get_tree().create_timer(tempo_recarga_invocacao).timeout
	pode_invocar = true

func morrer():
	esta_morto = true
	remove_from_group("inimigos")

	# Drop de moedas exclusivo do modo infinito (facilita a economia)
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
		
	# Apaga a barra de vida do Boss da tela quando ele morre
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
# GERAÇÃO DA INTERFACE DO BOSS
# ==========================================
func _criar_interface_do_boss():
	# 1. Criação da Camada (CanvasLayer) para ficar sempre acima do jogo
	canvas_boss = CanvasLayer.new()
	canvas_boss.layer = 10 
	add_child(canvas_boss)
	
	# Container de Margens para posicionar no topo
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_left", 350)
	margin.add_theme_constant_override("margin_right", 350)
	canvas_boss.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	# 2. Nome do Boss com Estética de RPG
	var label_nome = Label.new()
	label_nome.text = "☠️ " + nome_inimigo.to_upper() + " ☠️"
	label_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_nome.add_theme_font_size_override("font_size", 24)
	label_nome.add_theme_color_override("font_color", Color(1, 0.2, 0.2)) # Vermelho Intenso
	label_nome.add_theme_color_override("font_outline_color", Color.BLACK)
	label_nome.add_theme_constant_override("outline_size", 8)
	vbox.add_child(label_nome)

	# 3. Container para as barras (permite sobrepor uma à outra)
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(0, 30) # Altura da barra
	vbox.add_child(bar_container)

	# --- CONFIGURAÇÃO DE ESTILOS (Bordas Redondas e Premium) ---
	var raio_curvatura = 15 # Estilo Pílula

	# Estilo do Fundo (Borda metálica e sombra)
	var estilo_fundo = StyleBoxFlat.new()
	estilo_fundo.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	estilo_fundo.set_corner_radius_all(raio_curvatura)
	estilo_fundo.border_width_left = 2
	estilo_fundo.border_width_right = 2
	estilo_fundo.border_width_top = 2
	estilo_fundo.border_width_bottom = 2
	estilo_fundo.border_color = Color(0.3, 0.3, 0.3) # Prateado escuro
	estilo_fundo.expand_margin_left = 4
	estilo_fundo.expand_margin_right = 4
	estilo_fundo.expand_margin_top = 4
	estilo_fundo.expand_margin_bottom = 4

	# Estilo da Barra Fantasma (Branco suave)
	var estilo_fantasma = StyleBoxFlat.new()
	estilo_fantasma.bg_color = Color(1, 1, 1, 0.5)
	estilo_fantasma.set_corner_radius_all(raio_curvatura)

	# Estilo da Barra de Vida (Vermelho com brilho no topo)
	var estilo_vida = StyleBoxFlat.new()
	estilo_vida.bg_color = Color(0.8, 0, 0)
	estilo_vida.set_corner_radius_all(raio_curvatura)
	estilo_vida.border_width_top = 3
	estilo_vida.border_color = Color(1, 0.3, 0.3, 0.3) # Brilho interno "Glass"

	# 4. Instanciar as ProgressBars
	barra_fantasma = ProgressBar.new()
	barra_fantasma.set_anchors_preset(Control.PRESET_FULL_RECT)
	barra_fantasma.max_value = vida_maxima
	barra_fantasma.value = vida_atual
	barra_fantasma.show_percentage = false
	barra_fantasma.add_theme_stylebox_override("background", estilo_fundo)
	barra_fantasma.add_theme_stylebox_override("fill", estilo_fantasma)
	bar_container.add_child(barra_fantasma)

	barra_vida_boss = ProgressBar.new()
	barra_vida_boss.set_anchors_preset(Control.PRESET_FULL_RECT)
	barra_vida_boss.max_value = vida_maxima
	barra_vida_boss.value = vida_atual
	barra_vida_boss.show_percentage = false
	barra_vida_boss.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	barra_vida_boss.add_theme_stylebox_override("fill", estilo_vida)
	bar_container.add_child(barra_vida_boss)

	# 5. Adicionar exatamente 3 separadores (dividindo em 4 partes)
	var divisores_container = HBoxContainer.new()
	divisores_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	divisores_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(divisores_container)
	
	for i in range(3):
		var espaco = Control.new()
		espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		divisores_container.add_child(espaco)
		
		var linha = ColorRect.new()
		linha.color = Color(0, 0, 0, 0.4) # Separador discreto
		linha.custom_minimum_size = Vector2(2, 0)
		divisores_container.add_child(linha)
	
	var final_espaco = Control.new()
	final_espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divisores_container.add_child(final_espaco)

	# 6. Efeito de Brilho Pulsante (Animação constante)
	var tw_glow = create_tween().set_loops()
	tw_glow.tween_property(bar_container, "modulate:v", 1.2, 1.0)
	tw_glow.tween_property(bar_container, "modulate:v", 1.0, 1.0)

func _explodir():
	if esta_explodindo: return
	esta_explodindo = true
	velocidade = 0.0 
	
	# 1. Toca a animação ANTES da explosão (inchando/pavio)
	if animation_player and animation_player.has_animation(anim_explodir):
		animation_player.play(anim_explodir)
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout 
		
	# 2. CHAMA O EFEITO VISUAL E CAUSA O DANO (O "Boom" acontece aqui)
	_criar_efeito_explosao()
	
	var alvos_potenciais = get_tree().get_nodes_in_group("Construcao")
	if not prioriza_construcoes:
		alvos_potenciais.append_array(get_tree().get_nodes_in_group("Player"))
		
	for alvo in alvos_potenciais:
		if is_instance_valid(alvo) and alvo.has_method("receber_dano"):
			var distancia = global_position.distance_to(alvo.global_position)
			if distancia <= raio_explosao:
				alvo.receber_dano(dano_explosao)
				
	# 3. TOCA A ANIMAÇÃO PÓS-EXPLOSÃO (ex: caindo no chão, morrendo)
	if animation_player and animation_player.has_animation(anim_pos_explosao):
		animation_player.play(anim_pos_explosao)
		# Espera essa nova animação terminar também
		await animation_player.animation_finished
				
	# 4. Só agora, no final de tudo, o inimigo some da memória!
	queue_free()
	
func _criar_efeito_explosao():
	# Criamos um nó principal para segurar todos os efeitos visuais juntos
	var node_explosao = Node3D.new()
	get_tree().current_scene.add_child(node_explosao)
	node_explosao.global_position = global_position

	# 1. O CLARÃO DA EXPLOSÃO (Luz forte que ilumina o cenário em volta)
	var luz = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.4, 0.0) # Laranja quente
	luz.light_energy = 8.0 # Bem forte!
	luz.omni_range = raio_explosao * 2.5
	node_explosao.add_child(luz)

	# 2. A BOLA DE FOGO (Mais sólida e brilhante)
	var mesh_esfera = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	mesh_esfera.mesh = sphere
	
	var mat_esfera = StandardMaterial3D.new()
	mat_esfera.albedo_color = Color(1.0, 0.1, 0.0, 0.9) # Vermelho intenso
	mat_esfera.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_esfera.emission_enabled = true
	mat_esfera.emission = Color(1.0, 0.3, 0.0) # Fogo brilhante
	mat_esfera.emission_energy_multiplier = 4.0
	sphere.surface_set_material(0, mat_esfera)
	node_explosao.add_child(mesh_esfera)

	# 3. ANIMANDO TUDO
	var tween = get_tree().create_tween()
	var tamanho_final = raio_explosao * 2.0
	var tempo_explosao = 0.6 # Tempo que leva para o fogo sumir

	# A esfera de fogo cresce rapidamente
	tween.tween_property(mesh_esfera, "scale", Vector3(tamanho_final, tamanho_final, tamanho_final), tempo_explosao).from(Vector3.ZERO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# O fogo vai desaparecendo (ficando transparente)
	tween.parallel().tween_property(mat_esfera, "albedo_color:a", 0.0, tempo_explosao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# A luz do clarão apaga um pouco mais rápido que o fogo
	tween.parallel().tween_property(luz, "light_energy", 0.0, tempo_explosao * 0.7)

	# Quando tudo terminar, apaga os efeitos visuais
	tween.tween_callback(node_explosao.queue_free)
