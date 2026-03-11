extends Node3D

@export var custo_moedas: int = 3 
# Função do sensor - Quando o jogador entra na área
func _on_area_3d_body_entered(body):
	if body.name == "Player":
		# Aciona o varredor pedindo 75% de invisibilidade
		mudar_transparencia(self, 0.75) 

# Função do sensor - Quando o jogador sai da área
func _on_area_3d_body_exited(body):
	if body.name == "Player":
		# Aciona o varredor pedindo para voltar ao normal (sólido = 0.0)
		mudar_transparencia(self, 0.0)

# O Varredor: vasculha todas as peças do objeto pronto
func mudar_transparencia(no_atual: Node, valor: float):
	# Se a peça atual for um modelo 3D visual, aplica a transparência
	if no_atual is MeshInstance3D:
		no_atual.transparency = valor
		
	# Pede para o código repetir a busca dentro dos filhos dessa peça
	for filho in no_atual.get_children():
		mudar_transparencia(filho, valor)
