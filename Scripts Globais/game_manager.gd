extends Node

# Sinais para avisar o resto do jogo o que está acontecendo
signal dia_iniciado(onda_atual)
signal noite_iniciada(onda_atual)
signal onda_terminada # Mantivemos o seu sinal original!

# Os dois estados possíveis do jogo
enum EstadoJogo { DIA, NOITE }

# Variáveis para controlar o progresso
var estado_atual = EstadoJogo.DIA
var onda_atual = 1

func _process(_delta):
	# O seu botão de teste agora serve para avançar o jogo inteiro!
	if Input.is_action_just_pressed("passar_onda"): 
		if estado_atual == EstadoJogo.DIA:
			# Se for de dia e apertar o botão, a noite cai e o ataque começa
			iniciar_noite()
		else:
			# Se for de noite e apertar o botão, a onda acaba
			terminar_onda()

# --- FUNÇÕES DE CONTROLE ---

func iniciar_dia():
	estado_atual = EstadoJogo.DIA
	print("--- DIA ", onda_atual, " COMEÇOU - Fase de Construção ---")
	dia_iniciado.emit(onda_atual)

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	print("--- NOITE ", onda_atual, " CAIU - Prepare-se para o ataque! ---")
	noite_iniciada.emit(onda_atual)

func terminar_onda():
	print("A onda terminou! A distribuir os lucros...")
	onda_terminada.emit() # Dispara o seu sinal de lucros
	
	# Prepara a próxima rodada
	onda_atual += 1
	iniciar_dia()
