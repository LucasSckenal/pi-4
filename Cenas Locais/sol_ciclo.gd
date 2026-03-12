extends DirectionalLight3D

var energia_original: float
var cor_original: Color

@export var duracao: float = 2.0
@export var cor_noite: Color = Color(0.566, 0.308, 0.835, 1.0)
#Testar com esse também:
#Color(0.22, 0.423, 0.919, 1.0)

# Cores alvo para o ProceduralSkyMaterial durante a transição para a noite
@export var ceu_topo_noite: Color = Color(0.06, 0.065, 0.149, 1.0)
@export var ceu_horizonte_noite: Color = Color(0.188, 0.082, 0.435, 1.0)

# Referência ao nó irmão WorldEnvironment e suas propriedades de céu
@onready var world_env = $"../WorldEnvironment"
var ceu_material: ProceduralSkyMaterial
var ceu_topo_original: Color
var ceu_horizonte_original: Color
var chao_horizonte_original: Color
var chao_baixo_original: Color

func _ready():
	add_to_group("Sol")
	energia_original = light_energy
	cor_original = light_color
	
	if world_env and world_env.environment and world_env.environment.sky:
		ceu_material = world_env.environment.sky.sky_material as ProceduralSkyMaterial
		if ceu_material:
			ceu_topo_original = ceu_material.sky_top_color
			ceu_horizonte_original = ceu_material.sky_horizon_color

func mudar_para_noite():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "light_energy", energia_original * 0.5, duracao)
	tw.tween_property(self, "light_color", cor_noite, duracao)
	
	if ceu_material:
		tw.tween_property(ceu_material, "sky_top_color", ceu_topo_noite, duracao)
		tw.tween_property(ceu_material, "ground_bottom_color", ceu_topo_noite, duracao)
		tw.tween_property(ceu_material, "ground_horizon_color", ceu_horizonte_noite, duracao)

func mudar_para_dia():
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "light_energy", energia_original, duracao)
	tw.tween_property(self, "light_color", cor_original, duracao)
	
	if ceu_material:
		tw.tween_property(ceu_material, "sky_top_color", ceu_topo_original, duracao)
		tw.tween_property(ceu_material, "sky_horizon_color", ceu_horizonte_original, duracao)
		tw.tween_property(ceu_material, "ground_bottom_color", chao_baixo_original, duracao)
		tw.tween_property(ceu_material, "ground_horizon_color", chao_horizonte_original, duracao)
