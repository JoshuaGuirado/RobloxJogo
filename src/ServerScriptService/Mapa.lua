--[[
	ROUBE UM HERÓI - Construtor do mapa

	Onde colocar: ServerScriptService -> ModuleScript (nome: Mapa)

	Monta todo o cenário por código: chão, praça, ruas, cidade com prédios
	neon, árvores, postes, passarela com portais, letreiro, quadros de
	ranking e as 8 bases dos jogadores. Também configura a iluminação.
]]

local Lighting = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")

local Mapa = {}

local CHAO = 0.1 -- altura do topo da praça
local ALTURA_PISO = 0.5 -- piso das bases e passarela ficam 0.5 acima da praça
local TAMANHO_BASE = 48
Mapa.METADE_BASE = TAMANHO_BASE / 2

local CORES_BASES = {
	Color3.fromRGB(70, 130, 255),
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(70, 200, 100),
	Color3.fromRGB(255, 190, 50),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(40, 200, 210),
	Color3.fromRGB(255, 120, 200),
	Color3.fromRGB(255, 140, 40),
}

local CORES_NEON = {
	Color3.fromRGB(0, 220, 255),
	Color3.fromRGB(255, 60, 200),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(120, 255, 140),
	Color3.fromRGB(180, 120, 255),
}

--------------------------------------------------------------------------
-- AJUDANTES
--------------------------------------------------------------------------
local function parte(propriedades)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for nome, valor in propriedades do
		if nome ~= "Parent" then
			(p :: any)[nome] = valor
		end
	end
	p.Parent = propriedades.Parent
	return p
end

local function enfeite(propriedades)
	-- peças só de decoração: não fazem sombra nem atrapalham cliques
	propriedades.CastShadow = false
	propriedades.CanQuery = false
	propriedades.CanTouch = false
	return parte(propriedades)
end

local function pastaNova(nome, pai)
	local f = Instance.new("Folder")
	f.Name = nome
	f.Parent = pai
	return f
end

local function texto(pai, propriedades)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Size = UDim2.fromScale(1, 1)
	for nome, valor in propriedades do
		(t :: any)[nome] = valor
	end
	t.Parent = pai
	return t
end

local function superficie(alvo, face, pixelsPorStud)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPorStud
	gui.LightInfluence = 0
	gui.Parent = alvo
	return gui
end

local function billboard(alvo, largura, altura, deslocamento, distancia)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(largura, altura)
	gui.StudsOffset = deslocamento
	gui.MaxDistance = distancia
	gui.LightInfluence = 0
	gui.Parent = alvo
	return gui
end

local function cilindroEmPe(propriedades, cf)
	-- o eixo do cilindro no Roblox é o X; giramos para ficar em pé
	propriedades.Shape = Enum.PartType.Cylinder
	propriedades.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	return parte(propriedades)
end

--------------------------------------------------------------------------
-- ILUMINAÇÃO
--------------------------------------------------------------------------
local function configurarIluminacao(horaInicial)
	for _, objeto in Lighting:GetChildren() do
		if objeto:IsA("PostEffect") or objeto:IsA("Atmosphere") or objeto:IsA("Sky") then
			objeto:Destroy()
		end
	end

	Lighting.ClockTime = horaInicial
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(70, 70, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 115, 145)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true

	local ceu = Instance.new("Sky")
	ceu.StarCount = 3000
	ceu.Parent = Lighting

	local atmosfera = Instance.new("Atmosphere")
	atmosfera.Density = 0.3
	atmosfera.Offset = 0.25
	atmosfera.Color = Color3.fromRGB(200, 170, 150)
	atmosfera.Decay = Color3.fromRGB(110, 100, 140)
	atmosfera.Glare = 0.4
	atmosfera.Haze = 1.4
	atmosfera.Parent = Lighting

	local brilho = Instance.new("BloomEffect")
	brilho.Intensity = 0.7
	brilho.Size = 28
	brilho.Threshold = 1.2
	brilho.Parent = Lighting

	local raios = Instance.new("SunRaysEffect")
	raios.Intensity = 0.06
	raios.Spread = 0.7
	raios.Parent = Lighting

	local correcao = Instance.new("ColorCorrectionEffect")
	correcao.Saturation = 0.15
	correcao.Contrast = 0.08
	correcao.Parent = Lighting

	local terreno = workspace:FindFirstChildOfClass("Terrain")
	if terreno then
		local nuvens = terreno:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		nuvens.Cover = 0.55
		nuvens.Density = 0.6
		nuvens.Parent = terreno
	end

	return correcao
