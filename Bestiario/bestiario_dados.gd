extends RefCounted

# (sem class_name — é consumido via preload em bestiario.gd, evitando depender
# do cache de classes globais)
#
# Dados estáticos do Bestiário (o "livro").
# Campos por inimigo: nome, mapa, categoria, icone, lore (descrição),
#   comportamento, fraqueza, avistamento (primeiro avistamento). Textos são
#   rascunhos — ajuste o tom à vontade.

const INIMIGOS: Array = [
	# ---------------- Mapa 1 — A Floresta ----------------
	{"nome": "Orc", "mapa": 1, "categoria": "Comum", "icone": "res://Icons/OrcPreview.png",
	 "lore": "Bruto verde de pouca conversa e muito porrete. Vem na frente do bando achando que tamanho é documento.",
	 "comportamento": "Avança em linha reta, na dianteira da horda.",
	 "fraqueza": "Corpo a corpo dos soldados.",
	 "avistamento": "Bosque inicial"},
	{"nome": "Abelha", "mapa": 1, "categoria": "Comum", "icone": "res://Icons/BeePreview.png",
	 "lore": "Pequena, rápida e furiosa — voa direto pra base ignorando o chão. O vovô jura que já levou uma ferroada dessas em 1968.",
	 "comportamento": "Voa em linha reta, ignorando o caminho.",
	 "fraqueza": "Defesas antiaéreas.",
	 "avistamento": "Bosque inicial"},
	{"nome": "Cogumelão", "mapa": 1, "categoria": "Comum", "icone": "res://Icons/MushroomPreview.png",
	 "lore": "Um cogumelo grande demais pra ser saudável. Anda devagar, mas aguenta pancada como ninguém.",
	 "comportamento": "Lento e resistente; serve de escudo aos outros.",
	 "fraqueza": "Dano contínuo de fogo.",
	 "avistamento": "Bosque inicial"},
	{"nome": "Golem de Musgo Ancestral", "mapa": 1, "categoria": "Chefe", "icone": "res://Icons/GolemBossPreview.png",
	 "lore": "Guardião milenar coberto de musgo. Acordou de mau humor e decidiu que a floresta inteira é só dele.",
	 "comportamento": "Marcha implacável e absorve muito dano.",
	 "fraqueza": "Fogo concentrado de várias torres.",
	 "avistamento": "Coração do bosque"},

	# ---------------- Mapa 2 — O Deserto Carmesim ----------------
	{"nome": "Chacal", "mapa": 2, "categoria": "Comum", "icone": "res://Icons/ChacalPreview.png",
	 "lore": "Ágil e faminto, corre em matilha pela areia quente. Onde aparece um, vêm mais cinco atrás.",
	 "comportamento": "Corre veloz e em grupo.",
	 "fraqueza": "Torres de área (morteiro).",
	 "avistamento": "Dunas escaldantes"},
	{"nome": "Anubis", "mapa": 2, "categoria": "Comum", "icone": "res://Icons/AnubisPreview.png",
	 "lore": "Servo de cabeça de chacal que protege os segredos do deserto. Leva a eternidade muito a sério.",
	 "comportamento": "Avança firme, protegendo os aliados.",
	 "fraqueza": "Perfuração do sniper.",
	 "avistamento": "Dunas escaldantes"},
	{"nome": "Genio", "mapa": 2, "categoria": "Comum", "icone": "res://Icons/GenioPreview.png",
	 "lore": "Saiu da lâmpada de mau humor e sem a menor vontade de realizar desejo nenhum.",
	 "comportamento": "Flutua e atrapalha as defesas.",
	 "fraqueza": "Gelo (lentidão).",
	 "avistamento": "Oásis perdido"},
	{"nome": "Litch", "mapa": 2, "categoria": "Mini-Chefe", "icone": "res://Icons/LichPreview.png",
	 "lore": "Mago morto-vivo que troca a própria vida por feitiços. Custa a cair de vez.",
	 "comportamento": "Resiste e se recompõe sob pressão.",
	 "fraqueza": "Dano rápido e constante.",
	 "avistamento": "Tumba esquecida"},
	{"nome": "Faraó", "mapa": 2, "categoria": "Chefe", "icone": "res://Icons/FaraoPreview.png",
	 "lore": "O rei do deserto em pessoa. Comanda as areias e não perdoa quem invade sua tumba.",
	 "comportamento": "Comanda a horda e convoca reforços.",
	 "fraqueza": "Eliminar os reforços primeiro.",
	 "avistamento": "Câmara do sarcófago"},

	# ---------------- Mapa 3 — A Casa da Bruxa ----------------
	{"nome": "Abóbora", "mapa": 3, "categoria": "Comum", "icone": "res://Icons/AboboraPreview.png",
	 "lore": "Lanterna sorridente que rola sem dó em direção à base. Doçura? Só travessura.",
	 "comportamento": "Rola ganhando velocidade até a base.",
	 "fraqueza": "Lentidão para frear cedo.",
	 "avistamento": "Vila assombrada"},
	{"nome": "Bilbo", "mapa": 3, "categoria": "Comum", "icone": "res://Icons/FrankPreview.png",
	 "lore": "Criatura remendada e desengonçada. Forte, lenta e com um parafuso a menos (literalmente).",
	 "comportamento": "Lento, porém muito pancudo.",
	 "fraqueza": "Fogo e dano em área.",
	 "avistamento": "Laboratório nos fundos"},
	{"nome": "Cavaleiro", "mapa": 3, "categoria": "Mini-Chefe", "icone": "res://Icons/CavaleiroPreview.png",
	 "lore": "Armadura assombrada que não larga a espada nem depois de morto.",
	 "comportamento": "Investe e aguenta muitos golpes.",
	 "fraqueza": "Perfuração pesada.",
	 "avistamento": "Salão dos retratos"},
	{"nome": "Bruxa", "mapa": 3, "categoria": "Chefe", "icone": "res://Icons/BruxaPreview.png",
	 "lore": "A dona da casa. Invoca capangas e solta feitiços enquanto cacareja de prazer.",
	 "comportamento": "Invoca capangas e ataca à distância.",
	 "fraqueza": "Pressão rápida antes das invocações.",
	 "avistamento": "Sótão da bruxa"},

	# ---------------- Mapa 4 — A Fenda dos Piratas ----------------
	{"nome": "Monstro Peixe", "mapa": 4, "categoria": "Comum", "icone": "res://Icons/PeixePreview.png",
	 "lore": "Peixe grande e mal-encarado que saiu da água só pra arrumar encrenca.",
	 "comportamento": "Avança em cardume pela orla.",
	 "fraqueza": "Torres de área.",
	 "avistamento": "Mar aberto"},
	{"nome": "Bombardeiro", "mapa": 4, "categoria": "Comum", "icone": "res://Icons/BombardeiroPreview.png",
	 "lore": "Pirata aéreo que sobrevoa as defesas largando explosivos. Mira na base, não no chão.",
	 "comportamento": "Sobrevoa as defesas bombardeando.",
	 "fraqueza": "Defesas antiaéreas.",
	 "avistamento": "Céus da enseada"},
	{"nome": "Tubarão", "mapa": 4, "categoria": "Mini-Chefe", "icone": "res://Icons/TubaraoPreview.png",
	 "lore": "Predador faminto com dentes pra dois. Avança rápido e não dá ré.",
	 "comportamento": "Arranca veloz, sem recuar.",
	 "fraqueza": "Lentidão (gelo).",
	 "avistamento": "Águas profundas"},
	{"nome": "Holandês Voador", "mapa": 4, "categoria": "Chefe", "icone": "res://Icons/HolandesPreview.png",
	 "lore": "O navio amaldiçoado e seu capitão fantasma. Arrasta uma tripulação inteira de assombrações.",
	 "comportamento": "Arrasta tripulação fantasma e tanka muito.",
	 "fraqueza": "Foco no casco principal.",
	 "avistamento": "Névoa da fenda"},

	# ---------------- Mapa 5 — O Planeta Maluco ----------------
	{"nome": "Alexa astronauta", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/AlexaPreview.png",
	 "lore": "Assistente de bordo que ganhou vontade própria — e um traje espacial de brinde.",
	 "comportamento": "Patrulha metódica rumo à base.",
	 "fraqueza": "Dano elétrico.",
	 "avistamento": "Órbita distante"},
	{"nome": "Linigena astronauta", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/AlienPreview.png",
	 "lore": "Alienígena curioso de fato espacial. Veio de muito longe só pra atrapalhar.",
	 "comportamento": "Avança em zigue-zague, desviando.",
	 "fraqueza": "Torres de área.",
	 "avistamento": "Órbita distante"},
	{"nome": "Sapao Astronauta", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/SapoPreview.png",
	 "lore": "Anfíbio gigante em órbita. Pula obstáculos como se a gravidade fosse opcional.",
	 "comportamento": "Salta sobre obstáculos e defesas.",
	 "fraqueza": "Gelo (lentidão).",
	 "avistamento": "Crateras lunares"},
	{"nome": "Fernando o flamingo", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/FlamingoPreview.png",
	 "lore": "Flamingo cósmico de elegância duvidosa. Voa torto, mas sempre chega.",
	 "comportamento": "Voo irregular rumo à base.",
	 "fraqueza": "Defesas antiaéreas.",
	 "avistamento": "Anéis do planeta"},
	{"nome": "Tutuba", "mapa": 5, "categoria": "Comum", "icone": "res://Icons/VermelinPreview.png",
	 "lore": "Bichinho espacial teimoso que insiste em furar a fila rumo à base.",
	 "comportamento": "Pequeno e teimoso; fura a fila.",
	 "fraqueza": "Tiro rápido.",
	 "avistamento": "Superfície vermelha"},
	{"nome": "Cosmic Kraken", "mapa": 5, "categoria": "Chefe", "icone": "res://Icons/AlienPreview.png",
	 "lore": "Horror tentacular vindo do vazio entre as estrelas. Encara você com olhos demais.",
	 "comportamento": "Esmaga defesas com os tentáculos.",
	 "fraqueza": "Dano massivo concentrado.",
	 "avistamento": "Vazio entre estrelas"},

	# ---------------- Mapa 6 — O Covil do Dragão ----------------
	{"nome": "Lava golem", "mapa": 6, "categoria": "Mini-Chefe", "icone": "res://Icons/FireGolemPreview.png",
	 "lore": "Mole de rocha derretida. Cada passo deixa o chão fumegando atrás de si.",
	 "comportamento": "Pisa forte, deixando rastro de brasa.",
	 "fraqueza": "Gelo (lentidão).",
	 "avistamento": "Rios de lava"},
	{"nome": "Dragao Inicial", "mapa": 6, "categoria": "Comum", "icone": "res://Icons/DragaoBebePreview.png",
	 "lore": "Filhote de dragão cuspindo as primeiras fagulhas. Fofo até a hora de abrir a boca.",
	 "comportamento": "Anda e solta fagulhas curtas.",
	 "fraqueza": "Tiro rápido.",
	 "avistamento": "Ninho de pedra"},
	{"nome": "Dragao Evoluido", "mapa": 6, "categoria": "Mini-Chefe", "icone": "res://Icons/DragaoJovemPreview.png",
	 "lore": "Já cresceu, já voa e já queima. A adolescência dele é movida a fogo.",
	 "comportamento": "Voa e queima as defesas de longe.",
	 "fraqueza": "Defesas antiaéreas.",
	 "avistamento": "Penhascos do covil"},
	{"nome": "Dragao Final", "mapa": 6, "categoria": "Chefe", "icone": "res://Icons/DragaoAdultoPreview.png",
	 "lore": "O senhor do covil em sua forma plena. A batalha final pelos netos.",
	 "comportamento": "Domina o ar e o chão; cospe fogo intenso.",
	 "fraqueza": "Tudo o que você tiver — é a luta final.",
	 "avistamento": "Trono de magma"},
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
