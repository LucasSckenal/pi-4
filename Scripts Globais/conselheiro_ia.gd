extends Node
class_name ConselheiroIA

# Prioridades (usadas no painel para colorir e alertar)
const PRIO_URGENTE = 1
const PRIO_ALTA    = 2
const PRIO_MEDIA   = 3
const PRIO_BAIXA   = 4
const PRIO_NENHUMA = 5

# Tipos de recomendação
const TIPO_CONSTRUIR = 0
const TIPO_UPGRADE   = 1
const TIPO_AGUARDAR  = 2

# Limiar: renda/onda abaixo disso é considerada fraca
const RENDA_MINIMA = 7

class Recomendacao:
	var tipo: int = 2
	var prioridade: int = 5
	var cena_construcao = null        # PackedScene | null
	var nome_construcao: String = ""
	var slot_recomendado = null       # Node | null
	var construcao_upgrade = null     # Node | null
	var titulo: String = "Tudo bem"
	var explicacao: String = "Suas defesas estão em ordem."

# Cache de custos para não recriar instâncias a cada análise
var _cache_custos: Dictionary = {}

# ==========================================
# ANÁLISE PRINCIPAL
# ==========================================
func analisar():
	var rec = Recomendacao.new()

	var moedas: int = GameManager.moedas
	var vida_pct: float = 1.0
	if GameManager.vida_base_maxima > 0:
		vida_pct = float(GameManager.vida_base_atual) / float(GameManager.vida_base_maxima)

	var disponiveis: Array = GameManager.get_construcoes_disponiveis()
	var slots: Array       = _get_slots_vazios()
	var construcoes: Array = get_tree().get_nodes_in_group("Construcao")

	# Contagem por tipo (ignora BASE)
	var num_torres  = 0
	var num_eco     = 0
	for c in construcoes:
		if c.is_in_group("Base"):
			continue
		if not ("tipo" in c):
			continue
		var est = c.get("esta_destruida")
		if est != null and est:
			continue
		if c.tipo == 0:
			num_torres += 1
		elif c.tipo == 1 or c.tipo == 2 or c.tipo == 3:
			num_eco += 1

	var renda: int  = _renda_estimada(construcoes)
	var eh_dia: bool = not GameManager.is_night
	var onda_boss: bool = GameManager.modo_infinito and (GameManager.onda_atual % 5 == 0) and GameManager.onda_atual >= 5

	# ── PRIORIDADE 1: Vida crítica ──────────────────────────────────────────
	if vida_pct < 0.30 and eh_dia:
		var cena_urg = _get_ofensiva_acessivel(disponiveis, moedas)
		if cena_urg != null and slots.size() > 0:
			rec.tipo             = TIPO_CONSTRUIR
			rec.prioridade       = PRIO_URGENTE
			rec.cena_construcao  = cena_urg
			rec.nome_construcao  = _nome(cena_urg)
			rec.slot_recomendado = _slot_mais_ameacado(slots)
			rec.titulo           = "Reforce agora!"
			rec.explicacao       = "Castelo com menos de 30%% de vida! Construa uma %s no ponto mais exposto." % rec.nome_construcao
		else:
			rec.tipo       = TIPO_AGUARDAR
			rec.prioridade = PRIO_URGENTE
			rec.titulo     = "Castelo em perigo!"
			rec.explicacao = "Vida crítica e não há como construir agora. Aguarde o amanhecer!"
		return rec

	# ── PRIORIDADE 2: Slots vazios durante o dia ───────────────────────────
	if slots.size() > 0 and eh_dia:

		# Sub-caso: sem economia, já tem torre e renda fraca
		if num_eco == 0 and num_torres >= 1 and renda < RENDA_MINIMA:
			var cena_eco = _get_economica_acessivel(disponiveis, moedas)
			if cena_eco != null:
				rec.tipo             = TIPO_CONSTRUIR
				rec.prioridade       = PRIO_ALTA
				rec.cena_construcao  = cena_eco
				rec.nome_construcao  = _nome(cena_eco)
				rec.slot_recomendado = _slot_mais_proximo_da_base(slots)
				rec.titulo           = "Invista na economia"
				rec.explicacao       = "Renda por onda fraca (%d moedas). Uma %s garantirá recursos para upgrades." % [renda, rec.nome_construcao]
				return rec

		# Sub-caso: boss se aproximando (modo infinito)
		if onda_boss:
			var cena_boss = _get_ofensiva_acessivel(disponiveis, moedas)
			if cena_boss != null:
				rec.tipo             = TIPO_CONSTRUIR
				rec.prioridade       = PRIO_ALTA
				rec.cena_construcao  = cena_boss
				rec.nome_construcao  = _nome(cena_boss)
				rec.slot_recomendado = _slot_mais_ameacado(slots)
				rec.titulo           = "Boss se aproxima!"
				rec.explicacao       = "Onda múltipla de 5 — um chefe inimigo está a caminho! Posicione uma %s agora." % rec.nome_construcao
				return rec

		# Sub-caso padrão: construção ofensiva
		var cena_def = _get_ofensiva_acessivel(disponiveis, moedas)
		if cena_def != null:
			rec.tipo             = TIPO_CONSTRUIR
			rec.prioridade       = PRIO_MEDIA
			rec.cena_construcao  = cena_def
			rec.nome_construcao  = _nome(cena_def)
			rec.slot_recomendado = _slot_mais_ameacado(slots)
			rec.titulo           = "Construa uma %s" % rec.nome_construcao
			rec.explicacao       = "Há um slot disponível em posição estratégica. Uma %s aqui reforçará sua defesa." % rec.nome_construcao
			return rec

		# Qualquer coisa acessível
		var cena_any = _get_qualquer_acessivel(disponiveis, moedas)
		if cena_any != null:
			var tipo_any: int = _tipo_cena(cena_any)
			var eh_eco_any: bool = (tipo_any == 1 or tipo_any == 2 or tipo_any == 3)
			rec.tipo             = TIPO_CONSTRUIR
			rec.prioridade       = PRIO_MEDIA
			rec.cena_construcao  = cena_any
			rec.nome_construcao  = _nome(cena_any)
			rec.slot_recomendado = _slot_mais_proximo_da_base(slots) if eh_eco_any else _slot_mais_ameacado(slots)
			rec.titulo           = "Construa %s" % rec.nome_construcao
			rec.explicacao       = "Slot disponível — aproveite o dia para expandir com uma %s." % rec.nome_construcao
			return rec

	# ── PRIORIDADE 3: Upgrade acessível ───────────────────────────────────
	if eh_dia:
		var melhor_c: Node  = null
		var melhor_custo: int = moedas + 1

		for c in construcoes:
			if c.is_in_group("Base"):
				continue
			if not ("tipo" in c):
				continue
			var est2 = c.get("esta_destruida")
			if est2 != null and est2:
				continue
			if not c.has_method("get_custo_proximo_upgrade"):
				continue
			var custo_raw: int = c.get_custo_proximo_upgrade()
			if custo_raw <= 0:
				continue
			var custo_final: int = GameManager.obter_custo_com_desconto(custo_raw)
			if custo_final > moedas:
				continue
			# Prefere torres; em empate, pega o mais barato
			var eh_torre: bool = (c.tipo == 0)
			var melhor_eh_torre: bool = (melhor_c != null and melhor_c.tipo == 0)
			if melhor_c == null or (eh_torre and not melhor_eh_torre) or (eh_torre == melhor_eh_torre and custo_final < melhor_custo):
				melhor_custo = custo_final
				melhor_c = c

		if melhor_c != null:
			var nome_raw = melhor_c.get("nome_construcao")
			var nome_c: String = nome_raw if nome_raw != null else melhor_c.name
			rec.tipo               = TIPO_UPGRADE
			rec.prioridade         = PRIO_BAIXA
			rec.construcao_upgrade = melhor_c
			rec.nome_construcao    = nome_c
			rec.titulo             = "Faça upgrade da %s" % nome_c
			rec.explicacao         = "Sua %s pode ser melhorada por %d moedas — aumenta o poder de combate." % [nome_c, melhor_custo]
			return rec

	# ── PRIORIDADE 4: Aguardar / Noite ────────────────────────────────────
	if not eh_dia:
		rec.titulo     = "Boa sorte!"
		rec.explicacao = "Os inimigos chegaram. Suas torres estão em ação — fique de olho no castelo!"
	else:
		rec.titulo     = "Tudo sob controle"
		rec.explicacao = "Defesas montadas e economia funcionando. Inicie a noite quando estiver pronto."
	rec.prioridade = PRIO_NENHUMA
	return rec

