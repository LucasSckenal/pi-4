extends InimigoBase
class_name Tentaculo

# ============================================================================
# TENTÁCULO CÓSMICO — Invocação do Cosmic Kraken
# ============================================================================
# Surge do chão num path. Caça e destrói construções do jogador.
# Ao morrer, notifica o Kraken pai → este recebe dano fixo.
# Ignora a base (prioriza_construcoes = true + procurar_novo_alvo override).
# ============================================================================

@export_category("Tentáculo")
## Quanto o tentáculo emerge do chão na animação de surgimento (em metros)
@export var altura_emergencia: float = 1.8
## Duração da animação de emergência (em segundos)
@export var duracao_emergencia: float = 1.0

# Referência ao boss que invocou este tentáculo
var kraken_pai: Node = null

# ============================================================================
# READY
# ============================================================================
func _ready() -> void:
	# Configurações forçadas (sobrescreve o que vier do .tscn)
	nome_inimigo         = "Tentáculo Cósmico"
	prioriza_construcoes = true
	eh_kamikaze          = false
	eh_necromancer       = false

	super._ready()

	# Animação dramática: tentáculo emerge do chão
	_animar_emergencia()

func _animar_emergencia() -> void:
	var alvo_y: float = global_position.y
	global_position.y = alvo_y - altura_emergencia
	var tw = create_tween()
	tw.tween_property(self, "global_position:y", alvo_y, duracao_emergencia)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ============================================================================
# ALVO — Apenas construções (ignora a base completamente)
# ============================================================================
func procurar_novo_alvo():
	var construcoes = get_tree().get_nodes_in_group("Construcao")
	var melhor_alvo = null
	var menor_dist: float = 99999.0

	for c in construcoes:
		if not is_instance_valid(c):
			continue
		# Ignora a própria base (Castelo / Base) — tentáculo só ataca construções
		if c.is_in_group("Castelo") or c.is_in_group("Base"):
			continue
		if "esta_destruida" in c and c.esta_destruida:
			continue
		if "vida_atual" in c and c.vida_atual <= 0:
			continue
		var d: float = global_position.distance_to(c.global_position)
		if d < menor_dist:
			menor_dist = d
			melhor_alvo = c

	# Se não houver construção viva, fica parado (não ataca a base)
	return melhor_alvo

# ============================================================================
# MORTE — Notifica o Kraken pai antes de seguir o fluxo padrão
# ============================================================================
func morrer() -> void:
	if esta_morto:
		return
	if is_instance_valid(kraken_pai) and kraken_pai.has_method("notificar_tentaculo_morto"):
		kraken_pai.notificar_tentaculo_morto()
	super.morrer()
