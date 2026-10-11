--[[
	ROUBE UM HERÓI - Configuração (compartilhada entre servidor e jogadores)

	Onde colocar: ReplicatedStorage -> ModuleScript (nome: ConfigHerois)

	Aqui você muda TUDO do jogo sem mexer na lógica:
	heróis, preços, raridades, mutações, melhorias, eventos, sons e Robux.
]]

local Config = {}

--------------------------------------------------------------------------
-- GERAL
--------------------------------------------------------------------------
Config.Geral = {
	DinheiroInicial = 100,

	-- Passarela
	IntervaloSpawn = 2.5, -- segundos entre cada herói que sai do portal
	VelocidadePassarela = 9, -- studs por segundo
	ComprimentoPassarela = 300,

	-- Roubo e defesa
	TempoParaRoubar = 1.2, -- segundos segurando E
	MultiplicadorCarregando = 0.65, -- quem carrega um herói fica 35% mais lento
	RecuperarEncostando = false, -- true = o dono recupera o herói só de encostar no ladrão
	RecargaTranca = 20, -- segundos de espera depois que a tranca acaba
	RecargaSoco = 0.8,
	AlcanceSoco = 8,
	ForcaSoco = 75,

	-- Economia
	PorcentagemVenda = 0.5, -- vender devolve 50% do valor
	HorasOfflineMaximo = 4, -- quantas horas de renda offline o jogador pode acumular
	PorcentagemOffline = 0.5, -- offline rende 50%

	-- Mundo
	CicloDiaNoite = true,
	DuracaoDiaMinutos = 15,
	HoraInicial = 16.5,
	RemoverBaseplate = true, -- apaga o Baseplate e o SpawnLocation do modelo padrão

	-- Eventos
	IntervaloEventoMinutos = 7,
	DuracaoEventoMinutos = 2,

	-- Salvamento (DataStore)
	SalvarDados = true,
	NomeDataStore = "RoubeUmHeroi_v1",
	IntervaloAutoSave = 90, -- segundos
	IntervaloRanking = 120, -- segundos entre atualizações do ranking global

	-- Anúncios para o servidor inteiro
	AnunciarSpawnAPartirDe = "Lendario",
	AnunciarCompraAPartirDe = "Mitico",
	AnunciarRouboAPartirDe = "Epico",

	-- Comandos de teste (/dinheiro, /evento, /heroi) funcionam no Studio e para o dono do jogo
	ComandosDeTeste = true,

	-- Distância máxima da tenda para comprar na Loja
	DistanciaLoja = 32,
}

--------------------------------------------------------------------------
-- SONS (troque pelos IDs que quiser - Caixa de ferramentas > Áudio)
-- Para música de fundo: pegue um ID de música na Caixa de ferramentas,
-- clique com o botão direito > "Copiar ID do recurso" e cole como "rbxassetid://NUMERO"
--------------------------------------------------------------------------
Config.Sons = {
	Musica = "", -- exemplo: "rbxassetid://1234567890"
	VolumeMusica = 0.3,
	Clique = "rbxasset://sounds/clickfast.wav",
	Notificacao = "rbxasset://sounds/electronicpingshort.wav",
	Moeda = "rbxasset://sounds/electronicpingshort.wav",
	Compra = "rbxasset://sounds/electronicpingshort.wav",
	Alarme = "rbxasset://sounds/electronicpingshort.wav",
	Soco = "rbxasset://sounds/swordlunge.wav",
	Erro = "rbxasset://sounds/clickfast.wav",
}

--------------------------------------------------------------------------
-- RARIDADES (em ordem: da mais comum para a mais rara)
-- chance = peso no sorteio da passarela | escala = tamanho do herói
--------------------------------------------------------------------------
Config.Raridades = {
	{ id = "Comum", nome = "Comum", cor = Color3.fromRGB(200, 200, 200), chance = 55, escala = 0.9 },
	{ id = "Incomum", nome = "Incomum", cor = Color3.fromRGB(90, 220, 90), chance = 25, escala = 1.0 },
	{ id = "Raro", nome = "Raro", cor = Color3.fromRGB(70, 150, 255), chance = 12, escala = 1.1 },
	{ id = "Epico", nome = "Épico", cor = Color3.fromRGB(170, 80, 255), chance = 5, escala = 1.2 },
	{ id = "Lendario", nome = "Lendário", cor = Color3.fromRGB(255, 200, 40), chance = 2, escala = 1.35 },
	{ id = "Mitico", nome = "Mítico", cor = Color3.fromRGB(255, 60, 60), chance = 0.7, escala = 1.5 },
	{ id = "Divino", nome = "Divino", cor = Color3.fromRGB(255, 240, 150), chance = 0.25, escala = 1.65 },
	{ id = "Secreto", nome = "SECRETO", cor = Color3.fromRGB(0, 255, 200), chance = 0.05, escala = 1.8 },
}