end

--------------------------------------------------------------------------
-- CHÃO, PRAÇA E RUAS
--------------------------------------------------------------------------
local function construirChao(pasta)
	parte({
		Name = "Grama",
		Size = Vector3.new(1400, 2, 1400),
		CFrame = CFrame.new(0, CHAO - 1.3, 0),
		Color = Color3.fromRGB(70, 140, 60),
		Material = Enum.Material.Grass,
		Parent = pasta,
	})
	parte({
		Name = "Praca",
		Size = Vector3.new(440, 1, 220),
		CFrame = CFrame.new(0, CHAO - 0.5, 0),
		Color = Color3.fromRGB(120, 120, 130),
		Material = Enum.Material.Pavement,
		Parent = pasta,
	})

	-- Rua em volta da praça
	local asfalto = Color3.fromRGB(45, 45, 50)
	local ruas = {
		{ Vector3.new(540, 0.4, 26), Vector3.new(0, 0, 138) },
		{ Vector3.new(540, 0.4, 26), Vector3.new(0, 0, -138) },
		{ Vector3.new(26, 0.4, 250), Vector3.new(257, 0, 0) },
		{ Vector3.new(26, 0.4, 250), Vector3.new(-257, 0, 0) },
	}
	for _, rua in ruas do
		enfeite({
			Name = "Rua",
			Size = rua[1],
			CFrame = CFrame.new(rua[2] + Vector3.new(0, CHAO - 0.35, 0)),
			Color = asfalto,
			Material = Enum.Material.Asphalt,
			Parent = pasta,
		})
	end
	-- Faixas amarelas tracejadas
	for x = -250, 250, 20 do
		for _, z in { 138, -138 } do
			enfeite({
				Name = "Faixa",
				Size = Vector3.new(8, 0.1, 0.8),
				CFrame = CFrame.new(x, CHAO - 0.12, z),
				Color = Color3.fromRGB(255, 210, 60),
				Material = Enum.Material.SmoothPlastic,
				Parent = pasta,
			})
		end
	end
end

--------------------------------------------------------------------------
-- PASSARELA E PORTAIS
--------------------------------------------------------------------------
local function construirPortal(pasta, x, cor, nome)
	local modelo = Instance.new("Model")
	modelo.Name = nome
	modelo.Parent = pasta
	local base = CHAO + ALTURA_PISO

	local topo = enfeite({ Name = "Topo", Size = Vector3.new(2.5, 2.5, 21), CFrame = CFrame.new(x, base + 17.25, 0),
		Color = cor, Material = Enum.Material.Neon, Parent = modelo })
	for _, z in { -9.5, 9.5 } do
		parte({ Name = "Coluna", Size = Vector3.new(2.5, 18, 2.5), CFrame = CFrame.new(x, base + 9, z),
			Color = Color3.fromRGB(35, 35, 45), Material = Enum.Material.Metal, Parent = modelo })
		enfeite({ Name = "Faixa", Size = Vector3.new(2.7, 18, 0.6), CFrame = CFrame.new(x, base + 9, z),
			Color = cor, Material = Enum.Material.Neon, Parent = modelo })
	end

	local disco = enfeite({
		Name = "Energia",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 16, 16),
		CFrame = CFrame.new(x, base + 8, 0),
		Color = cor,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		Parent = modelo,
	})
	local particulas = Instance.new("ParticleEmitter")
	particulas.Color = ColorSequence.new(cor)
	particulas.LightEmission = 1
	particulas.Rate = 25
	particulas.Lifetime = NumberRange.new(1, 2)
	particulas.Speed = NumberRange.new(2, 5)
	particulas.SpreadAngle = Vector2.new(180, 180)
	particulas.Size = NumberSequence.new(0.6, 0)
	particulas.Parent = disco

	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = 30
	luz.Brightness = 3
	luz.Parent = disco

	local placa = billboard(topo, 320, 60, Vector3.new(0, 4, 0), 220)
	texto(placa, { Text = "🌀 PORTAL DOS HERÓIS", TextColor3 = cor })
