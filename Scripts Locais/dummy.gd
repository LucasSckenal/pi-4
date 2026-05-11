extends Node3D 

@onready var texto_dps = $Label3D
@onready var timer = $Timer

var dps_atual: int = 0
var dano_total: int = 0
var tempo_em_combate: int = 0
var tempo_ocioso: int = 0 # Conta quanto tempo ele ficou sem apanhar

func _ready():
	add_to_group("inimigos") 
	add_to_group("Construcao")
	
	# Garante que o Timer está em 1 segundo
	timer.wait_time = 1.0 
	
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
		
	texto_dps.text = "Pronto para o teste"

func receber_dano(qtd, origem = "indefinido"):
	dps_atual += qtd
	dano_total += qtd
	tempo_ocioso = 0 # Levou dano, então zera o tempo ocioso (não reseta mais o teste)
	
	var tw = create_tween()
	scale = Vector3(1.2, 1.2, 1.2)
	tw.tween_property(self, "scale", Vector3.ONE, 0.1)

# Esta função roda a cada 1 segundo cravado
func _on_timer_timeout():
	# TEMPO DE RESET: Se ficar 5 segundos sem apanhar, ele reseta o teste
	if tempo_ocioso >= 5:
		if dano_total > 0: # Só limpa a tela se tivesse números lá
			dano_total = 0
			tempo_em_combate = 0
			texto_dps.text = "Teste Concluído.\nAguardando..."
			texto_dps.modulate = Color.WHITE
	else:
		# Estamos em combate!
		tempo_em_combate += 1
		
		# Monta um painel de dados com 3 linhas (DPS, Total e Tempo)
		var texto_final = "DPS (Último seg): " + str(dps_atual) + "\n"
		texto_final += "Dano Total: " + str(dano_total) + "\n"
		texto_final += "Tempo de Teste: " + str(tempo_em_combate) + "s"
		
		texto_dps.text = texto_final
		texto_dps.modulate = Color.RED
		
		dps_atual = 0 # Zera apenas o DPS daquele segundo
		tempo_ocioso += 1 # Adiciona 1 segundo de ociosidade (será zerado se ele apanhar de novo)
