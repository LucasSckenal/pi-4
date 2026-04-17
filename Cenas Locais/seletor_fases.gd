extends Control

signal fechar_seletor

# Caminho para a sua textura do tracinho
var textura_linha = preload("res://Icons/textura_tracinho.png")
var estrela_cheia = preload("res://Icons/star.png")
var estrela_vazia = preload("res://Icons/star_outline_depth.png") # Uma versão cinza ou vazia da estrela
# Pegamos o nó do pergaminho para jogar as linhas lá dentro
@onready var pergaminho = $Meshy_AI_Blank_Scroll_0416004051_texture
var progresso_atual = 2

# Nomes corrigidos exatamente iguais à sua foto!
@onready var botoes_fases = [
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map1,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map2,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map3,
	$Meshy_AI_Blank_Scroll_0416004051_texture/Map6
]

var estrelas_por_fase = {
	"Map1": 3,
	"Map2": 2,
	"Map3": 1,
	"Map6": 0
}

var linhas_criadas = []

func _ready() -> void:
	# Conecta o sinal para redimensionar
	get_tree().root.size_changed.connect(recalcular_linhas)
	
	# Desenha tudo pela primeira vez
	recalcular_linhas()

func recalcular_linhas() -> void:
	# Espera um frame para o Godot calcular as novas posições da UI
	await get_tree().process_frame
	
	# 1. Limpa e cria as linhas
	criar_linhas_tracejadas()
	
	# 2. Atualiza o mapa usando a variável que está lá no topo!
	atualizar_mapa(progresso_atual)

func criar_linhas_tracejadas() -> void:
	# Limpa as antigas
	for l in linhas_criadas:
		l.queue_free()
	linhas_criadas.clear()

	for i in range(botoes_fases.size() - 1):
		var b1 = botoes_fases[i]
		var b2 = botoes_fases[i + 1]
		
		if b1 == null or b2 == null: continue
			
		var linha = Line2D.new()
		
		# USAREMOS POSIÇÃO GLOBAL DE TELA
		# Isso ignora se o pergaminho está esticado ou torto
		var p1 = b1.global_position + (b1.size * b1.get_global_transform().get_scale() / 2.0)
		var p2 = b2.global_position + (b2.size * b2.get_global_transform().get_scale() / 2.0)
		
		linha.add_point(p1)
		linha.add_point(p2)
		
		# Se a linha sumir, aumente esse width para 20 ou 30
		linha.width = 150.0 
		linha.texture = textura_linha
		linha.texture_mode = Line2D.LINE_TEXTURE_TILE
		linha.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		linha.default_color = Color(1, 1, 1, 1)
		
		# Z_INDEX alto faz a linha ficar na frente de tudo (para vermos onde ela está!)
		linha.z_index = 0
	
		
		# ADICIONAMOS DIRETO NA RAIZ DA CENA (mais seguro para teste)
		get_tree().current_scene.add_child(linha)
		
		linhas_criadas.append(linha)

func atualizar_mapa(fases_liberadas: int) -> void:
	for i in range(botoes_fases.size()):
		var botao = botoes_fases[i] 
		var nivel_da_fase = i + 1 
		
		if nivel_da_fase <= fases_liberadas:
			botao.modulate = Color(1, 1, 1, 1) 
			botao.disabled = false 
			# Chamamos a atualização das estrelas aqui:
			atualizar_estrelas_do_botao(botao)
		else:
			botao.modulate = Color(0.2, 0.2, 0.2, 1) 
			botao.disabled = true

	for i in range(linhas_criadas.size()):
		var nivel_destino = i + 2 
		if nivel_destino <= fases_liberadas:
			linhas_criadas[i].show()
		else:
			linhas_criadas[i].hide()

func atualizar_estrelas_do_botao(botao: Button) -> void:
	var nome_do_mapa = botao.name # Pega "Map1", "Map2", etc 
	var qtd_estrelas = estrelas_por_fase.get(nome_do_mapa, 0)
	
	# Faz um loop de 1 a 3 para verificar star1, star2 e star3
	for n in range(1, 4):
		var nome_node = "Star" + str(n)
		if botao.has_node(nome_node):
			var estrela_node = botao.get_node(nome_node) as MeshInstance2D
			
			# Se a quantidade de estrelas ganhas for maior ou igual ao número da estrela
			if qtd_estrelas >= n:
				estrela_node.texture = estrela_cheia
			else:
				estrela_node.texture = estrela_vazia
				
# ==========================================
# SEUS SINAIS ORIGINAIS 
# (Certifique-se de que os nomes correspondem aos sinais dos botões no Godot)
# ==========================================		

func _on_btn_aquatico_pressed() -> void:
	MusicaGlobal.tocar_aquatico()
	get_tree().change_scene_to_file("res://Maps/fenda_dos_piratas.tscn")

func _on_btn_scifi_pressed() -> void:
	MusicaGlobal.tocar_tutorial()
	get_tree().change_scene_to_file("res://Maps/tutorial_world.tscn")

func _on_btn_voltar_pressed() -> void:
	fechar_seletor.emit()


func _on_map_1_pressed() -> void:
	MusicaGlobal.tocar_tutorial()
	get_tree().change_scene_to_file("res://Maps/tutorial_world.tscn")


func _on_map_2_pressed() -> void:
	MusicaGlobal.tocar_deserto()
	get_tree().change_scene_to_file("res://Maps/Crimson_Desert.tscn")


func _on_map_3_pressed() -> void:
	MusicaGlobal.tocar_bruxa()
	get_tree().change_scene_to_file("res://Maps/Witch_house.tscn")


func _on_map_6_pressed() -> void:
	MusicaGlobal.tocar_covil()
	get_tree().change_scene_to_file("res://Maps/Covil_Dragon.tscn")
