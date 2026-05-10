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
	# SISTEMA DE IMAGEM DE FUNDO (Texturas)
	# ==========================================
	var caminho_imagem = ""
	
	match dados.tipo_bonus:
		CartaUpgrade.TipoUpgrade.DANO:
			caminho_imagem = "res://Assets/UI/CartaDano.png"
		CartaUpgrade.TipoUpgrade.VELOCIDADE_ATAQUE:
			caminho_imagem = "res://Assets/UI/CartaDano.png"
		CartaUpgrade.TipoUpgrade.VIDA:
			caminho_imagem = "res://Assets/UI/CartaVida.png"
		CartaUpgrade.TipoUpgrade.MOEDA:
			caminho_imagem = "res://Assets/UI/CartaEconomia.png"
		CartaUpgrade.TipoUpgrade.CUSTO_CONSTRUCAO:
			caminho_imagem = "res://Assets/UI/CartaEconomia.png"
		_:
			# Caso não tenha uma imagem específica, pode usar uma padrão ou a de Dano
			caminho_imagem = "res://Assets/UI/CartaDano.png" 

	if caminho_imagem != "":
		var textura_fundo = load(caminho_imagem)
		var estilo_imagem = StyleBoxTexture.new()
		estilo_imagem.texture = textura_fundo
		
		# Aplica a textura aos estados do botão
		add_theme_stylebox_override("normal", estilo_imagem)
		add_theme_stylebox_override("hover", estilo_imagem)
		add_theme_stylebox_override("pressed", estilo_imagem)

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
