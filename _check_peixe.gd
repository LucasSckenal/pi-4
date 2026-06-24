extends SceneTree
func _init():
	var ps = load("res://Enemies/Map 4/PeixeLanterna.tscn")
	if ps == null:
		print("FAIL: cena nula"); quit(); return
	var n = ps.instantiate()
	print("ROOT class=", n.get_class(), " name=", n.name)
	print("nome_inimigo=", n.nome_inimigo)
	print("stats vida=", n.vida_maxima, " vel=", n.velocidade, " dano=", n.forca_dano, " distAtq=", n.distancia_ataque)
	print("anim_andar=", n.anim_andar, " atacar=", n.anim_atacar, " morrer=", n.anim_morrer)
	print("modelo_3d resolve=", n.modelo_3d != null)
	var ap = n.animation_player
	print("animation_player export resolve=", ap != null)
	if ap == null:
		ap = n.get_node_or_null("Lumenfang_rigged/AnimationPlayer")
		print("fallback get_node AnimationPlayer=", ap != null)
	if ap:
		print("animacoes=", ap.get_animation_list())
		for a in ["Idle","Attack","Death","Swim","Hit"]:
			print("  has ", a, "=", ap.has_animation(a))
		var idle = ap.get_animation("Idle")
		if idle: print("  Idle.loop_mode=", idle.loop_mode, " (1=loop)")
	n.free()
	quit()
