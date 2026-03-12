extends DirectionalLight3D

var energia_original: float
var cor_original: Color

@export var duracao: float = 2.0
@export var cor_noite: Color = Color(0.2, 0.2, 0.5)

func _ready():
	add_to_group("Sol")
	energia_original = light_energy
	cor_original = light_color

func mudar_para_noite():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "light_energy", energia_original * 0.2, duracao)
	tw.tween_property(self, "light_color", cor_noite, duracao)

func mudar_para_dia():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "light_energy", energia_original, duracao)
	tw.tween_property(self, "light_color", cor_original, duracao)
