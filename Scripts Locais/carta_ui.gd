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
	var caminho_imagem = _textura_por_tipo(int(dados.tipo_bonus))

	if caminho_imagem != "":
		var textura_fundo = load(caminho_imagem)
		var estilo_imagem = StyleBoxTexture.new()
		estilo_imagem.texture = textura_fundo
		
		# Aplica a textura aos estados do botão
		add_theme_stylebox_override("normal", estilo_imagem)
		add_theme_stylebox_override("hover", estilo_imagem)
		add_theme_stylebox_override("pressed", estilo_imagem)

# Escolhe a textura de fundo conforme o EFEITO da carta (não só dano).
# Economia (ouro) / Defesa+controle (azul) / Ofensiva (vermelho = padrão).
# Os números são os valores do enum TipoUpgrade (carta_upgrade.gd).
func _textura_por_tipo(tipo: int) -> String:
	match tipo:
		# Economia: moeda, custo, ouro por abate, renda, ouro inicial,
		# reroll grátis, onda perfeita, primeira grátis
		1, 5, 12, 14, 18, 19, 26, 27:
			return "res://Assets/UI/CartaEconomia.png"
		# Defesa/utilidade: vida, lentidão, menos inimigos, espinho, explosão
		# da construção, soldado forte, vida torres, mais soldados
		2, 4, 6, 10, 13, 21, 23, 24:
			return "res://Assets/UI/CartaVida.png"
		# Ofensiva (padrão): dano, velocidade de ataque, alcance, ricochete,
		# inflamável, dano chefe, crítico, dano aéreo, execução, veneno,
		# dano crescente, base atiradora
		_:
			return "res://Assets/UI/CartaDano.png"

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