# ==========================================
# HELPERS — SLOTS
# ==========================================
func _get_slots_vazios() -> Array:
	var result: Array = []
	for slot in get_tree().get_nodes_in_group("BuildSlots"):
		if not slot.is_built and slot.slot_disponivel:
			result.append(slot)
	return result

func _slot_mais_ameacado(slots: Array) -> Node:
	if slots.size() == 0:
		return null
	var spawners: Array = get_tree().get_nodes_in_group("Spawner")
	if spawners.size() == 0:
		return slots[0] as Node

	# Posição da base para calcular posicionamento estratégico
	var base_pos: Vector3 = _posicao_base()

	# Pontuação por spawner = inimigos na onda atual (prioriza spawners mais ativos)
	var scores: Dictionary = {}
	for s in spawners:
		var score: int = 1
		var ondas = s.get("ondas")
		var onda_idx = s.get("onda_atual")
		if ondas != null and onda_idx != null and int(onda_idx) < ondas.size():
			var wd = ondas[int(onda_idx)]
			if wd != null:
				for cfg in wd.inimigos:
					if cfg != null:
						score += int(cfg.quantidade)
		scores[s] = score

	# Para cada slot: soma (score_spawner / dist_ao_spawner) ponderado pela posição
	# entre o spawner e a base (slots no caminho dos inimigos valem mais)
	var melhor_slot: Node = slots[0] as Node
	var melhor_score: float = -1.0
	for slot in slots:
		var slot_pos: Vector3 = (slot as Node3D).global_position
		var pontuacao: float = 0.0
		for s in spawners:
			var spawner_pos: Vector3 = (s as Node3D).global_position
			var dist_slot_spawner: float = slot_pos.distance_to(spawner_pos)
			# Fator de interceptação: quão próximo o slot está do segmento spawner→base
			var dist_slot_base: float = slot_pos.distance_to(base_pos)
			var dist_spawner_base: float = spawner_pos.distance_to(base_pos)
			# Pontos no meio do caminho valem mais; muito longe da base ou colados no spawner valem menos
			var fator_interceptacao: float = clamp(1.0 - abs(dist_slot_base / max(0.1, dist_spawner_base) - 0.5) * 2.0, 0.1, 1.0)
			pontuacao += float(scores.get(s, 1)) / max(0.1, dist_slot_spawner) * fator_interceptacao
		if pontuacao > melhor_score:
			melhor_score = pontuacao
			melhor_slot  = slot as Node
	return melhor_slot

