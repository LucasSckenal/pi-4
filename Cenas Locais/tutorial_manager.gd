extends CanvasLayer

@onready var fundo_escuro = $FundoEscuro
@onready var seta = $Seta
# Adicionamos a referência da CaixaDialogo aqui para o script
@onready var caixa_dialogo_node = $CaixaDialogo 

# === REFERÊNCIAS DA UI ===
@onready var caixa_texto = $CaixaDialogo/HBoxContainer/FundoTexto/CaixaTexto
@onready var retrato_esquerda = $CaixaDialogo/HBoxContainer/RetratoEsquerda
@onready var retrato_direita = $CaixaDialogo/HBoxContainer/RetratoDireita

# === REFERÊNCIAS DOS ANIMATION PLAYERS 3D ===
@onready var anim_avo = $"CaixaDialogo/HBoxContainer/RetratoEsquerda/SubViewport/character-female-c2/AnimationPlayer"
@onready var anim_afonso = $"CaixaDialogo/HBoxContainer/RetratoDireita/SubViewport/character-male-b2/AnimationPlayer"

var alvo_3d_atual: Node3D = null
var alvo_2d_atual: Control = null
var material_fundo: ShaderMaterial

# Configurações de Acessibilidade
var velocidade_texto: float = 0.05 
var tamanho_fonte: int = 32

func _ready():
	# Garante que o tutorial continue rodando e animando mesmo com o jogo pausado!
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false
	
	# --- CORREÇÃO DE PRIORIDADE (LAYER/ORDEM) ---
	layer = 128 # Valor alto para ficar acima de qualquer outra interface (UI)
	
	seta.top_level = true 
	seta.z_index = 1000 # Valor máximo absoluto para garantir que a seta fica À FRENTE DE TUDO

	# NOVA CORREÇÃO: Colocamos a caixa de diálogo à frente do fundo escuro
	caixa_dialogo_node.z_index = 999 
	
	fundo_escuro.z_index = 998 # O shader fica no fundo, cobrindo o jogo mas não a UI do tutorial
	# --------------------------------------------
	
	if fundo_escuro.material is ShaderMaterial:
		material_fundo = fundo_escuro.material as ShaderMaterial
	
	configurar_estilo_acessivel()
	configurar_animacoes_loop()

func configurar_estilo_acessivel():
	caixa_texto.bbcode_enabled = true
	caixa_texto.add_theme_font_size_override("font_size", tamanho_fonte)
	caixa_texto.add_theme_constant_override("outline_size", 8)
	caixa_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	caixa_texto.add_theme_constant_override("line_separation", 10)

func configurar_animacoes_loop():
	if anim_avo and anim_avo.has_animation("idle"):
		anim_avo.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	if anim_afonso and anim_afonso.has_animation("idle"):
		anim_afonso.get_animation("idle").loop_mode = Animation.LOOP_LINEAR

func _process(_delta):
	if not visible: return
	
	var pos_global = Vector2.ZERO
	
	if alvo_3d_atual:
		var camera = get_viewport().get_camera_3d()
		if camera:
			pos_global = camera.unproject_position(alvo_3d_atual.global_position)
	elif alvo_2d_atual and is_instance_valid(alvo_2d_atual):
		# Usa a transformação de tela para ignorar escalas de outras cenas
		var t = alvo_2d_atual.get_screen_transform()
		pos_global = t.get_origin() + (alvo_2d_atual.size * t.get_scale() / 2.0)
	
	if pos_global != Vector2.ZERO:
		# Atualiza a posição da seta
		seta.global_position = pos_global + Vector2(-seta.size.x / 2, -110)
		
		if material_fundo:
			var tamanho_tela = get_viewport().get_visible_rect().size
			var pos_uv = pos_global / tamanho_tela
			
			material_fundo.set_shader_parameter("center", pos_uv)
			material_fundo.set_shader_parameter("radius", 0.025) 
			material_fundo.set_shader_parameter("feather", 0.015)

func configurar_dialogo(texto_completo: String):
	var partes = texto_completo.split(": ", true, 1)
	var nome = ""
	var fala = ""
	
	if partes.size() > 1:
		nome = partes[0].strip_edges()
		fala = partes[1].strip_edges()
		caixa_texto.text = "[color=yellow][b]" + nome + ":[/b][/color]\n"
		
		retrato_esquerda.visible = ("Avó Berta" in nome)
		retrato_direita.visible = ("Afonso" in nome)
		
		if retrato_esquerda.visible and anim_avo: anim_avo.play("idle")
		if retrato_direita.visible and anim_afonso: anim_afonso.play("idle")
	else:
		fala = texto_completo
		caixa_texto.text = ""

	caixa_texto.text += fala
	caixa_texto.visible_ratio = 0.0
	
	var tween = create_tween()
	# Garante que as letras vão aparecer mesmo se o jogo estiver pausado (ex: nos menus)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween.tween_property(caixa_texto, "visible_ratio", 1.0, fala.length() * velocidade_texto)

func focar_em_slot_3d(slot_alvo: Node3D, texto: String):
	if slot_alvo == null: return
	visible = true
	configurar_dialogo(texto)
	alvo_3d_atual = slot_alvo
	alvo_2d_atual = null
	
	# ESPERA O CLIQUE DEPENDENDO DO TIPO DO OBJETO
	if slot_alvo.has_signal("slot_clicado"):
		await slot_alvo.slot_clicado
	elif slot_alvo.has_signal("construcao_selecionada"):
		await slot_alvo.construcao_selecionada
	else:
		await get_tree().create_timer(3.0).timeout 
		
	esconder()

func focar_em_ui_2d(botao_alvo: Control, texto: String):
	if botao_alvo == null: return
	visible = true
	configurar_dialogo(texto)
	alvo_2d_atual = botao_alvo
	alvo_3d_atual = null
	
	bloquear_outros_botoes(botao_alvo)
	
	var estado = {"clicado": false}
	var ao_clicar = func(): estado.clicado = true
	
	if botao_alvo.has_signal("pressed"):
		botao_alvo.pressed.connect(ao_clicar)
		
	while not estado.clicado and is_instance_valid(botao_alvo):
		await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(botao_alvo) and botao_alvo.pressed.is_connected(ao_clicar):
		botao_alvo.pressed.disconnect(ao_clicar)
		
	esconder()

func bloquear_outros_botoes(botao_alvo):
	var pai = botao_alvo.get_parent()
	if pai:
		for irmao in pai.get_children():
			if irmao != botao_alvo and (irmao is Control):
				irmao.mouse_filter = Control.MOUSE_FILTER_IGNORE
				if "disabled" in irmao: irmao.disabled = true
				irmao.modulate = Color(0.3, 0.3, 0.3, 0.6)

func esconder():
	visible = false
	alvo_3d_atual = null
	alvo_2d_atual = null
