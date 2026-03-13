extends Node

signal dia_iniciado(onda_atual)
signal noite_iniciada(onda_atual)
signal onda_terminada

enum EstadoJogo { DIA, NOITE }
var estado_atual = EstadoJogo.DIA

# --- SISTEMA DE ECONOMIA ---
var moedas: int = 3 # Começa com 3 moedas
var onda_atual: int = 1
var is_night: bool = false

func _process(_delta):
	if Input.is_action_just_pressed("passar_onda"): 
		if estado_atual == EstadoJogo.DIA:
			iniciar_noite()

func iniciar_dia():
	estado_atual = EstadoJogo.DIA
	is_night = false
	dia_iniciado.emit(onda_atual)
	
	# Avisa a HUD para mostrar o botão de Iniciar Noite novamente
	get_tree().call_group("Interface", "verificar_estado_dia_noite")

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	is_night = true
	noite_iniciada.emit(onda_atual)
	
	# Avisa a HUD para esconder o botão e piscar o texto da Onda
	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))

func terminar_onda():
	if estado_atual == EstadoJogo.DIA: return 
	
	estado_atual = EstadoJogo.DIA
	is_night = false
	
	# Bônus de vitória por passar de onda
	var bonus_vitoria = 3 + (onda_atual * 2) 
	moedas += bonus_vitoria
	print("Onda ", onda_atual, " vencida! Bônus de vitória: ", bonus_vitoria)
	
	# Dispara o sinal para os prédios pagarem suas moedas extras
	onda_terminada.emit() 
	
	onda_atual += 1
	iniciar_dia()
	
	# Atualiza o dinheiro na tela ao final de tudo
	get_tree().call_group("Interface", "atualizar_moedas")


# ==========================================
# NOVA FUNÇÃO: GASTAR DINHEIRO COM ANIMAÇÃO
# ==========================================
func gastar_moedas(valor_custo: int) -> bool:
	if moedas >= valor_custo:
		moedas -= valor_custo # Desconta o dinheiro
		
		# Grita para a HUD atualizar o texto e abrir o baú!
		get_tree().call_group("Interface", "atualizar_moedas")
		get_tree().call_group("Interface", "animar_bau_abrindo")
		
		return true # Retorna verdadeiro (pode construir)
	else:
		print("Dinheiro insuficiente!")
		return false # Retorna falso (não pode construir)
