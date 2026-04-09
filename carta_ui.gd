extends Button

@onready var label_titulo = $VBoxContainer/LabelTitulo
@onready var label_desc = $VBoxContainer/LabelDesc
@onready var texture_icone = $VBoxContainer/textureIcone

var carta_dados: CartaUpgrade

func _ready() -> void:
	# Conecta os sinais para o efeito de escala (Hover)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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
			
			# Criamos uma variação para o Hover com borda mais grossa
			var estilo_hover = estilo_borda.duplicate()
			estilo_hover.border_width_left = 4
			estilo_hover.border_width_top = 4
			estilo_hover.border_width_right = 4
			estilo_hover.border_width_bottom = 4
			
			add_theme_stylebox_override("normal", estilo_borda)
			add_theme_stylebox_override("hover", estilo_hover) # <--- Aplicando o estilo de destaque
			
			match dados.tipo_bonus:
				CartaUpgrade.TipoUpgrade.DANO:
					estilo_borda.border_color = Color.RED
					estilo_hover.border_color = Color.RED.lightened(0.2) # Brilha um pouco mais no hover
				CartaUpgrade.TipoUpgrade.VIDA:
					estilo_borda.border_color = Color.GREEN
					estilo_hover.border_color = Color.GREEN.lightened(0.2)
				CartaUpgrade.TipoUpgrade.VELOCIDADE_ATAQUE:
					estilo_borda.border_color = Color.SKY_BLUE
					estilo_hover.border_color = Color.SKY_BLUE.lightened(0.2)
				CartaUpgrade.TipoUpgrade.MOEDA:
					estilo_borda.border_color = Color.GOLD
					estilo_hover.border_color = Color.YELLOW
				_:
					estilo_borda.border_color = Color.WHITE
					estilo_hover.border_color = Color.WHITE

# ==========================================
# ANIMAÇÕES DE HOVER (Suave)
# ==========================================
func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	z_index = 170 # Fica acima das outras cartas ao focar

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	z_index = 160
