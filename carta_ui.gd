extends Button

@onready var label_titulo = $VBoxContainer/LabelTitulo
@onready var label_desc = $VBoxContainer/LabelDesc
@onready var texture_icone = $VBoxContainer/textureIcone

# Vamos pegar o StyleBox único desta carta para não pintar todas as outras juntas
var estilo_borda : StyleBoxFlat

func configurar(dados: CartaUpgrade):
	label_titulo.text = dados.titulo
	label_desc.text = dados.descricao
	texture_icone.texture = dados.icone
	
	# 1. Pegamos o estilo que está no seu botão (ou no painel de fundo)
	# Se a borda estiver no próprio Button, use: get_theme_stylebox("normal")
	# Se tiver um Panel separado, use: $SeuPainel.get_theme_stylebox("panel")
	estilo_borda = get_theme_stylebox("normal").duplicate() 
	add_theme_stylebox_override("normal", estilo_borda)
	add_theme_stylebox_override("hover", estilo_borda) # Para não mudar a cor ao passar o mouse
	
	# 2. Definimos a cor da borda baseado no tipo
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
