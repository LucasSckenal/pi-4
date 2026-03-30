extends AnimationPlayer

## Gerencia as transições visuais de dia e noite da fase atual.
## Requer um AnimationPlayer configurado com as animações 'transicao_para_noite' e 'transicao_para_dia'.

func _ready() -> void:
	# Conecta os sinais globais de estado do jogo às funções locais de transição.
	GameManager.dia_iniciado.connect(_on_dia_iniciado)
	GameManager.noite_iniciada.connect(_on_noite_iniciada)

## Acionado pelo sinal do GameManager quando a fase de preparação começa.
func _on_dia_iniciado(_onda_atual: int) -> void:
	if has_animation("transicao_para_dia"):
		play("transicao_para_dia")

## Acionado pelo sinal do GameManager quando a onda de inimigos começa.
func _on_noite_iniciada(_onda_atual: int) -> void:
	if has_animation("transicao_para_noite"):
		play("transicao_para_noite")