end

local function construirPassarela(pasta, comprimento)
	local metade = comprimento / 2
	parte({
		Name = "Passarela",
		Size = Vector3.new(comprimento + 6, ALTURA_PISO, 14),
		CFrame = CFrame.new(0, CHAO + ALTURA_PISO / 2, 0),
		Color = Color3.fromRGB(180, 25, 45),
		Material = Enum.Material.Fabric,
		Parent = pasta,
	})
	for _, z in { -7.4, 7.4 } do
		enfeite({
			Name = "BordaDourada",
			Size = Vector3.new(comprimento + 6, ALTURA_PISO + 0.15, 0.8),
			CFrame = CFrame.new(0, CHAO + (ALTURA_PISO + 0.15) / 2, z),
			Color = Color3.fromRGB(255, 200, 40),
			Material = Enum.Material.Neon,
			Parent = pasta,
		})
	end

	construirPortal(pasta, -metade - 1, Color3.fromRGB(0, 220, 255), "PortalEntrada")
	construirPortal(pasta, metade + 1, Color3.fromRGB(190, 80, 255), "PortalSaida")

	return Vector3.new(-metade, CHAO + ALTURA_PISO, 0)
end

local function construirPostes(pasta, comprimento)
	local metade = comprimento / 2
	for x = -metade, metade, 30 do
		for _, z in { -20, 20 } do
			enfeite({ Name = "Poste", Size = Vector3.new(0.6, 12, 0.6), CFrame = CFrame.new(x, CHAO + 6, z),
				Color = Color3.fromRGB(40, 40, 50), Material = Enum.Material.Metal, Parent = pasta })
			local lampada = enfeite({ Name = "Lampada", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8),
				CFrame = CFrame.new(x, CHAO + 12.4, z), Color = Color3.fromRGB(255, 230, 180),
				Material = Enum.Material.Neon, Parent = pasta })
			local luz = Instance.new("PointLight")
			luz.Color = Color3.fromRGB(255, 220, 170)
			luz.Range = 24
			luz.Brightness = 1.3
			luz.Parent = lampada
		end
	end
end

