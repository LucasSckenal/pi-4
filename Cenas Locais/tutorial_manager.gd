extends CanvasLayer

signal clicou_na_tela # Necessário para o sistema estilo Genshin
signal tutorial_pulado # Emitido quando o jogador decide pular o tutorial

@onready var fundo_escuro = $FundoEscuro
@onready var seta = $Seta
@onready var caixa_dialogo_node = $CaixaDialogo 

@onready var caixa_texto = $CaixaDialogo/HBoxContainer/FundoTexto/CaixaTexto
@onready var retrato_esquerda = $CaixaDialogo/HBoxContainer/RetratoEsquerda
@onready var retrato_direita = $CaixaDialogo/HBoxContainer/RetratoDireita

@onready var anim_avo = $"CaixaDialogo/HBoxContainer/RetratoEsquerda/SubViewport/character-female-c2/AnimationPlayer"
@onready var anim_afonso = $"CaixaDialogo/HBoxContainer/RetratoDireita/SubViewport/character-male-b2/AnimationPlayer"

@onready var btn = $BotaoPular

var alvo_3d_atual: Node3D = null
var alvo_2d_atual: Control = null
var material_fundo: ShaderMaterial

var velocidade_texto: float = 0.05
var tamanho_fonte: int = 32
var tween_texto: Tween # Animação do texto estilo Genshin
var _tempo_seta: float = 0.0  # acumulador para a animação de "pulo" da seta

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	layer = 128 
	seta.top_level = true 
	seta.z_index = 1000 
	caixa_dialogo_node.z_index = 999 
	fundo_escuro.z_index = 998 
	
	# Permite que o rato passe através da UI do tutorial
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa_dialogo_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if fundo_escuro.material is ShaderMaterial:
		material_fundo = fundo_escuro.material as ShaderMaterial
	
	$BotaoPular.visible = true
	
	configurar_estilo_acessivel()
	configurar_animacoes_loop()

# === SISTEMA GENSHIN: PULAR/ACELERAR TEXTO ===
func _input(event):
	if not visible:
		return

	var quer_avancar := false

	# Clique/toque na tela avança (ou completa) o diálogo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Ignora se o clique foi no botão de pular tutorial (ele tem sua própria ação)
		if btn and btn.is_visible_in_tree() and btn.is_hovered():
			return
		quer_avancar = true
	elif event is InputEventScreenTouch and event.pressed:
		quer_avancar = true

	# Teclado: ESC pula o tutorial; qualquer outra tecla avança
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# Consome o input para o ESC não vazar e acabar abrindo o menu de pausa no fundo
			get_viewport().set_input_as_handled()
			# Chama exatamente a mesma função de quando o jogador clica no botão "Pular"
			_on_botao_pular_pressed()
			return
		quer_avancar = true

	if quer_avancar:
		if caixa_texto.visible_ratio < 1.0:
			# Texto ainda digitando: completa de uma vez
			if tween_texto and tween_texto.is_valid():
				tween_texto.kill()
			caixa_texto.visible_ratio = 1.0
		else:
			clicou_na_tela.emit()

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
	
	# Oculta a seta se for só diálogo de história
	if alvo_3d_atual == null and alvo_2d_atual == null:
		seta.visible = false
		if material_fundo:
			material_fundo.set_shader_parameter("radius", 0.0)
		return
		
	seta.visible = true
	var pos_global = Vector2.ZERO
	
	if alvo_3d_atual:
		var camera = get_viewport().get_camera_3d()
		if camera:
			pos_global = camera.unproject_position(alvo_3d_atual.global_position)
	elif alvo_2d_atual and is_instance_valid(alvo_2d_atual):
		var t = alvo_2d_atual.get_screen_transform()
		pos_global = t.get_origin() + (alvo_2d_atual.size * t.get_scale() / 2.0)
	
	if pos_global != Vector2.ZERO:
		# Animação de "pulo": a seta sobe e desce suavemente para chamar atenção.
		_tempo_seta += _delta
		var bob := sin(_tempo_seta * 6.0) * 12.0
		seta.global_position = pos_global + Vector2(-seta.size.x / 2, -110 + bob)
		
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
		
		retrato_esquerda.visible = ("Berta" in nome)
		retrato_direita.visible = ("Afonso" in nome)
		
		if retrato_esquerda.visible and anim_avo: anim_avo.play("idle")
		if retrato_direita.visible and anim_afonso: anim_afonso.play("idle")
	else:
		fala = texto_completo
		caixa_texto.text = ""

	caixa_texto.text += fala
	caixa_texto.visible_ratio = 0.0
	
	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()
		
	tween_texto = create_tween()
	tween_texto.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween_texto.tween_property(caixa_texto, "visible_ratio", 1.0, fala.length() * velocidade_texto)

