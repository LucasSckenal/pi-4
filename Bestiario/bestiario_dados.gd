extends RefCounted

# (sem class_name — é consumido via preload em bestiario.gd, evitando depender
# do cache de classes globais)

## Dados estáticos do Bestiário (o "livro").
## - INIMIGOS: ficha de cada mob (nome casa com Global.inimigos_descobertos e a
##   tabela _ICONES de inimigo_base.gd). "lore" é rascunho — ajuste o tom à vontade.
## - MAPAS: capítulos das histórias (gated por Global.fases_liberadas). As imagens
##   da história são puxadas dinamicamente da cutscene de cada fase.

const INIMIGOS: Array = [
	# ---------------- Mapa 1 — A Floresta ----------------
	{"nome": "Orc", "mapa": 1, "categoria": "Comum", "icone": "res://Icons/OrcPreview.png",
	 "lore": "Bruto verde de pouca conversa e muito porrete. Vem na frente do bando achando que tamanho é documento."},
	{"nome": "Abelha", "mapa": 1, "categoria": "Comum", "icone": "res://Icons/BeePreview.png",
	 "lore": "Pequena, rápida e furiosa — voa direto pra base ignorando o chão. O vovô jura que já levou uma ferroada dessas em 1968."},
	{"nome": "Cogumelão", "mapa": 1, "categoria": "Comum", "icone": "res://Icons/MushroomPreview.png",
	 "lore": "Um cogumelo grande demais pra ser saudável. Anda devagar, mas aguenta pancada como ninguém."},
	{"nome": "Golem de Musgo Ancestral", "mapa": 1, "categoria": "Chefe", "icone": "res://Icons/GolemBossPreview.png",
	 "lore": "Guardião milenar coberto de musgo. Acordou de mau humor e decidiu que a floresta inteira é só dele."},

	# ---------------- Mapa 2 — O Deserto ----------------
	{"nome": "Chacal", "mapa": 2, "categoria": "Comum", "icone": "res://Icons/ChacalPreview.png",
	 "lore": "Ágil e faminto, corre em matilha pela areia quente. Onde aparece um, vêm mais cinco atrás."},
	{"nome": "Anubis", "mapa": 2, "categoria": "Comum", "icone": "res://Icons/AnubisPreview.png",
	 "lore": "Servo de cabeça de chacal que protege os segredos do deserto. Leva a eternidade muito a sério."},
	{"nome": "Genio", "mapa": 2, "categoria": "Comum", "icone": "res://Icons/GenioPreview.png",
	 "lore": "Saiu da lâmpada de mau humor e sem a menor vontade de realizar desejo nenhum."},
	{"nome": "Litch", "mapa": 2, "categoria": "Mini-Chefe", "icone": "res://Icons/LichPreview.png",
	 "lore": "Mago morto-vivo que troca a própria vida por feitiços. Custa a cair de vez."},
	{"nome": "Faraó", "mapa": 2, "categoria": "Chefe", "icone": "res://Icons/FaraoPreview.png",
	 "lore": "O rei do deserto em pessoa. Comanda as areias e não perdoa quem invade sua tumba."},

	# ---------------- Mapa 3 — A Casa da Bruxa ----------------
	{"nome": "Abóbora", "mapa": 3, "categoria": "Comum", "icone": "res://Icons/AboboraPreview.png",
	 "lore": "Lanterna sorridente que rola sem dó em direção à base. Doçura? Só travessura."},
	{"nome": "Bilbo", "mapa": 3, "categoria": "Comum", "icone": "res://Icons/FrankPreview.png",
	 "lore": "Criatura remendada e desengonçada. Forte, lenta e com um parafuso a menos (literalmente)."},
	{"nome": "Cavaleiro", "mapa": 3, "categoria": "Mini-Chefe", "icone": "res://Icons/CavaleiroPreview.png",
	 "lore": "Armadura assombrada que não larga a espada nem depois de morto."},
	{"nome": "Bruxa", "mapa": 3, "categoria": "Chefe", "icone": "res://Icons/BruxaPreview.png",
	 "lore": "A dona da casa. Invoca capangas e solta feitiços enquanto cacareja de prazer."},

	# ---------------- Mapa 4 — A Fenda dos Piratas ----------------
	{"nome": "Monstro Peixe", "mapa": 4, "categoria": "Comum", "icone": "res://Icons/PeixePreview.png",
	 "lore": "Peixe grande e mal-encarado que saiu da água só pra arrumar encrenca."},
	{"nome": "Bombardeiro", "mapa": 4, "categoria": "Comum", "icone": "res://Icons/BombardeiroPreview.png",
	 "lore": "Pirata aéreo que sobrevoa as defesas largando explosivos. Mira na base, não no chão."},
	{"nome": "Tubarão", "mapa": 4, "categoria": "Mini-Chefe", "icone": "res://Icons/TubaraoPreview.png",
	 "lore": "Predador faminto com dentes pra dois. Avança rápido e não dá ré."},
	{"nome": "Holandês Voador", "mapa": 4, "categoria": "Chefe", "icone": "res://Icons/HolandesPreview.png",
	 "lore": "O navio amaldiçoado e seu capitão fantasma. Arrasta uma tripulação inteira de assombrações."},

	# ---------------- Mapa 5 — O Planeta Maluco ----------------
	{"nome": "Alexa astronauta", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/AlexaPreview.png",
	 "lore": "Assistente de bordo que ganhou vontade própria — e um traje espacial de brinde."},
	{"nome": "Linigena astronauta", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/AlienPreview.png",
	 "lore": "Alienígena curioso de fato espacial. Veio de muito longe só pra atrapalhar."},
	{"nome": "Sapao Astronauta", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/SapoPreview.png",
	 "lore": "Anfíbio gigante em órbita. Pula obstáculos como se a gravidade fosse opcional."},
	{"nome": "Fernando o flamingo", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/FlamingoPreview.png",
	 "lore": "Flamingo cósmico de elegância duvidosa. Voa torto, mas sempre chega."},
	{"nome": "Tutuba", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/VermelinPreview.png",
	 "lore": "Bichinho espacial teimoso que insiste em furar a fila rumo à base."},
	{"nome": "Cosmic Kraken", "mapa": 5, "categoria": "Chefe", "icone": "res://Icons/AlienPreview.png",
	 "lore": "Horror tentacular vindo do vazio entre as estrelas. Encara você com olhos demais."},

	# ---------------- Mapa 6 — O Covil do Dragão ----------------
	{"nome": "Lava golem", "mapa": 6, "categoria": "Mini-Chefe", "icone": "res://Icons/FireGolemPreview.png",
	 "lore": "Mole de rocha derretida. Cada passo deixa o chão fumegando atrás de si."},
	{"nome": "Dragao Inicial", "mapa": 6, "categoria": "Comum", "icone": "res://Icons/DragaoBebePreview.png",
	 "lore": "Filhote de dragão cuspindo as primeiras fagulhas. Fofo até a hora de abrir a boca."},
	{"nome": "Dragao Evoluido", "mapa": 6, "categoria": "Mini-Chefe", "icone": "res://Icons/DragaoJovemPreview.png",
	 "lore": "Já cresceu, já voa e já queima. A adolescência dele é movida a fogo."},
	{"nome": "Dragao Final", "mapa": 6, "categoria": "Chefe", "icone": "res://Icons/DragaoAdultoPreview.png",
	 "lore": "O senhor do covil em sua forma plena. A batalha final pelos netos."},
]