--------------------------------------------------------------------------
-- MUTAÇÕES (chance de cada herói da passarela nascer mutado)
--------------------------------------------------------------------------
Config.Mutacoes = {
	{ id = "Normal", nome = "Normal", cor = Color3.fromRGB(255, 255, 255), multiplicador = 1, chance = 0 },
	{ id = "Ouro", nome = "OURO", cor = Color3.fromRGB(255, 200, 40), multiplicador = 2, chance = 0.05 },
	{ id = "Diamante", nome = "DIAMANTE", cor = Color3.fromRGB(120, 230, 255), multiplicador = 3, chance = 0.02 },
	{ id = "ArcoIris", nome = "ARCO-ÍRIS", cor = Color3.fromRGB(255, 120, 255), multiplicador = 5, chance = 0.007 },
	{ id = "Cosmico", nome = "CÓSMICO", cor = Color3.fromRGB(150, 70, 255), multiplicador = 10, chance = 0.002 },
}

--------------------------------------------------------------------------
-- HERÓIS (36 super-heróis inspirados nos filmes, com nomes e visuais originais)
--
-- visual: cores do uniforme e o que o herói usa.
--   cabeca: bone, quepe, capaceteBombeiro, toucaMedica, chapeuAbas, capaceteAstronauta,
--           capacetePiloto, cabelo, capuzAranha, capuzMorcego, capaceteEstrela,
--           orelhasRaio, elmoTrovao, tiara, capaceteArmadura
--   rosto: oculos, oculosSol, oculosProtecao, mascaraCirurgica, mascaraMergulho
--   corpo (lista): faixasRefletivas, jaleco, colete, avental, estetoscopio, distintivo,
--           cintoUtilidade, teia, listrasPeito, discosPeito, faixasAmarelas, binoculo, armaduraOuro
--   emblema: cruz, estrela, raio, aranha, morcego, reator, supremo, bandeira
--   mao: extintor, machado, vassoura, livro, maleta, frasco, boia, prancheta, lanterna, carta, martelo, laco
--   maoEsquerda: escudo | costas: tanque, mochilaAstronauta, bolsaCarteiro | capa: cor
-- renda = dinheiro por segundo
--------------------------------------------------------------------------
local rgb = Color3.fromRGB
local PELE_CLARA = rgb(255, 214, 180)
local PELE_MEDIA = rgb(224, 172, 120)
local PELE_MORENA = rgb(170, 110, 70)
local PELE_ESCURA = rgb(110, 70, 45)
local PRETO = rgb(25, 25, 30)
local BRANCO = rgb(245, 245, 245)
local CASTANHO = rgb(90, 55, 30)
local LOIRO = rgb(240, 200, 90)

