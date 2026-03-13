extends Button

@onready var label_titulo = $VBoxContainer/LabelTitulo
@onready var label_desc = $VBoxContainer/LabelDesc
@onready var texture_icone = $VBoxContainer/textureIcone

var carta_dados: CartaUpgrade

func configurar(dados: CartaUpgrade):
	carta_dados = dados
	
	# Atualiza o visual (Título, Descrição e Ícone)
	if label_titulo: label_titulo.text = dados.titulo
	if label_desc: label_desc.text = dados.descricao
	if texture_icone: texture_icone.texture = dados.icone
	
	# ==========================================
	# SISTEMA DE CORES DA BORDA (Seguro)
	# ==========================================
	if has_theme_stylebox("normal"):
		var estilo_original = get_theme_stylebox("normal")
		
		# Só tenta pintar a borda se o botão realmente tiver um StyleBox do tipo Flat
		if estilo_original is StyleBoxFlat:
			var estilo_borda = estilo_original.duplicate() 
			add_theme_stylebox_override("normal", estilo_borda)
			add_theme_stylebox_override("hover", estilo_borda)
			
			match dados.tipo_bonus:
				CartaUpgrade.TipoUpgrade.DANO:
					estilo_borda.border_color = Color.RED
				CartaUpgrade.TipoUpgrade.VIDA:
					estilo_borda.border_color = Color.GREEN
				CartaUpgrade.TipoUpgrade.VELOCIDADE_ATAQUE:
					estilo_borda.border_color = Color.SKY_BLUE
				CartaUpgrade.TipoUpgrade.MOEDA:
					estilo_borda.border_color = Color.GOLD
				_:
					estilo_borda.border_color = Color.WHITE