const MAPAS: Array = [
	{"numero": 1, "nome": "A Floresta",         "thumb": "res://Icons/Map1Selcetor.png",
	 "cutscene": "res://Cenas Locais/Cutscenes/cutscene_dinamica.tscn"},
	{"numero": 2, "nome": "O Deserto Carmesim",  "thumb": "res://Icons/Map2Selector.png",
	 "cutscene": "res://Cenas Locais/Cutscenes/cutscene_animada_2.tscn"},
	{"numero": 3, "nome": "A Casa da Bruxa",     "thumb": "res://Icons/Map3Selector.png",
	 "cutscene": "res://Cenas Locais/Cutscenes/cutscene_animada_3.tscn"},
	{"numero": 4, "nome": "A Fenda dos Piratas", "thumb": "res://Icons/Map4Selector.png",
	 "cutscene": "res://Cenas Locais/Cutscenes/cutscene_animada_4.tscn"},
	{"numero": 5, "nome": "O Planeta Maluco",    "thumb": "res://Icons/Map5Selector.png",
	 "cutscene": "res://Cenas Locais/Cutscenes/cutscene_animada_5.tscn"},
	{"numero": 6, "nome": "O Covil do Dragão",   "thumb": "res://Icons/Map6Selector.png",
	 "cutscene": "res://Cenas Locais/Cutscenes/cutscene_animada_6.tscn"},
]

const NOMES_MAPAS: Array = ["", "A Floresta", "O Deserto Carmesim", "A Casa da Bruxa",
	"A Fenda dos Piratas", "O Planeta Maluco", "O Covil do Dragão"]

# Extrai com segurança as imagens (quadros) da cutscene de uma fase, SEM rodar a
# cutscene: instantiate() não dispara _ready, então lemos o export e liberamos.
static func obter_imagens_historia(caminho_cutscene: String) -> Array:
	var imgs: Array = []
	if caminho_cutscene == "" or not ResourceLoader.exists(caminho_cutscene):
		return imgs
	var cena := load(caminho_cutscene)
	if cena == null:
		return imgs
	var inst = cena.instantiate()
	if inst != null:
		if "imagens" in inst and inst.imagens != null:
			for t in inst.imagens:
				if t != null:
					imgs.append(t)
		inst.free()
	return imgs
