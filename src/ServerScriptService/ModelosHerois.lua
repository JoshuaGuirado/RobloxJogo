--[[
	ROUBE UM HERÓI - Modelos 3D (heróis, luvas, mola e vendedor)

	Onde colocar: ServerScriptService -> ModuleScript (nome: ModelosHerois)

	Cada herói é montado com peças em blocos (estilo Roblox) a partir da
	descrição "visual" que está no ConfigHerois: cores do uniforme, chapéu ou
	capacete, rosto, itens nas mãos, coisas nas costas e emblema no peito.
	Todas as peças ficam soldadas na peça principal (o tronco).
]]

local CollectionService = game:GetService("CollectionService")

local Modelos = {}

local BLOCO, BOLA, CILINDRO = Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder
local LISO = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
local VIDRO = Enum.Material.Glass
local FOLHA = Enum.Material.Foil

local PRETO = Color3.fromRGB(22, 22, 26)
local BRANCO = Color3.fromRGB(245, 245, 245)
local OURO = Color3.fromRGB(255, 200, 40)
local PRATA = Color3.fromRGB(195, 200, 210)
local VERMELHO = Color3.fromRGB(220, 35, 35)
local REFLETIVO = Color3.fromRGB(225, 230, 220)
local CASTANHO_PADRAO = Color3.fromRGB(60, 40, 25)

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad
local EM_PE = ANG(0, 0, rad(90)) -- cilindro em pé (o eixo do cilindro no Roblox é o X)
local DE_FRENTE = ANG(0, rad(90), 0) -- cilindro com a face virada para a frente

