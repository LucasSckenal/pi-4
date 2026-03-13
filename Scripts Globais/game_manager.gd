extends Node

signal dia_iniciado(onda_atual)
signal noite_iniciada(onda_atual)
signal onda_terminada
signal mostrar_menu_upgrade(cartas_sorteadas)

enum EstadoJogo { DIA, NOITE }
var estado_atual = EstadoJogo.DIA

# --- UPGRADES ---
# --- UPGRADES E MODIFICADORES ---
var bonus_dano: int = 0 
var bonus_moedas_onda: int = 0
var bonus_velocidade_ataque: float = 0.0 # Ex: 0.2 é +20%
var modificador_custo: float = 1.0       # 1.0 é preço normal, 0.75 é 25% de desconto
var multiplicador_horda: float = 1.0     # 1.0 é normal, 1.5 é 50% mais inimigos
var multiplicador_velocidade_inimigo: float = 1.0
var baralho_upgrades: Array = [
	preload("res://PowerUps/BalisticaPesada.tres"),
	preload("res://PowerUps/EngenhariaEficiente.tres"),
	preload("res://PowerUps/FrequenciaCritica.tres"),
	preload("res://PowerUps/ImpostoGuerra.tres"),
	preload("res://PowerUps/MuralhasReforçadas.tres"),
	preload("res://PowerUps/TFRICO.tres"),

]

# --- ECONOMIA ---
var moedas: int = 113
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
	get_tree().call_group("Interface", "verificar_estado_dia_noite")

func iniciar_noite():
	estado_atual = EstadoJogo.NOITE
	is_night = true
	noite_iniciada.emit(onda_atual)
	get_tree().call_group("Interface", "verificar_estado_dia_noite")
	get_tree().call_group("Interface", "mostrar_wave_na_tela", "ONDA " + str(onda_atual))

func terminar_onda():
	if estado_atual == EstadoJogo.DIA: return 
	
	estado_atual = EstadoJogo.DIA
	is_night = false
	
	var bonus_vitoria = 3 + (onda_atual * 2) + bonus_moedas_onda
	moedas += bonus_vitoria
	
	onda_terminada.emit() 
	
	# --- VERIFICAÇÃO DE UPGRADE ---
	# Teste na onda 1, depois mude para (onda_atual % 5 == 0)
	if onda_atual == 1:
		sortear_cartas()
	
	onda_atual += 1
	iniciar_dia()
	get_tree().call_group("Interface", "atualizar_moedas")

func sortear_cartas():
	if baralho_upgrades.size() == 0:
		print("ERRO: O baralho está vazio no Inspetor!")
		return

	var copia = baralho_upgrades.duplicate()
	copia.shuffle()
	
	var escolhidas = []
	for i in range(3):
		if i < copia.size():
			escolhidas.append(copia[i])
	
	mostrar_menu_upgrade.emit(escolhidas)
	get_tree().paused = true # Pausa o jogo

func aplicar_upgrade(dados: CartaUpgrade):
	match dados.tipo:
		CartaUpgrade.TipoUpgrade.DANO:
			bonus_dano += int(dados.valor)
			print("Bónus de Dano agora é: ", bonus_dano)
			
		CartaUpgrade.TipoUpgrade.MOEDA:
			bonus_moedas_onda += int(dados.valor)
			print("Bónus de Moedas agora é: ", bonus_moedas_onda)
			
		CartaUpgrade.TipoUpgrade.VIDA:
			# Se tiveres uma var de vida na base
			# vida_base += int(dados.valor)
			print("Vida da base aumentada em: ", dados.valor)
			
		CartaUpgrade.TipoUpgrade.VELOCIDADE_ATAQUE:
			# Ex: bonus_velocidade_ataque += dados.valor
			print("Velocidade aumentada!")
			
		CartaUpgrade.TipoUpgrade.MOEDA:
			# Ex: desconto_construcao += dados.valor
			print("Desconto aplicado!")

	print("Upgrade '", dados.titulo, "' aplicado com sucesso!")

func gastar_moedas(valor_custo: int) -> bool:
	if moedas >= valor_custo:
		moedas -= valor_custo
		get_tree().call_group("Interface", "atualizar_moedas")
		get_tree().call_group("Interface", "animar_bau_abrindo")
		return true
	return false