Config.Herois = {
	-- Comum
	{ id = "FormigaAtomica", nome = "Formiga Atômica", raridade = "Comum", preco = 25, renda = 1, icone = "🐜", visual = {
		pele = PELE_CLARA, camisa = rgb(190, 30, 30), mangas = rgb(30, 30, 35), calca = rgb(30, 30, 35), botas = PRETO, maos = PRETO,
		cabeca = "capaceteFormiga", cabecaCor = rgb(170, 175, 185), corpo = { "cintoUtilidade" }, cintoCor = rgb(170, 175, 185) } },
	{ id = "FlechaCerteira", nome = "Flecha Certeira", raridade = "Comum", preco = 40, renda = 2, icone = "🏹", visual = {
		pele = PELE_CLARA, cabelo = LOIRO, camisa = rgb(40, 120, 50), calca = rgb(35, 80, 40), botas = rgb(90, 60, 35), maos = rgb(90, 60, 35),
		cabeca = "capuzArqueiro", cabecaCor = rgb(30, 100, 40), rosto = "mascaraDomino", mascaraCor = rgb(20, 70, 30),
		maoEsquerda = "arco", costas = "aljava" } },
	{ id = "ReiDosMares", nome = "Rei dos Mares", raridade = "Comum", preco = 60, renda = 3, icone = "🔱", visual = {
		pele = PELE_MEDIA, cabelo = LOIRO, estiloCabelo = "longo", camisa = rgb(240, 140, 30), calca = rgb(30, 130, 70), botas = rgb(30, 130, 70),
		maos = rgb(30, 130, 70), cabeca = "cabelo", rosto = "barba", corpo = { "escamas" }, mao = "tridente" } },
	{ id = "AgenteSombra", nome = "Agente Sombra", raridade = "Comum", preco = 90, renda = 4, icone = "🕶️", visual = {
		pele = PELE_CLARA, cabelo = rgb(180, 40, 30), estiloCabelo = "longo", camisa = rgb(25, 25, 30), calca = rgb(25, 25, 30), botas = PRETO,
		maos = PRETO, cabeca = "cabelo", corpo = { "cintoUtilidade" }, cintoCor = rgb(70, 70, 80), mao = "blasters" } },
	{ id = "PassaroVermelho", nome = "Pássaro Vermelho", raridade = "Comum", preco = 130, renda = 5, icone = "🐦", visual = {
		pele = PELE_CLARA, cabelo = PRETO, camisa = rgb(200, 30, 30), mangas = rgb(30, 110, 50), calca = rgb(30, 110, 50), botas = PRETO,
		maos = rgb(30, 110, 50), cabeca = "cabelo", rosto = "mascaraDomino", corpo = { "cintoUtilidade" }, capa = rgb(255, 200, 40) } },
	{ id = "AsaDeAco", nome = "Asa de Aço", raridade = "Comum", preco = 180, renda = 6, icone = "🦅", visual = {
		pele = PELE_ESCURA, cabelo = PRETO, camisa = rgb(110, 115, 125), calca = rgb(60, 62, 70), botas = PRETO, maos = PRETO,
		cabeca = "cabelo", rosto = "oculosVoo", costas = "asasMetal", corpo = { "cintoUtilidade" }, cintoCor = rgb(200, 40, 40) } },

	-- Incomum
	{ id = "PanteraReal", nome = "Pantera Real", raridade = "Incomum", preco = 300, renda = 10, icone = "🐾", visual = {
		pele = PELE_ESCURA, camisa = rgb(25, 25, 30), calca = rgb(25, 25, 30), botas = PRETO, maos = PRETO,
		cabeca = "capuzPantera", corpo = { "linhasPrata", "colar" } } },
	{ id = "MagoSupremo", nome = "Mago Supremo", raridade = "Incomum", preco = 420, renda = 14, icone = "🔮", visual = {
		pele = PELE_CLARA, cabelo = PRETO, camisa = rgb(30, 60, 130), calca = rgb(25, 35, 80), botas = rgb(90, 60, 35),
		maos = rgb(160, 120, 70), cabeca = "magoCabelo", corpo = { "robe", "amuleto" }, capa = rgb(180, 20, 30), mao = "magia" } },
	{ id = "CiborgueMax", nome = "Ciborgue Max", raridade = "Incomum", preco = 560, renda = 18, icone = "🦾", visual = {
		pele = PELE_ESCURA, cabelo = PRETO, camisa = rgb(130, 135, 145), calca = rgb(110, 115, 125), botas = rgb(60, 62, 70),
		maos = rgb(150, 155, 165), material = "Metal", cabeca = "capaceteCiborgue", corpo = { "metadeMetal" } } },
	{ id = "GarraSelvagem", nome = "Garra Selvagem", raridade = "Incomum", preco = 750, renda = 24, icone = "🐺", visual = {
		pele = PELE_CLARA, camisa = rgb(255, 200, 0), calca = rgb(40, 60, 160), botas = rgb(40, 60, 160), maos = rgb(40, 60, 160),
		cabeca = "mascaraGarra", cabecaCor = rgb(255, 200, 0), corpo = { "faixasPretasLaterais", "cintoUtilidade" }, cintoCor = rgb(200, 30, 30),
		mao = "garras" } },
	{ id = "MercenarioTagarela", nome = "Mercenário Tagarela", raridade = "Incomum", preco = 950, renda = 30, icone = "⚔️", visual = {
		pele = PELE_CLARA, camisa = rgb(170, 20, 25), calca = rgb(170, 20, 25), botas = PRETO, maos = PRETO,
		cabeca = "mascaraMercenario", cabecaCor = rgb(170, 20, 25), corpo = { "cintoUtilidade" }, cintoCor = PRETO, costas = "espadas" } },
	{ id = "SenhoraTempestade", nome = "Senhora Tempestade", raridade = "Incomum", preco = 1200, renda = 36, icone = "🌩️", visual = {
		pele = PELE_ESCURA, cabelo = rgb(240, 240, 245), estiloCabelo = "longo", camisa = rgb(30, 30, 35), calca = rgb(30, 30, 35),
		botas = PRETO, maos = PRETO, cabeca = "cabelo", rosto = "olhosBrancos", capa = rgb(60, 60, 75), mao = "raios" } },

	-- Raro
	{ id = "OlhoLaser", nome = "Olho Laser", raridade = "Raro", preco = 2000, renda = 60, icone = "👁️", visual = {
		pele = PELE_CLARA, cabelo = CASTANHO, camisa = rgb(30, 40, 90), calca = rgb(30, 40, 90), botas = rgb(255, 200, 0), maos = rgb(255, 200, 0),
		cabeca = "cabelo", rosto = "viseira", corpo = { "cintoUtilidade" } } },
	{ id = "GarotaInvisivel", nome = "Garota Invisível", raridade = "Raro", preco = 2800, renda = 80, icone = "🫥", visual = {
		pele = PELE_CLARA, cabelo = LOIRO, estiloCabelo = "longo", camisa = rgb(40, 90, 200), calca = rgb(40, 90, 200), botas = PRETO,
		maos = PRETO, cabeca = "cabelo", transparencia = 0.45, corpo = { "cintoUtilidade" }, cintoCor = PRETO } },
	{ id = "ChamaViva", nome = "Chama Viva", raridade = "Raro", preco = 3800, renda = 105, icone = "🔥", visual = {
		pele = rgb(255, 130, 30), camisa = rgb(255, 90, 10), calca = rgb(255, 120, 20), botas = rgb(255, 180, 40), maos = rgb(255, 160, 40),
		material = "Neon", cabeca = "cabecaFogo", corpo = { "chamas" } } },
	{ id = "GiganteDePedra", nome = "Gigante de Pedra", raridade = "Raro", preco = 5000, renda = 135, icone = "🪨", visual = {
		pele = rgb(220, 120, 50), camisa = rgb(220, 120, 50), calca = rgb(40, 60, 160), botas = rgb(220, 120, 50), maos = rgb(220, 120, 50),
		material = "Concrete", largo = true, cabeca = "cabecaPedra", corpo = { "corpoPedra" } } },
	{ id = "AndroideRubro", nome = "Androide Rubro", raridade = "Raro", preco = 6500, renda = 170, icone = "💎", visual = {
		pele = rgb(200, 40, 50), camisa = rgb(40, 120, 70), calca = rgb(40, 120, 70), botas = rgb(200, 160, 40), maos = rgb(200, 40, 50),
		cabeca = "androide", corpo = { "linhasDouradas" }, capa = rgb(230, 180, 40) } },
	{ id = "CorvoMistico", nome = "Corvo Místico", raridade = "Raro", preco = 8500, renda = 210, icone = "🐦‍⬛", visual = {
		pele = rgb(215, 195, 230), cabelo = rgb(60, 40, 120), camisa = rgb(40, 30, 90), calca = rgb(30, 25, 70), botas = rgb(30, 25, 70),
		cabeca = "capuzCorvo", cabecaCor = rgb(50, 40, 110), capa = rgb(50, 40, 110), corpo = { "cintoUtilidade" } } },

	-- Épico
	{ id = "BruxaRubi", nome = "Bruxa Rubi", raridade = "Epico", preco = 15000, renda = 350, icone = "🔴", visual = {
		pele = PELE_CLARA, cabelo = rgb(150, 50, 30), camisa = rgb(170, 20, 40), calca = rgb(80, 10, 20), botas = rgb(170, 20, 40),
		maos = rgb(170, 20, 40), cabeca = "tiaraBruxa", capa = rgb(140, 15, 35), mao = "energiaVermelha" } },
	{ id = "CapitaCosmica", nome = "Capitã Cósmica", raridade = "Epico", preco = 22000, renda = 480, icone = "⭐", visual = {
		pele = PELE_CLARA, cabelo = LOIRO, camisa = rgb(190, 25, 35), calca = rgb(30, 50, 140), botas = rgb(190, 25, 35), maos = rgb(190, 25, 35),
		cabeca = "cabelo", corpo = { "faixaAzul" }, emblema = "estrelaDourada", mao = "punhoEnergia" } },
	{ id = "LanternaEsmeralda", nome = "Lanterna Esmeralda", raridade = "Epico", preco = 30000, renda = 620, icone = "💚", visual = {
		pele = PELE_MEDIA, cabelo = CASTANHO, camisa = rgb(30, 170, 70), mangas = rgb(25, 25, 30), calca = rgb(25, 25, 30), botas = rgb(30, 170, 70),
		maos = BRANCO, cabeca = "cabelo", rosto = "mascaraDomino", mascaraCor = rgb(30, 170, 70), emblema = "lanterna", mao = "anelVerde" } },
	{ id = "GataNoturna", nome = "Gata Noturna", raridade = "Epico", preco = 42000, renda = 800, icone = "🐈‍⬛", visual = {
		pele = PELE_CLARA, camisa = rgb(28, 28, 34), calca = rgb(28, 28, 34), botas = PRETO, maos = PRETO,
		cabeca = "capuzGata", mao = "chicote", corpo = { "cintoUtilidade" }, cintoCor = rgb(70, 70, 80) } },
	{ id = "LordeGalactico", nome = "Lorde Galáctico", raridade = "Epico", preco = 58000, renda = 1050, icone = "🚀", visual = {
		pele = PELE_CLARA, camisa = rgb(120, 30, 30), calca = rgb(40, 35, 45), botas = PRETO, maos = PRETO,
		cabeca = "mascaraLorde", corpo = { "casaco" }, mao = "blasters" } },

	-- Lendário
	{ id = "AranhaEscarlate", nome = "Aranha Escarlate", raridade = "Lendario", preco = 100000, renda = 1600, icone = "🕷️", visual = {
		pele = PELE_CLARA, camisa = rgb(210, 25, 35), calca = rgb(30, 60, 170), botas = rgb(210, 25, 35), maos = rgb(210, 25, 35),
		cabeca = "capuzAranha", cabecaCor = rgb(210, 25, 35), corpo = { "teia" }, emblema = "aranha" } },
	{ id = "CavaleiroMorcego", nome = "Cavaleiro Morcego", raridade = "Lendario", preco = 140000, renda = 2100, icone = "🦇", visual = {
		pele = PELE_MEDIA, camisa = rgb(35, 32, 45), calca = rgb(22, 20, 28), botas = PRETO, maos = PRETO,
		cabeca = "capuzMorcego", cabecaCor = rgb(22, 20, 28), corpo = { "cintoUtilidade" }, cintoCor = rgb(120, 60, 220),
		emblema = "morcego", capa = rgb(40, 18, 70) } },
	{ id = "CapitaoEstrela", nome = "Capitão Estrela", raridade = "Lendario", preco = 190000, renda = 2700, icone = "🛡️", visual = {
		pele = PELE_CLARA, camisa = rgb(30, 60, 170), calca = rgb(30, 60, 170), botas = rgb(200, 30, 30), maos = rgb(120, 80, 45),
		cabeca = "capaceteEstrela", cabecaCor = rgb(30, 60, 170), corpo = { "listrasPeito" }, emblema = "estrela", maoEsquerda = "escudo" } },
	{ id = "RaioVeloz", nome = "Raio Veloz", raridade = "Lendario", preco = 260000, renda = 3500, icone = "⚡", visual = {
		pele = PELE_CLARA, camisa = rgb(200, 20, 25), calca = rgb(200, 20, 25), botas = rgb(255, 200, 0), maos = rgb(200, 20, 25),
		cabeca = "orelhasRaio", cabecaCor = rgb(200, 20, 25), emblema = "raio" } },
	{ id = "SimbionteSombrio", nome = "Simbionte Sombrio", raridade = "Lendario", preco = 350000, renda = 4500, icone = "🕸️", visual = {
		pele = rgb(20, 20, 25), camisa = rgb(20, 20, 25), calca = rgb(20, 20, 25), botas = rgb(20, 20, 25), maos = rgb(20, 20, 25),
		largo = true, cabeca = "capuzSimbionte", emblema = "aranha", emblemaCor = BRANCO } },

	-- Mítico
	{ id = "TitaEsmeralda", nome = "Titã Esmeralda", raridade = "Mitico", preco = 700000, renda = 8000, icone = "💪", visual = {
		pele = rgb(70, 170, 70), cabelo = PRETO, camisa = rgb(70, 170, 70), calca = rgb(110, 50, 150), botas = rgb(70, 170, 70),
		cabeca = "cabelo", largo = true } },
	{ id = "GuardiaoTrovao", nome = "Guardião do Trovão", raridade = "Mitico", preco = 1000000, renda = 11000, icone = "🔨", visual = {
		pele = PELE_CLARA, cabelo = LOIRO, camisa = rgb(70, 75, 90), calca = rgb(25, 25, 32), botas = rgb(120, 125, 135),
		maos = rgb(150, 155, 165), cabeca = "elmoTrovao", corpo = { "discosPeito" }, capa = rgb(190, 20, 25), mao = "martelo" } },
	{ id = "AmazonaDourada", nome = "Amazona Dourada", raridade = "Mitico", preco = 1400000, renda = 15000, icone = "👑", visual = {
		pele = PELE_MORENA, cabelo = PRETO, camisa = rgb(180, 20, 30), calca = rgb(180, 20, 30), botas = rgb(180, 20, 30),
		maos = rgb(200, 205, 215), cabeca = "tiara", corpo = { "armaduraOuro" }, mao = "laco" } },
	{ id = "CapitaoRelampago", nome = "Capitão Relâmpago", raridade = "Mitico", preco = 2000000, renda = 20000, icone = "💥", visual = {
		pele = PELE_MEDIA, cabelo = PRETO, camisa = rgb(190, 20, 25), calca = rgb(190, 20, 25), botas = rgb(255, 200, 40),
		maos = rgb(255, 200, 40), cabeca = "cabelo", emblema = "raioPeito", capa = rgb(245, 245, 240), corpo = { "cintoUtilidade" } } },

	-- Divino
	{ id = "ArmaduraRubi", nome = "Armadura Rubi", raridade = "Divino", preco = 5000000, renda = 45000, icone = "🤖", visual = {
		pele = PELE_CLARA, camisa = rgb(170, 20, 25), calca = rgb(170, 20, 25), botas = rgb(255, 190, 40), maos = rgb(255, 190, 40),
		material = "Metal", cabeca = "capaceteArmadura", cabecaCor = rgb(170, 20, 25), emblema = "reator" } },
	{ id = "FenixCosmica", nome = "Fênix Cósmica", raridade = "Divino", preco = 8000000, renda = 70000, icone = "🌟", visual = {
		pele = PELE_CLARA, cabelo = rgb(220, 50, 20), camisa = rgb(220, 40, 20), calca = rgb(220, 40, 20), botas = rgb(255, 190, 40),
		maos = rgb(255, 190, 40), cabeca = "cabeloChamas", emblema = "fenix", corpo = { "chamas", "cintoUtilidade" } } },

	-- Secreto
	{ id = "HeroiSupremo", nome = "Herói Supremo", raridade = "Secreto", preco = 25000000, renda = 200000, icone = "🦸", visual = {
		pele = PELE_CLARA, cabelo = PRETO, estiloCabelo = "cacho", camisa = rgb(30, 80, 200), calca = rgb(30, 80, 200),
		botas = rgb(200, 25, 30), maos = rgb(30, 80, 200), cabeca = "cabelo", emblema = "supremo", capa = rgb(200, 25, 30) } },
	{ id = "ViajantePrata", nome = "Viajante de Prata", raridade = "Secreto", preco = 50000000, renda = 380000, icone = "🏄", visual = {
		pele = rgb(205, 210, 220), camisa = rgb(205, 210, 220), calca = rgb(205, 210, 220), botas = rgb(205, 210, 220),
		maos = rgb(205, 210, 220), material = "Foil", mao = "prancha" } },
}