--------------------------------------------------------------------------
-- CIDADE DE FUNDO, ÁRVORES E LETREIRO
--------------------------------------------------------------------------
local function construirCidade(pasta)
	local aleatorio = Random.new(2024)
	local coresPredio = {
		Color3.fromRGB(35, 40, 60),
		Color3.fromRGB(50, 55, 75),
		Color3.fromRGB(30, 30, 40),
		Color3.fromRGB(60, 50, 80),
		Color3.fromRGB(40, 60, 80),
	}
	local quantidade = 70
	for i = 1, quantidade do
		local angulo = (i / quantidade) * math.pi * 2 + aleatorio:NextNumber(-0.03, 0.03)
		local raio = aleatorio:NextNumber(330, 470)
		local largura = aleatorio:NextNumber(30, 55)
		local profundidade = aleatorio:NextNumber(30, 55)
		local altura = aleatorio:NextNumber(60, 240)
		local centro = Vector3.new(math.cos(angulo) * raio, CHAO + altura / 2 - 0.3, math.sin(angulo) * raio)
		local cf = CFrame.lookAt(centro, Vector3.new(0, centro.Y, 0))
		local corNeon = CORES_NEON[aleatorio:NextInteger(1, #CORES_NEON)]

		local predio = Instance.new("Model")
		predio.Name = "Predio"
		predio.Parent = pasta
		enfeite({ Name = "Corpo", Size = Vector3.new(largura, altura, profundidade), CFrame = cf,
			Color = coresPredio[aleatorio:NextInteger(1, #coresPredio)], Material = Enum.Material.SmoothPlastic,
			Reflectance = 0.05, Parent = predio })

		-- Quinas neon
		for _, canto in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
			enfeite({ Name = "Quina", Size = Vector3.new(0.7, altura, 0.7),
				CFrame = cf * CFrame.new(canto.X * largura / 2, 0, canto.Z * profundidade / 2),
				Color = corNeon, Material = Enum.Material.Neon, Parent = predio })
		end

		-- Faixas de janelas acesas na frente
		for y = -altura / 2 + 10, altura / 2 - 6, 16 do
			enfeite({ Name = "Janelas", Size = Vector3.new(largura * 0.8, 2, 0.3),
				CFrame = cf * CFrame.new(0, y, -profundidade / 2 - 0.1),
				Color = Color3.fromRGB(255, 230, 160), Material = Enum.Material.Neon, Transparency = 0.25,
				Parent = predio })
		end

		-- Antena com luz vermelha
		if aleatorio:NextNumber() < 0.5 then
			enfeite({ Name = "Antena", Size = Vector3.new(0.6, 14, 0.6), CFrame = cf * CFrame.new(0, altura / 2 + 7, 0),
				Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal, Parent = predio })
			enfeite({ Name = "LuzAntena", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2),
				CFrame = cf * CFrame.new(0, altura / 2 + 14.5, 0), Color = Color3.fromRGB(255, 40, 40),
				Material = Enum.Material.Neon, Parent = predio })
		end
	end
end

local function construirArvores(pasta)
	local aleatorio = Random.new(77)
	for i = 1, 60 do
		local angulo = (i / 60) * math.pi * 2 + aleatorio:NextNumber(-0.04, 0.04)
		local raio = aleatorio:NextNumber(285, 315)
		local x, z = math.cos(angulo) * raio, math.sin(angulo) * raio
		local altura = aleatorio:NextNumber(7, 11)
		enfeite({ Name = "Tronco", Size = Vector3.new(1.4, altura, 1.4), CFrame = CFrame.new(x, CHAO + altura / 2 - 0.3, z),
			Color = Color3.fromRGB(100, 70, 45), Material = Enum.Material.Wood, Parent = pasta })
		local tamanho = aleatorio:NextNumber(8, 12)
		enfeite({ Name = "Copa", Shape = Enum.PartType.Ball, Size = Vector3.new(tamanho, tamanho, tamanho),
			CFrame = CFrame.new(x, CHAO + altura + tamanho * 0.25, z),
			Color = Color3.fromRGB(50, aleatorio:NextInteger(120, 160), 60), Material = Enum.Material.Grass, Parent = pasta })
	end
end

local function construirLetreiro(pasta)
	local placa = parte({
		Name = "Letreiro",
		Size = Vector3.new(100, 18, 2),
		CFrame = CFrame.new(0, CHAO + 50, 0),
		Color = Color3.fromRGB(20, 20, 30),
		Material = Enum.Material.SmoothPlastic,
		CastShadow = false,
		Parent = pasta,
	})
	for _, info in {
		{ Vector3.new(102, 1, 2.4), Vector3.new(0, 9.5, 0) },
		{ Vector3.new(102, 1, 2.4), Vector3.new(0, -9.5, 0) },
		{ Vector3.new(1, 20, 2.4), Vector3.new(50.5, 0, 0) },
		{ Vector3.new(1, 20, 2.4), Vector3.new(-50.5, 0, 0) },
	} do
		enfeite({ Name = "Moldura", Size = info[1], CFrame = placa.CFrame + info[2],
			Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, Parent = pasta })
	end

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = superficie(placa, face, 20)
		local titulo = texto(gui, {
			Text = "ROUBE UM HERÓI",
			Size = UDim2.fromScale(0.94, 0.66),
			Position = UDim2.fromScale(0.03, 0.04),
			TextStrokeTransparency = 1,
		})
		local gradiente = Instance.new("UIGradient")
		gradiente.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 30))
		gradiente.Rotation = 90
		gradiente.Parent = titulo
		local contorno = Instance.new("UIStroke")
		contorno.Thickness = 8
		contorno.Color = Color3.fromRGB(90, 20, 0)
		contorno.Parent = titulo
		texto(gui, {
			Text = "🦸 Compre • Colete • Roube 🦹",
			Size = UDim2.fromScale(0.9, 0.24),
			Position = UDim2.fromScale(0.05, 0.72),
			TextColor3 = Color3.fromRGB(255, 255, 255),
		})
	end
end

--------------------------------------------------------------------------
-- QUADROS DE RANKING
--------------------------------------------------------------------------
local CATEGORIAS_RANKING = {
	{ id = "Dinheiro", titulo = "🏆 MAIS RICOS", subtitulo = "Total de dinheiro ganho", cor = Color3.fromRGB(255, 190, 40), z = -50 },
	{ id = "Roubos", titulo = "🦹 MAIORES LADRÕES", subtitulo = "Heróis roubados", cor = Color3.fromRGB(255, 70, 70), z = 0 },
	{ id = "Renascimentos", titulo = "♻️ RENASCIMENTOS", subtitulo = "Vezes que renasceu", cor = Color3.fromRGB(170, 90, 255), z = 50 },
}
Mapa.CATEGORIAS_RANKING = CATEGORIAS_RANKING

local function construirQuadro(pasta, categoria)
	local posicao = Vector3.new(205, CHAO + 23, categoria.z)
	local cf = CFrame.lookAt(posicao, Vector3.new(0, posicao.Y, categoria.z))
	local quadro = parte({
		Name = "Ranking" .. categoria.id,
		Size = Vector3.new(30, 40, 1),
		CFrame = cf,
		Color = Color3.fromRGB(20, 22, 32),
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	parte({ Name = "Suporte", Size = Vector3.new(32, 3, 4), CFrame = cf * CFrame.new(0, -21.5, 0),
		Color = Color3.fromRGB(40, 40, 50), Material = Enum.Material.Metal, Parent = pasta })
	enfeite({ Name = "Moldura", Size = Vector3.new(31, 41, 0.6), CFrame = cf * CFrame.new(0, 0, 0.5),
		Color = categoria.cor, Material = Enum.Material.Neon, Parent = pasta })

	local gui = superficie(quadro, Enum.NormalId.Front, 20)
	local cabecalho = Instance.new("Frame")
	cabecalho.Size = UDim2.fromScale(1, 0.12)
	cabecalho.BackgroundColor3 = categoria.cor
	cabecalho.BorderSizePixel = 0
	cabecalho.Parent = gui
	texto(cabecalho, { Text = categoria.titulo, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1) })
	texto(gui, {
		Text = categoria.subtitulo,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		Size = UDim2.fromScale(0.9, 0.04),
		Position = UDim2.fromScale(0.05, 0.135),
	})

	local lista = Instance.new("Frame")
	lista.BackgroundTransparency = 1
	lista.Size = UDim2.fromScale(0.94, 0.75)
	lista.Position = UDim2.fromScale(0.03, 0.19)
	lista.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.008, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = lista

	local medalhas = { Color3.fromRGB(255, 200, 40), Color3.fromRGB(200, 200, 215), Color3.fromRGB(205, 130, 70) }
	local linhas = {}
	for i = 1, 10 do
		local linha = Instance.new("Frame")
		linha.LayoutOrder = i
		linha.Size = UDim2.fromScale(1, 0.092)
		linha.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(34, 37, 52) or Color3.fromRGB(42, 46, 64)
		linha.BorderSizePixel = 0
		linha.Parent = lista
		local canto = Instance.new("UICorner")
		canto.CornerRadius = UDim.new(0.2, 0)
		canto.Parent = linha
		local posicaoTexto = texto(linha, { Text = "#" .. i, TextColor3 = medalhas[i] or Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromScale(0.14, 0.8), Position = UDim2.fromScale(0.02, 0.1) })
		local nome = texto(linha, { Text = "—", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.5, 0.7), Position = UDim2.fromScale(0.18, 0.15) })
		local valor = texto(linha, { Text = "", TextColor3 = categoria.cor, TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.fromScale(0.3, 0.7), Position = UDim2.fromScale(0.68, 0.15) })
		linhas[i] = { posicao = posicaoTexto, nome = nome, valor = valor }
	end

	local rodape = texto(gui, {
		Text = "Carregando ranking...",
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(170, 170, 185),
		Size = UDim2.fromScale(0.9, 0.035),
		Position = UDim2.fromScale(0.05, 0.955),
	})

	return { linhas = linhas, rodape = rodape }
end

--------------------------------------------------------------------------
-- BASES
--------------------------------------------------------------------------
local function construirBase(pasta, indice, centro, cor)
	-- A frente da base (eixo -Z local) aponta para a passarela (z = 0).
	-- Bases do lado negativo giram 180 graus para olhar para +Z.
	local cf = CFrame.new(centro)
	if centro.Z < 0 then
		cf *= CFrame.Angles(0, math.pi, 0)
	end
	local P = ALTURA_PISO
	local corParede = Color3.fromRGB(45, 48, 62)
	local metade = TAMANHO_BASE / 2

	local modelo = Instance.new("Model")
	modelo.Name = "Base" .. indice
	modelo.Parent = pasta

	parte({ Name = "Piso", Size = Vector3.new(TAMANHO_BASE, 1, TAMANHO_BASE), CFrame = cf * CFrame.new(0, P - 0.5, 0),
		Color = cor:Lerp(Color3.fromRGB(40, 40, 50), 0.55), Material = Enum.Material.SmoothPlastic, Parent = modelo })

	-- Bordas neon do piso
	for _, info in {
		{ Vector3.new(TAMANHO_BASE, 0.15, 0.8), Vector3.new(0, 0, metade - 0.4) },
		{ Vector3.new(TAMANHO_BASE, 0.15, 0.8), Vector3.new(0, 0, -metade + 0.4) },
		{ Vector3.new(0.8, 0.15, TAMANHO_BASE), Vector3.new(metade - 0.4, 0, 0) },
		{ Vector3.new(0.8, 0.15, TAMANHO_BASE), Vector3.new(-metade + 0.4, 0, 0) },
	} do
		enfeite({ Name = "BordaPiso", Size = info[1], CFrame = cf * CFrame.new(info[2] + Vector3.new(0, P + 0.03, 0)),
			Color = cor, Material = Enum.Material.Neon, Parent = modelo })
	end

	-- Paredes
	local paredes = {
		{ "ParedeFundo", Vector3.new(TAMANHO_BASE, 16, 1), Vector3.new(0, P + 8, metade - 0.5) },
		{ "ParedeEsquerda", Vector3.new(1, 16, TAMANHO_BASE), Vector3.new(-metade + 0.5, P + 8, 0) },
		{ "ParedeDireita", Vector3.new(1, 16, TAMANHO_BASE), Vector3.new(metade - 0.5, P + 8, 0) },
	}
	for _, info in paredes do
		parte({ Name = info[1], Size = info[2], CFrame = cf * CFrame.new(info[3]), Color = corParede,
			Material = Enum.Material.SmoothPlastic, Parent = modelo })
	end
	for _, info in {
		{ Vector3.new(TAMANHO_BASE + 0.6, 0.8, 1.6), Vector3.new(0, P + 16.4, metade - 0.5) },
		{ Vector3.new(1.6, 0.8, TAMANHO_BASE + 0.6), Vector3.new(-metade + 0.5, P + 16.4, 0) },
		{ Vector3.new(1.6, 0.8, TAMANHO_BASE + 0.6), Vector3.new(metade - 0.5, P + 16.4, 0) },
	} do
		enfeite({ Name = "Friso", Size = info[1], CFrame = cf * CFrame.new(info[2]), Color = cor,
			Material = Enum.Material.Neon, Parent = modelo })
	end

	-- Pilares da entrada
	for _, x in { -metade + 0.5, metade - 0.5 } do
		parte({ Name = "Pilar", Size = Vector3.new(2.4, 18, 2.4), CFrame = cf * CFrame.new(x, P + 9, -metade + 0.5),
			Color = corParede, Material = Enum.Material.SmoothPlastic, Parent = modelo })
		enfeite({ Name = "TopoPilar", Size = Vector3.new(3, 1, 3), CFrame = cf * CFrame.new(x, P + 18.5, -metade + 0.5),
			Color = cor, Material = Enum.Material.Neon, Parent = modelo })
	end

	-- Barreira laser (só aparece quando a base está trancada)
	local barreira = parte({
		Name = "Barreira",
		Size = Vector3.new(TAMANHO_BASE - 1.5, 16, 0.4),
		CFrame = cf * CFrame.new(0, P + 8, -metade + 0.4),
		Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Parent = modelo,
	})

	-- Grupos de colisão: a barreira bloqueia todo mundo, menos o dono da base
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
	local placa = parte({ Name = "Placa", Size = Vector3.new(30, 6, 0.6), CFrame = cf * CFrame.new(0, P + 20, metade - 0.5),
		Color = Color3.fromRGB(20, 22, 30), Material = Enum.Material.SmoothPlastic, Parent = modelo })
	local guiPlaca = superficie(placa, Enum.NormalId.Front, 25)
	local textoPlaca = texto(guiPlaca, { Text = "BASE LIVRE", Size = UDim2.fromScale(0.95, 0.6), Position = UDim2.fromScale(0.025, 0.05) })
	local textoRenda = texto(guiPlaca, { Text = "", TextColor3 = Color3.fromRGB(80, 255, 120),
		Size = UDim2.fromScale(0.9, 0.32), Position = UDim2.fromScale(0.05, 0.65) })

	-- Botão de trancar
	local botao = cilindroEmPe({ Name = "BotaoTrancar", Size = Vector3.new(0.5, 6, 6), Color = Color3.fromRGB(60, 220, 90),
		Material = Enum.Material.Neon, Parent = modelo }, cf * CFrame.new(-17, P + 0.25, -17))
	local guiBotao = billboard(botao, 200, 50, Vector3.new(0, 3.5, 0), 70)
	local textoBotao = texto(guiBotao, { Text = "🔒 TRANCAR BASE" })

	-- Ponto de entrega (para a seta de "leve até sua base")
	local alvo = parte({ Name = "AlvoEntrega", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, P + 3, 0),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = modelo })
	local anexo = Instance.new("Attachment")
	anexo.Name = "Alvo"
	anexo.Parent = alvo

	local base = {
		indice = indice,
		cor = cor,
		cframe = cf,
		modelo = modelo,
		barreira = barreira,
		botao = botao,
		textoPlaca = textoPlaca,
		textoRenda = textoRenda,
		textoBotao = textoBotao,
		grupoDono = grupoDono,
		spawn = cf * CFrame.new(0, P + 3.2, -16),
		saida = cf * CFrame.new(0, P + 3.2, -metade - 8),
		slots = {},
	}

	-- 12 pedestais (3 fileiras de 4). Os primeiros são os mais perto da entrada.
	for _, z in { -4, 7, 18 } do
		for _, x in { -18, -6, 6, 18 } do
			local pedestal = cilindroEmPe({ Name = "Pedestal", Size = Vector3.new(1.2, 7, 7), Color = Color3.fromRGB(235, 235, 240),
				Material = Enum.Material.Marble, Parent = modelo }, cf * CFrame.new(x, P + 0.6, z))
			local anel = cilindroEmPe({ Name = "Anel", Size = Vector3.new(0.25, 7.8, 7.8), Color = cor,
				Material = Enum.Material.Neon, CastShadow = false, Parent = modelo }, cf * CFrame.new(x, P + 0.125, z))
			local pad = parte({ Name = "Coletar", Size = Vector3.new(5, 0.3, 2.4), CFrame = cf * CFrame.new(x, P + 0.15, z - 5.6),
				Color = Color3.fromRGB(60, 220, 100), Material = Enum.Material.Neon, Parent = modelo })

			local guiPad = billboard(pad, 160, 40, Vector3.new(0, 2.2, 0), 50)
			guiPad.Enabled = false
			local textoPad = texto(guiPad, { Text = "💰 $0", TextColor3 = Color3.fromRGB(120, 255, 140) })

			local guiCadeado = billboard(pedestal, 170, 60, Vector3.new(0, 3, 0), 60)
			guiCadeado.Enabled = false
			texto(guiCadeado, { Text = "🔒\nCompre na Loja", Font = Enum.Font.GothamBold })

			table.insert(base.slots, {
				indice = #base.slots + 1,
				base = base,
				topo = cf * CFrame.new(x, P + 1.2, z),
				pedestal = pedestal,
				anel = anel,
				pad = pad,
				guiPad = guiPad,
				textoPad = textoPad,
				guiCadeado = guiCadeado,
				acumulado = 0,
				heroi = nil,
			})
		end
	end

	return base
