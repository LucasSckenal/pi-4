extends Node

var personagem_escolhido_path : String = ""

# Verifique se os nomes dos arquivos abaixo estão IGUAIS aos da sua pasta
var lista_personagens = [
	"res://Personagens/character-female-a.glb",
	"res://Personagens/character-female-b.glb",
	"res://Personagens/character-female-c.glb",
	"res://Personagens/character-female-d.glb",
	"res://Personagens/character-female-e.glb",
	"res://Personagens/character-female-f.glb",
	"res://Personagens/character-male-a.glb",
	"res://Personagens/character-male-b.glb",
	"res://Personagens/character-male-c.glb",
	"res://Personagens/character-male-d.glb",
	"res://Personagens/character-male-e.glb",
	"res://Personagens/character-male-f.glb"
]

func _ready():
	print("--- DEBUG GLOBAL ---")
	print("Lista carregada com ", lista_personagens.size(), " personagens.")