-- Heróis da versão antiga do jogo viram os novos (para ninguém perder o que salvou)
Config.IdsAntigos = {
	GarotoBolha = "FormigaAtomica", GarotaMola = "FlechaCerteira", CapitaoChinelo = "ReiDosMares", SenhorPipoca = "AgenteSombra",
	Ventania = "PanteraReal", DoutorGelinho = "MagoSupremo", Faisca = "CiborgueMax", EscudeiroMirim = "GarraSelvagem",
	Trovoada = "OlhoLaser", LaminaNoturna = "GarotaInvisivel", PunhoDeAco = "ChamaViva", SombraVeloz = "GiganteDePedra",
	CapitaoCometa = "BruxaRubi", FenixRubra = "CapitaCosmica", GuardiaoEsmeralda = "LanternaEsmeralda",
	TitaDourado = "AranhaEscarlate", DamaDoRelampago = "CavaleiroMorcego", CoronelGalaxia = "CapitaoEstrela",
	ImperadorSolar = "TitaEsmeralda", RainhaNebulosa = "GuardiaoTrovao", ArcanjoSupremo = "ArmaduraRubi",
	OraculoEterno = "FenixCosmica", HeroiDesconhecido = "HeroiSupremo", MestreMultiverso = "ViajantePrata",
}

