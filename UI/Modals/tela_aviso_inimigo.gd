extends CanvasLayer

# ==========================================
# REFERÊNCIAS AOS NÓS DA INTERFACE
# ==========================================
@onready var nome_inimigo_label: Label      = $CartaoCentral/Margin/VBox/NomeInimigo
@onready var dica_texto: Label              = $CartaoCentral/Margin/VBox/DicaTexto
@onready var vel_info: Label                = $CartaoCentral/Margin/VBox/Status/VelocidadeInfo
@onready var vida_info: Label               = $CartaoCentral/Margin/VBox/Status/VidaInfo
@onready var icone_rect: TextureRect        = $CartaoCentral/Margin/VBox/IconeInimigo
@onready var cartao: Panel                  = $CartaoCentral

func _ready():
	hide()

# ==========================================
# FUNÇÃO PRINCIPAL (Chamada pelo Inimigo)
# ==========================================
func mostrar_novo_inimigo(nome: String, dica: String, icone: Texture2D, vel_desc: String, hp_desc: String):
	nome_inimigo_label.text = nome.to_upper()
	dica_texto.text         = dica
	vel_info.text           = "Vel: " + vel_desc
	vida_info.text          = "HP: "  + hp_desc

	icone_rect.texture = icone   # null é aceite — TextureRect simplesmente fica em branco

	get_tree().paused = true
	show()

	# Garante que o pivot do ícone está centrado (necessário para o pulso não deslocar)
	await get_tree().process_frame
	icone_rect.pivot_offset = icone_rect.size * 0.5

	# Animação de entrada: cartão sobe do nada
	cartao.scale    = Vector2(0.82, 0.82)
	cartao.modulate = Color(1, 1, 1, 0.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cartao, "scale",       Vector2.ONE,          0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cartao, "modulate:a",  1.0,                  0.20).set_trans(Tween.TRANS_SINE)

	# Animação do ícone: pulso lento enquanto o cartão estiver visível
	if icone != null:
		var tw_pulse := create_tween().set_loops()
		tw_pulse.tween_property(icone_rect, "scale", Vector2(1.04, 1.04), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_pulse.tween_property(icone_rect, "scale", Vector2.ONE,         1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ==========================================
# FECHAR
# ==========================================
func _input(event):
	if visible and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_fechar_aviso()

func _fechar_aviso():
	get_tree().paused = false
	hide()
	# Reset do ícone e escala para a próxima exibição
	icone_rect.texture = null
	icone_rect.scale   = Vector2.ONE
