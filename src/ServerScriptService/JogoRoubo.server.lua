--[[
	ROUBE UM PERSONAGEM - script principal (servidor)

	Onde colocar: ServerScriptService -> Script (nome: JogoRoubo)

	Este script monta o mapa sozinho (passarela + bases) e cuida de toda a logica:
	  - dinheiro de cada jogador (leaderstats)
	  - personagens andando na passarela para comprar
	  - renda por segundo dos personagens que estao na sua base
	  - roubar personagens da base dos outros e levar para a sua
	  - vender personagens
	  - trancar a base por alguns segundos
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

--------------------------------------------------------------------------
-- CONFIGURACOES (mude a vontade)
--------------------------------------------------------------------------
local CONFIG = {
	DinheiroInicial = 100,
	IntervaloSpawn = 3, -- segundos entre cada personagem que aparece na passarela
	VelocidadePassarela = 8, -- velocidade dos personagens andando (studs por segundo)
	ComprimentoPassarela = 260,
	TempoTrancado = 60, -- segundos que a base fica trancada
	RecargaTranca = 15, -- espera depois de destrancar para poder trancar de novo
	TempoParaRoubar = 1.5, -- segundos segurando a tecla para roubar
	VelocidadeNormal = 16,
	VelocidadeCarregando = 11, -- quem carrega um personagem roubado fica mais lento
	DistanciaRecuperar = 6, -- o dono recupera o personagem se chegar perto assim do ladrao
	PorcentagemVenda = 0.5, -- vender devolve 50% do preco
	AlturaDoChao = 0, -- altura do topo do Baseplate
}

-- chance = peso do sorteio (quanto maior, mais aparece)
local RARIDADES = {
	Comum = { nome = "Comum", cor = Color3.fromRGB(200, 200, 200), chance = 60 },
	Raro = { nome = "Raro", cor = Color3.fromRGB(70, 150, 255), chance = 25 },
	Epico = { nome = "Épico", cor = Color3.fromRGB(170, 80, 255), chance = 10 },
	Lendario = { nome = "Lendário", cor = Color3.fromRGB(255, 200, 40), chance = 4 },
	Mitico = { nome = "Mítico", cor = Color3.fromRGB(255, 60, 60), chance = 0.9 },
	Secreto = { nome = "SECRETO", cor = Color3.fromRGB(0, 255, 200), chance = 0.1 },
}

-- Adicione quantos personagens quiser! renda = dinheiro por segundo
local PERSONAGENS = {
	{ nome = "Batatinha Saltitante", raridade = "Comum", preco = 25, renda = 1, cor = Color3.fromRGB(222, 184, 135) },
	{ nome = "Chinelo Voador", raridade = "Comum", preco = 40, renda = 2, cor = Color3.fromRGB(80, 160, 80) },
	{ nome = "Pato de Gravata", raridade = "Raro", preco = 150, renda = 6, cor = Color3.fromRGB(255, 220, 0) },
	{ nome = "Melancia Ninja", raridade = "Raro", preco = 250, renda = 10, cor = Color3.fromRGB(40, 140, 40) },
	{ nome = "Sapo Astronauta", raridade = "Epico", preco = 1000, renda = 35, cor = Color3.fromRGB(90, 200, 90) },
	{ nome = "Pizza Dançarina", raridade = "Epico", preco = 1500, renda = 50, cor = Color3.fromRGB(240, 150, 50) },
	{ nome = "Tubarão de Tênis", raridade = "Lendario", preco = 5000, renda = 150, cor = Color3.fromRGB(100, 130, 170) },
	{ nome = "Capivara Rei", raridade = "Lendario", preco = 8000, renda = 250, cor = Color3.fromRGB(150, 100, 60) },
	{ nome = "Dragão de Pijama", raridade = "Mitico", preco = 25000, renda = 700, cor = Color3.fromRGB(200, 40, 40) },
	{ nome = "Bigodudo Supremo", raridade = "Secreto", preco = 100000, renda = 2500, cor = Color3.fromRGB(30, 30, 30) },
}

-- Tamanho do personagem de acordo com a raridade
local TAMANHO_POR_RARIDADE = {
	Comum = 2,
	Raro = 2.4,
	Epico = 2.8,
	Lendario = 3.2,
	Mitico = 3.6,
	Secreto = 4,
}

-- Posicao do centro de cada base (1 base por jogador)
local POSICOES_BASES = {
	Vector3.new(-70, 0, -50),
	Vector3.new(0, 0, -50),
	Vector3.new(70, 0, -50),
	Vector3.new(-70, 0, 50),
	Vector3.new(0, 0, 50),
	Vector3.new(70, 0, 50),
}

local CORES_BASES = {
	Color3.fromRGB(70, 120, 200),
	Color3.fromRGB(200, 80, 80),
	Color3.fromRGB(80, 170, 90),
	Color3.fromRGB(200, 160, 60),
	Color3.fromRGB(150, 90, 200),
	Color3.fromRGB(60, 180, 180),
}

--------------------------------------------------------------------------
-- ESTADO DO JOGO
--------------------------------------------------------------------------
local Y = CONFIG.AlturaDoChao
local METADE_BASE = 20 -- a base tem 40 x 40 studs

local bases = {} -- lista de bases
local basePorJogador = {} -- [jogador] = base
local personagens = {} -- [modelo] = dados do personagem
local carregando = {} -- [jogador] = dados do personagem que ele esta roubando

-- Peso de sorteio de cada personagem
for _, def in PERSONAGENS do
	local quantidade = 0
	for _, outro in PERSONAGENS do
		if outro.raridade == def.raridade then
			quantidade += 1
		end
	end
	def.peso = RARIDADES[def.raridade].chance / quantidade
	def.tamanho = TAMANHO_POR_RARIDADE[def.raridade]
end

--------------------------------------------------------------------------
-- FUNCOES DE AJUDA
--------------------------------------------------------------------------
local function formatar(numero)
	numero = math.floor(numero)
	local sufixos = { "", "K", "M", "B", "T" }
	local valor = numero
	local i = 1
	while valor >= 1000 and i < #sufixos do
		valor /= 1000
		i += 1
	end
	if i == 1 then
		return "$" .. numero
	end
	return string.format("$%.1f%s", valor, sufixos[i])
end

local function criarParte(propriedades)
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	for nome, valor in propriedades do
		if nome ~= "Parent" then
			parte[nome] = valor
		end
	end
	parte.Parent = propriedades.Parent
	return parte
end

local function criarTexto(pai, propriedades)
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.GothamBold
	texto.TextScaled = true
	texto.TextColor3 = Color3.new(1, 1, 1)
	texto.TextStrokeTransparency = 0
	texto.Size = UDim2.fromScale(1, 1)
	for nome, valor in propriedades do
		texto[nome] = valor
	end
	texto.Parent = pai
	return texto
end

-- Mostra uma mensagem na tela de um jogador
local function avisar(jogador, mensagem, cor)
	if not jogador or not jogador.Parent then
		return
	end
	local playerGui = jogador:FindFirstChild("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("HudRoubo")
	if not hud then
		return
	end
	local label = hud.Aviso
	local id = (label:GetAttribute("Id") or 0) + 1
	label:SetAttribute("Id", id)
	label.Text = mensagem
	label.TextColor3 = cor or Color3.new(1, 1, 1)
	label.Visible = true
	task.delay(3, function()
		if label:GetAttribute("Id") == id then
			label.Visible = false
		end
	end)
end

local VERDE = Color3.fromRGB(80, 255, 120)
local VERMELHO = Color3.fromRGB(255, 80, 80)
local AMARELO = Color3.fromRGB(255, 220, 60)

--------------------------------------------------------------------------
-- MAPA: PASSARELA
--------------------------------------------------------------------------
local pasta = workspace:FindFirstChild("JogoRoubo")
if pasta then
	pasta:Destroy()
end
pasta = Instance.new("Folder")
pasta.Name = "JogoRoubo"
pasta.Parent = workspace

local pastaPersonagens = Instance.new("Folder")
pastaPersonagens.Name = "Personagens"
pastaPersonagens.Parent = pasta

criarParte({
	Name = "Passarela",
	Size = Vector3.new(CONFIG.ComprimentoPassarela, 0.4, 12),
	CFrame = CFrame.new(0, Y + 0.2, 0),
	Color = Color3.fromRGB(170, 30, 50),
	Material = Enum.Material.Fabric,
	Parent = pasta,
})

-- Os personagens nascem no comeco da passarela e andam no sentido +X
local INICIO_PASSARELA = Vector3.new(-CONFIG.ComprimentoPassarela / 2, Y + 0.4, 0)

--------------------------------------------------------------------------
-- MAPA: BASES
--------------------------------------------------------------------------
local function atualizarBarreira(base, trancada)
	base.barreira.CanCollide = trancada
	base.barreira.Transparency = trancada and 0.4 or 1
end

local function construirBase(indice, posicao)
	posicao += Vector3.new(0, Y, 0)
	-- A frente da base aponta para a passarela (eixo -Z local)
	local cf = CFrame.lookAt(posicao, Vector3.new(posicao.X, posicao.Y, 0))
	local cor = CORES_BASES[(indice - 1) % #CORES_BASES + 1]

	local modelo = Instance.new("Model")
	modelo.Name = "Base" .. indice
	modelo.Parent = pasta

	criarParte({
		Name = "Chao",
		Size = Vector3.new(40, 1, 40),
		CFrame = cf * CFrame.new(0, 0.5, 0),
		Color = cor,
		Material = Enum.Material.SmoothPlastic,
		Parent = modelo,
	})

	local corParede = Color3.fromRGB(60, 60, 70)
	local paredes = {
		{ "ParedeFundo", Vector3.new(40, 14, 1), CFrame.new(0, 7, 19.5) },
		{ "ParedeEsquerda", Vector3.new(1, 14, 40), CFrame.new(-19.5, 7, 0) },
		{ "ParedeDireita", Vector3.new(1, 14, 40), CFrame.new(19.5, 7, 0) },
	}
	for _, info in paredes do
		criarParte({
			Name = info[1],
			Size = info[2],
			CFrame = cf * info[3],
			Color = corParede,
			Material = Enum.Material.Concrete,
			Parent = modelo,
		})
	end

	-- Barreira laser na frente (so aparece quando a base esta trancada)
	local barreira = criarParte({
		Name = "Barreira",
		Size = Vector3.new(38, 14, 0.5),
		CFrame = cf * CFrame.new(0, 7, -19.75),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})

	-- Grupos de colisao: a barreira bloqueia todo mundo, menos o dono da base
	local grupoBarreira = "Barreira" .. indice
	local grupoDono = "Dono" .. indice
	for _, grupo in { grupoBarreira, grupoDono } do
		if not PhysicsService:IsCollisionGroupRegistered(grupo) then
			PhysicsService:RegisterCollisionGroup(grupo)
		end
	end
	PhysicsService:CollisionGroupSetCollidable(grupoBarreira, grupoDono, false)
	barreira.CollisionGroup = grupoBarreira

	-- Placa com o nome do dono
	local placa = criarParte({
		Name = "Placa",
		Size = Vector3.new(24, 5, 1),
		CFrame = cf * CFrame.new(0, 16.5, 19.5),
		Color = Color3.fromRGB(30, 30, 35),
		Parent = modelo,
	})
	local guiPlaca = Instance.new("SurfaceGui")
	guiPlaca.Face = Enum.NormalId.Front
	guiPlaca.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	guiPlaca.PixelsPerStud = 40
	guiPlaca.Parent = placa
	local textoPlaca = criarTexto(guiPlaca, { Text = "Base livre" })

	-- Botao de trancar
	local botao = criarParte({
		Name = "BotaoTrancar",
		Size = Vector3.new(5, 0.4, 5),
		CFrame = cf * CFrame.new(-14, 1.2, -14),
		Color = Color3.fromRGB(60, 220, 90),
		Material = Enum.Material.Neon,
		Parent = modelo,
	})
	local guiBotao = Instance.new("BillboardGui")
	guiBotao.Size = UDim2.fromOffset(180, 40)
	guiBotao.StudsOffset = Vector3.new(0, 3, 0)
	guiBotao.MaxDistance = 60
	guiBotao.Parent = botao
	local textoBotao = criarTexto(guiBotao, { Text = "PISE PARA TRANCAR" })

	local base = {
		indice = indice,
		cframe = cf,
		modelo = modelo,
		slots = {},
		dono = nil,
		trancadaAte = 0,
		recargaAte = 0,
		barreira = barreira,
		textoPlaca = textoPlaca,
		textoBotao = textoBotao,
		grupoDono = grupoDono,
	}

	-- 8 pedestais (2 fileiras de 4)
	for _, z in { 0, 10 } do
		for _, x in { -15, -5, 5, 15 } do
			criarParte({
				Name = "Pedestal",
				Size = Vector3.new(6, 1, 6),
				CFrame = cf * CFrame.new(x, 1.5, z),
				Color = Color3.fromRGB(235, 235, 235),
				Material = Enum.Material.Marble,
				Parent = modelo,
			})
			table.insert(base.slots, {
				base = base,
				cframe = cf * CFrame.new(x, 2, z), -- topo do pedestal
				personagem = nil,
			})
		end
	end

	botao.Touched:Connect(function(parteQueTocou)
		local jogador = Players:GetPlayerFromCharacter(parteQueTocou.Parent)
		if not jogador or jogador ~= base.dono then
			return
		end
		local agora = os.clock()
		if agora < base.trancadaAte or agora < base.recargaAte then
			return
		end
		base.trancadaAte = agora + CONFIG.TempoTrancado
		base.recargaAte = base.trancadaAte + CONFIG.RecargaTranca
		atualizarBarreira(base, true)
		avisar(jogador, "Base trancada por " .. CONFIG.TempoTrancado .. " segundos!", VERDE)
	end)

	return base
end

for indice, posicao in POSICOES_BASES do
	table.insert(bases, construirBase(indice, posicao))
end

local function slotLivre(base)
	for _, slot in base.slots do
		if not slot.personagem then
			return slot
		end
	end
	return nil
end

local function dentroDaBase(base, posicao)
	local posicaoLocal = base.cframe:PointToObjectSpace(posicao)
	return math.abs(posicaoLocal.X) <= METADE_BASE and math.abs(posicaoLocal.Z) <= METADE_BASE
end

--------------------------------------------------------------------------
-- PERSONAGENS
--------------------------------------------------------------------------
local function removerPersonagem(dados)
	dados.estado = "removido"
	personagens[dados.modelo] = nil
	dados.modelo:Destroy()
end

local function limparPrompts(dados)
	for _, filho in dados.raiz:GetChildren() do
		if filho:IsA("ProximityPrompt") then
			filho:Destroy()
		end
	end
end

local function criarPrompt(dados, nome, acao, tecla, segurar, aoAtivar)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = nome
	prompt.ActionText = acao
	prompt.ObjectText = dados.def.nome
	prompt.KeyboardKeyCode = tecla
	prompt.HoldDuration = segurar
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = dados.raiz
	prompt.Triggered:Connect(function(jogador)
		aoAtivar(dados, jogador)
	end)
	return prompt
end

local aoRoubar, aoVender -- definidas mais abaixo

-- Coloca o personagem em um pedestal da base (andando ate la se animar = true)
local function colocarNaBase(dados, base, slot, animar)
	limparPrompts(dados)
	slot.personagem = dados
	dados.base = base
	dados.slot = slot
	dados.modelo:SetAttribute("DonoId", base.dono and base.dono.UserId or 0)
	dados.raiz.Anchored = true

	local destino = slot.cframe * CFrame.new(0, dados.def.tamanho, 0)
	local valorVenda = math.floor(dados.def.preco * CONFIG.PorcentagemVenda)

	local function finalizar()
		dados.estado = "base"
		dados.raiz.CFrame = destino
		criarPrompt(dados, "PromptRoubar", "Roubar", Enum.KeyCode.E, CONFIG.TempoParaRoubar, aoRoubar)
		criarPrompt(dados, "PromptVender", "Vender (" .. formatar(valorVenda) .. ")", Enum.KeyCode.F, 0.5, aoVender)
	end

	if animar then
		dados.estado = "indo"
		local tween = TweenService:Create(
			dados.raiz,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = destino }
		)
		tween.Completed:Connect(function()
			if dados.estado == "indo" then
				finalizar()
			end
		end)
		tween:Play()
	else
		finalizar()
	end
end

-- Solta o personagem das costas do ladrao. Retorna o slot que estava reservado na base do ladrao.
local function terminarCarregar(dados)
	local ladrao = dados.ladrao
	if dados.conexaoMorte then
		dados.conexaoMorte:Disconnect()
		dados.conexaoMorte = nil
	end
	dados.raiz.Anchored = true
	local solda = dados.raiz:FindFirstChild("SoldaRoubo")
	if solda then
		solda:Destroy()
	end
	if ladrao then
		carregando[ladrao] = nil
		local humanoid = ladrao.Character and ladrao.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = CONFIG.VelocidadeNormal
		end
	end
	dados.ladrao = nil
	local slotDestino = dados.slotDestino
	dados.slotDestino = nil
	return slotDestino
end

-- O roubo falhou: o personagem volta para a base de onde saiu
local function devolver(dados, motivo)
	if dados.estado ~= "carregado" then
		return
	end
	local ladrao = dados.ladrao
	local slotDestino = terminarCarregar(dados)
	if slotDestino then
		slotDestino.personagem = nil
	end
	if not dados.base or not dados.base.dono then
		-- o dono saiu do jogo: o personagem some
		removerPersonagem(dados)
		return
	end
	colocarNaBase(dados, dados.base, dados.slot, false)
	if motivo then
		avisar(ladrao, motivo, VERMELHO)
	end
	avisar(dados.base.dono, "Seu " .. dados.def.nome .. " voltou para a base!", VERDE)
end

-- O ladrao chegou na propria base: o personagem agora e dele
local function entregar(dados)
	local ladrao = dados.ladrao
	local donoAntigo = dados.base and dados.base.dono
	local slotDestino = terminarCarregar(dados)
	if dados.slot then
		dados.slot.personagem = nil
	end
	colocarNaBase(dados, slotDestino.base, slotDestino, false)
	avisar(ladrao, "Você roubou " .. dados.def.nome .. "!", VERDE)
	if donoAntigo then
		avisar(donoAntigo, ladrao.Name .. " roubou seu " .. dados.def.nome .. "!", VERMELHO)
	end
end

local function verificarCarregado(dados)
	local ladrao = dados.ladrao
	local hrp = ladrao and ladrao.Character and ladrao.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		devolver(dados, "Você perdeu o personagem!")
		return
	end

	if dentroDaBase(dados.slotDestino.base, hrp.Position) then
		entregar(dados)
		return
	end

	local dono = dados.base and dados.base.dono
	local hrpDono = dono and dono.Character and dono.Character:FindFirstChild("HumanoidRootPart")
	if hrpDono and (hrpDono.Position - hrp.Position).Magnitude < CONFIG.DistanciaRecuperar then
		devolver(dados, dono.Name .. " pegou o personagem de volta!")
	end
end

function aoRoubar(dados, ladrao)
	if dados.estado ~= "base" then
		return
	end
	local base = dados.base
	if base.dono == ladrao then
		return
	end
	local baseLadrao = basePorJogador[ladrao]
	if not baseLadrao then
		return
	end
	if carregando[ladrao] then
		avisar(ladrao, "Você já está carregando um personagem!", AMARELO)
		return
	end
	if os.clock() < base.trancadaAte then
		avisar(ladrao, "Esta base está trancada!", VERMELHO)
		return
	end
	local slotDestino = slotLivre(baseLadrao)
	if not slotDestino then
		avisar(ladrao, "Sua base está cheia! Venda um personagem primeiro.", AMARELO)
		return
	end
	local personagem = ladrao.Character
	local hrp = personagem and personagem:FindFirstChild("HumanoidRootPart")
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return
	end

	limparPrompts(dados)
	slotDestino.personagem = dados -- reserva o lugar na base do ladrao
	dados.slotDestino = slotDestino
	dados.estado = "carregado"
	dados.ladrao = ladrao
	carregando[ladrao] = dados

	-- Gruda o personagem em cima da cabeca do ladrao
	dados.raiz.CFrame = hrp.CFrame * CFrame.new(0, 3 + dados.def.tamanho, 0)
	local solda = Instance.new("WeldConstraint")
	solda.Name = "SoldaRoubo"
	solda.Part0 = hrp
	solda.Part1 = dados.raiz
	solda.Parent = dados.raiz
	dados.raiz.Anchored = false

	humanoid.WalkSpeed = CONFIG.VelocidadeCarregando
	dados.conexaoMorte = humanoid.Died:Connect(function()
		devolver(dados, "Você morreu e perdeu o personagem!")
	end)

	avisar(ladrao, "Corra para a sua base!", AMARELO)
	if base.dono then
		avisar(base.dono, ladrao.Name .. " está roubando seu " .. dados.def.nome .. "! Encoste nele!", VERMELHO)
	end
end

function aoVender(dados, jogador)
	if dados.estado ~= "base" or dados.base.dono ~= jogador then
		return
	end
	local valor = math.floor(dados.def.preco * CONFIG.PorcentagemVenda)
	jogador.leaderstats.Dinheiro.Value += valor
	dados.slot.personagem = nil
	removerPersonagem(dados)
	avisar(jogador, "Vendido por " .. formatar(valor) .. "!", VERDE)
end

local function aoComprar(dados, jogador)
	if dados.estado ~= "andando" then
		return
	end
	local base = basePorJogador[jogador]
	if not base then
		return
	end
	local dinheiro = jogador.leaderstats.Dinheiro
	if dinheiro.Value < dados.def.preco then
		avisar(jogador, "Dinheiro insuficiente! Custa " .. formatar(dados.def.preco), VERMELHO)
		return
	end
	local slot = slotLivre(base)
	if not slot then
		avisar(jogador, "Sua base está cheia! Venda um personagem primeiro.", AMARELO)
		return
	end
	dinheiro.Value -= dados.def.preco
	colocarNaBase(dados, base, slot, true)
	avisar(jogador, "Você comprou " .. dados.def.nome .. "!", VERDE)
end

-- Monta o boneco com pecas simples: corpo, cabeca, olhos e pernas
local function criarPersonagem(def)
	local s = def.tamanho
	local raridade = RARIDADES[def.raridade]
	local brilhante = def.raridade == "Mitico" or def.raridade == "Secreto"

	local modelo = Instance.new("Model")
	modelo.Name = def.nome

	local raiz = criarParte({
		Name = "Corpo",
		Size = Vector3.new(s, s, s * 0.8),
		CFrame = CFrame.new(INICIO_PASSARELA + Vector3.new(0, s, 0)),
		Color = def.cor,
		Material = brilhante and Enum.Material.Neon or Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanTouch = false,
		Massless = true,
		Parent = modelo,
	})

	local function peca(nome, forma, tamanho, deslocamento, cor)
		local parte = criarParte({
			Name = nome,
			Shape = forma,
			Size = tamanho,
			CFrame = raiz.CFrame * deslocamento,
			Color = cor,
			Anchored = false,
			CanCollide = false,
			CanTouch = false,
			Massless = true,
			Parent = modelo,
		})
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = raiz
		solda.Part1 = parte
		solda.Parent = parte
	end

	local bola = Enum.PartType.Ball
	local bloco = Enum.PartType.Block
	local preto = Color3.new(0, 0, 0)
	peca("Cabeca", bola, Vector3.one * s * 0.8, CFrame.new(0, s * 0.85, 0), def.cor)
	peca("OlhoEsquerdo", bola, Vector3.one * s * 0.18, CFrame.new(-s * 0.17, s * 0.92, -s * 0.33), preto)
	peca("OlhoDireito", bola, Vector3.one * s * 0.18, CFrame.new(s * 0.17, s * 0.92, -s * 0.33), preto)
	peca("PernaEsquerda", bloco, Vector3.new(s * 0.25, s * 0.5, s * 0.25), CFrame.new(-s * 0.22, -s * 0.75, 0), def.cor)
	peca("PernaDireita", bloco, Vector3.new(s * 0.25, s * 0.5, s * 0.25), CFrame.new(s * 0.22, -s * 0.75, 0), def.cor)

	if raridade.chance <= RARIDADES.Lendario.chance then
		local luz = Instance.new("PointLight")
		luz.Color = raridade.cor
		luz.Range = 12
		luz.Brightness = 2
		luz.Parent = raiz
	end

	-- Nome, raridade, preco e renda em cima da cabeca
	local placa = Instance.new("BillboardGui")
	placa.Size = UDim2.fromOffset(220, 75)
	placa.StudsOffset = Vector3.new(0, s * 1.3 + 2, 0)
	placa.MaxDistance = 90
	placa.Parent = raiz
	local linhas = {
		{ def.nome, Color3.new(1, 1, 1) },
		{ raridade.nome, raridade.cor },
		{ formatar(def.preco) .. "  |  +" .. formatar(def.renda) .. "/s", VERDE },
	}
	for i, linha in linhas do
		criarTexto(placa, {
			Text = linha[1],
			TextColor3 = linha[2],
			Size = UDim2.fromScale(1, 1 / 3),
			Position = UDim2.fromScale(0, (i - 1) / 3),
		})
	end

	modelo.PrimaryPart = raiz
	modelo.Parent = pastaPersonagens

	local dados = {
		modelo = modelo,
		raiz = raiz,
		def = def,
		estado = "andando", -- andando | indo | base | carregado | removido
		distancia = 0,
	}
	personagens[modelo] = dados

	criarPrompt(dados, "PromptComprar", "Comprar (" .. formatar(def.preco) .. ")", Enum.KeyCode.E, 0, aoComprar)
	return dados
end

local function sortearPersonagem()
	local total = 0
	for _, def in PERSONAGENS do
		total += def.peso
	end
	local sorteio = math.random() * total
	for _, def in PERSONAGENS do
		sorteio -= def.peso
		if sorteio <= 0 then
			return def
		end
	end
	return PERSONAGENS[1]
end

--------------------------------------------------------------------------
-- JOGADORES
--------------------------------------------------------------------------
local function criarHud(jogador, dinheiro)
	local hud = Instance.new("ScreenGui")
	hud.Name = "HudRoubo"
	hud.ResetOnSpawn = false

	local fundo = Instance.new("Frame")
	fundo.Size = UDim2.fromOffset(260, 50)
	fundo.Position = UDim2.new(0.5, -130, 0, 10)
	fundo.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	fundo.BackgroundTransparency = 0.2
	fundo.Parent = hud
	local canto = Instance.new("UICorner")
	canto.CornerRadius = UDim.new(0, 12)
	canto.Parent = fundo

	local textoDinheiro = criarTexto(fundo, {
		Name = "Dinheiro",
		TextColor3 = VERDE,
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
	})

	criarTexto(hud, {
		Name = "Aviso",
		Text = "",
		Visible = false,
		Size = UDim2.fromOffset(600, 40),
		Position = UDim2.new(0.5, -300, 0.7, 0),
	})

	local function atualizar()
		textoDinheiro.Text = formatar(dinheiro.Value)
	end
	atualizar()
	dinheiro.Changed:Connect(atualizar)

	hud.Parent = jogador:WaitForChild("PlayerGui")
end

local function aoNascer(jogador, personagem)
	local base = basePorJogador[jogador]
	if not base then
		return
	end
	local humanoid = personagem:WaitForChild("Humanoid", 10)
	local hrp = personagem:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not hrp then
		return
	end

	-- Deixa o dono atravessar a barreira da propria base
	for _, parte in personagem:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.CollisionGroup = base.grupoDono
		end
	end
	personagem.DescendantAdded:Connect(function(parte)
		if parte:IsA("BasePart") then
			parte.CollisionGroup = base.grupoDono
		end
	end)

	humanoid.WalkSpeed = CONFIG.VelocidadeNormal
	task.wait(0.1)
	personagem:PivotTo(base.cframe * CFrame.new(0, 5, -12))
end

local function aoEntrar(jogador)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = jogador

	local dinheiro = Instance.new("IntValue")
	dinheiro.Name = "Dinheiro"
	dinheiro.Value = CONFIG.DinheiroInicial
	dinheiro.Parent = leaderstats

	for _, base in bases do
		if not base.dono then
			base.dono = jogador
			basePorJogador[jogador] = base
			break
		end
	end

	criarHud(jogador, dinheiro)
	if not basePorJogador[jogador] then
		avisar(jogador, "Todas as bases estão ocupadas!", VERMELHO)
	end

	jogador.CharacterAdded:Connect(function(personagem)
		aoNascer(jogador, personagem)
	end)
	if jogador.Character then
		aoNascer(jogador, jogador.Character)
	end
end

local function liberarBase(base)
	for _, slot in base.slots do
		local dados = slot.personagem
		if dados then
			slot.personagem = nil
			if dados.estado == "carregado" and dados.slot == slot then
				-- alguem esta roubando: o ladrao continua com ele
				dados.base = nil
				dados.slot = nil
			elseif dados.estado ~= "carregado" then
				removerPersonagem(dados)
			end
		end
	end
	base.dono = nil
	base.trancadaAte = 0
	base.recargaAte = 0
	atualizarBarreira(base, false)
end

Players.PlayerAdded:Connect(aoEntrar)
for _, jogador in Players:GetPlayers() do
	task.spawn(aoEntrar, jogador)
end

Players.PlayerRemoving:Connect(function(jogador)
	local dados = carregando[jogador]
	if dados then
		devolver(dados, nil)
	end
	local base = basePorJogador[jogador]
	if base then
		liberarBase(base)
		basePorJogador[jogador] = nil
	end
end)

--------------------------------------------------------------------------
-- LOOPS DO JOGO
--------------------------------------------------------------------------

-- A cada frame: move os personagens da passarela e verifica os roubos
RunService.Heartbeat:Connect(function(dt)
	for _, dados in personagens do
		if dados.estado == "andando" then
			dados.distancia += CONFIG.VelocidadePassarela * dt
			if dados.distancia >= CONFIG.ComprimentoPassarela then
				removerPersonagem(dados)
			else
				local posicao = INICIO_PASSARELA
					+ Vector3.new(dados.distancia, dados.def.tamanho, 0)
					+ Vector3.new(0, math.abs(math.sin(dados.distancia)) * 0.4, 0) -- pulinho ao andar
				dados.raiz.CFrame = CFrame.lookAt(posicao, posicao + Vector3.xAxis)
			end
		elseif dados.estado == "carregado" then
			verificarCarregado(dados)
		end
	end
end)

-- A cada segundo: paga a renda, atualiza placas e trancas
task.spawn(function()
	while true do
		task.wait(1)
		local agora = os.clock()
		for _, base in bases do
			local rendaTotal = 0
			for _, slot in base.slots do
				local dados = slot.personagem
				if dados and dados.estado == "base" and dados.base == base then
					rendaTotal += dados.def.renda
				end
			end

			if base.dono then
				local leaderstats = base.dono:FindFirstChild("leaderstats")
				if leaderstats then
					leaderstats.Dinheiro.Value += rendaTotal
				end
				base.textoPlaca.Text = "Base de " .. base.dono.DisplayName .. "\n+" .. formatar(rendaTotal) .. "/s"
			else
				base.textoPlaca.Text = "Base livre"
			end

			local trancada = agora < base.trancadaAte
			atualizarBarreira(base, trancada)
			if trancada then
				base.textoBotao.Text = "TRANCADA " .. math.ceil(base.trancadaAte - agora) .. "s"
				base.textoBotao.TextColor3 = VERMELHO
			elseif agora < base.recargaAte then
				base.textoBotao.Text = "RECARGA " .. math.ceil(base.recargaAte - agora) .. "s"
				base.textoBotao.TextColor3 = AMARELO
			else
				base.textoBotao.Text = "PISE PARA TRANCAR"
				base.textoBotao.TextColor3 = VERDE
			end
		end
	end
end)

-- A cada X segundos: um personagem novo aparece na passarela
task.spawn(function()
	while true do
		criarPersonagem(sortearPersonagem())
		task.wait(CONFIG.IntervaloSpawn)
	end
end)