--------------------------------------------------------------------------
-- LUVAS (compradas na tenda da Loja). A Básica todo mundo já tem.
-- forca = empurrão do soco | alcance = distância | recarga = segundos entre socos
-- atordoar = segundos que a vítima fica caída
--------------------------------------------------------------------------
Config.Luvas = {
	{ id = "Basica", nome = "Luva Básica", icone = "🥊", preco = 0, forca = 75, alcance = 8, recarga = 0.8, atordoar = 0.8,
		cor = rgb(215, 30, 30), corPunho = BRANCO, corDetalhe = rgb(30, 30, 30) },
	{ id = "Ferro", nome = "Luva de Ferro", icone = "🔩", preco = 5000, forca = 95, alcance = 9, recarga = 0.75, atordoar = 1.0,
		cor = rgb(170, 175, 185), corPunho = rgb(60, 60, 70), corDetalhe = rgb(255, 200, 40), material = "Metal" },
	{ id = "Turbo", nome = "Luva Turbo", icone = "💨", preco = 50000, forca = 115, alcance = 10, recarga = 0.65, atordoar = 1.2,
		cor = rgb(30, 110, 255), corPunho = rgb(20, 30, 60), corDetalhe = rgb(80, 240, 255), neon = true },
	{ id = "Trovao", nome = "Luva Trovão", icone = "⚡", preco = 500000, forca = 140, alcance = 11, recarga = 0.55, atordoar = 1.4,
		cor = rgb(255, 200, 0), corPunho = rgb(25, 25, 30), corDetalhe = rgb(255, 255, 150), neon = true, particulas = rgb(255, 240, 120) },
	{ id = "Cosmica", nome = "Luva Cósmica", icone = "🌌", preco = 5000000, forca = 170, alcance = 12.5, recarga = 0.45, atordoar = 1.7,
		cor = rgb(120, 40, 220), corPunho = rgb(20, 10, 40), corDetalhe = rgb(255, 120, 255), material = "Neon", neon = true,
		particulas = rgb(200, 120, 255) },
}

