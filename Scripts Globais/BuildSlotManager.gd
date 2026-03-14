extends Node

# Referência ao menu radial na UI
var menu_radial_ref: Control = null

# Referência ao slot que o jogador clicou no momento
var slot_ativo: Node3D = null

# Função chamada pelo build_slot.gd quando o jogador interage com ele
func abrir_menu_para_slot(slot: Node3D, pos_tela: Vector2):
	if menu_radial_ref and not menu_radial_ref.menu_ativo:
		slot_ativo = slot
		menu_radial_ref.abrir_menu(pos_tela)

# Função chamada pelo Menu Radial quando o jogador confirma a compra
func construir_no_slot_ativo(cena: PackedScene, custo: int):
	if slot_ativo and GameManager.gastar_moedas(custo):
		slot_ativo.construir(cena)
		slot_ativo = null
