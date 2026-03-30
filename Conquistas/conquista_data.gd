extends Resource
class_name ConquistaData

@export var id: String = ""
@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var icone: Texture2D 

# --- RECOMPENSAS DE CUSTOMIZAÇÃO ---
# Se a conquista não der nada, deixamos a String vazia ("")
@export var libera_chapeu_id: String = "" 
@export var libera_arma_id: String = ""