--------------------------------------------------------------------------
-- MELHORIAS (compradas na tenda da Loja)
--------------------------------------------------------------------------
Config.Melhorias = {
	{
		id = "Velocidade",
		nome = "Mola Turbo",
		icone = "🌀",
		precos = { 300, 1500, 6000, 25000, 100000, 400000, 1500000, 6000000, 25000000, 100000000 },
	},
	{
		id = "Pedestais",
		nome = "Mais Pedestais",
		icone = "🏛️",
		precos = { 800, 5000, 30000, 150000, 700000, 3000000, 12000000, 50000000, 200000000 },
	},
	{
		id = "Tranca",
		nome = "Tranca Reforçada",
		icone = "🔒",
		precos = { 1500, 12000, 90000, 700000, 5000000, 40000000 },
	},
	{
		id = "Coletor",
		nome = "Coletor Automático",
		icone = "🧲",
		precos = { 250000 },
	},
}

function Config.velocidadeDoNivel(nivel)
	return 16 + 2 * nivel
end

function Config.puloDoNivel(nivel)
	return 7.2 + 0.7 * nivel -- altura do pulo (a mola faz pular mais alto)
end

function Config.pedestaisDoNivel(nivel)
	return 6 + 2 * nivel -- de 6 até 24 (3 andares com 8 pedestais)