end

--------------------------------------------------------------------------
-- MONTAGEM
--------------------------------------------------------------------------
function Mapa.construir(Config)
	local G = Config.Geral

	if G.RemoverBaseplate then
		for _, nome in { "Baseplate", "SpawnLocation" } do
			local objeto = workspace:FindFirstChild(nome)
			if objeto then
				objeto:Destroy()
			end
		end
	end
	local antigo = workspace:FindFirstChild("MapaHerois")
	if antigo then
		antigo:Destroy()
	end

	local pasta = pastaNova("MapaHerois", workspace)
	local cenario = pastaNova("Cenario", pasta)
	local pastaBases = pastaNova("Bases", pasta)
	local pastaHerois = pastaNova("Herois", pasta)
	local pastaRanking = pastaNova("Ranking", pasta)

	local correcaoCor = configurarIluminacao(G.HoraInicial)
	construirChao(cenario)
	local inicio = construirPassarela(cenario, G.ComprimentoPassarela)
	construirPostes(cenario, G.ComprimentoPassarela)
	construirLetreiro(cenario)
	construirArvores(cenario)
	construirCidade(cenario)

	local quadros = {}
	for _, categoria in CATEGORIAS_RANKING do
		quadros[categoria.id] = construirQuadro(pastaRanking, categoria)
	end

	-- Lugar onde nasce quem ficou sem base (servidor cheio)
	local spawnLobby = Instance.new("SpawnLocation")
	spawnLobby.Name = "SpawnLobby"
	spawnLobby.Anchored = true
	spawnLobby.Neutral = true
	spawnLobby.Duration = 0
	spawnLobby.Size = Vector3.new(10, 1, 10)
	spawnLobby.CFrame = CFrame.new(182, CHAO + 0.5, 0)
	spawnLobby.Color = Color3.fromRGB(255, 200, 40)
	spawnLobby.Material = Enum.Material.Neon
	spawnLobby.TopSurface = Enum.SurfaceType.Smooth
	spawnLobby.Parent = pasta

	local bases = {}
	for _, z in { -58, 58 } do
		for _, x in { -105, -35, 35, 105 } do
			local indice = #bases + 1
			table.insert(bases, construirBase(pastaBases, indice, Vector3.new(x, CHAO, z), CORES_BASES[indice]))
		end
	end

	return {
		pasta = pasta,
		pastaHerois = pastaHerois,
		bases = bases,
		inicio = inicio,
		comprimento = G.ComprimentoPassarela,
		quadros = quadros,
		correcaoCor = correcaoCor,
	}
end

return Mapa
