extends InimigoBase
class_name PeixeLanterna

# ==========================================
# ISCA PROVOCADORA (mecânica única)
# ==========================================
# A cada `taunt_intervalo`, a isca bioluminescente pulsa e as torres que
# conseguem alcançá-lo passam a focar SÓ neste inimigo por `taunt_duracao`
# segundos, protegendo o resto da horda. Papel de suporte/escudo.
#
# O lado da torre lê a flag `taunt_ativo` em Builds.gd (_process):
# qualquer inimigo no alcance com taunt_ativo == true vira o alvo preferido.

@export_category("Isca Provocadora")
## Tempo entre cada pulso da isca
@export var taunt_intervalo: float = 6.0
## Quanto tempo as torres ficam presas nele a cada pulso
@export var taunt_duracao: float = 3.0
## Cor do brilho da isca (telegrafia o pulso)
@export var taunt_cor: Color = Color(0.4, 0.9, 1.0)

@export_category("Voo")
## Altura que ele flutua ACIMA do ponto de spawn (0 = rente ao chão).
## Como é aéreo (eh_aereo), a base mantém essa altitude sem gravidade.
## IMPORTANTE: a esfera de alcance das torres fica baixa (~chão); se ele voar
## mais alto que o alcance das torres, elas NÃO conseguem mirar nele. Mantenha
## abaixo de ~1.0 pra continuar atacável pelas torres comuns.
@export var altura_voo: float = 0.8

## Lido pelas torres (Builds.gd): quando true, elas miram neste inimigo.
var taunt_ativo: bool = false

var _taunt_timer: Timer = null
var _dur_timer: Timer = null
var _luz_isca: OmniLight3D = null


func _ready() -> void:
	super._ready()

	# Voo: a base captura posicao_de_spawn via call_deferred dentro do super._ready().
	# Enfileiramos o NOSSO deferred depois — então ele roda APÓS o da base e eleva
	# o alvo de altitude. O peixe sobe suave (da "água") até flutuar acima do chão.
	if altura_voo > 0.0:
		(func(): posicao_de_spawn.y += altura_voo).call_deferred()

	_criar_luz_isca()

	# Timer do ciclo: dispara o pulso a cada intervalo
	_taunt_timer = Timer.new()
	_taunt_timer.wait_time = taunt_intervalo
	_taunt_timer.one_shot = false
	_taunt_timer.autostart = true
	add_child(_taunt_timer)
	_taunt_timer.timeout.connect(_ativar_isca)

	# Timer da duração: desliga o taunt depois de taunt_duracao
	_dur_timer = Timer.new()
	_dur_timer.wait_time = taunt_duracao
	_dur_timer.one_shot = true
	add_child(_dur_timer)
	_dur_timer.timeout.connect(_desativar_isca)


func _criar_luz_isca() -> void:
	_luz_isca = OmniLight3D.new()
	_luz_isca.light_color = taunt_cor
	_luz_isca.light_energy = 0.0
	_luz_isca.omni_range = 6.0
	_luz_isca.shadow_enabled = false
	_luz_isca.position = Vector3(0, 0.9, 0)  # perto da isca, no alto do corpo
	add_child(_luz_isca)


func _ativar_isca() -> void:
	if esta_morto:
		return
	taunt_ativo = true
	_pulsar_luz(true)
	_dur_timer.start()


func _desativar_isca() -> void:
	taunt_ativo = false
	_pulsar_luz(false)


func _pulsar_luz(aceso: bool) -> void:
	if not is_instance_valid(_luz_isca):
		return
	var tw := create_tween()
	if aceso:
		tw.tween_property(_luz_isca, "light_energy", 4.0, 0.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_luz_isca, "light_energy", 2.2, 0.3).set_trans(Tween.TRANS_SINE)
	else:
		tw.tween_property(_luz_isca, "light_energy", 0.0, 0.4)


# Ao morrer, solta as torres imediatamente (não ficam presas num peixe morto).
func morrer() -> void:
	taunt_ativo = false
	if _taunt_timer:
		_taunt_timer.stop()
	super.morrer()