end

function Config.trancaDoNivel(nivel)
	return 30 + 10 * nivel
end

-- Texto mostrado na Loja para cada melhoria
function Config.descricaoMelhoria(id, nivel)
	if id == "Velocidade" then
		return "Velocidade " .. Config.velocidadeDoNivel(nivel) .. " e pulo mais alto"
	elseif id == "Pedestais" then
		return Config.pedestaisDoNivel(nivel) .. " pedestais na base"
	elseif id == "Tranca" then
		return "Tranca dura " .. Config.trancaDoNivel(nivel) .. "s"
	elseif id == "Coletor" then
		return nivel > 0 and "Dinheiro cai direto na conta" or "Coleta tudo sozinho"
	end
	return ""
end

--------------------------------------------------------------------------
-- ROLETA DA SORTE (gira a cada 12 horas)
-- tipo: dinheiro (minutos de renda, com valor mínimo), boostRenda, boostVelocidade,
--       heroi (raridade), girarDeNovo | peso = chance
--------------------------------------------------------------------------
Config.Roleta = {
	IntervaloHoras = 12,
	DuracaoGiro = 6,
	Premios = {
		{ id = "MoedasP", nome = "Saquinho de Moedas", curto = "$", icone = "💰", cor = rgb(80, 200, 90), peso = 30, tipo = "dinheiro", minutos = 3, minimo = 1000 },
		{ id = "Renda2x", nome = "Renda 2x por 15 min", curto = "2x", icone = "⚡", cor = rgb(255, 200, 40), peso = 15, tipo = "boostRenda", minutos = 15 },
		{ id = "HeroiEpico", nome = "Herói Épico", curto = "Épico", icone = "🦸", cor = rgb(170, 80, 255), peso = 12, tipo = "heroi", raridade = "Epico" },
		{ id = "MoedasM", nome = "Cofre de Moedas", curto = "$$", icone = "🏦", cor = rgb(40, 170, 220), peso = 20, tipo = "dinheiro", minutos = 15, minimo = 5000 },
		{ id = "Velocidade", nome = "Super velocidade por 10 min", curto = "Rápido", icone = "🌀", cor = rgb(60, 220, 200), peso = 10, tipo = "boostVelocidade", minutos = 10 },
		{ id = "HeroiLendario", nome = "Herói Lendário", curto = "Lendário", icone = "🌟", cor = rgb(255, 140, 30), peso = 3, tipo = "heroi", raridade = "Lendario" },
		{ id = "MoedasG", nome = "Tesouro de Moedas", curto = "$$$", icone = "💎", cor = rgb(230, 60, 130), peso = 6, tipo = "dinheiro", minutos = 45, minimo = 25000 },
		{ id = "GirarDeNovo", nome = "Gire de novo!", curto = "+1", icone = "🔁", cor = rgb(90, 110, 255), peso = 4, tipo = "girarDeNovo" },
	},
}

--------------------------------------------------------------------------
-- RENASCIMENTO
--------------------------------------------------------------------------
Config.Renascimento = {
	CustoBase = 1000000,
	CrescimentoCusto = 4, -- cada renascimento custa 4x o anterior
	BonusPorRenascimento = 0.5, -- +50% de renda por renascimento
}

function Config.custoRenascimento(renascimentos)
	return Config.Renascimento.CustoBase * Config.Renascimento.CrescimentoCusto ^ renascimentos
end

function Config.multiplicadorRenascimento(renascimentos)
	return 1 + Config.Renascimento.BonusPorRenascimento * renascimentos
end