# Função limpa apenas para contar história (sem focar no Castelo)
func mostrar_dialogo(texto: String):
	if not GameManager.is_tutorial_ativo:
		return
	var camera = get_viewport().get_camera_3d()
	if camera and camera.has_method("reset_zoom_tutorial"):
		camera.reset_zoom_tutorial()
	
	visible = true
	fundo_escuro.visible = true
	
	
	# === NOVO: Ativa o "Escudo" bloqueando cliques nos botões de trás ===
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	alvo_3d_atual = null
	alvo_2d_atual = null
	
	configurar_dialogo(texto)
	
	await clicou_na_tela
	
	# === NOVO: Desativa o "Escudo" para que o jogador consiga clicar no cenário depois ===
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	esconder()

# Aponta a seta para um alvo 3D e fala, avançando ao clique (sem exigir interação no alvo).
# Útil para EXPLICAR algo (ex.: caminhos do quartel) sem forçar uma compra.
func apontar_e_falar_3d(alvo: Node3D, texto: String) -> void:
	if not GameManager.is_tutorial_ativo: return
	var camera = get_viewport().get_camera_3d()
	if camera and camera.has_method("reset_zoom_tutorial"):
		camera.reset_zoom_tutorial()
	visible = true
	fundo_escuro.visible = true
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_STOP
	alvo_2d_atual = null
	alvo_3d_atual = alvo
	configurar_dialogo(texto)
	await clicou_na_tela
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esconder()

# Aponta a seta (animada) para um Control 2D SEM bloquear e SEM escurecer a tela.
# Usado para indicar o botão de melhoria dentro da janela de upgrade (que fica visível).
# O chamador deve chamar esconder() quando terminar.
func indicar_alvo_2d(alvo: Control, texto: String = "") -> void:
	if not GameManager.is_tutorial_ativo: return
	if not is_instance_valid(alvo): return
	visible = true
	fundo_escuro.visible = false  # mantém a janela de upgrade totalmente visível
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alvo_3d_atual = null
	alvo_2d_atual = alvo
	if texto != "":
		configurar_dialogo(texto)

# Aponta a seta para um botão/Control 2D e fala, avançando ao clique (sem exigir clique no alvo).
func apontar_e_falar_2d(alvo: Control, texto: String) -> void:
	if not GameManager.is_tutorial_ativo: return
	if not is_instance_valid(alvo): return
	visible = true
	fundo_escuro.visible = true
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_STOP
	alvo_3d_atual = null
	alvo_2d_atual = alvo
	configurar_dialogo(texto)
	await clicou_na_tela
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	esconder()

# As tuas funções originais de foco inalteradas (apenas usam o fundo_escuro)
func focar_em_slot_3d(slot_alvo: Node3D, texto: String):
	if not GameManager.is_tutorial_ativo: return
	if slot_alvo == null: return
	visible = true
	fundo_escuro.visible = true
	configurar_dialogo(texto)
	alvo_3d_atual = slot_alvo
	alvo_2d_atual = null

	# Usa polling com verificação de is_tutorial_ativo para o botão pular funcionar
	var estado = {"concluido": false}
	var _cb := func(): estado.concluido = true

	if slot_alvo.has_signal("slot_clicado"):
		slot_alvo.slot_clicado.connect(_cb, CONNECT_ONE_SHOT)
	elif slot_alvo.has_signal("construcao_selecionada"):
		slot_alvo.construcao_selecionada.connect(_cb, CONNECT_ONE_SHOT)
	else:
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud and hud.upgrade_ui_instance:
			while not hud.upgrade_ui_instance.visible:
				if not GameManager.is_tutorial_ativo: break
				await get_tree().create_timer(0.1).timeout
		else:
			await get_tree().create_timer(3.0).timeout
		estado.concluido = true

	while not estado.concluido:
		if not GameManager.is_tutorial_ativo: break
		# Robustez: assim que a UI de upgrade abrir, considera o passo concluído.
		# (Evita o diálogo ficar preso por cima da janela de melhoria — ex.: Castelo.)
		if _upgrade_ui_aberta():
			break
		await get_tree().create_timer(0.1).timeout

	esconder()

