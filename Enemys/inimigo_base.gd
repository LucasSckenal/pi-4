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

@export_category("Referências Visuais & Som")
@export var modelo_3d: Node3D           
@export var animation_player: AnimationPlayer 
@export var som_dano_stream: AudioStream 

@export_category("Nomes das Animações")
@export var anim_andar: String = "walk"
@export var anim_atacar: String = "attack-melee-right"
@export var anim_morrer: String = "sit"

# ==========================================
# VARIÁVEIS INTERNAS
# ==========================================
var vida_atual: int
var esta_morto: bool = false
var alvo_atual: Node3D = null
var pode_atacar: bool = true
var escala_original: Vector3
var posicao_de_spawn: Vector3

@onready var nav_agent = $NavigationAgent3D

# --- VARIÁVEIS DO BOSS ---
var canvas_boss: CanvasLayer = null
var barra_vida_boss: ProgressBar = null
var barra_fantasma: ProgressBar = null  # A barra que "persegue" a vida real
var label_vida: Label = null

func _ready():
	add_to_group("inimigos")
	vida_atual = vida_maxima
	
	if modelo_3d:
		escala_original = modelo_3d.scale
	else:
		escala_original = scale 
		
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.5
		
	# SE FOR UM BOSS, CRIA A BARRA DE VIDA NA TELA
	if tipo_inimigo == Categoria.BOSS:
		_criar_interface_do_boss()
		
	# SE FOR MINI BOSS, PODEMOS DEIXÁ-LO UM POUCO MAIOR AUTOMATICAMENTE (Opcional)
	elif tipo_inimigo == Categoria.MINI_BOSS:
		if modelo_3d:
			modelo_3d.scale = escala_original * 1.3 # Fica 30% maior

func _physics_process(delta):
	if esta_morto: return

	# 1. Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. IA de Alvo
	if alvo_atual == null or not is_instance_valid(alvo_atual) or \
	   alvo_atual.is_in_group("Castelo") or (alvo_atual.get("esta_destruida") == true):
		alvo_atual = procurar_novo_alvo()

	if alvo_atual == null or not is_instance_valid(alvo_atual) or esta_morto:
		alvo_atual = procurar_novo_alvo()
		
	# 3. Movimento
	if alvo_atual and nav_agent:
		nav_agent.target_position = alvo_atual.global_position
		var dist = global_position.distance_to(alvo_atual.global_position)
		
		if dist > distancia_ataque:
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var dir = (next_pos - global_position).normalized()
				
				# PULO AUTOMÁTICO
				if is_on_floor() and is_on_wall():
					var eh_barreira: bool = false
					for i in get_slide_collision_count():
						var colisao = get_slide_collision(i)
						var colisor = colisao.get_collider()
						
						if colisor and colisor.is_in_group("Barreiras"):
							eh_barreira = true
							break
					
					if not eh_barreira:
						velocity.y = jump_velocity
				
				velocity.x = dir.x * velocidade
				velocity.z = dir.z * velocidade
				
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
		
	return get_tree().get_first_node_in_group("Castelo")

func atacar():
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

func morrer():
	esta_morto = true
	remove_from_group("inimigos")
	
	if $CollisionShape3D:
		$CollisionShape3D.set_deferred("disabled", true)
		
	if animation_player and animation_player.has_animation(anim_morrer):
		animation_player.play(anim_morrer)
		
	# Apaga a barra de vida do Boss da tela quando ele morre
	if canvas_boss:
		var tw_boss = create_tween()
		tw_boss.tween_property(canvas_boss.get_child(0), "modulate:a", 0.0, 1.0)
		tw_boss.finished.connect(canvas_boss.queue_free)
	
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(self, "scale", Vector3.ZERO, 1.0)
	tw.finished.connect(queue_free)

# ==========================================
# GERAÇÃO DA INTERFACE DO BOSS
# ==========================================
func _criar_interface_do_boss():
	# 1. Camada e Margens
	canvas_boss = CanvasLayer.new()
	canvas_boss.layer = 10 
	add_child(canvas_boss)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_left", 250)
	margin.add_theme_constant_override("margin_right", 250)
	canvas_boss.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# 2. Nome do Boss
	var label_nome = Label.new()
	label_nome.text =   nome_inimigo.to_upper() 
	label_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_nome.add_theme_font_size_override("font_size", 24)
	vbox.add_child(label_nome)

	# 3. Container da Barra
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(0, 30) # Altura da barra
	vbox.add_child(bar_container)

	# --- ESTILO ARREDONDADO (Pílula) ---
	var raio_curvatura = 15 

	var estilo_fundo = StyleBoxFlat.new()
	estilo_fundo.bg_color = Color(0, 0, 0, 0.7)
	estilo_fundo.set_corner_radius_all(raio_curvatura)
	# Margens individuais para evitar erro de função inexistente
	estilo_fundo.expand_margin_left = 3
	estilo_fundo.expand_margin_right = 3
	estilo_fundo.expand_margin_top = 3
	estilo_fundo.expand_margin_bottom = 3

	var estilo_fantasma = StyleBoxFlat.new()
	estilo_fantasma.bg_color = Color(1, 1, 1, 0.6)
	estilo_fantasma.set_corner_radius_all(raio_curvatura)

	# AQUI ESTAVA O ERRO: Nomeada como estilo_vida
	var estilo_vida = StyleBoxFlat.new()
	estilo_vida.bg_color = Color(0.8, 0.1, 0.1)
	estilo_vida.set_corner_radius_all(raio_curvatura)

	# 4. Instanciando as Barras
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
	# CORRIGIDO: Agora usando o nome correto da variável declarada acima
	barra_vida_boss.add_theme_stylebox_override("fill", estilo_vida)
	bar_container.add_child(barra_vida_boss)

	# --- ADICIONANDO OS 3 SEPARADORES ---
	var divisores_container = HBoxContainer.new()
	divisores_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	divisores_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_container.add_child(divisores_container)
	
	for i in range(3): 
		var espaco = Control.new()
		espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		divisores_container.add_child(espaco)
		
		var linha = ColorRect.new()
		linha.color = Color(0, 0, 0, 0.5) 
		linha.custom_minimum_size = Vector2(2, 0)
		divisores_container.add_child(linha)
	
	var final_espaco = Control.new()
	final_espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divisores_container.add_child(final_espaco)
