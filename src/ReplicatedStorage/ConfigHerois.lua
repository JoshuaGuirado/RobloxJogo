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
-- HERÓIS
-- cabeca: "mascara", "capacete", "coroa" ou "antena"
-- renda = dinheiro por segundo
--------------------------------------------------------------------------
local PELE_CLARA = Color3.fromRGB(255, 214, 180)
local PELE_MEDIA = Color3.fromRGB(224, 172, 120)
local PELE_MORENA = Color3.fromRGB(170, 110, 70)
local PELE_ESCURA = Color3.fromRGB(110, 70, 45)

local function cores(traje, capa, emblema, pele, botas)
	return { traje = traje, capa = capa, emblema = emblema, pele = pele, botas = botas }
end
local rgb = Color3.fromRGB

Config.Herois = {
	-- Comum
	{ id = "GarotoBolha", nome = "Garoto Bolha", raridade = "Comum", preco = 25, renda = 1, icone = "🫧", cabeca = "mascara",
		cores = cores(rgb(90, 180, 255), rgb(255, 255, 255), rgb(200, 240, 255), PELE_CLARA, rgb(40, 90, 170)) },
	{ id = "GarotaMola", nome = "Garota Mola", raridade = "Comum", preco = 40, renda = 2, icone = "🌀", cabeca = "mascara",
		cores = cores(rgb(255, 120, 180), rgb(120, 60, 160), rgb(255, 230, 0), PELE_MORENA, rgb(120, 60, 160)) },
	{ id = "CapitaoChinelo", nome = "Capitão Chinelo", raridade = "Comum", preco = 60, renda = 3, icone = "🩴", cabeca = "capacete",
		cores = cores(rgb(60, 140, 60), rgb(230, 60, 60), rgb(255, 255, 255), PELE_MEDIA, rgb(230, 60, 60)) },
	{ id = "SenhorPipoca", nome = "Senhor Pipoca", raridade = "Comum", preco = 90, renda = 4, icone = "🍿", cabeca = "antena",
		cores = cores(rgb(255, 230, 150), rgb(220, 40, 40), rgb(255, 255, 255), PELE_CLARA, rgb(220, 40, 40)) },

	-- Incomum
	{ id = "Ventania", nome = "Ventania", raridade = "Incomum", preco = 200, renda = 8, icone = "🌪️", cabeca = "mascara",
		cores = cores(rgb(170, 220, 230), rgb(40, 90, 140), rgb(255, 255, 255), PELE_ESCURA, rgb(40, 90, 140)) },
	{ id = "DoutorGelinho", nome = "Doutor Gelinho", raridade = "Incomum", preco = 300, renda = 12, icone = "❄️", cabeca = "capacete",
		cores = cores(rgb(180, 230, 255), rgb(40, 120, 200), rgb(255, 255, 255), PELE_CLARA, rgb(40, 120, 200)) },
	{ id = "Faisca", nome = "Faísca", raridade = "Incomum", preco = 450, renda = 17, icone = "⚡", cabeca = "mascara",
		cores = cores(rgb(255, 210, 0), rgb(30, 30, 30), rgb(255, 120, 0), PELE_MEDIA, rgb(30, 30, 30)) },
	{ id = "EscudeiroMirim", nome = "Escudeiro Mirim", raridade = "Incomum", preco = 600, renda = 22, icone = "🛡️", cabeca = "capacete",
		cores = cores(rgb(40, 70, 170), rgb(200, 30, 30), rgb(255, 255, 255), PELE_MORENA, rgb(200, 30, 30)) },

	-- Raro
	{ id = "Trovoada", nome = "Trovoada", raridade = "Raro", preco = 1200, renda = 40, icone = "🌩️", cabeca = "antena",
		cores = cores(rgb(60, 60, 90), rgb(120, 160, 255), rgb(255, 255, 120), PELE_ESCURA, rgb(120, 160, 255)) },
	{ id = "LaminaNoturna", nome = "Lâmina Noturna", raridade = "Raro", preco = 1800, renda = 55, icone = "🗡️", cabeca = "mascara",
		cores = cores(rgb(25, 25, 35), rgb(90, 0, 0), rgb(255, 40, 40), PELE_CLARA, rgb(90, 0, 0)) },
	{ id = "PunhoDeAco", nome = "Punho de Aço", raridade = "Raro", preco = 2500, renda = 75, icone = "👊", cabeca = "capacete",
		cores = cores(rgb(150, 150, 160), rgb(255, 140, 0), rgb(255, 200, 0), PELE_MEDIA, rgb(80, 80, 90)) },
	{ id = "SombraVeloz", nome = "Sombra Veloz", raridade = "Raro", preco = 3500, renda = 100, icone = "💨", cabeca = "mascara",
		cores = cores(rgb(80, 40, 120), rgb(20, 20, 20), rgb(200, 120, 255), PELE_MORENA, rgb(20, 20, 20)) },

	-- Épico
	{ id = "CapitaoCometa", nome = "Capitão Cometa", raridade = "Epico", preco = 8000, renda = 200, icone = "☄️", cabeca = "capacete",
		cores = cores(rgb(30, 60, 150), rgb(255, 120, 0), rgb(255, 220, 0), PELE_CLARA, rgb(255, 120, 0)) },
	{ id = "FenixRubra", nome = "Fênix Rubra", raridade = "Epico", preco = 12000, renda = 300, icone = "🔥", cabeca = "coroa",
		cores = cores(rgb(220, 40, 20), rgb(255, 170, 0), rgb(255, 230, 120), PELE_MEDIA, rgb(255, 170, 0)) },
	{ id = "GuardiaoEsmeralda", nome = "Guardião Esmeralda", raridade = "Epico", preco = 18000, renda = 420, icone = "💚", cabeca = "mascara",
		cores = cores(rgb(20, 160, 80), rgb(10, 60, 30), rgb(120, 255, 160), PELE_ESCURA, rgb(10, 60, 30)) },

	-- Lendário
	{ id = "TitaDourado", nome = "Titã Dourado", raridade = "Lendario", preco = 50000, renda = 1000, icone = "🏆", cabeca = "coroa",
		cores = cores(rgb(230, 180, 30), rgb(130, 20, 20), rgb(255, 255, 255), PELE_MORENA, rgb(130, 20, 20)) },
	{ id = "DamaDoRelampago", nome = "Dama do Relâmpago", raridade = "Lendario", preco = 80000, renda = 1500, icone = "🌟", cabeca = "antena",
		cores = cores(rgb(250, 250, 255), rgb(90, 130, 255), rgb(255, 230, 0), PELE_CLARA, rgb(90, 130, 255)) },
	{ id = "CoronelGalaxia", nome = "Coronel Galáxia", raridade = "Lendario", preco = 120000, renda = 2200, icone = "🪐", cabeca = "capacete",
		cores = cores(rgb(40, 20, 80), rgb(200, 60, 255), rgb(120, 255, 255), PELE_ESCURA, rgb(200, 60, 255)) },

	-- Mítico
	{ id = "ImperadorSolar", nome = "Imperador Solar", raridade = "Mitico", preco = 400000, renda = 6000, icone = "☀️", cabeca = "coroa",
		cores = cores(rgb(255, 150, 0), rgb(255, 240, 120), rgb(255, 255, 255), PELE_MEDIA, rgb(200, 80, 0)) },
	{ id = "RainhaNebulosa", nome = "Rainha Nebulosa", raridade = "Mitico", preco = 650000, renda = 9000, icone = "🌌", cabeca = "coroa",
		cores = cores(rgb(120, 60, 200), rgb(255, 100, 200), rgb(150, 255, 255), PELE_ESCURA, rgb(255, 100, 200)) },

	-- Divino
	{ id = "ArcanjoSupremo", nome = "Arcanjo Supremo", raridade = "Divino", preco = 2000000, renda = 25000, icone = "😇", cabeca = "coroa",
		cores = cores(rgb(255, 255, 255), rgb(255, 215, 0), rgb(255, 240, 150), PELE_CLARA, rgb(255, 215, 0)) },
	{ id = "OraculoEterno", nome = "Oráculo Eterno", raridade = "Divino", preco = 3500000, renda = 40000, icone = "🔮", cabeca = "antena",
		cores = cores(rgb(60, 0, 90), rgb(0, 255, 200), rgb(255, 255, 255), PELE_MORENA, rgb(0, 255, 200)) },

	-- Secreto
	{ id = "HeroiDesconhecido", nome = "O Herói Desconhecido", raridade = "Secreto", preco = 15000000, renda = 150000, icone = "❓", cabeca = "mascara",
		cores = cores(rgb(15, 15, 15), rgb(255, 0, 60), rgb(255, 0, 60), PELE_MEDIA, rgb(255, 0, 60)) },
	{ id = "MestreMultiverso", nome = "Mestre Multiverso", raridade = "Secreto", preco = 30000000, renda = 280000, icone = "♾️", cabeca = "capacete",
		cores = cores(rgb(0, 0, 0), rgb(0, 200, 255), rgb(255, 255, 255), PELE_ESCURA, rgb(0, 200, 255)) },
}

--------------------------------------------------------------------------
-- MELHORIAS (Loja)
--------------------------------------------------------------------------
Config.Melhorias = {
	{
		id = "Velocidade",
		nome = "Botas Turbo",
		icone = "👟",
		precos = { 300, 1500, 6000, 25000, 100000, 400000, 1500000, 6000000, 25000000, 100000000 },
	},
	{
		id = "Pedestais",
		nome = "Mais Pedestais",
		icone = "🏛️",
		precos = { 800, 5000, 30000, 200000, 1200000, 8000000 },
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

function Config.pedestaisDoNivel(nivel)
	return 6 + nivel
end

function Config.trancaDoNivel(nivel)
	return 30 + 10 * nivel
end

-- Texto mostrado na Loja para cada melhoria
function Config.descricaoMelhoria(id, nivel)
	if id == "Velocidade" then
		return "Velocidade " .. Config.velocidadeDoNivel(nivel)
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

Config.EventoPorId = {}
for _, evento in Config.Eventos do
	Config.EventoPorId[evento.id] = evento
end

return Config
