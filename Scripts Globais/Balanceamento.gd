extends Node

# ==========================================
# BALANCEAMENTO — Autoload central
# Carrega todos os valores de balanceamento de um CSV
# editavel no Excel/Google Sheets/qualquer editor de texto.
#
# Como usar:
#   var dano = Balanceamento.get_int("torre_padrao_dano", 30)
#   var dps  = Balanceamento.get_float("torre_fogo_dps", 15.0)
#
# Hot-reload em tempo de jogo: tecla F5
# ==========================================

const CAMINHO_CSV: String = "res://Balanceamento/balanceamento.csv"

# chave -> valor tipado (int, float ou String)
var dados: Dictionary = {}

# Emitido sempre que o CSV for recarregado (F5).
# Scripts podem ouvir para reaplicar valores em runtime.
signal recarregado

func _ready() -> void:
	carregar()


# ==========================================
# CARREGAMENTO
# ==========================================
func carregar() -> void:
	dados.clear()

	var arquivo := FileAccess.open(CAMINHO_CSV, FileAccess.READ)
	if arquivo == null:
		push_error("[Balanceamento] CSV não encontrado em %s" % CAMINHO_CSV)
		return

	# Pula a linha de cabeçalho (chave,valor,tipo,categoria,descricao)
	arquivo.get_csv_line()

	while not arquivo.eof_reached():
		var linha: PackedStringArray = arquivo.get_csv_line()

		# Pula linhas vazias ou mal formadas
		if linha.size() < 3:
			continue
		if linha[0].is_empty():
			continue
		# Permite linhas começadas com '#' como comentários
		if linha[0].begins_with("#"):
			continue

		var chave: String = linha[0].strip_edges()
		var valor_str: String = linha[1].strip_edges()
		var tipo: String = linha[2].strip_edges().to_lower()

		match tipo:
			"int":
				dados[chave] = int(valor_str)
			"float":
				dados[chave] = float(valor_str)
			"bool":
				dados[chave] = valor_str.to_lower() in ["true", "1", "sim", "yes"]
			_:
				dados[chave] = valor_str  # String / desconhecido

	arquivo.close()
	print("[Balanceamento] %d valores carregados de %s" % [dados.size(), CAMINHO_CSV])


# ==========================================
# ACESSORES
# ==========================================
func tem(chave: String) -> bool:
	return dados.has(chave)

func get_int(chave: String, padrao: int = 0) -> int:
	if not dados.has(chave):
		return padrao
	var v = dados[chave]
	if typeof(v) == TYPE_INT:
		return v
	if typeof(v) == TYPE_FLOAT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		return int(v)
	return padrao

func get_float(chave: String, padrao: float = 0.0) -> float:
	if not dados.has(chave):
		return padrao
	var v = dados[chave]
	if typeof(v) == TYPE_FLOAT:
		return v
	if typeof(v) == TYPE_INT:
		return float(v)
	if typeof(v) == TYPE_STRING:
		return float(v)
	return padrao

func get_bool(chave: String, padrao: bool = false) -> bool:
	if not dados.has(chave):
		return padrao
	var v = dados[chave]
	if typeof(v) == TYPE_BOOL:
		return v
	return padrao

func get_string(chave: String, padrao: String = "") -> String:
	if not dados.has(chave):
		return padrao
	return str(dados[chave])


# ==========================================
# HOT-RELOAD POR TECLA (F5)
# Útil durante o desenvolvimento: edita o CSV,
# aperta F5 e o jogo aplica os novos valores
# sem precisar reiniciar.
# ==========================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			carregar()
			recarregado.emit()
			# Avisa torres e construções para reaplicarem seus valores
			get_tree().call_group("Torres", "atualizar_status")
			get_tree().call_group("Construcao", "recarregar_balanceamento")
			print("[Balanceamento] CSV recarregado — valores atualizados!")
