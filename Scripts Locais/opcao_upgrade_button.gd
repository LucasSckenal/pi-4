extends Button

@onready var icone = $Icone
@onready var nome_label = $Nome
@onready var custo_label = $Custo

func configurar(opcao: Dictionary):
	if opcao.has("icone") and opcao.icone:
		icone.texture = opcao.icone
		icone.show()
	else:
		icone.hide()
	
	nome_label.text = opcao.get("nome", "Upgrade")
	custo_label.text = "Custo: " + str(opcao.get("custo", 0))
	
	# Armazena o índice para usar no clique
	set_meta("caminho_index", opcao.get("index", 0))