function Config.dinheiroInicial(renascimentos)
	return Config.Geral.DinheiroInicial * (1 + 2 * renascimentos)
end

--------------------------------------------------------------------------
-- RECOMPENSA DIÁRIA
--------------------------------------------------------------------------
Config.Diaria = {
	IntervaloHoras = 20,
	PerdeSequenciaHoras = 48,
	ValorBase = 200,
}

function Config.recompensaDiaria(dia, renascimentos)
	local bonusDia7 = dia == 7 and 2 or 1
	return math.floor(Config.Diaria.ValorBase * dia * bonusDia7 * (1 + renascimentos))
end

--------------------------------------------------------------------------
-- EVENTOS (um sorteado a cada IntervaloEventoMinutos)
--------------------------------------------------------------------------
Config.Eventos = {
	{ id = "HoraDourada", nome = "HORA DOURADA", icone = "✨", descricao = "Mutações 4x mais comuns!",
		cor = Color3.fromRGB(255, 200, 40), multMutacao = 4 },
	{ id = "InvasaoLendaria", nome = "INVASÃO LENDÁRIA", icone = "🌟", descricao = "Heróis Lendários ou melhores 5x mais comuns!",
		cor = Color3.fromRGB(255, 120, 40), multRaros = 5 },
	{ id = "ChuvaDeHerois", nome = "CHUVA DE HERÓIS", icone = "🌧️", descricao = "Heróis saem do portal 2x mais rápido!",
		cor = Color3.fromRGB(80, 170, 255), multSpawn = 2 },
	{ id = "RendaDobrada", nome = "RENDA EM DOBRO", icone = "💸", descricao = "Todos os heróis rendem 2x!",
		cor = Color3.fromRGB(60, 220, 100), multRenda = 2 },
}

--------------------------------------------------------------------------
-- ROBUX (opcional) - crie no Creator Dashboard e cole os IDs. 0 = desligado
--------------------------------------------------------------------------
Config.Robux = {
	PasseDinheiroDobrado = 0, -- ID do Game Pass "Dinheiro em Dobro"
	Produtos = {
		{ id = 0, nome = "Saco de Moedas", icone = "💰", valorBase = 5000 },
		{ id = 0, nome = "Cofre Heroico", icone = "🏦", valorBase = 50000 },
		{ id = 0, nome = "Tesouro Lendário", icone = "👑", valorBase = 500000 },
	},
}

function Config.valorProduto(produto, renascimentos)
	return produto.valorBase * (1 + renascimentos)
end

--------------------------------------------------------------------------
-- FUNÇÕES DE AJUDA (não precisa mexer)
--------------------------------------------------------------------------
local SUFIXOS = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp" }

function Config.formatarNumero(numero)
	numero = math.floor(numero or 0)
	if numero < 0 then
		return "-" .. Config.formatarNumero(-numero)
	end
	if numero < 1000 then
		return tostring(numero)
	end
	local valor = numero
	local i = 0
	-- 999.95 em vez de 1000 para 999999 virar "1M" e não "1000K"
	while valor >= 999.95 and i < #SUFIXOS do
		valor /= 1000
		i += 1
	end
	local texto = string.format("%.1f", valor):gsub("%.0$", "")
	return texto .. SUFIXOS[i]
end

function Config.formatar(numero)
	return "$" .. Config.formatarNumero(numero)
end

function Config.formatarTempo(segundos)
	segundos = math.max(0, math.floor(segundos))
	local h = math.floor(segundos / 3600)
	local m = math.floor((segundos % 3600) / 60)
	local s = segundos % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

-- Tabelas de busca rápida
Config.RaridadePorId = {}
for ordem, raridade in Config.Raridades do
	raridade.ordem = ordem
	raridade.quantidade = 0
	Config.RaridadePorId[raridade.id] = raridade
end

Config.MutacaoPorId = {}
for _, mutacao in Config.Mutacoes do
	Config.MutacaoPorId[mutacao.id] = mutacao
end

Config.HeroiPorId = {}
for ordem, heroi in Config.Herois do
	heroi.ordem = ordem
	Config.HeroiPorId[heroi.id] = heroi
	local raridade = Config.RaridadePorId[heroi.raridade]
	raridade.quantidade += 1
end

Config.MelhoriaPorId = {}
for _, melhoria in Config.Melhorias do
	Config.MelhoriaPorId[melhoria.id] = melhoria
end

Config.LuvaPorId = {}
for ordem, luva in Config.Luvas do
	luva.ordem = ordem
	Config.LuvaPorId[luva.id] = luva
end

Config.PremioPorId = {}
for indice, premio in Config.Roleta.Premios do
	premio.indice = indice
	Config.PremioPorId[premio.id] = premio
end

Config.EventoPorId = {}
for _, evento in Config.Eventos do
	Config.EventoPorId[evento.id] = evento
end

return Config
