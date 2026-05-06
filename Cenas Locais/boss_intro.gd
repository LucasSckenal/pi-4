extends CanvasLayer

signal cutscene_finished

@onready var root_control = $Control
@onready var video_player = $Control/VideoStreamPlayer
@onready var boss_name = $Control/boss_name
@onready var skip_button = $Control/skip_button

var ja_finalizou := false
var pode_pular := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# fade in geral
	root_control.modulate.a = 0
	create_tween().tween_property(root_control, "modulate:a", 1, 0.5)
	
	skip_button.pressed.connect(_on_skip_pressed)

func reproduzir_stream(stream: VideoStream, nome: String):
	if stream:
		video_player.stream = stream
		video_player.play()
		get_tree().paused = true
		
		_animar_nome(nome)
	else:
		_finalizar()

# 🎬 ANIMAÇÃO DO NOME (ESTILO ELDEN RING)
func _animar_nome(nome: String):
	boss_name.text = nome.to_upper()
	
	boss_name.modulate.a = 0
	boss_name.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	
	# Fade + zoom leve
	tween.tween_property(boss_name, "modulate:a", 1, 0.6)
	tween.parallel().tween_property(boss_name, "scale", Vector2(1, 1), 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Glow pulsante
	var glow = create_tween().set_loops()
	glow.tween_property(boss_name, "modulate:v", 1.2, 1)
	glow.tween_property(boss_name, "modulate:v", 1.0, 1)
	
	# Delay pra liberar skip
	await get_tree().create_timer(1.5).timeout
	
	pode_pular = true
	
	# Fade do botão
	create_tween().tween_property(skip_button, "modulate:a", 1, 0.5)

# 🧪 fallback
func _process(delta):
	if not ja_finalizou and video_player.stream and not video_player.is_playing():
		_finalizar()

func _on_video_stream_player_finished():
	_finalizar()

# ⏭️ botão
func _on_skip_pressed():
	if pode_pular:
		_finalizar()

# ⌨️ teclado/toque
func _input(event):
	if pode_pular and event.is_pressed():
		_finalizar()

# 🎬 FINALIZAÇÃO COM FADE
func _finalizar():
	if ja_finalizou:
		return
	
	ja_finalizou = true
	
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0, 0.5)
	
	await tween.finished
	
	get_tree().paused = false
	emit_signal("cutscene_finished")
	queue_free()
