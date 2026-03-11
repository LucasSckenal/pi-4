extends CanvasLayer # (Se você escolheu a Opção A antes, mude isso para 'extends Control')

@onready var anim = $AnimationPlayer
@onready var panel = $PanelContainer

var labelName: Label
var iconeRect: TextureRect # NOVO: Variável para guardar o nó da imagem

func _ready():
	# Busca os nós dinamicamente em qualquer lugar da cena
	labelName = find_child("LabelName", true, false) as Label
	iconeRect = find_child("Icone", true, false) as TextureRect # Busca o nó "Icone"
	
	if panel:
		panel.modulate.a = 0 # Garante que o painel comece invisível
	
	# Conecta o sinal do Global.gd de forma segura
	if Global.has_signal("conquista_desbloqueada"):
		Global.conquista_desbloqueada.connect(_exibir_popup)
	else:
		print("[ERRO] Sinal 'conquista_desbloqueada' não encontrado no Global.gd")

# NOVO: Agora a função recebe 3 parâmetros (incluindo o icone_conquista)
func _exibir_popup(nome_conquista, _index_liberado, icone_conquista):
	print("[Popup] Tentando mostrar: ", nome_conquista)
	
	# Caso as variáveis tenham se perdido, tenta buscar de novo
	if not labelName:
		labelName = find_child("LabelName", true, false) as Label
	if not iconeRect:
		iconeRect = find_child("Icone", true, false) as TextureRect

	# Define o texto da conquista
	if labelName:
		labelName.text = str(nome_conquista)
		print("[Popup] Sucesso: Texto definido!")
	else:
		print("[ERRO] Nó 'LabelName' não foi encontrado!")
		
	# --- NOVIDADE: DEFINE A IMAGEM DO ÍCONE ---
	if iconeRect:
		if icone_conquista != null:
			iconeRect.texture = icone_conquista
			print("[Popup] Sucesso: Ícone definido!")
		else:
			print("[Aviso] Esta conquista não tem ícone cadastrado no arquivo .tres!")
	else:
		print("[ERRO] Nó 'Icone' não foi encontrado!")

	# --- 1. MOSTRAR O POPUP ---
	if anim:
		if anim.has_animation("show_popup"):
			anim.play("show_popup")
		else:
			panel.modulate.a = 1
			print("[Aviso] Animação 'show_popup' não encontrada. Exibindo estaticamente.")
	elif panel:
		panel.modulate.a = 1
