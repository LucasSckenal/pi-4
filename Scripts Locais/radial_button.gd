extends TextureButton

## Representa a cena da torre que este botão constrói
var cena_associada: PackedScene
var nome_torre: String = ""
var custo_torre: int = 0

## Referência ao menu principal para enviar comandos
var menu_referencia: Control

@onready var icone_visual: TextureRect = $IconeTorre
@onready var sub_viewport: SubViewport = $SubViewport
@onready var model_container: Node3D = $SubViewport/ModelContainer

func _ready() -> void:
	# Feedback visual de hover padrão
	mouse_entered.connect(_ao_mouse_entrar)
	mouse_exited.connect(_ao_mouse_sair)
	pressed.connect(_ao_pressionar)
	
	# Estilização visual básica via código (se o TextureRect falhar, o botão ainda tem uma cor)
	modulate = Color(1.0, 1.0, 1.0, 1.0) # Transparente

func configurar(cena: PackedScene, textura: Texture2D, nome: String, custo: int, menu: Control) -> void:
	cena_associada = cena
	nome_torre = nome
	custo_torre = custo
	menu_referencia = menu
	
	if is_instance_valid(icone_visual):
		icone_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if textura != null:
			# Utiliza o ícone 2D predefinido e descarta os recursos 3D para economizar processamento
			icone_visual.texture = textura
			if is_instance_valid(sub_viewport):
				sub_viewport.queue_free()
		else:
			# Renderiza a malha 3D da cena no SubViewport e utiliza seu output como textura
			if is_instance_valid(sub_viewport) and is_instance_valid(model_container):
				var modelo_3d = cena.instantiate()
				model_container.add_child(modelo_3d)
				
				_desativar_processamento_miniatura(modelo_3d)
				
				icone_visual.texture = sub_viewport.get_texture()

## Desabilita iterativamente a física e scripts da malha instanciada no SubViewport 
## para evitar comportamentos indesejados (ex: temporizadores de ataque ou spawns)
func _desativar_processamento_miniatura(no: Node) -> void:
	no.set_process(false)
	no.set_physics_process(false)
	
	if no is CollisionObject3D:
		no.collision_layer = 0
		no.collision_mask = 0
		
	if no.get_script() != null:
		no.set_script(null)
		
	for filho in no.get_children():
		_desativar_processamento_miniatura(filho)

var _tween_rec: Tween = null
var _eh_recomendado: bool = false

func destacar_recomendado():
	_eh_recomendado = true
	if _tween_rec != null and is_instance_valid(_tween_rec):
		_tween_rec.kill()
	_tween_rec = create_tween().set_loops()
	_tween_rec.tween_property(self, "modulate", Color(1.6, 1.4, 0.2, 1.0), 0.4)
	_tween_rec.tween_property(self, "modulate", Color(1.1, 1.0, 0.6, 1.0), 0.4)

func _ao_mouse_entrar() -> void:
	if is_instance_valid(menu_referencia):
		menu_referencia.atualizar_informacoes(nome_torre, custo_torre)
	if _tween_rec != null and is_instance_valid(_tween_rec):
		_tween_rec.kill()
	modulate = Color(1.4, 1.4, 1.4, 1.0)

func _ao_mouse_sair() -> void:
	if is_instance_valid(menu_referencia):
		menu_referencia.limpar_informacoes()
	if _eh_recomendado:
		destacar_recomendado()
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _ao_pressionar() -> void:
	if is_instance_valid(menu_referencia):
		menu_referencia._solicitar_construcao(cena_associada, custo_torre)
