extends InimigoBase
class_name Genio
# Gênio: disruptor à distância. Em vez de bater de perto, lança um TORNADO
# que viaja até a torre/base alvo, dá dano ao chegar e se dissipa.

@export_category("Ataque Tornado")
## Cena do projétil de tornado (TornadoProjetil).
@export var cena_tornado: PackedScene
## Velocidade com que o tornado viaja até o alvo.
@export var velocidade_tornado: float = 7.0
## Altura de onde o tornado sai (relativo ao gênio).
@export var altura_lancamento: float = 0.4


# Sobrescreve o ataque da base: lança o tornado no lugar do golpe corpo-a-corpo.
func atacar() -> void:
	if not (pode_atacar and alvo_atual):
		return
	pode_atacar = false

	# anim de ataque (se o AnimationPlayer estiver ligado — você liga depois)
	if animation_player and animation_player.has_animation(anim_atacar):
		animation_player.play(anim_atacar)
	SFXManager.tocar_enemy_hit()

	_lancar_tornado(alvo_atual)

	await get_tree().create_timer(tempo_recarga_ataque).timeout
	if not esta_morto:
		pode_atacar = true


func _lancar_tornado(alvo: Node3D) -> void:
	if cena_tornado == null or alvo == null or not is_instance_valid(alvo):
		return
	var t = cena_tornado.instantiate()
	get_tree().current_scene.add_child(t)
	t.global_position = global_position + Vector3(0, altura_lancamento, 0)
	if t.has_method("iniciar"):
		t.iniciar(alvo, forca_dano, velocidade_tornado)