# True quando a janela de upgrade da HUD está aberta (visível).
func _upgrade_ui_aberta() -> bool:
	var hud = get_tree().get_first_node_in_group("Interface")
	if hud and "upgrade_ui_instance" in hud:
		var uui = hud.upgrade_ui_instance
		return is_instance_valid(uui) and uui.visible
	return false

func focar_em_ui_2d(botao_alvo: Control, texto: String):
	if not GameManager.is_tutorial_ativo: return
	if botao_alvo == null: return
	visible = true
	fundo_escuro.visible = true
	configurar_dialogo(texto)
	alvo_2d_atual = botao_alvo
	alvo_3d_atual = null
	
	bloquear_outros_botoes(botao_alvo)
	
	var estado = {"clicado": false}
	var ao_clicar = func(): estado.clicado = true
	
	if botao_alvo.has_signal("pressed"):
		botao_alvo.pressed.connect(ao_clicar)
		
	while not estado.clicado and is_instance_valid(botao_alvo):
		if not GameManager.is_tutorial_ativo: break
		await get_tree().create_timer(0.1).timeout
	
	desbloquear_botoes(botao_alvo)    
	
	if is_instance_valid(botao_alvo) and botao_alvo.has_signal("pressed") and botao_alvo.pressed.is_connected(ao_clicar):
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

func desbloquear_botoes(botao_alvo):
	# === NOVA LINHA DE SEGURANÇA ===
	if not is_instance_valid(botao_alvo):
		return # Cancela se o botão já foi destruído!
		
	var pai = botao_alvo.get_parent()
	if pai:
		for irmao in pai.get_children():
			if irmao != botao_alvo and (irmao is Control):
				irmao.mouse_filter = Control.MOUSE_FILTER_STOP # Devolve o clique
				irmao.modulate = Color(1, 1, 1, 1) # Devolve a cor normal (Branco)

func esconder():
	visible = false
	fundo_escuro.visible = false
	alvo_3d_atual = null
	alvo_2d_atual = null

# Função conectada ao botão de pular tutorial na interface
func _on_botao_pular_pressed():
	GameManager.is_tutorial_ativo = false
	tutorial_pulado.emit()
	clicou_na_tela.emit()
	esconder()
	
	if fundo_escuro:
		fundo_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Hover → escala 1.05
func _on_btn_hover_entrou() -> void:
	_animar_escala_btn(btn, 1.05)

# Mouse sai → volta ao normal 1.0
func _on_btn_hover_saiu() -> void:
	_animar_escala_btn(btn, 1.0)

# Pressionado → escala 0.95
func _on_btn_pressionado() -> void:
	_animar_escala_btn(btn, 0.95)

# Solto → volta ao hover (1.05) se o mouse ainda estiver sobre o botão, senão ao normal
func _on_btn_solto() -> void:
	var escala_alvo := 1.05 if btn.is_hovered() else 1.0
	_animar_escala_btn(btn, escala_alvo)

# Aplica a animação de escala com tween suave, usando o pivot no centro do botão
func _animar_escala_btn(btnChosen: Button, escala: float) -> void:
	# Atualiza o pivot para o centro atual (tamanho pode mudar com o viewport)
	btnChosen.pivot_offset = btn.size / 2.0
	var tw := btnChosen.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btnChosen, "scale", Vector2(escala, escala), 0.12)