func _slot_mais_proximo_da_base(slots: Array) -> Node:
	if slots.size() == 0:
		return null
	var base_pos: Vector3 = _posicao_base()
	var melhor_slot: Node = slots[0] as Node
	var menor_dist: float = INF
	for slot in slots:
		var dist: float = (slot as Node3D).global_position.distance_to(base_pos)
		if dist < menor_dist:
			menor_dist = dist
			melhor_slot = slot as Node
	return melhor_slot

func _posicao_base() -> Vector3:
	var bases: Array = get_tree().get_nodes_in_group("Base")
	if bases.size() > 0:
		return (bases[0] as Node3D).global_position
	return Vector3.ZERO

# ==========================================
# HELPERS — CONSTRUÇÕES
# ==========================================
func _renda_estimada(construcoes: Array) -> int:
	var config: Dictionary = GameManager.banco_de_fases.get(GameManager.fase_atual, {})
	var total: int = int(config.get("renda_base_por_onda", 5)) + GameManager.bonus_moedas_onda
	if GameManager.modo_infinito:
		total += 3
	for c in construcoes:
		if c.is_in_group("Base"):
			continue
		if not ("tipo" in c):
			continue
		var est = c.get("esta_destruida")
		if est != null and est:
			continue
		if c.tipo == 1 or c.tipo == 2 or c.tipo == 3:
			var val = c.get("moedas_por_onda_atual")
			if val != null:
				total += int(val)
	return total

# ==========================================
# HELPERS — CENAS
# ==========================================
func _get_custo_cache(cena: PackedScene) -> int:
	var path: String = cena.resource_path
	if _cache_custos.has(path):
		return _cache_custos[path]
	var inst = cena.instantiate()
	var val = inst.get("custo_moedas")
	var custo: int = int(val) if val != null else 5
	inst.free()
	_cache_custos[path] = custo
	return custo

func _tipo_cena(cena: PackedScene) -> int:
	var p: String = cena.resource_path.to_lower()
	if "tower" in p or "torre" in p or "morteiro" in p or "sniper" in p:
		return 0
	if "mina" in p:
		return 1
	if "house" in p or "casa" in p:
		return 2
	if "mill" in p or "moinho" in p:
		return 3
	if "quartel" in p:
		return 4
	return -1

func _nome(cena: PackedScene) -> String:
	var t: int = _tipo_cena(cena)
	if t == 0: return "Torre"
	if t == 1: return "Mina"
	if t == 2: return "Casa"
	if t == 3: return "Moinho"
	if t == 4: return "Quartel"
	return cena.resource_path.get_file().get_basename().capitalize()

func _get_ofensiva_acessivel(disponiveis: Array, moedas: int) -> PackedScene:
	for cena in disponiveis:
		var t: int = _tipo_cena(cena)
		if t == 0 or t == 4:
			if GameManager.obter_custo_com_desconto(_get_custo_cache(cena)) <= moedas:
				return cena
	return null

func _get_economica_acessivel(disponiveis: Array, moedas: int) -> PackedScene:
	for cena in disponiveis:
		var t: int = _tipo_cena(cena)
		if t == 1 or t == 2 or t == 3:
			if GameManager.obter_custo_com_desconto(_get_custo_cache(cena)) <= moedas:
				return cena
	return null

func _get_qualquer_acessivel(disponiveis: Array, moedas: int) -> PackedScene:
	for cena in disponiveis:
		if GameManager.obter_custo_com_desconto(_get_custo_cache(cena)) <= moedas:
			return cena
	return null