--------------------------------------------------------------------------
-- Construtor: cria peças soldadas na raiz
--------------------------------------------------------------------------
local function novoConstrutor(modelo, raiz)
	local c = {}
	function c.peca(nome, forma, tamanho, cf, cor, material, opcoes)
		local p = Instance.new("Part")
		p.Name = nome
		p.Shape = forma
		p.Size = tamanho
		p.CFrame = raiz.CFrame * cf
		p.Color = cor
		p.Material = material or LISO
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.Anchored = false
		if opcoes then
			if opcoes.transparencia then
				p.Transparency = opcoes.transparencia
			end
			if opcoes.pintavel then
				p:SetAttribute("Pintavel", true)
			end
		end
		p.Parent = modelo
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = raiz
		solda.Part1 = p
		solda.Parent = p
		return p
	end
	-- Peça arredondada que pode ser achatada (esfera esticada)
	function c.elipse(nome, tamanho, cf, cor, material, opcoes)
		local p = c.peca(nome, BLOCO, tamanho, cf, cor, material, opcoes)
		local malha = Instance.new("SpecialMesh")
		malha.MeshType = Enum.MeshType.Sphere
		malha.Parent = p
		return p
	end
	-- Anel feito de várias peças pequenas (boia, laço)
	function c.anel(nome, raio, quantidade, tamanho, centro, cores, material)
		for i = 1, quantidade do
			local a = (i / quantidade) * math.pi * 2
			c.peca(nome, BLOCO, tamanho, centro * CF(math.cos(a) * raio, math.sin(a) * raio, 0) * ANG(0, 0, a),
				cores[(i - 1) % #cores + 1], material)
		end
	end
	return c
end

local function novaRaiz(modelo, nome, tamanho, cor, material)
	local raiz = Instance.new("Part")
	raiz.Name = nome
	raiz.Size = tamanho
	raiz.CFrame = CFrame.new()
	raiz.Color = cor
	raiz.Material = material or LISO
	raiz.TopSurface = Enum.SurfaceType.Smooth
	raiz.BottomSurface = Enum.SurfaceType.Smooth
	raiz.CanCollide = false
	raiz.CanTouch = false
	raiz.CanQuery = false
	raiz.Massless = true
	raiz.Anchored = true
	raiz.Parent = modelo
	return raiz
end

--------------------------------------------------------------------------
-- ROSTOS (ctx: c, s, yC = altura da cabeça, v = visual)
--------------------------------------------------------------------------
local function olhosEBoca(ctx, corOlhos)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	for _, lado in { -1, 1 } do
		c.peca("Olho", BOLA, V3(0.15, 0.15, 0.15) * s, CF(0.19 * s * lado, yC + 0.08 * s, -0.5 * s), corOlhos or PRETO)
		c.peca("Sobrancelha", BLOCO, V3(0.2, 0.04, 0.04) * s, CF(0.19 * s * lado, yC + 0.22 * s, -0.5 * s) * ANG(0, 0, rad(-8 * lado)),
			ctx.v.cabelo or PRETO)
	end
	c.peca("Boca", BLOCO, V3(0.3, 0.05, 0.05) * s, CF(0, yC - 0.2 * s, -0.51 * s), Color3.fromRGB(120, 40, 40))
end

local ROSTOS = {}
function ROSTOS.oculos(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	for _, lado in { -1, 1 } do
		c.peca("Lente", BLOCO, V3(0.3, 0.22, 0.05) * s, CF(0.2 * s * lado, yC + 0.08 * s, -0.56 * s), Color3.fromRGB(200, 230, 255), VIDRO,
			{ transparencia = 0.3 })
		c.peca("Armacao", BLOCO, V3(0.34, 0.04, 0.06) * s, CF(0.2 * s * lado, yC + 0.2 * s, -0.56 * s), PRETO)
	end
	c.peca("Ponte", BLOCO, V3(0.12, 0.04, 0.05) * s, CF(0, yC + 0.12 * s, -0.57 * s), PRETO)
end
function ROSTOS.oculosSol(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("OculosSol", BLOCO, V3(0.75, 0.2, 0.06) * s, CF(0, yC + 0.08 * s, -0.56 * s), PRETO, VIDRO)
end
function ROSTOS.oculosProtecao(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Faixa", BLOCO, V3(1.14, 0.14, 1.14) * s, CF(0, yC + 0.1 * s, 0), Color3.fromRGB(40, 40, 40))
	c.peca("LenteProtecao", BLOCO, V3(0.8, 0.3, 0.12) * s, CF(0, yC + 0.1 * s, -0.56 * s), Color3.fromRGB(170, 255, 200), VIDRO,
		{ transparencia = 0.25 })
end
function ROSTOS.mascaraCirurgica(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.elipse("Mascara", V3(0.75, 0.4, 0.3) * s, CF(0, yC - 0.17 * s, -0.46 * s), Color3.fromRGB(150, 210, 240))
end
function ROSTOS.mascaraMergulho(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Tira", BLOCO, V3(1.16, 0.14, 1.16) * s, CF(0, yC + 0.1 * s, 0), PRETO)
	c.peca("Moldura", BLOCO, V3(0.85, 0.42, 0.14) * s, CF(0, yC + 0.08 * s, -0.55 * s), PRETO)
	c.peca("Visor", BLOCO, V3(0.72, 0.3, 0.06) * s, CF(0, yC + 0.08 * s, -0.63 * s), Color3.fromRGB(110, 200, 255), VIDRO,
		{ transparencia = 0.2 })
	c.peca("Snorkel", BLOCO, V3(0.1, 0.8, 0.1) * s, CF(0.55 * s, yC + 0.25 * s, -0.1 * s), Color3.fromRGB(255, 200, 0))
end

--------------------------------------------------------------------------
-- CABEÇAS (chapéus, capacetes, máscaras de super-herói)
--------------------------------------------------------------------------
local CABECAS = {}
local CABECAS_SEM_ROSTO = { capaceteAstronauta = true, capuzAranha = true, capuzMorcego = true, capaceteArmadura = true }

local function cabelo(ctx, estilo)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabelo or Color3.fromRGB(60, 40, 25)
	c.elipse("Cabelo", V3(1.16, 0.72, 1.18) * s, CF(0, yC + 0.24 * s, 0.06 * s), cor)
	if estilo == "coque" then
		c.peca("Coque", BOLA, V3(0.45, 0.45, 0.45) * s, CF(0, yC + 0.5 * s, 0.45 * s), cor)
	elseif estilo == "longo" then
		c.peca("CabeloLongo", BLOCO, V3(1.0, 1.15, 0.3) * s, CF(0, yC - 0.3 * s, 0.42 * s), cor)
	elseif estilo == "espetado" then
		for i = -1, 1 do
			c.peca("Mecha", BLOCO, V3(0.22, 0.45, 0.22) * s, CF(i * 0.3 * s, yC + 0.62 * s, 0.05 * s) * ANG(0, 0, rad(-i * 25)), cor)
		end
	elseif estilo == "cacho" then
		c.peca("Cacho", BOLA, V3(0.2, 0.2, 0.2) * s, CF(0.1 * s, yC + 0.4 * s, -0.5 * s), cor)
	end
end

function CABECAS.cabelo(ctx)
	cabelo(ctx, ctx.v.estiloCabelo)
end
function CABECAS.bone(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Bone", V3(1.17, 0.62, 1.18) * s, CF(0, yC + 0.28 * s, 0.02 * s), cor)
	c.peca("Aba", BLOCO, V3(0.72, 0.07, 0.5) * s, CF(0, yC + 0.12 * s, -0.66 * s), cor)
end
function CABECAS.quepe(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Faixa", CILINDRO, V3(0.32, 1.17, 1.17) * s, CF(0, yC + 0.32 * s, 0) * EM_PE, cor)
	c.peca("Topo", CILINDRO, V3(0.14, 1.38, 1.38) * s, CF(0, yC + 0.52 * s, -0.05 * s) * EM_PE, cor)
	c.peca("Aba", BLOCO, V3(0.8, 0.06, 0.45) * s, CF(0, yC + 0.18 * s, -0.66 * s), PRETO)
	c.peca("Insignia", BLOCO, V3(0.2, 0.2, 0.05) * s, CF(0, yC + 0.34 * s, -0.6 * s) * ANG(0, 0, rad(45)), OURO, NEON)
end
function CABECAS.capaceteBombeiro(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Capacete", V3(1.3, 0.88, 1.35) * s, CF(0, yC + 0.3 * s, 0), cor, LISO)
	c.peca("Crista", BLOCO, V3(0.14, 0.24, 1.22) * s, CF(0, yC + 0.7 * s, 0.02 * s), cor)
	c.peca("AbaTras", BLOCO, V3(1.3, 0.08, 0.6) * s, CF(0, yC + 0.02 * s, 0.6 * s) * ANG(rad(-15), 0, 0), cor)
	c.peca("Escudo", BLOCO, V3(0.45, 0.42, 0.06) * s, CF(0, yC + 0.5 * s, -0.66 * s), OURO, FOLHA)
end
function CABECAS.toucaMedica(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Touca", V3(1.18, 0.72, 1.18) * s, CF(0, yC + 0.27 * s, 0.03 * s), cor)
	c.peca("CruzA", BLOCO, V3(0.08, 0.24, 0.04) * s, CF(0, yC + 0.4 * s, -0.56 * s), VERMELHO)
	c.peca("CruzB", BLOCO, V3(0.24, 0.08, 0.04) * s, CF(0, yC + 0.4 * s, -0.56 * s), VERMELHO)
end
function CABECAS.chapeuAbas(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Aba", CILINDRO, V3(0.08, 1.95, 1.95) * s, CF(0, yC + 0.36 * s, 0) * EM_PE, cor)
	c.peca("Copa", CILINDRO, V3(0.5, 1.12, 1.12) * s, CF(0, yC + 0.62 * s, 0) * EM_PE, cor)
	c.peca("Fita", CILINDRO, V3(0.12, 1.15, 1.15) * s, CF(0, yC + 0.45 * s, 0) * EM_PE, Color3.fromRGB(80, 55, 30))
end
function CABECAS.capaceteAstronauta(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Capacete", BOLA, V3(1.55, 1.55, 1.55) * s, CF(0, yC + 0.05 * s, 0), BRANCO)
	c.elipse("Visor", V3(1.05, 0.8, 0.55) * s, CF(0, yC + 0.05 * s, -0.55 * s), Color3.fromRGB(255, 185, 60), FOLHA)
	c.peca("Gola", CILINDRO, V3(0.2, 1.3, 1.3) * s, CF(0, yC - 0.72 * s, 0) * EM_PE, PRATA, METAL)
end
function CABECAS.capacetePiloto(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Capacete", BOLA, V3(1.3, 1.3, 1.3) * s, CF(0, yC + 0.1 * s, 0.02 * s), cor)
	c.elipse("Visor", V3(1.0, 0.45, 0.5) * s, CF(0, yC + 0.12 * s, -0.48 * s), Color3.fromRGB(30, 35, 50), VIDRO)
	c.peca("Faixa", BLOCO, V3(0.18, 0.08, 1.2) * s, CF(0, yC + 0.75 * s, 0.05 * s), VERMELHO)
end
function CABECAS.capuzAranha(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Mascara", BOLA, V3(1.13, 1.13, 1.13) * s, CF(0, yC, 0), cor)
	for _, lado in { -1, 1 } do
		c.elipse("ContornoOlho", V3(0.42, 0.3, 0.12) * s, CF(0.22 * s * lado, yC + 0.1 * s, -0.52 * s) * ANG(0, 0, rad(28 * lado)), PRETO)
		c.elipse("Olho", V3(0.34, 0.22, 0.1) * s, CF(0.22 * s * lado, yC + 0.1 * s, -0.56 * s) * ANG(0, 0, rad(28 * lado)), BRANCO)
	end
	-- linhas de teia na máscara
	c.peca("TeiaV", BLOCO, V3(0.03, 1.15, 0.03) * s, CF(0, yC, -0.565 * s), PRETO)
	c.peca("TeiaH", BLOCO, V3(1.15, 0.03, 0.03) * s, CF(0, yC - 0.28 * s, -0.47 * s), PRETO)
end
function CABECAS.capuzMorcego(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	local cor = ctx.v.cabecaCor
	c.peca("Capuz", BOLA, V3(1.14, 1.14, 1.14) * s, CF(0, yC, 0), cor)
	for _, lado in { -1, 1 } do
		c.peca("Orelha", BLOCO, V3(0.18, 0.62, 0.18) * s, CF(0.33 * s * lado, yC + 0.72 * s, 0) * ANG(0, 0, rad(-12 * lado)), cor)
		c.peca("Olho", BLOCO, V3(0.26, 0.09, 0.05) * s, CF(0.2 * s * lado, yC + 0.1 * s, -0.56 * s) * ANG(0, 0, rad(10 * lado)),
			Color3.fromRGB(120, 230, 255), NEON)
	end
end
function CABECAS.capaceteEstrela(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Capacete", V3(1.17, 0.82, 1.19) * s, CF(0, yC + 0.16 * s, 0.01 * s), cor)
	c.peca("EstrelaA", BLOCO, V3(0.24, 0.24, 0.04) * s, CF(0, yC + 0.42 * s, -0.56 * s), BRANCO)
	c.peca("EstrelaB", BLOCO, V3(0.24, 0.24, 0.04) * s, CF(0, yC + 0.42 * s, -0.565 * s) * ANG(0, 0, rad(45)), BRANCO)
	for _, lado in { -1, 1 } do
		c.peca("Asa", BLOCO, V3(0.06, 0.3, 0.18) * s, CF(0.6 * s * lado, yC + 0.2 * s, -0.05 * s) * ANG(rad(-25), 0, 0), BRANCO)
		c.peca("Olho", BLOCO, V3(0.16, 0.1, 0.05) * s, CF(0.19 * s * lado, yC + 0.08 * s, -0.56 * s), BRANCO)
	end
	c.peca("Boca", BLOCO, V3(0.3, 0.05, 0.05) * s, CF(0, yC - 0.2 * s, -0.51 * s), Color3.fromRGB(120, 40, 40))
	ctx.rostoFeito = true
end
function CABECAS.orelhasRaio(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Mascara", V3(1.17, 0.85, 1.19) * s, CF(0, yC + 0.13 * s, 0.01 * s), cor)
	for _, lado in { -1, 1 } do
		c.peca("RaioA", BLOCO, V3(0.07, 0.36, 0.12) * s, CF(0.59 * s * lado, yC + 0.28 * s, 0) * ANG(0, 0, rad(-30 * lado)), OURO, NEON)
		c.peca("RaioB", BLOCO, V3(0.07, 0.3, 0.12) * s, CF(0.64 * s * lado, yC + 0.5 * s, 0.05 * s) * ANG(0, 0, rad(25 * lado)), OURO, NEON)
		c.peca("Olho", BLOCO, V3(0.18, 0.09, 0.05) * s, CF(0.19 * s * lado, yC + 0.08 * s, -0.57 * s), BRANCO)
	end
	c.peca("Boca", BLOCO, V3(0.3, 0.05, 0.05) * s, CF(0, yC - 0.22 * s, -0.51 * s), Color3.fromRGB(120, 40, 40))
	ctx.rostoFeito = true
end
function CABECAS.elmoTrovao(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	cabelo(ctx, "longo")
	c.elipse("Elmo", V3(1.21, 0.68, 1.23) * s, CF(0, yC + 0.32 * s, 0.01 * s), PRATA, METAL)
	for _, lado in { -1, 1 } do
		c.peca("AsaElmo", BLOCO, V3(0.06, 0.55, 0.32) * s, CF(0.62 * s * lado, yC + 0.55 * s, 0.05 * s) * ANG(rad(-20), 0, rad(-20 * lado)), BRANCO)
	end
end
function CABECAS.tiara(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	cabelo(ctx, "longo")
	c.peca("Tiara", CILINDRO, V3(0.12, 1.19, 1.19) * s, CF(0, yC + 0.32 * s, 0) * EM_PE, OURO, FOLHA)
	c.peca("EstrelaTiara", BLOCO, V3(0.18, 0.18, 0.05) * s, CF(0, yC + 0.36 * s, -0.6 * s) * ANG(0, 0, rad(45)), VERMELHO, NEON)
end
function CABECAS.capaceteArmadura(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Capacete", BOLA, V3(1.16, 1.16, 1.16) * s, CF(0, yC, 0), cor, METAL)
	c.elipse("Placa", V3(0.8, 0.88, 0.38) * s, CF(0, yC - 0.02 * s, -0.42 * s), OURO, FOLHA)
	for _, lado in { -1, 1 } do
		c.peca("Olho", BLOCO, V3(0.22, 0.07, 0.05) * s, CF(0.17 * s * lado, yC + 0.12 * s, -0.6 * s), Color3.fromRGB(200, 250, 255), NEON)
	end
end

function ROSTOS.mascaraDomino(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Domino", BLOCO, V3(0.85, 0.22, 0.08) * s, CF(0, yC + 0.1 * s, -0.53 * s), ctx.v.mascaraCor or PRETO)
	for _, lado in { -1, 1 } do
		c.peca("OlhoMascara", BLOCO, V3(0.16, 0.08, 0.04) * s, CF(0.19 * s * lado, yC + 0.1 * s, -0.575 * s), BRANCO)
	end
end
function ROSTOS.oculosVoo(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Tira", BLOCO, V3(1.15, 0.12, 1.15) * s, CF(0, yC + 0.12 * s, 0), PRETO)
	for _, lado in { -1, 1 } do
		c.elipse("Lente", V3(0.34, 0.28, 0.14) * s, CF(0.2 * s * lado, yC + 0.1 * s, -0.53 * s), Color3.fromRGB(230, 40, 40), VIDRO)
	end
end
function ROSTOS.viseira(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Viseira", BLOCO, V3(1.0, 0.2, 0.12) * s, CF(0, yC + 0.1 * s, -0.53 * s), Color3.fromRGB(255, 30, 30), NEON)
	c.peca("TiraViseira", BLOCO, V3(1.14, 0.14, 1.14) * s, CF(0, yC + 0.1 * s, 0), Color3.fromRGB(255, 200, 0))
end
function ROSTOS.olhosBrancos(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	for _, lado in { -1, 1 } do
		c.peca("OlhoBranco", BOLA, V3(0.17, 0.17, 0.17) * s, CF(0.19 * s * lado, yC + 0.08 * s, -0.505 * s), BRANCO, NEON)
	end
end
function ROSTOS.barba(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.elipse("Barba", V3(0.85, 0.45, 0.45) * s, CF(0, yC - 0.3 * s, -0.33 * s), ctx.v.cabelo or CASTANHO_PADRAO)
	c.peca("Boca", BLOCO, V3(0.26, 0.05, 0.05) * s, CF(0, yC - 0.2 * s, -0.53 * s), Color3.fromRGB(120, 40, 40))
end

function CABECAS.capaceteFormiga(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Capacete", BOLA, V3(1.2, 1.2, 1.2) * s, CF(0, yC, 0), cor, METAL)
	for _, lado in { -1, 1 } do
		c.elipse("Lente", V3(0.38, 0.32, 0.14) * s, CF(0.22 * s * lado, yC + 0.1 * s, -0.53 * s), Color3.fromRGB(255, 90, 40), VIDRO)
		c.peca("Antena", BLOCO, V3(0.05, 0.6, 0.05) * s, CF(0.25 * s * lado, yC + 0.8 * s, -0.1 * s) * ANG(0, 0, rad(-20 * lado)), PRETO)
		c.peca("Disco", CILINDRO, V3(0.14, 0.4, 0.4) * s, CF(0.62 * s * lado, yC, 0), Color3.fromRGB(190, 30, 30))
	end
	c.peca("Grade", BLOCO, V3(0.5, 0.18, 0.1) * s, CF(0, yC - 0.27 * s, -0.55 * s), PRATA, METAL)
end
function CABECAS.capuzArqueiro(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Capuz", V3(1.25, 1.3, 1.3) * s, CF(0, yC + 0.1 * s, 0.22 * s), cor)
	c.peca("PontaCapuz", BLOCO, V3(0.3, 0.3, 0.4) * s, CF(0, yC + 0.55 * s, 0.75 * s) * ANG(rad(35), 0, 0), cor)
end
function CABECAS.magoCabelo(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	cabelo(ctx)
	for _, lado in { -1, 1 } do
		c.peca("Grisalho", BLOCO, V3(0.08, 0.3, 0.3) * s, CF(0.56 * s * lado, yC + 0.15 * s, 0), Color3.fromRGB(220, 220, 225))
	end
	c.peca("Cavanhaque", BLOCO, V3(0.22, 0.22, 0.1) * s, CF(0, yC - 0.38 * s, -0.45 * s), ctx.v.cabelo or PRETO)
end
function CABECAS.capuzPantera(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Mascara", BOLA, V3(1.13, 1.13, 1.13) * s, CF(0, yC, 0), PRETO)
	for _, lado in { -1, 1 } do
		c.peca("Orelha", BLOCO, V3(0.22, 0.24, 0.12) * s, CF(0.33 * s * lado, yC + 0.55 * s, -0.05 * s) * ANG(0, 0, rad(45)), PRETO)
		c.peca("Olho", BLOCO, V3(0.24, 0.08, 0.05) * s, CF(0.19 * s * lado, yC + 0.1 * s, -0.565 * s) * ANG(0, 0, rad(12 * lado)), BRANCO, NEON)
		c.peca("Linha", BLOCO, V3(0.04, 0.5, 0.04) * s, CF(0.12 * s * lado, yC + 0.3 * s, -0.5 * s) * ANG(rad(-25), 0, rad(15 * lado)), PRATA, NEON)
	end
end
function CABECAS.capuzGata(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Mascara", BOLA, V3(1.13, 1.13, 1.13) * s, CF(0, yC, 0), PRETO)
	for _, lado in { -1, 1 } do
		c.peca("Orelha", BLOCO, V3(0.22, 0.26, 0.12) * s, CF(0.3 * s * lado, yC + 0.56 * s, 0) * ANG(0, 0, rad(45)), PRETO)
		c.elipse("Oculos", V3(0.3, 0.22, 0.1) * s, CF(0.2 * s * lado, yC + 0.12 * s, -0.53 * s), Color3.fromRGB(90, 220, 140), VIDRO)
	end
	c.peca("Labios", BLOCO, V3(0.22, 0.06, 0.05) * s, CF(0, yC - 0.25 * s, -0.53 * s), Color3.fromRGB(200, 30, 50))
end
function CABECAS.capuzSimbionte(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Mascara", BOLA, V3(1.16, 1.16, 1.16) * s, CF(0, yC, 0), PRETO)
	for _, lado in { -1, 1 } do
		c.elipse("Olho", V3(0.42, 0.32, 0.1) * s, CF(0.22 * s * lado, yC + 0.12 * s, -0.55 * s) * ANG(0, 0, rad(35 * lado)), BRANCO)
	end
	c.peca("Dentes", BLOCO, V3(0.62, 0.12, 0.06) * s, CF(0, yC - 0.25 * s, -0.54 * s), BRANCO)
	c.peca("Lingua", BLOCO, V3(0.14, 0.3, 0.06) * s, CF(0.05 * s, yC - 0.42 * s, -0.55 * s), Color3.fromRGB(200, 40, 60))
end
function CABECAS.mascaraMercenario(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.peca("Mascara", BOLA, V3(1.13, 1.13, 1.13) * s, CF(0, yC, 0), cor)
	for _, lado in { -1, 1 } do
		c.elipse("Mancha", V3(0.4, 0.36, 0.1) * s, CF(0.21 * s * lado, yC + 0.1 * s, -0.53 * s), PRETO)
		c.elipse("Olho", V3(0.2, 0.14, 0.06) * s, CF(0.21 * s * lado, yC + 0.1 * s, -0.585 * s), BRANCO)
	end
end
function CABECAS.mascaraGarra(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	c.elipse("Mascara", V3(1.17, 0.85, 1.19) * s, CF(0, yC + 0.14 * s, 0.01 * s), cor)
	for _, lado in { -1, 1 } do
		c.elipse("Mancha", V3(0.36, 0.3, 0.1) * s, CF(0.2 * s * lado, yC + 0.12 * s, -0.53 * s) * ANG(0, 0, rad(20 * lado)), PRETO)
		c.peca("Olho", BLOCO, V3(0.18, 0.06, 0.04) * s, CF(0.2 * s * lado, yC + 0.12 * s, -0.585 * s), BRANCO)
		c.peca("Chifre", BLOCO, V3(0.1, 0.55, 0.12) * s, CF(0.42 * s * lado, yC + 0.6 * s, -0.1 * s) * ANG(0, 0, rad(-30 * lado)), PRETO)
	end
	c.peca("Boca", BLOCO, V3(0.3, 0.05, 0.05) * s, CF(0, yC - 0.22 * s, -0.51 * s), Color3.fromRGB(120, 40, 40))
	ctx.rostoFeito = true
end
function CABECAS.capaceteCiborgue(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	cabelo(ctx)
	c.elipse("MetadeMetal", V3(0.62, 1.16, 1.16) * s, CF(0.27 * s, yC, 0), PRATA, METAL)
	c.peca("OlhoRobo", BOLA, V3(0.2, 0.2, 0.2) * s, CF(0.2 * s, yC + 0.08 * s, -0.52 * s), Color3.fromRGB(255, 30, 30), NEON)
end
function CABECAS.cabecaPedra(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	local cor = ctx.v.pele
	c.peca("CabecaPedra", BLOCO, V3(1.2, 1.1, 1.15) * s, CF(0, yC, 0), cor, Enum.Material.Slate)
	c.peca("Testa", BLOCO, V3(1.05, 0.22, 0.25) * s, CF(0, yC + 0.25 * s, -0.55 * s), cor:Lerp(PRETO, 0.2), Enum.Material.Slate)
	for _, lado in { -1, 1 } do
		c.peca("Olho", BLOCO, V3(0.16, 0.1, 0.05) * s, CF(0.22 * s * lado, yC + 0.08 * s, -0.59 * s), Color3.fromRGB(80, 160, 255))
	end
	c.peca("Boca", BLOCO, V3(0.4, 0.06, 0.05) * s, CF(0, yC - 0.25 * s, -0.59 * s), PRETO)
end
function CABECAS.cabecaFogo(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	for i = -2, 2 do
		c.peca("Chama", BLOCO, V3(0.22, 0.5 + (2 - math.abs(i)) * 0.15, 0.22) * s, CF(i * 0.22 * s, yC + 0.6 * s, 0.05 * s) * ANG(0, 0, rad(-i * 12)),
			i % 2 == 0 and Color3.fromRGB(255, 230, 80) or Color3.fromRGB(255, 140, 20), NEON)
	end
end
function CABECAS.androide(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Gema", BLOCO, V3(0.22, 0.22, 0.06) * s, CF(0, yC + 0.32 * s, -0.5 * s) * ANG(0, 0, rad(45)), Color3.fromRGB(255, 220, 60), NEON)
	for _, lado in { -1, 1 } do
		c.peca("Linha", BLOCO, V3(0.04, 0.9, 0.04) * s, CF(0.3 * s * lado, yC + 0.1 * s, -0.42 * s) * ANG(rad(-30), 0, 0), Color3.fromRGB(40, 120, 70))
	end
end
function CABECAS.capuzCorvo(ctx)
	local c, s, yC, cor = ctx.c, ctx.s, ctx.yC, ctx.v.cabecaCor
	cabelo(ctx)
	c.elipse("Capuz", V3(1.3, 1.32, 1.3) * s, CF(0, yC + 0.08 * s, 0.24 * s), cor)
	c.peca("Gema", BOLA, V3(0.12, 0.12, 0.12) * s, CF(0, yC + 0.3 * s, -0.51 * s), Color3.fromRGB(230, 30, 40), NEON)
end
function CABECAS.tiaraBruxa(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	cabelo(ctx, "longo")
	for _, lado in { -1, 1 } do
		c.peca("Tiara", BLOCO, V3(0.08, 0.5, 0.06) * s, CF(0.12 * s * lado, yC + 0.42 * s, -0.5 * s) * ANG(0, 0, rad(30 * lado)), Color3.fromRGB(190, 20, 40))
	end
	c.peca("TiaraCentro", BLOCO, V3(0.5, 0.08, 0.06) * s, CF(0, yC + 0.26 * s, -0.53 * s), Color3.fromRGB(190, 20, 40))
end
function CABECAS.mascaraLorde(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	c.peca("Mascara", BOLA, V3(1.15, 1.15, 1.15) * s, CF(0, yC, 0), Color3.fromRGB(70, 30, 30), METAL)
	for _, lado in { -1, 1 } do
		c.elipse("Olho", V3(0.36, 0.3, 0.12) * s, CF(0.22 * s * lado, yC + 0.1 * s, -0.52 * s), Color3.fromRGB(255, 40, 40), NEON)
		c.peca("Orelha", CILINDRO, V3(0.16, 0.36, 0.36) * s, CF(0.6 * s * lado, yC, 0), PRATA, METAL)
	end
	for k = -1, 1 do
		c.peca("Grade", BLOCO, V3(0.08, 0.22, 0.06) * s, CF(k * 0.14 * s, yC - 0.28 * s, -0.55 * s), PRATA, METAL)
	end
end
function CABECAS.cabeloChamas(ctx)
	local c, s, yC = ctx.c, ctx.s, ctx.yC
	cabelo(ctx, "longo")
	for i = -1, 1 do
		c.peca("ChamaCabelo", BLOCO, V3(0.25, 0.55, 0.25) * s, CF(i * 0.3 * s, yC + 0.65 * s, 0.25 * s) * ANG(rad(-20), 0, rad(-i * 15)),
			Color3.fromRGB(255, 150, 30), NEON)
	end
end
CABECAS_SEM_ROSTO.capaceteFormiga = true
CABECAS_SEM_ROSTO.capuzPantera = true
CABECAS_SEM_ROSTO.capuzGata = true
CABECAS_SEM_ROSTO.capuzSimbionte = true
CABECAS_SEM_ROSTO.mascaraMercenario = true
CABECAS_SEM_ROSTO.cabecaPedra = true
CABECAS_SEM_ROSTO.mascaraLorde = true

--------------------------------------------------------------------------
-- DETALHES DO CORPO
--------------------------------------------------------------------------
local CORPO = {}
function CORPO.faixasRefletivas(ctx)
	local c, s, L = ctx.c, ctx.s, ctx.L
	for _, y in { -0.3, 0.25 } do
		c.peca("Faixa", BLOCO, V3(1.64 * L, 0.13, 0.94) * s, CF(0, y * s, 0), REFLETIVO, NEON)
	end
	for _, lado in { -1, 1 } do
		c.peca("FaixaPerna", BLOCO, V3(0.64 * L, 0.11, 0.64) * s, CF(0.42 * s * L * lado, -1.55 * s, 0), REFLETIVO, NEON)
		c.peca("FaixaBraco", BLOCO, V3(0.49 * L, 0.1, 0.49 * L) * s, CF(1.08 * s * L * lado, -0.3 * s, 0) * ANG(0, 0, rad(8 * lado)), REFLETIVO, NEON)
	end
end
function CORPO.jaleco(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Jaleco", BLOCO, V3(1.66, 1.62, 0.96) * s, CF(0, 0, 0), BRANCO)
	c.peca("CamisaV", BLOCO, V3(0.42, 0.7, 0.05) * s, CF(0, 0.42 * s, -0.48 * s), ctx.v.camisa)
	c.peca("Barra", BLOCO, V3(1.64, 0.85, 0.98) * s, CF(0, -1.2 * s, 0), BRANCO)
	c.peca("Abertura", BLOCO, V3(0.08, 0.85, 0.06) * s, CF(0, -1.2 * s, -0.5 * s), Color3.fromRGB(200, 200, 205))
	for _, lado in { -1, 1 } do
		c.peca("Bolso", BLOCO, V3(0.32, 0.25, 0.04) * s, CF(0.45 * s * lado, -0.35 * s, -0.5 * s), Color3.fromRGB(225, 225, 230))
	end
end
function CORPO.colete(ctx)
	local c, s = ctx.c, ctx.s
	local cor = ctx.v.coleteCor or Color3.fromRGB(255, 130, 0)
	c.peca("Colete", BLOCO, V3(1.66, 1.45, 0.96) * s, CF(0, 0.05 * s, 0), cor)
	c.peca("FaixaColete", BLOCO, V3(1.68, 0.14, 0.98) * s, CF(0, -0.15 * s, 0), REFLETIVO, NEON)
	c.peca("CruzA", BLOCO, V3(0.1, 0.34, 0.04) * s, CF(0.4 * s, 0.38 * s, -0.5 * s), BRANCO)
	c.peca("CruzB", BLOCO, V3(0.34, 0.1, 0.04) * s, CF(0.4 * s, 0.38 * s, -0.5 * s), BRANCO)
end
function CORPO.avental(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Avental", BLOCO, V3(1.2, 1.9, 0.06) * s, CF(0, -0.5 * s, -0.48 * s), Color3.fromRGB(240, 220, 160))
	c.peca("Bolso", BLOCO, V3(0.6, 0.35, 0.04) * s, CF(0, -0.65 * s, -0.52 * s), Color3.fromRGB(220, 190, 120))
end
function CORPO.estetoscopio(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("Tubo", BLOCO, V3(0.06, 0.65, 0.06) * s, CF(0.28 * s * lado, 0.38 * s, -0.5 * s) * ANG(0, 0, rad(-10 * lado)), PRETO)
	end
	c.peca("TuboBaixo", BLOCO, V3(0.06, 0.4, 0.06) * s, CF(0.2 * s, -0.12 * s, -0.5 * s), PRETO)
	c.peca("Disco", CILINDRO, V3(0.06, 0.2, 0.2) * s, CF(0.2 * s, -0.36 * s, -0.52 * s) * DE_FRENTE, PRATA, METAL)
end
function CORPO.distintivo(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Distintivo", BLOCO, V3(0.24, 0.24, 0.05) * s, CF(0.45 * s, 0.4 * s, -0.48 * s) * ANG(0, 0, rad(45)), OURO, FOLHA)
	c.peca("Bolso", BLOCO, V3(0.32, 0.22, 0.04) * s, CF(-0.45 * s, 0.35 * s, -0.48 * s), ctx.v.camisa:Lerp(PRETO, 0.25))
end
function CORPO.cintoUtilidade(ctx)
	local c, s, L = ctx.c, ctx.s, ctx.L
	local cor = ctx.v.cintoCor or Color3.fromRGB(255, 200, 40)
	c.peca("Cinto", BLOCO, V3(1.66 * L, 0.22, 0.96) * s, CF(0, -0.68 * s, 0), cor)
	for i = -2, 2 do
		if i ~= 0 then
			c.peca("Bolsinha", BLOCO, V3(0.22, 0.24, 0.12) * s, CF(i * 0.3 * s * L, -0.68 * s, -0.52 * s), cor:Lerp(PRETO, 0.25))
		end
	end
	c.peca("Fivela", BLOCO, V3(0.26, 0.2, 0.08) * s, CF(0, -0.68 * s, -0.52 * s), OURO, NEON)
end
function CORPO.teia(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("TeiaV", BLOCO, V3(0.03, 1.6, 0.03) * s, CF(0, 0, -0.47 * s), PRETO)
	for _, y in { -0.45, 0, 0.45 } do
		c.peca("TeiaH", BLOCO, V3(1.6, 0.03, 0.03) * s, CF(0, y * s, -0.47 * s), PRETO)
	end
	for _, lado in { -1, 1 } do
		c.peca("TeiaD", BLOCO, V3(0.03, 2.1, 0.03) * s, CF(0, 0, -0.47 * s) * ANG(0, 0, rad(40 * lado)), PRETO)
	end
end
function CORPO.listrasPeito(ctx)
	local c, s = ctx.c, ctx.s
	for i = 0, 2 do
		c.peca("Listra", BLOCO, V3(1.62, 0.12, 0.92) * s, CF(0, (-0.35 - i * 0.14) * s, 0), i % 2 == 0 and VERMELHO or BRANCO)
	end
end
function CORPO.discosPeito(ctx)
	local c, s = ctx.c, ctx.s
	for _, x in { -0.4, 0.4 } do
		for _, y in { 0.45, 0.05, -0.35 } do
			c.peca("Disco", CILINDRO, V3(0.06, 0.32, 0.32) * s, CF(x * s, y * s, -0.47 * s) * DE_FRENTE, PRATA, METAL)
		end
	end
end
function CORPO.faixasAmarelas(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("Faixa", BLOCO, V3(0.12, 1.62, 0.94) * s, CF(0.72 * s * lado, 0, 0), Color3.fromRGB(255, 210, 0))
	end
end
function CORPO.binoculo(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("Lente", CILINDRO, V3(0.3, 0.2, 0.2) * s, CF(0.12 * s * lado, -0.1 * s, -0.55 * s) * DE_FRENTE, PRETO)
	end
	c.peca("Alca", BLOCO, V3(0.05, 0.9, 0.05) * s, CF(0, 0.35 * s, -0.48 * s), Color3.fromRGB(90, 60, 35))
end
function CORPO.armaduraOuro(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Peitoral", BLOCO, V3(1.4, 0.7, 0.08) * s, CF(0, 0.4 * s, -0.47 * s), OURO, FOLHA)
	c.peca("Saia", BLOCO, V3(1.68, 0.5, 0.98) * s, CF(0, -0.95 * s, 0), Color3.fromRGB(30, 60, 160))
	c.peca("Cinto", BLOCO, V3(1.66, 0.16, 0.96) * s, CF(0, -0.68 * s, 0), OURO, FOLHA)
end

--------------------------------------------------------------------------
-- EMBLEMAS NO PEITO
--------------------------------------------------------------------------
local EMBLEMAS = {}
local function emblemaCF(s, y)
	return CF(0, (y or 0.25) * s, -0.47 * s)
end
function EMBLEMAS.cruz(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("CruzFundo", BLOCO, V3(0.42, 0.42, 0.04) * s, CF(-0.42 * s, 0.4 * s, -0.47 * s), BRANCO)
	c.peca("CruzA", BLOCO, V3(0.1, 0.32, 0.05) * s, CF(-0.42 * s, 0.4 * s, -0.49 * s), VERMELHO)
	c.peca("CruzB", BLOCO, V3(0.32, 0.1, 0.05) * s, CF(-0.42 * s, 0.4 * s, -0.49 * s), VERMELHO)
end
function EMBLEMAS.estrela(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Circulo", CILINDRO, V3(0.05, 0.8, 0.8) * s, emblemaCF(s) * DE_FRENTE, Color3.fromRGB(230, 235, 245))
	c.peca("EstrelaA", BLOCO, V3(0.38, 0.38, 0.06) * s, emblemaCF(s) * CF(0, 0, -0.03 * s), Color3.fromRGB(30, 60, 170))
	c.peca("EstrelaB", BLOCO, V3(0.38, 0.38, 0.06) * s, emblemaCF(s) * CF(0, 0, -0.035 * s) * ANG(0, 0, rad(45)), Color3.fromRGB(30, 60, 170))
end
function EMBLEMAS.raio(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Circulo", CILINDRO, V3(0.05, 0.85, 0.85) * s, emblemaCF(s) * DE_FRENTE, BRANCO)
	c.peca("RaioA", BLOCO, V3(0.12, 0.42, 0.05) * s, emblemaCF(s) * CF(0.06 * s, 0.14 * s, -0.04 * s) * ANG(0, 0, rad(-25)), OURO, NEON)
	c.peca("RaioB", BLOCO, V3(0.3, 0.1, 0.05) * s, emblemaCF(s) * CF(0, 0, -0.045 * s) * ANG(0, 0, rad(-15)), OURO, NEON)
	c.peca("RaioC", BLOCO, V3(0.12, 0.42, 0.05) * s, emblemaCF(s) * CF(-0.06 * s, -0.14 * s, -0.04 * s) * ANG(0, 0, rad(-25)), OURO, NEON)
end
function EMBLEMAS.aranha(ctx)
	local c, s = ctx.c, ctx.s
	local cor = ctx.v.emblemaCor or PRETO
	local esc = ctx.v.largo and 1.6 or 1
	c.elipse("Corpo", V3(0.18, 0.3, 0.08) * s * esc, emblemaCF(s, 0.2), cor)
	c.peca("Cabeca", BOLA, V3(0.12, 0.12, 0.12) * s * esc, emblemaCF(s, 0.2 + 0.2 * esc), cor)
	for _, lado in { -1, 1 } do
		for k = 0, 3 do
			local ang = rad(lado * (35 + k * 32))
			c.peca("Perna", BLOCO, V3(0.03, 0.34 * esc, 0.03) * s, emblemaCF(s, 0.22) * ANG(0, 0, ang) * CF(0, 0.17 * s * esc, -0.01 * s), cor)
		end
	end
end
function EMBLEMAS.morcego(ctx)
	-- emblema original: lua crescente com três garras
	local c, s = ctx.c, ctx.s
	c.peca("Lua", CILINDRO, V3(0.05, 0.75, 0.75) * s, emblemaCF(s) * DE_FRENTE, Color3.fromRGB(110, 225, 255), NEON)
	c.peca("Sombra", CILINDRO, V3(0.06, 0.62, 0.62) * s, emblemaCF(s) * CF(0.16 * s, 0.1 * s, -0.01 * s) * DE_FRENTE, ctx.v.camisa)
	for k = -1, 1 do
		c.peca("Garra", BLOCO, V3(0.06, 0.5, 0.05) * s, emblemaCF(s) * CF(k * 0.15 * s, 0, -0.04 * s) * ANG(0, 0, rad(-20)),
			Color3.fromRGB(200, 140, 255), NEON)
	end
end
function EMBLEMAS.reator(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Anel", CILINDRO, V3(0.05, 0.62, 0.62) * s, emblemaCF(s) * DE_FRENTE, PRATA, METAL)
	c.peca("Reator", CILINDRO, V3(0.06, 0.42, 0.42) * s, emblemaCF(s) * CF(0, 0, -0.02 * s) * DE_FRENTE, Color3.fromRGB(140, 240, 255), NEON)
end
function EMBLEMAS.supremo(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Diamante", BLOCO, V3(0.62, 0.62, 0.05) * s, emblemaCF(s) * ANG(0, 0, rad(45)), OURO)
	c.peca("DiamanteInterno", BLOCO, V3(0.44, 0.44, 0.05) * s, emblemaCF(s) * CF(0, 0, -0.02 * s) * ANG(0, 0, rad(45)), VERMELHO)
	c.peca("Brilho", BLOCO, V3(0.14, 0.14, 0.05) * s, emblemaCF(s) * CF(0, 0, -0.04 * s) * ANG(0, 0, rad(45)), OURO, NEON)
end
function EMBLEMAS.bandeira(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Bandeira", BLOCO, V3(0.4, 0.26, 0.04) * s, CF(-0.45 * s, 0.45 * s, -0.47 * s), Color3.fromRGB(0, 140, 70))
	c.peca("Losango", BLOCO, V3(0.16, 0.16, 0.05) * s, CF(-0.45 * s, 0.45 * s, -0.49 * s) * ANG(0, 0, rad(45)), Color3.fromRGB(255, 220, 0))
end

--------------------------------------------------------------------------
-- ITENS NAS MÃOS (mão direita = +X)
--------------------------------------------------------------------------
local MAOS = {}
function MAOS.extintor(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Extintor", CILINDRO, V3(0.95, 0.42, 0.42) * s, CF(hx, hy - 0.2 * s, -0.3 * s) * EM_PE, VERMELHO)
	c.peca("Valvula", BLOCO, V3(0.22, 0.18, 0.22) * s, CF(hx, hy + 0.35 * s, -0.3 * s), PRETO)
	c.peca("Bico", BLOCO, V3(0.08, 0.08, 0.4) * s, CF(hx, hy + 0.38 * s, -0.55 * s), PRETO)
end
function MAOS.machado(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Cabo", BLOCO, V3(0.09, 1.5, 0.09) * s, CF(hx, hy + 0.3 * s, -0.1 * s), Color3.fromRGB(120, 80, 40))
	c.peca("Lamina", BLOCO, V3(0.08, 0.36, 0.5) * s, CF(hx, hy + 0.9 * s, -0.36 * s), VERMELHO)
	c.peca("Fio", BLOCO, V3(0.09, 0.4, 0.06) * s, CF(hx, hy + 0.9 * s, -0.63 * s), PRATA, METAL)
end
function MAOS.vassoura(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Cabo", BLOCO, V3(0.08, 2.3, 0.08) * s, CF(hx, hy - 0.15 * s, -0.15 * s), Color3.fromRGB(255, 200, 40))
	c.peca("Cerdas", BLOCO, V3(0.7, 0.35, 0.22) * s, CF(hx, hy - 1.3 * s, -0.15 * s), Color3.fromRGB(70, 60, 50))
end
function MAOS.livro(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Capa", BLOCO, V3(0.18, 0.62, 0.5) * s, CF(hx + 0.05 * s, hy, -0.15 * s), Color3.fromRGB(40, 90, 200))
	c.peca("Paginas", BLOCO, V3(0.16, 0.56, 0.44) * s, CF(hx + 0.07 * s, hy, -0.17 * s), BRANCO)
end
function MAOS.maleta(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Maleta", BLOCO, V3(0.32, 0.55, 0.75) * s, CF(hx + 0.05 * s, hy - 0.42 * s, 0), BRANCO)
	c.peca("CruzA", BLOCO, V3(0.34, 0.32, 0.1) * s, CF(hx + 0.05 * s, hy - 0.42 * s, 0), VERMELHO)
	c.peca("CruzB", BLOCO, V3(0.34, 0.1, 0.32) * s, CF(hx + 0.05 * s, hy - 0.42 * s, 0), VERMELHO)
	c.peca("Alca", BLOCO, V3(0.08, 0.12, 0.3) * s, CF(hx + 0.05 * s, hy - 0.08 * s, 0), PRETO)
end
function MAOS.frasco(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Frasco", BOLA, V3(0.42, 0.42, 0.42) * s, CF(hx, hy + 0.2 * s, -0.25 * s), Color3.fromRGB(80, 255, 140), NEON, { transparencia = 0.1 })
	c.peca("Gargalo", CILINDRO, V3(0.25, 0.14, 0.14) * s, CF(hx, hy + 0.5 * s, -0.25 * s) * EM_PE, Color3.fromRGB(200, 240, 255), VIDRO)
end
function MAOS.boia(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.anel("Boia", 0.42 * s, 10, V3(0.26, 0.24, 0.2) * s, CF(hx + 0.15 * s, hy - 0.2 * s, -0.15 * s) * ANG(0, rad(90), 0),
		{ VERMELHO, BRANCO })
end
function MAOS.prancheta(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Prancheta", BLOCO, V3(0.08, 0.7, 0.55) * s, CF(hx + 0.1 * s, hy + 0.1 * s, -0.2 * s), Color3.fromRGB(150, 100, 50))
	c.peca("Papel", BLOCO, V3(0.09, 0.58, 0.46) * s, CF(hx + 0.11 * s, hy + 0.06 * s, -0.2 * s), BRANCO)
	c.peca("Clipe", BLOCO, V3(0.1, 0.08, 0.2) * s, CF(hx + 0.12 * s, hy + 0.42 * s, -0.2 * s), PRATA, METAL)
end
function MAOS.lanterna(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Lanterna", CILINDRO, V3(0.6, 0.16, 0.16) * s, CF(hx, hy, -0.35 * s) * DE_FRENTE, PRETO)
	c.peca("Luz", CILINDRO, V3(0.06, 0.2, 0.2) * s, CF(hx, hy, -0.66 * s) * DE_FRENTE, Color3.fromRGB(255, 250, 200), NEON)
end
function MAOS.carta(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Carta", BLOCO, V3(0.06, 0.38, 0.58) * s, CF(hx + 0.08 * s, hy + 0.1 * s, -0.2 * s), BRANCO)
	c.peca("Selo", BLOCO, V3(0.07, 0.1, 0.1) * s, CF(hx + 0.1 * s, hy + 0.18 * s, -0.4 * s), VERMELHO)
end
function MAOS.martelo(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Cabo", BLOCO, V3(0.12, 1.0, 0.12) * s, CF(hx, hy + 0.1 * s, -0.15 * s), Color3.fromRGB(110, 70, 40))
	c.peca("Cabeca", BLOCO, V3(0.45, 0.42, 0.7) * s, CF(hx, hy + 0.72 * s, -0.15 * s), PRATA, METAL)
	c.peca("Brilho", BLOCO, V3(0.47, 0.06, 0.72) * s, CF(hx, hy + 0.72 * s, -0.15 * s), Color3.fromRGB(150, 220, 255), NEON)
end
function MAOS.laco(ctx)
	local c, s = ctx.c, ctx.s
	c.anel("Laco", 0.26 * s, 10, V3(0.1, 0.16, 0.1) * s, CF(0.7 * s, -0.75 * s, -0.25 * s) * ANG(0, rad(70), 0), { OURO }, NEON)
end
local MAOS_ESQUERDA = {}
function MAOS_ESQUERDA.escudo(ctx)
	local c, s = ctx.c, ctx.s
	local base = CF(-1.32 * s * ctx.L, -0.15 * s, -0.25 * s) * ANG(0, rad(-70), 0)
	local aneis = { { 1.35, VERMELHO }, { 1.05, BRANCO }, { 0.75, VERMELHO }, { 0.48, Color3.fromRGB(30, 60, 170) } }
	for i, info in aneis do
		c.peca("Escudo", CILINDRO, V3(0.08, info[1], info[1]) * s, base * CF(0, 0, -0.03 * s * i) * DE_FRENTE, info[2], METAL)
	end
	c.peca("EstrelaA", BLOCO, V3(0.26, 0.26, 0.05) * s, base * CF(0, 0, -0.16 * s), BRANCO, NEON)
	c.peca("EstrelaB", BLOCO, V3(0.26, 0.26, 0.05) * s, base * CF(0, 0, -0.165 * s) * ANG(0, 0, rad(45)), BRANCO, NEON)
end

--------------------------------------------------------------------------
-- COSTAS
--------------------------------------------------------------------------
local COSTAS = {}
function COSTAS.tanque(ctx)
	local c, s = ctx.c, ctx.s
	local cor = ctx.v.tanqueCor or Color3.fromRGB(255, 200, 0)
	for _, lado in { -1, 1 } do
		c.peca("Tanque", CILINDRO, V3(1.2, 0.4, 0.4) * s, CF(0.22 * s * lado, 0.05 * s, 0.68 * s) * EM_PE, cor, METAL)
	end
	c.peca("Valvula", BLOCO, V3(0.5, 0.12, 0.12) * s, CF(0, 0.7 * s, 0.68 * s), PRATA, METAL)
end
function COSTAS.mochilaAstronauta(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Mochila", BLOCO, V3(1.3, 1.35, 0.55) * s, CF(0, 0.1 * s, 0.72 * s), BRANCO)
	c.peca("Painel", BLOCO, V3(0.5, 0.3, 0.05) * s, CF(0.2 * s, 0.4 * s, 1.0 * s), Color3.fromRGB(60, 140, 255), NEON)
end
function COSTAS.bolsaCarteiro(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Bolsa", BLOCO, V3(0.32, 0.6, 0.75) * s, CF(0.98 * s, -0.55 * s, 0.05 * s), Color3.fromRGB(130, 85, 45))
	c.peca("Alca", BLOCO, V3(0.08, 2.1, 0.06) * s, CF(0, 0.05 * s, -0.48 * s) * ANG(0, 0, rad(42)), Color3.fromRGB(110, 70, 35))
end

function CORPO.escamas(ctx)
	local c, s = ctx.c, ctx.s
	for _, y in { 0.45, 0.15, -0.15, -0.45 } do
		for _, x in { -0.4, 0, 0.4 } do
			c.peca("Escama", BLOCO, V3(0.3, 0.05, 0.04) * s, CF((x + (y * 0.3)) * s, y * s, -0.47 * s), Color3.fromRGB(255, 220, 90))
		end
	end
end
function CORPO.linhasPrata(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("Linha", BLOCO, V3(0.05, 1.2, 0.04) * s, CF(0.35 * s * lado, 0, -0.47 * s) * ANG(0, 0, rad(20 * lado)), PRATA, NEON)
		c.peca("LinhaPerna", BLOCO, V3(0.04, 1.0, 0.64) * s, CF(0.42 * s * lado, -1.4 * s, 0), PRATA, NEON)
	end
end
function CORPO.colar(ctx)
	local c, s = ctx.c, ctx.s
	for k = -3, 3 do
		c.peca("Dente", BLOCO, V3(0.1, 0.18, 0.05) * s, CF(k * 0.12 * s, (0.62 - math.abs(k) * 0.05) * s, -0.48 * s), PRATA, METAL)
	end
end
function CORPO.robe(ctx)
	local c, s = ctx.c, ctx.s
	local cor = ctx.v.robeCor or Color3.fromRGB(30, 60, 130)
	c.peca("Robe", BLOCO, V3(1.66, 1.62, 0.96) * s, CF(0, 0, 0), cor)
	c.peca("Barra", BLOCO, V3(1.64, 0.9, 0.98) * s, CF(0, -1.2 * s, 0), cor)
	c.peca("Faixa", BLOCO, V3(0.25, 1.62, 0.04) * s, CF(0, 0, -0.49 * s), cor:Lerp(BRANCO, 0.25))
end
function CORPO.amuleto(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Amuleto", CILINDRO, V3(0.06, 0.42, 0.42) * s, CF(0, 0.45 * s, -0.5 * s) * DE_FRENTE, OURO, FOLHA)
	c.elipse("Olho", V3(0.2, 0.12, 0.05) * s, CF(0, 0.45 * s, -0.54 * s), Color3.fromRGB(60, 255, 120), NEON)
end
function CORPO.metadeMetal(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("PlacaMetal", BLOCO, V3(0.85, 1.64, 0.96) * s, CF(0.4 * s, 0, 0), PRATA, METAL)
	c.peca("Luz", CILINDRO, V3(0.06, 0.3, 0.3) * s, CF(0.4 * s, 0.35 * s, -0.5 * s) * DE_FRENTE, Color3.fromRGB(255, 40, 40), NEON)
	c.peca("BracoMetal", BLOCO, V3(0.5, 1.42, 0.5) * s, CF(1.05 * s, 0.05 * s, 0) * ANG(0, 0, rad(8)), PRATA, METAL)
end
function CORPO.faixasPretasLaterais(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("FaixaPreta", BLOCO, V3(0.14, 1.62, 0.94) * s, CF(0.73 * s * lado, 0, 0), PRETO)
		c.peca("PontaPreta", BLOCO, V3(0.5, 0.12, 0.06) * s, CF(0.45 * s * lado, 0.55 * s, -0.47 * s) * ANG(0, 0, rad(-35 * lado)), PRETO)
	end
end
function CORPO.chamas(ctx)
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 60, 0))
	p.LightEmission = 1
	p.Rate = 18
	p.Lifetime = NumberRange.new(0.5, 1)
	p.Speed = NumberRange.new(1.5, 3)
	p.SpreadAngle = Vector2.new(25, 25)
	p.Size = NumberSequence.new(0.6 * ctx.s, 0)
	p.Parent = ctx.raiz
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 140, 40)
	luz.Range = 10
	luz.Brightness = 2
	luz.Parent = ctx.raiz
end
function CORPO.corpoPedra(ctx)
	local c, s = ctx.c, ctx.s
	local cor = ctx.v.pele:Lerp(PRETO, 0.25)
	for i, info in { { -0.4, 0.45 }, { 0.35, 0.2 }, { -0.2, -0.15 }, { 0.45, -0.4 }, { 0, 0.55 } } do
		c.peca("Pedra", BLOCO, V3(0.32, 0.26, 0.06) * s, CF(info[1] * s * ctx.L, info[2] * s, -0.47 * s) * ANG(0, 0, rad(i * 17)), cor, Enum.Material.Slate)
	end
end
function CORPO.linhasDouradas(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("LinhaDourada", BLOCO, V3(0.06, 1.6, 0.04) * s, CF(0.5 * s * lado, 0, -0.47 * s), OURO)
	end
	c.peca("LinhaCentro", BLOCO, V3(1.0, 0.06, 0.04) * s, CF(0, 0.5 * s, -0.47 * s), OURO)
end
function CORPO.faixaAzul(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Faixa", BLOCO, V3(1.64, 0.7, 0.94) * s, CF(0, -0.45 * s, 0), Color3.fromRGB(30, 50, 140))
	c.peca("FaixaDourada", BLOCO, V3(1.66, 0.08, 0.96) * s, CF(0, -0.08 * s, 0), OURO)
end
function CORPO.casaco(ctx)
	local c, s = ctx.c, ctx.s
	local cor = ctx.v.camisa
	c.peca("Barra", BLOCO, V3(1.64, 1.0, 0.98) * s, CF(0, -1.25 * s, 0), cor)
	c.peca("Abertura", BLOCO, V3(0.1, 1.0, 0.06) * s, CF(0, -1.25 * s, -0.5 * s), PRETO)
	c.peca("Gola", BLOCO, V3(1.2, 0.25, 0.3) * s, CF(0, 0.8 * s, -0.35 * s), cor:Lerp(PRETO, 0.3))
end

function EMBLEMAS.raioPeito(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("RaioA", BLOCO, V3(0.16, 0.6, 0.05) * s, emblemaCF(s) * CF(0.1 * s, 0.2 * s, -0.01 * s) * ANG(0, 0, rad(-28)), OURO, NEON)
	c.peca("RaioB", BLOCO, V3(0.5, 0.13, 0.05) * s, emblemaCF(s) * CF(0, 0, -0.015 * s) * ANG(0, 0, rad(-12)), OURO, NEON)
	c.peca("RaioC", BLOCO, V3(0.16, 0.6, 0.05) * s, emblemaCF(s) * CF(-0.1 * s, -0.22 * s, -0.01 * s) * ANG(0, 0, rad(-28)), OURO, NEON)
end
function EMBLEMAS.estrelaDourada(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("EstrelaA", BLOCO, V3(0.42, 0.42, 0.05) * s, emblemaCF(s), OURO, NEON)
	c.peca("EstrelaB", BLOCO, V3(0.42, 0.42, 0.05) * s, emblemaCF(s) * CF(0, 0, -0.005 * s) * ANG(0, 0, rad(45)), OURO, NEON)
end
function EMBLEMAS.lanterna(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Circulo", CILINDRO, V3(0.05, 0.8, 0.8) * s, emblemaCF(s) * DE_FRENTE, BRANCO)
	c.peca("Anel", CILINDRO, V3(0.06, 0.55, 0.55) * s, emblemaCF(s) * CF(0, 0, -0.02 * s) * DE_FRENTE, Color3.fromRGB(40, 220, 90), NEON)
	c.peca("Miolo", CILINDRO, V3(0.07, 0.34, 0.34) * s, emblemaCF(s) * CF(0, 0, -0.03 * s) * DE_FRENTE, BRANCO)
	for _, y in { 0.38, -0.38 } do
		c.peca("Barra", BLOCO, V3(0.5, 0.08, 0.05) * s, emblemaCF(s) * CF(0, y * s, -0.02 * s), Color3.fromRGB(40, 220, 90), NEON)
	end
end
function EMBLEMAS.fenix(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Corpo", BLOCO, V3(0.22, 0.22, 0.05) * s, emblemaCF(s) * ANG(0, 0, rad(45)), OURO, NEON)
	for _, lado in { -1, 1 } do
		c.peca("Asa", BLOCO, V3(0.5, 0.1, 0.05) * s, emblemaCF(s) * CF(0.28 * s * lado, 0.12 * s, 0) * ANG(0, 0, rad(30 * lado)), OURO, NEON)
	end
	c.peca("Cauda", BLOCO, V3(0.1, 0.4, 0.05) * s, emblemaCF(s) * CF(0, -0.3 * s, 0), OURO, NEON)
end

function MAOS.tridente(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.peca("Haste", BLOCO, V3(0.1, 2.8, 0.1) * s, CF(hx, hy + 0.5 * s, -0.15 * s), OURO, FOLHA)
	c.peca("Travessa", BLOCO, V3(0.6, 0.08, 0.08) * s, CF(hx, hy + 1.85 * s, -0.15 * s), OURO, FOLHA)
	for k = -1, 1 do
		c.peca("Dente", BLOCO, V3(0.07, 0.45, 0.07) * s, CF(hx + k * 0.27 * s, hy + 2.1 * s, -0.15 * s), OURO, FOLHA)
	end
end
function MAOS.garras(ctx)
	local c, s, hy = ctx.c, ctx.s, ctx.hy
	for _, lado in { -1, 1 } do
		for k = -1, 1 do
			c.peca("Garra", BLOCO, V3(0.04, 0.85, 0.06) * s, CF(ctx.hx * lado + k * 0.1 * s, hy - 0.55 * s, -0.25 * s) * ANG(rad(-25), 0, 0),
				PRATA, METAL)
		end
	end
end
function MAOS.blasters(ctx)
	local c, s, hy = ctx.c, ctx.s, ctx.hy
	for _, lado in { -1, 1 } do
		c.peca("Arma", BLOCO, V3(0.22, 0.3, 0.6) * s, CF(ctx.hx * lado, hy, -0.35 * s), Color3.fromRGB(70, 75, 85), METAL)
		c.peca("Cano", CILINDRO, V3(0.4, 0.14, 0.14) * s, CF(ctx.hx * lado, hy + 0.05 * s, -0.75 * s) * DE_FRENTE, PRETO)
		c.peca("LuzArma", BLOCO, V3(0.06, 0.06, 0.3) * s, CF(ctx.hx * lado + 0.12 * s * lado, hy + 0.05 * s, -0.4 * s), Color3.fromRGB(80, 200, 255), NEON)
	end
end
function MAOS.prancha(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.elipse("Prancha", V3(0.22, 3.0, 1.0) * s, CF(hx + 0.35 * s, hy - 0.1 * s, 0.2 * s), PRATA, FOLHA)
end
function MAOS.anelVerde(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	local brilho = c.peca("Energia", BOLA, V3(0.45, 0.45, 0.45) * s, CF(hx, hy - 0.05 * s, -0.3 * s), Color3.fromRGB(60, 255, 120), NEON,
		{ transparencia = 0.2 })
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(60, 255, 120)
	luz.Range = 8
	luz.Brightness = 2
	luz.Parent = brilho
end
function MAOS.magia(ctx)
	local c, s, hy = ctx.c, ctx.s, ctx.hy
	for _, lado in { -1, 1 } do
		c.peca("CirculoMagico", CILINDRO, V3(0.04, 0.9, 0.9) * s, CF(ctx.hx * lado, hy, -0.4 * s) * DE_FRENTE, Color3.fromRGB(255, 150, 30), NEON,
			{ transparencia = 0.2 })
	end
end
function MAOS.energiaVermelha(ctx)
	local c, s, hy = ctx.c, ctx.s, ctx.hy
	for _, lado in { -1, 1 } do
		local bola = c.peca("Energia", BOLA, V3(0.5, 0.5, 0.5) * s, CF(ctx.hx * lado, hy - 0.05 * s, -0.3 * s), Color3.fromRGB(255, 30, 70), NEON,
			{ transparencia = 0.25 })
		local p = Instance.new("ParticleEmitter")
		p.Color = ColorSequence.new(Color3.fromRGB(255, 40, 90))
		p.LightEmission = 1
		p.Rate = 10
		p.Lifetime = NumberRange.new(0.4, 0.8)
		p.Speed = NumberRange.new(0.5, 1.5)
		p.Size = NumberSequence.new(0.3 * s, 0)
		p.Parent = bola
	end
end
function MAOS.raios(ctx)
	local c, s, hy = ctx.c, ctx.s, ctx.hy
	for _, lado in { -1, 1 } do
		c.peca("Raio", BOLA, V3(0.45, 0.45, 0.45) * s, CF(ctx.hx * lado, hy - 0.05 * s, -0.3 * s), Color3.fromRGB(220, 240, 255), NEON,
			{ transparencia = 0.15 })
	end
end
function MAOS.punhoEnergia(ctx)
	local c, s, hy = ctx.c, ctx.s, ctx.hy
	for _, lado in { -1, 1 } do
		c.peca("Energia", BOLA, V3(0.55, 0.55, 0.55) * s, CF(ctx.hx * lado, hy - 0.05 * s, -0.05 * s), Color3.fromRGB(255, 200, 60), NEON,
			{ transparencia = 0.35 })
	end
end
function MAOS.chicote(ctx)
	local c, s, hx, hy = ctx.c, ctx.s, ctx.hx, ctx.hy
	c.anel("Chicote", 0.3 * s, 10, V3(0.08, 0.2, 0.08) * s, CF(hx + 0.1 * s, hy - 0.35 * s, -0.2 * s) * ANG(0, rad(90), 0),
		{ Color3.fromRGB(40, 30, 30) })
	c.peca("PontaChicote", BLOCO, V3(0.06, 1.0, 0.06) * s, CF(hx + 0.1 * s, hy - 1.05 * s, -0.2 * s), Color3.fromRGB(40, 30, 30))
end
function MAOS_ESQUERDA.arco(ctx)
	local c, s = ctx.c, ctx.s
	local base = CF(-ctx.hx, ctx.hy + 0.2 * s, -0.3 * s)
	local madeira = Color3.fromRGB(110, 70, 40)
	c.peca("ArcoMeio", BLOCO, V3(0.1, 0.9, 0.12) * s, base, madeira)
	c.peca("ArcoCima", BLOCO, V3(0.1, 0.9, 0.12) * s, base * CF(0, 0.82 * s, 0.18 * s) * ANG(rad(25), 0, 0), madeira)
	c.peca("ArcoBaixo", BLOCO, V3(0.1, 0.9, 0.12) * s, base * CF(0, -0.82 * s, 0.18 * s) * ANG(rad(-25), 0, 0), madeira)
	c.peca("Corda", BLOCO, V3(0.03, 2.3, 0.03) * s, base * CF(0, 0, 0.42 * s), BRANCO)
end

function COSTAS.aljava(ctx)
	local c, s = ctx.c, ctx.s
	c.peca("Aljava", CILINDRO, V3(1.3, 0.4, 0.4) * s, CF(0.3 * s, 0.2 * s, 0.62 * s) * ANG(0, 0, rad(70)), Color3.fromRGB(110, 70, 40))
	for k = -1, 1 do
		c.peca("Flecha", BLOCO, V3(0.05, 0.5, 0.05) * s, CF((0.55 + k * 0.07) * s, 0.95 * s, 0.62 * s) * ANG(0, 0, rad(-20)), Color3.fromRGB(230, 40, 40))
	end
end
function COSTAS.espadas(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		c.peca("Espada", BLOCO, V3(0.1, 2.0, 0.06) * s, CF(0, 0.3 * s, 0.55 * s) * ANG(0, 0, rad(30 * lado)), PRATA, METAL)
		c.peca("Cabo", BLOCO, V3(0.14, 0.45, 0.12) * s, CF(0.55 * s * lado, 1.25 * s, 0.55 * s) * ANG(0, 0, rad(30 * lado)), PRETO)
	end
end
function COSTAS.asasMetal(ctx)
	local c, s = ctx.c, ctx.s
	for _, lado in { -1, 1 } do
		for k = 0, 2 do
			c.peca("Pena", BLOCO, V3(1.6 - k * 0.3, 0.32, 0.08) * s,
				CF((1.0 + k * 0.1) * s * lado, (0.45 - k * 0.35) * s, 0.6 * s) * ANG(0, 0, rad((22 - k * 12) * lado)),
				k == 0 and Color3.fromRGB(200, 40, 40) or PRATA, METAL)
		end
	end
end

local function capa(ctx, cor, material)
	local c, s = ctx.c, ctx.s
	c.peca("Capa", BLOCO, V3(1.5 * ctx.L, 2.35, 0.12) * s, CF(0, -0.3 * s, 0.56 * s) * ANG(rad(10), 0, 0), cor, material)
	c.peca("Gola", BLOCO, V3(1.65 * ctx.L, 0.2, 0.95) * s, CF(0, 0.78 * s, 0), cor, material)
end

--------------------------------------------------------------------------
-- HERÓI COMPLETO
--------------------------------------------------------------------------
-- opcoes: { semPlaca = true, escala = número, formatar = função }
function Modelos.heroi(def, mutacao, Config, opcoes)
	opcoes = opcoes or {}
	local raridade = Config.RaridadePorId[def.raridade]
	local s = opcoes.escala or raridade.escala
	local v = def.visual
	local L = v.largo and 1.25 or 1

	local camisa, calca = v.camisa, v.calca
	local mangas = v.mangas or v.camisa
	local MATERIAIS = { Metal = METAL, Neon = NEON, Concrete = Enum.Material.Slate, Foil = FOLHA }
	local material = MATERIAIS[v.material or ""] or LISO
	local corCapa = v.capa
	if mutacao.id == "Ouro" then
		camisa, calca, mangas, material = mutacao.cor, mutacao.cor, mutacao.cor, FOLHA
	elseif mutacao.id == "Diamante" then
		camisa, calca, mangas, material = mutacao.cor, mutacao.cor:Lerp(BRANCO, 0.3), mutacao.cor, VIDRO
	elseif mutacao.id == "Cosmico" then
		camisa, calca, mangas, material = Color3.fromRGB(50, 0, 110), Color3.fromRGB(30, 0, 70), Color3.fromRGB(50, 0, 110), NEON
		corCapa = corCapa and mutacao.cor
	end
	local vMut = setmetatable({ camisa = camisa }, { __index = v })

	local modelo = Instance.new("Model")
	modelo.Name = def.nome
	modelo:SetAttribute("HeroiId", def.id)
	modelo:SetAttribute("Mutacao", mutacao.id)

	local raiz = novaRaiz(modelo, "Tronco", V3(1.6 * L, 1.6, 0.9) * s, camisa, material)
	raiz:SetAttribute("Pintavel", true)
	local c = novoConstrutor(modelo, raiz)
	local yC = 1.32 * s
	local ctx = { c = c, s = s, L = L, yC = yC, hx = 1.15 * s * L, hy = -0.72 * s, v = vMut, raiz = raiz, rostoFeito = false }

	-- Corpo base
	local pele = v.pele
	local botas = v.botas or PRETO
	local maos = v.maos or pele
	for _, lado in { -1, 1 } do
		c.peca("Perna", BLOCO, V3(0.6 * L, 1.2, 0.6) * s, CF(0.42 * s * L * lado, -1.4 * s, 0), calca, material, { pintavel = true })
		c.peca("Bota", BLOCO, V3(0.68 * L, 0.45, 0.78) * s, CF(0.42 * s * L * lado, -1.8 * s, -0.05 * s), botas)
		c.peca("Braco", BLOCO, V3(0.45 * L, 1.4, 0.45 * L) * s, CF(1.05 * s * L * lado, 0.05 * s, 0) * ANG(0, 0, rad(8 * lado)),
			mangas, material, { pintavel = mangas == camisa })
		c.peca("Mao", BOLA, V3(0.5, 0.5, 0.5) * s * L, CF(1.15 * s * L * lado, -0.72 * s, 0), maos)
	end
	c.peca("Cabeca", BOLA, V3(1.1, 1.1, 1.1) * s, CF(0, yC, 0), pele, v.material == "Neon" and NEON or (v.material == "Foil" and FOLHA or LISO))

	-- Corpo, cabeça, rosto, emblema, mãos e costas
	for _, nome in v.corpo or {} do
		CORPO[nome](ctx)
	end
	if v.emblema then
		EMBLEMAS[v.emblema](ctx)
	end
	if corCapa then
		capa(ctx, corCapa, mutacao.id == "Cosmico" and NEON or LISO)
	end
	if v.cabeca then
		CABECAS[v.cabeca](ctx)
	end
	if not CABECAS_SEM_ROSTO[v.cabeca or ""] and not ctx.rostoFeito then
		olhosEBoca(ctx)
		if v.rosto then
			ROSTOS[v.rosto](ctx)
		end
	end
	if v.mao then
		MAOS[v.mao](ctx)
	end
	if v.maoEsquerda then
		MAOS_ESQUERDA[v.maoEsquerda](ctx)
	end
	if v.costas then
		COSTAS[v.costas](ctx)
	end

	if v.transparencia then
		for _, p in modelo:GetChildren() do
			if p:IsA("BasePart") and (p:GetAttribute("Pintavel") or p.Name == "Cabeca" or p.Name == "Mao" or p.Name == "Bota" or p.Name == "Cabelo") then
				p.Transparency = v.transparencia
			end
		end
	end

	-- Efeitos das raridades altas e mutações
	if raridade.ordem >= Config.RaridadePorId.Lendario.ordem then
		local luz = Instance.new("PointLight")
		luz.Color = raridade.cor
		luz.Range = 10
		luz.Brightness = 1.5
		luz.Parent = raiz
	end
	if def.raridade == "Divino" then
		c.peca("Aureola", CILINDRO, V3(0.12, 1.3, 1.3) * s, CF(0, yC + 1.05 * s, 0) * EM_PE, Color3.fromRGB(255, 240, 150), NEON)
	end
	if def.raridade == "Secreto" or mutacao.id == "Cosmico" then
		local particulas = Instance.new("ParticleEmitter")
		particulas.Color = def.raridade == "Secreto"
				and ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 255, 200))
			or ColorSequence.new(Color3.fromRGB(150, 70, 255), Color3.fromRGB(255, 120, 255))
		particulas.LightEmission = 0.6
		particulas.Rate = 14
		particulas.Lifetime = NumberRange.new(0.8, 1.6)
		particulas.Speed = NumberRange.new(1, 3)
		particulas.SpreadAngle = Vector2.new(180, 180)
		particulas.Size = NumberSequence.new(0.5 * s, 0)
		particulas.Parent = raiz
	end
	if mutacao.id == "ArcoIris" then
		CollectionService:AddTag(modelo, "HeroiArcoIris")
	end

	if not opcoes.semPlaca then
		local formatar = Config.formatar
		local placa = Instance.new("BillboardGui")
		placa.Name = "Info"
		placa.Size = UDim2.fromOffset(240, 96)
		placa.StudsOffset = Vector3.new(0, 2.9 * s + 1.4, 0)
		placa.MaxDistance = 70
		placa.LightInfluence = 0
		placa.Parent = raiz
		local layout = Instance.new("UIListLayout")
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = placa
		local function linha(ordem, texto, cor, fonte)
			local rotulo = Instance.new("TextLabel")
			rotulo.LayoutOrder = ordem
			rotulo.Size = UDim2.new(1, 0, 0, 23)
			rotulo.BackgroundTransparency = 1
			rotulo.Text = texto
			rotulo.TextColor3 = cor
			rotulo.Font = fonte or Enum.Font.FredokaOne
			rotulo.TextScaled = true
			rotulo.TextStrokeTransparency = 0
			rotulo.Parent = placa
			return rotulo
		end
		if mutacao.id ~= "Normal" then
			local rotulo = linha(1, "✦ " .. mutacao.nome .. " ✦", mutacao.cor)
			if mutacao.id == "ArcoIris" then
				rotulo.Name = "TextoArcoIris"
			end
		end
		linha(2, def.nome, Color3.new(1, 1, 1))
		linha(3, raridade.nome, raridade.cor)
		linha(4, formatar(def.preco * mutacao.multiplicador) .. "  •  +" .. formatar(def.renda * mutacao.multiplicador) .. "/s",
			Color3.fromRGB(110, 255, 130), Enum.Font.GothamBold)
	end

	return modelo, raiz
end

--------------------------------------------------------------------------
-- LUVA (estilo luva de boxe). A raiz fica no centro da mão; os dedos
-- apontam para -Y e o punho (pulso) sobe para +Y.
--------------------------------------------------------------------------
function Modelos.luva(def, escala)
	local modelo = Instance.new("Model")
	modelo.Name = "Luva" .. def.id
	local material = def.material == "Metal" and METAL or (def.material == "Neon" and NEON or LISO)
	local raiz = novaRaiz(modelo, "Luva", V3(1.15, 1.35, 1.2), def.cor, material)
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = raiz
	local c = novoConstrutor(modelo, raiz)
	local escura = def.cor:Lerp(PRETO, 0.25)

	c.elipse("Nos", V3(1.0, 0.62, 0.55), CF(0, -0.38, -0.35), escura, material)
	c.elipse("Polegar", V3(0.42, 0.78, 0.5), CF(-0.52, 0.05, -0.28) * ANG(0, 0, rad(18)), def.cor, material)
	c.peca("Punho", CILINDRO, V3(0.65, 1.0, 1.0), CF(0, 0.78, 0) * EM_PE, def.corPunho or BRANCO)
	c.peca("Faixa", CILINDRO, V3(0.16, 1.05, 1.05), CF(0, 0.6, 0) * EM_PE, def.corDetalhe or VERMELHO, def.neon and NEON or LISO)
	c.peca("FaixaTopo", CILINDRO, V3(0.1, 1.03, 1.03), CF(0, 1.05, 0) * EM_PE, def.corDetalhe or VERMELHO, def.neon and NEON or LISO)
	for k = 0, 2 do
		c.peca("Cadarco", BLOCO, V3(0.42, 0.06, 0.06), CF(0, 0.62 + k * 0.17, 0.52), BRANCO)
	end
	c.peca("Emblema", BLOCO, V3(0.3, 0.3, 0.06), CF(0, -0.05, 0.58) * ANG(0, 0, rad(45)), def.corDetalhe or OURO, NEON)
	if def.particulas then
		local p = Instance.new("ParticleEmitter")
		p.Color = ColorSequence.new(def.particulas)
		p.LightEmission = 1
		p.Rate = 12
		p.Lifetime = NumberRange.new(0.4, 0.8)
		p.Speed = NumberRange.new(0.5, 1.5)
		p.SpreadAngle = Vector2.new(180, 180)
		p.Size = NumberSequence.new(0.35, 0)
		p.Parent = raiz
	end
	if def.neon then
		local luz = Instance.new("PointLight")
		luz.Color = def.corDetalhe or def.cor
		luz.Range = 6
		luz.Brightness = 1.2
		luz.Parent = raiz
	end
	-- Na mão do jogador a luva fica maior, para o punho cobrir o braço
	if escala and escala ~= 1 then
		for _, parte in modelo:GetDescendants() do
			if parte:IsA("BasePart") then
				parte.Size *= escala
				parte.CFrame = CF(parte.CFrame.Position * escala) * parte.CFrame.Rotation
			end
		end
	end
	return modelo, raiz
end

--------------------------------------------------------------------------
-- MOLA (enfeite da loja): espiral de bolinhas metálicas
--------------------------------------------------------------------------
function Modelos.mola()
	local modelo = Instance.new("Model")
	modelo.Name = "Mola"
	local raiz = novaRaiz(modelo, "Base", V3(1.4, 0.2, 1.4), Color3.fromRGB(60, 60, 70), METAL)
	local c = novoConstrutor(modelo, raiz)
	local voltas, pontos = 5, 60
	for i = 0, pontos do
		local t = i / pontos
		local a = t * voltas * math.pi * 2
		c.peca("Espira", BOLA, V3(0.22, 0.22, 0.22), CF(math.cos(a) * 0.5, 0.15 + t * 1.8, math.sin(a) * 0.5),
			Color3.fromRGB(80, 220, 255), METAL)
	end
	c.peca("Topo", CILINDRO, V3(0.12, 1.2, 1.2), CF(0, 2.0, 0) * EM_PE, Color3.fromRGB(255, 200, 40), METAL)
	return modelo, raiz
end

return Modelos
