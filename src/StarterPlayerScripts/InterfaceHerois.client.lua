--[[
	ROUBE UM HERÓI - Interface do jogador

	Onde colocar: StarterPlayer -> StarterPlayerScripts -> LocalScript (nome: InterfaceHerois)

	Cria toda a interface: dinheiro, menus (Loja, Índice, Ranking, Renascer,
	Diário, Configurações), tutorial, notificações, anúncios, alarme de roubo,
	seta até a base, música, sons e efeitos visuais.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local jogador = Players.LocalPlayer
local playerGui = jogador:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("ConfigHerois"))
local remotes = ReplicatedStorage:WaitForChild("RemotesHerois")
local Notificar = remotes:WaitForChild("Notificar")
local Anuncio = remotes:WaitForChild("Anuncio")
local Efeito = remotes:WaitForChild("Efeito")
local Empurrao = remotes:WaitForChild("Empurrao")
local Acao = remotes:WaitForChild("Acao")
local ObterRanking = remotes:WaitForChild("ObterRanking")

local formatar = Config.formatar

--------------------------------------------------------------------------
-- ESTILO
--------------------------------------------------------------------------
local COR = {
	fundo = Color3.fromRGB(26, 28, 42),
	fundo2 = Color3.fromRGB(40, 44, 64),
	fundo3 = Color3.fromRGB(52, 57, 82),
	texto = Color3.fromRGB(255, 255, 255),
	cinza = Color3.fromRGB(170, 175, 195),
	desligado = Color3.fromRGB(95, 100, 120),
	amarelo = Color3.fromRGB(255, 196, 0),
	laranja = Color3.fromRGB(255, 130, 30),
	verde = Color3.fromRGB(60, 210, 100),
	vermelho = Color3.fromRGB(235, 70, 70),
	azul = Color3.fromRGB(70, 150, 255),
	roxo = Color3.fromRGB(150, 90, 255),
	rosa = Color3.fromRGB(255, 100, 180),
	ciano = Color3.fromRGB(40, 200, 220),
}
local FONTE_TITULO = Enum.Font.FredokaOne
local FONTE = Enum.Font.GothamBold
local FONTE_TEXTO = Enum.Font.GothamMedium
local MEDALHAS = { Color3.fromRGB(255, 200, 40), Color3.fromRGB(205, 205, 220), Color3.fromRGB(215, 135, 70) }

local function criar(classe, propriedades, filhos)
	local objeto = Instance.new(classe)
	local pai = nil
	for nome, valor in propriedades or {} do
		if nome == "Parent" then
			pai = valor
		else
			(objeto :: any)[nome] = valor
		end
	end
	for _, filho in filhos or {} do
		filho.Parent = objeto
	end
	if pai then
		objeto.Parent = pai
	end
	return objeto
end

local function canto(raio)
	return criar("UICorner", { CornerRadius = UDim.new(0, raio or 12) })
end

local function borda(cor, espessura, transparencia)
	return criar("UIStroke", {
		Color = cor,
		Thickness = espessura or 2,
		Transparency = transparencia or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function contornoTexto(espessura)
	return criar("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = espessura or 2, Transparency = 0.15 })
end

local function gradiente(cor1, cor2, rotacao)
	return criar("UIGradient", { Color = ColorSequence.new(cor1, cor2), Rotation = rotacao or 90 })
end

local function sombreado()
	return gradiente(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 190), 90)
end

local function limiteTexto(maximo)
	return criar("UITextSizeConstraint", { MaxTextSize = maximo })
end

local function rotulo(propriedades, filhos)
	local base = {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = COR.texto,
		TextScaled = true,
		Size = UDim2.fromScale(1, 1),
	}
	for nome, valor in propriedades do
		base[nome] = valor
	end
	return criar("TextLabel", base, filhos)
end

--------------------------------------------------------------------------
-- SONS E MÚSICA
--------------------------------------------------------------------------
local configLocal = { musica = true, sons = true }
local sons = {}
local function criarSom(nome, id, volume, velocidade)
	if id and id ~= "" then
		sons[nome] = criar("Sound", { Name = "Som" .. nome, SoundId = id, Volume = volume, PlaybackSpeed = velocidade or 1, Parent = SoundService })
	end
end
criarSom("clique", Config.Sons.Clique, 0.35, 1.2)
criarSom("notificacao", Config.Sons.Notificacao, 0.4)
criarSom("moeda", Config.Sons.Moeda, 0.45, 1.6)
criarSom("compra", Config.Sons.Compra, 0.55, 1.25)
criarSom("alarme", Config.Sons.Alarme, 0.7, 0.55)
criarSom("erro", Config.Sons.Erro, 0.4, 0.6)

local function tocar(nome)
	local som = sons[nome]
	if som and configLocal.sons then
		SoundService:PlayLocalSound(som)
	end
end

local musica = nil
if Config.Sons.Musica ~= "" then
	musica = criar("Sound", { Name = "MusicaDeFundo", SoundId = Config.Sons.Musica, Looped = true, Volume = Config.Sons.VolumeMusica, Parent = SoundService })
end
local function aplicarMusica()
	if not musica then
		return
	end
	if configLocal.musica then
		if not musica.IsPlaying then
			musica:Play()
		end
	else
		musica:Stop()
	end
end

local function atributo(nome, padrao)
	local valor = jogador:GetAttribute(nome)
	if valor == nil then
		return padrao
	end
	return valor
end

local function invocar(acao, argumento)
	local ok, sucesso, mensagem = pcall(function()
		return Acao:InvokeServer(acao, argumento)
	end)
	if not ok then
		return false, "Erro de conexão. Tente de novo!"
	end
	return sucesso, mensagem
end

--------------------------------------------------------------------------
-- TELA PRINCIPAL
--------------------------------------------------------------------------
local gui = criar("ScreenGui", {
	Name = "InterfaceHerois",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Clarão vermelho do alarme (fica atrás de tudo e não bloqueia cliques)
local telaAlarme = criar("Frame", {
	Name = "Alarme",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COR.vermelho,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = gui,
})

--------------------------------------------------------------------------
-- NOTIFICAÇÕES (canto direito) E ANÚNCIOS (centro)
--------------------------------------------------------------------------
local CORES_TIPO = { sucesso = COR.verde, erro = COR.vermelho, aviso = COR.amarelo, info = COR.azul, especial = COR.roxo }
local areaNotificacoes = criar("Frame", {
	Name = "Notificacoes",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 0.8, 0),
	Size = UDim2.fromOffset(340, 330),
	BackgroundTransparency = 1,
	ZIndex = 30,
	Parent = gui,
}, {
	criar("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}),
})
local contadorNotificacao = 0

local function notificar(mensagem, tipo)
	if not mensagem or mensagem == "" then
		return
	end
	contadorNotificacao += 1
	local cor = CORES_TIPO[tipo] or COR.azul
	local caixa = criar("Frame", {
		LayoutOrder = contadorNotificacao,
		Size = UDim2.fromOffset(340, 48),
		BackgroundColor3 = COR.fundo,
		BackgroundTransparency = 0.05,
		Parent = areaNotificacoes,
	}, { canto(12) })
	local contorno = borda(cor, 2)
	contorno.Parent = caixa
	criar("Frame", { Size = UDim2.new(0, 6, 1, -14), Position = UDim2.fromOffset(7, 7), BackgroundColor3 = cor, BorderSizePixel = 0, Parent = caixa }, { canto(3) })
	local texto = rotulo({
		Text = mensagem,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, -28, 1, -10),
		Position = UDim2.fromOffset(20, 5),
		Parent = caixa,
	}, { limiteTexto(17) })
	local escala = criar("UIScale", { Scale = 0.6, Parent = caixa })
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	tocar(tipo == "erro" and "erro" or "notificacao")

	local caixas = {}
	for _, filho in areaNotificacoes:GetChildren() do
		if filho:IsA("Frame") then
			table.insert(caixas, filho)
		end
	end
	table.sort(caixas, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #caixas - 5 do
		caixas[i]:Destroy()
	end

	task.delay(4, function()
		if not caixa.Parent then
			return
		end
		local info = TweenInfo.new(0.35)
		TweenService:Create(caixa, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(texto, info, { TextTransparency = 1 }):Play()
		TweenService:Create(contorno, info, { Transparency = 1 }):Play()
		task.wait(0.35)
		caixa:Destroy()
	end)
end

local faixaAnuncio = criar("Frame", {
	Name = "Anuncio",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.26),
	Size = UDim2.new(0.62, 0, 0, 62),
	BackgroundColor3 = COR.fundo,
	BackgroundTransparency = 0.08,
	Visible = false,
	ZIndex = 25,
	Parent = gui,
}, { canto(16), criar("UISizeConstraint", { MaxSize = Vector2.new(780, 62) }) })
local bordaAnuncio = borda(COR.amarelo, 3)
bordaAnuncio.Parent = faixaAnuncio
local textoAnuncio = rotulo({
	Font = FONTE_TITULO,
	Size = UDim2.new(1, -24, 1, -14),
	Position = UDim2.fromOffset(12, 7),
	Parent = faixaAnuncio,
}, { contornoTexto(2) })
local escalaAnuncio = criar("UIScale", { Parent = faixaAnuncio })
local idAnuncio = 0

local function anunciar(mensagem, cor, duracao)
	idAnuncio += 1
	local meuId = idAnuncio
	cor = cor or COR.amarelo
	textoAnuncio.Text = mensagem
	textoAnuncio.TextColor3 = cor
	bordaAnuncio.Color = cor
	faixaAnuncio.Visible = true
	escalaAnuncio.Scale = 0.4
	TweenService:Create(escalaAnuncio, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	tocar("notificacao")
	task.delay(duracao or 4.5, function()
		if idAnuncio == meuId then
			faixaAnuncio.Visible = false
		end
	end)
end

--------------------------------------------------------------------------
-- BOTÕES
--------------------------------------------------------------------------
local function animarBotao(botao)
	local escala = criar("UIScale", { Parent = botao })
	local function para(valor, tempo)
		TweenService:Create(escala, TweenInfo.new(tempo), { Scale = valor }):Play()
	end
	botao.MouseEnter:Connect(function()
		para(1.06, 0.12)
	end)
	botao.MouseLeave:Connect(function()
		para(1, 0.12)
	end)
	botao.MouseButton1Down:Connect(function()
		para(0.93, 0.06)
	end)
	botao.MouseButton1Up:Connect(function()
		para(1.06, 0.08)
	end)
end

local function botao(propriedades, aoClicar)
	local cor = propriedades.Cor or COR.azul
	local base = {
		AutoButtonColor = false,
		BackgroundColor3 = cor,
		Font = FONTE_TITULO,
		TextColor3 = COR.texto,
		TextScaled = true,
		Text = "",
		Size = UDim2.fromOffset(120, 44),
	}
	for nome, valor in propriedades do
		if nome ~= "Cor" then
			base[nome] = valor
		end
	end
	local b = criar("TextButton", base, {
		canto(12),
		sombreado(),
		contornoTexto(2),
		criar("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
	})
	animarBotao(b)
	if aoClicar then
		b.Activated:Connect(function()
			tocar("clique")
			aoClicar()
		end)
	end
	return b
end

--------------------------------------------------------------------------
-- PAINÉIS (janelas)
--------------------------------------------------------------------------
local paineis = {}
local painelAberto = nil

local fundoEscuro = criar("TextButton", {
	Name = "FundoEscuro",
	Text = "",
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 8,
	Parent = gui,
})

local function fecharPainel()
	local nome = painelAberto
	if not nome then
		return
	end
	local painel = paineis[nome]
	painelAberto = nil
	fundoEscuro.Visible = false
	TweenService:Create(painel.escala, TweenInfo.new(0.12), { Scale = 0.8 }):Play()
	task.delay(0.12, function()
		if painelAberto ~= nome then
			painel.quadro.Visible = false
		end
	end)
	if painel.aoFechar then
		painel.aoFechar()
	end
end

local function abrirPainel(nome)
	if painelAberto == nome then
		fecharPainel()
		return
	end
	if painelAberto then
		local anterior = paineis[painelAberto]
		anterior.quadro.Visible = false
		if anterior.aoFechar then
			anterior.aoFechar()
		end
	end
	local painel = paineis[nome]
	painelAberto = nome
	if painel.aoAbrir then
		painel.aoAbrir()
	end
	fundoEscuro.Visible = true
	fundoEscuro.BackgroundTransparency = 1
	TweenService:Create(fundoEscuro, TweenInfo.new(0.2), { BackgroundTransparency = 0.55 }):Play()
	painel.quadro.Visible = true
	painel.escala.Scale = 0.75
	TweenService:Create(painel.escala, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

fundoEscuro.Activated:Connect(fecharPainel)

local function criarPainel(nome, titulo, cor)
	local quadro = criar("Frame", {
		Name = "Painel" .. nome,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.62, 0.7),
		BackgroundColor3 = COR.fundo,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, {
		canto(20),
		borda(cor, 3),
		criar("UISizeConstraint", { MinSize = Vector2.new(330, 280), MaxSize = Vector2.new(720, 520) }),
	})
	local escala = criar("UIScale", { Parent = quadro })

	local faixa = criar("Frame", { Name = "Titulo", Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = cor, Parent = quadro }, {
		canto(20),
		gradiente(Color3.new(1, 1, 1), Color3.fromRGB(160, 160, 170), 90),
	})
	criar("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundColor3 = cor,
		BorderSizePixel = 0,
		Parent = faixa,
	}, { gradiente(Color3.fromRGB(198, 198, 205), Color3.fromRGB(160, 160, 170), 90) })
	rotulo({
		Text = titulo,
		Font = FONTE_TITULO,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -80, 0, 38),
		Position = UDim2.fromOffset(18, 9),
		ZIndex = 2,
		Parent = faixa,
	}, { contornoTexto(2.5) })
	botao({
		Text = "✕",
		Cor = COR.vermelho,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(42, 42),
		ZIndex = 2,
		Parent = faixa,
	}, fecharPainel)

	local corpo = criar("Frame", {
		Name = "Corpo",
		Position = UDim2.fromOffset(16, 68),
		Size = UDim2.new(1, -32, 1, -82),
		BackgroundTransparency = 1,
		Parent = quadro,
	})
	local painel = { nome = nome, quadro = quadro, escala = escala, corpo = corpo }
	paineis[nome] = painel
	return painel
end

local function listaRolavel(pai, propriedades)
	local base = {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = COR.cinza,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = pai,
	}
	for nome, valor in propriedades or {} do
		base[nome] = valor
	end
	return criar("ScrollingFrame", base, { criar("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) }) })
end

local function barraProgresso(pai, posicao, tamanho, cor)
	local fundo = criar("Frame", { Position = posicao, Size = tamanho, BackgroundColor3 = COR.fundo3, Parent = pai }, { canto(8) })
	local preenchimento = criar("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = cor, Parent = fundo }, { canto(8), sombreado() })
	local texto = rotulo({ Text = "", Size = UDim2.new(1, -10, 1, -4), Position = UDim2.fromOffset(5, 2), ZIndex = 2, Parent = fundo }, { contornoTexto(1.5) })
	return function(fracao, rotuloTexto)
		fracao = math.clamp(fracao, 0, 1)
		TweenService:Create(preenchimento, TweenInfo.new(0.25), { Size = UDim2.fromScale(fracao, 1) }):Play()
		texto.Text = rotuloTexto or ""
	end
end

--------------------------------------------------------------------------
-- HUD: DINHEIRO, RENDA E EVENTO
--------------------------------------------------------------------------
local hud = criar("Frame", {
	Name = "Dinheiro",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(300, 72),
	BackgroundColor3 = COR.fundo,
	BackgroundTransparency = 0.08,
	Parent = gui,
}, { canto(18), borda(COR.amarelo, 2.5, 0.1) })
local escalaHud = criar("UIScale", { Parent = hud })
local textoDinheiro = rotulo({
	Text = "$0",
	Font = FONTE_TITULO,
	TextColor3 = COR.verde,
	Size = UDim2.new(1, -24, 0, 44),
	Position = UDim2.fromOffset(12, 4),
	Parent = hud,
}, { contornoTexto(2.5) })
local textoRenda = rotulo({
	Text = "+$0/s",
	TextColor3 = COR.amarelo,
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.fromOffset(12, 49),
	Parent = hud,
}, { contornoTexto(1.5) })

local barraEvento = criar("Frame", {
	Name = "Evento",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 84),
	Size = UDim2.fromOffset(380, 34),
	BackgroundColor3 = COR.amarelo,
	Visible = false,
	Parent = gui,
}, { canto(12), sombreado() })
local textoEvento = rotulo({
	Font = FONTE_TITULO,
	Size = UDim2.new(1, -16, 1, -8),
	Position = UDim2.fromOffset(8, 4),
	Parent = barraEvento,
}, { contornoTexto(2) })

local valorExibido = 0
local alvoDinheiro = 0

local function formatarMultiplicador(valor)
	return "x" .. (string.format("%.1f", valor):gsub("%.0$", ""))
end

local function atualizarRenda()
	local renda = atributo("RendaPorSegundo", 0)
	local mult = atributo("Multiplicador", 1)
	local texto = "+" .. formatar(renda) .. "/s"
	if mult > 1 then
		texto ..= "  •  " .. formatarMultiplicador(mult)
	end
	textoRenda.Text = texto
end

--------------------------------------------------------------------------
-- MENU LATERAL
--------------------------------------------------------------------------
local menu = criar("Frame", {
	Name = "Menu",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(152, 236),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	criar("UIGridLayout", { CellSize = UDim2.fromOffset(72, 72), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local escalaMenu = criar("UIScale", { Parent = menu })
local alertasMenu = {}

local function botaoMenu(ordem, nome, icone, texto, cor)
	local b = criar("TextButton", {
		Name = nome,
		LayoutOrder = ordem,
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = cor,
		Parent = menu,
	}, { canto(16), borda(Color3.new(1, 1, 1), 2, 0.55), sombreado() })
	rotulo({ Text = icone, Size = UDim2.new(1, -16, 0.56, 0), Position = UDim2.new(0, 8, 0.06, 0), Parent = b })
	rotulo({ Text = texto, Font = FONTE_TITULO, Size = UDim2.new(1, -6, 0.26, 0), Position = UDim2.new(0, 3, 0.68, 0), Parent = b }, { contornoTexto(1.5) })
	local alerta = criar("Frame", {
		Name = "Alerta",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = COR.vermelho,
		Visible = false,
		ZIndex = 3,
		Parent = b,
	}, { canto(10), borda(Color3.new(1, 1, 1), 2) })
	rotulo({ Text = "!", Font = FONTE_TITULO, ZIndex = 4, Parent = alerta })
	alertasMenu[nome] = alerta
	animarBotao(b)
	b.Activated:Connect(function()
		tocar("clique")
		abrirPainel(nome)
	end)
	return b
end

botaoMenu(1, "Loja", "🛒", "Loja", COR.verde)
botaoMenu(2, "Indice", "📖", "Índice", COR.azul)
botaoMenu(3, "Ranking", "🏆", "Ranking", COR.amarelo)
botaoMenu(4, "Renascer", "♻️", "Renascer", COR.roxo)
botaoMenu(5, "Diario", "🎁", "Diário", COR.rosa)
botaoMenu(6, "Config", "⚙️", "Opções", COR.desligado)

-- Ajusta o tamanho em telas pequenas (celular)
local function ajustarEscala()
	local camera = workspace.CurrentCamera
	local altura = camera and camera.ViewportSize.Y or 720
	local escala = math.clamp(altura / 720, 0.7, 1)
	escalaMenu.Scale = escala
	escalaHud.Scale = escala
end

--------------------------------------------------------------------------
-- PAINEL: LOJA
--------------------------------------------------------------------------
local atualizarLoja
do
	local painel = criarPainel("Loja", "🛒 LOJA DE MELHORIAS", COR.verde)
	local lista = listaRolavel(painel.corpo)
	criar("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = lista })

	local cartoes = {}
	for i, melhoria in Config.Melhorias do
		local cartao = criar("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = COR.fundo2, Parent = lista }, {
			canto(14),
			borda(Color3.new(1, 1, 1), 1.5, 0.85),
		})
		rotulo({ Text = melhoria.icone, Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(10, 12), Parent = cartao })
		local nome = rotulo({
			Text = melhoria.nome,
			Font = FONTE_TITULO,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -230, 0, 28),
			Position = UDim2.fromOffset(76, 10),
			Parent = cartao,
		}, { limiteTexto(26) })
		local descricao = rotulo({
			Text = "",
			Font = FONTE_TEXTO,
			TextColor3 = COR.cinza,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -230, 0, 32),
			Position = UDim2.fromOffset(76, 40),
			TextWrapped = true,
			Parent = cartao,
		}, { limiteTexto(16) })
		local comprar = botao({
			Text = "$0",
			Cor = COR.verde,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(140, 50),
			Parent = cartao,
		}, function()
			local ok, mensagem = invocar("Melhoria", melhoria.id)
			notificar(mensagem, ok and "sucesso" or "erro")
		end)
		cartoes[melhoria.id] = { nome = nome, descricao = descricao, botao = comprar, melhoria = melhoria }
	end

	-- Ofertas com Robux (só aparecem se os IDs estiverem configurados)
	local ofertas = {}
	local temRobux = Config.Robux.PasseDinheiroDobrado ~= 0
	for _, produto in Config.Robux.Produtos do
		if produto.id ~= 0 then
			temRobux = true
		end
	end
	if temRobux then
		rotulo({
			LayoutOrder = 100,
			Text = "💎 OFERTAS ESPECIAIS",
			Font = FONTE_TITULO,
			TextColor3 = COR.ciano,
			Size = UDim2.new(1, 0, 0, 30),
			Parent = lista,
		}, { contornoTexto(2) })
		local function cartaoRobux(ordem, icone, titulo, aoComprar)
			local cartao = criar("Frame", { LayoutOrder = ordem, Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = COR.fundo2, Parent = lista }, {
				canto(14),
				borda(COR.ciano, 1.5, 0.4),
			})
			rotulo({ Text = icone, Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(10, 10), Parent = cartao })
			local texto = rotulo({
				Text = titulo,
				Font = FONTE_TITULO,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -220, 0, 30),
				Position = UDim2.fromOffset(64, 17),
				Parent = cartao,
			}, { limiteTexto(22) })
			local b = botao({
				Text = "R$ Comprar",
				Cor = COR.ciano,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(140, 44),
				Parent = cartao,
			}, aoComprar)
			return texto, b, cartao
		end
		if Config.Robux.PasseDinheiroDobrado ~= 0 then
			local _, _, cartao = cartaoRobux(101, "💸", "Dinheiro em Dobro (para sempre)", function()
				MarketplaceService:PromptGamePassPurchase(jogador, Config.Robux.PasseDinheiroDobrado)
			end)
			ofertas.passe = cartao
		end
		for i, produto in Config.Robux.Produtos do
			if produto.id ~= 0 then
				local texto = cartaoRobux(101 + i, produto.icone, produto.nome, function()
					MarketplaceService:PromptProductPurchase(jogador, produto.id)
				end)
				table.insert(ofertas, { texto = texto, produto = produto })
			end
		end
	end

	function atualizarLoja()
		local dinheiro = atributo("Dinheiro", 0)
		for id, cartao in cartoes do
			local nivel = atributo("Nivel" .. id, 0)
			local precos = cartao.melhoria.precos
			local maximo = #precos
			if nivel >= maximo then
				cartao.descricao.Text = "Nível " .. nivel .. "/" .. maximo .. " • " .. Config.descricaoMelhoria(id, nivel)
				cartao.botao.Text = "MÁXIMO"
				cartao.botao.BackgroundColor3 = COR.amarelo
			else
				cartao.descricao.Text = "Nível " .. nivel .. "/" .. maximo .. " • " .. Config.descricaoMelhoria(id, nivel)
					.. " → " .. Config.descricaoMelhoria(id, nivel + 1)
				local preco = precos[nivel + 1]
				cartao.botao.Text = formatar(preco)
				cartao.botao.BackgroundColor3 = dinheiro >= preco and COR.verde or COR.desligado
			end
		end
		if ofertas.passe then
			ofertas.passe.Visible = not atributo("PasseDobro", false)
		end
		local renascimentos = atributo("Renascimentos", 0)
		for _, oferta in ofertas do
			if type(oferta) == "table" and oferta.produto then
				oferta.texto.Text = oferta.produto.nome .. "  +" .. formatar(Config.valorProduto(oferta.produto, renascimentos))
			end
		end
	end
	painel.aoAbrir = atualizarLoja
end

--------------------------------------------------------------------------
-- PAINEL: ÍNDICE DE HERÓIS
--------------------------------------------------------------------------
local atualizarIndice
do
	local painel = criarPainel("Indice", "📖 ÍNDICE DE HERÓIS", COR.azul)
	local textoProgresso = rotulo({
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = painel.corpo,
	}, { limiteTexto(20) })
	local progresso = barraProgresso(painel.corpo, UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 16), COR.azul)
	local grade = listaRolavel(painel.corpo, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50) })
	criar("UIGridLayout", {
		CellSize = UDim2.fromOffset(118, 132),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grade,
	})

	local cartoes = {}
	for _, def in Config.Herois do
		local raridade = Config.RaridadePorId[def.raridade]
		local cartao = criar("Frame", { LayoutOrder = def.ordem, BackgroundColor3 = COR.fundo2, Parent = grade }, { canto(14) })
		local contorno = borda(raridade.cor, 2, 0.2)
		contorno.Parent = cartao
		local icone = rotulo({ Text = "❓", Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 8), Parent = cartao })
		local nome = rotulo({ Text = "???", Font = FONTE_TITULO, Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 60), Parent = cartao }, { contornoTexto(1.5) })
		rotulo({ Text = raridade.nome, TextColor3 = raridade.cor, Size = UDim2.new(1, -10, 0, 16), Position = UDim2.fromOffset(5, 84), Parent = cartao }, { contornoTexto(1.2) })
		local renda = rotulo({ Text = "", TextColor3 = COR.verde, Size = UDim2.new(1, -10, 0, 16), Position = UDim2.fromOffset(5, 104), Parent = cartao })
		cartoes[def.id] = { cartao = cartao, icone = icone, nome = nome, renda = renda, contorno = contorno, def = def }
	end

	function atualizarIndice()
		local descobertos = {}
		local ok, lista = pcall(function()
			return HttpService:JSONDecode(atributo("Descobertos", "[]"))
		end)
		if ok and type(lista) == "table" then
			for _, id in lista do
				descobertos[id] = true
			end
		end
		local quantidade = 0
		for id, cartao in cartoes do
			if descobertos[id] then
				quantidade += 1
				cartao.icone.Text = cartao.def.icone
				cartao.nome.Text = cartao.def.nome
				cartao.renda.Text = "+" .. formatar(cartao.def.renda) .. "/s"
				cartao.cartao.BackgroundColor3 = COR.fundo2
				cartao.contorno.Transparency = 0
			else
				cartao.icone.Text = "❓"
				cartao.nome.Text = "???"
				cartao.renda.Text = formatar(cartao.def.preco)
				cartao.cartao.BackgroundColor3 = Color3.fromRGB(30, 32, 46)
				cartao.contorno.Transparency = 0.6
			end
		end
		local total = #Config.Herois
		textoProgresso.Text = "Descobertos: " .. quantidade .. " de " .. total .. "  •  Compre ou roube heróis para descobrir!"
		progresso(quantidade / total, math.floor(quantidade / total * 100) .. "%")
	end
	painel.aoAbrir = atualizarIndice
end

--------------------------------------------------------------------------
-- PAINEL: RANKING
--------------------------------------------------------------------------
local atualizarRankingPainel
do
	local painel = criarPainel("Ranking", "🏆 RANKING", COR.amarelo)
	local abas = criar("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = painel.corpo }, {
		criar("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local aviso = rotulo({
		Text = "",
		Font = FONTE_TEXTO,
		TextColor3 = COR.cinza,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 46),
		Parent = painel.corpo,
	}, { limiteTexto(15) })
	local lista = listaRolavel(painel.corpo, { Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 1, -68) })
	criar("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = lista })

	local ABAS = {
		{ id = "Servidor", texto = "Servidor" },
		{ id = "Dinheiro", texto = "🌎 Ricos" },
		{ id = "Roubos", texto = "🌎 Ladrões" },
		{ id = "Renascimentos", texto = "🌎 Renasc." },
	}
	local abaAtual = "Servidor"
	local botoesAba = {}

	local function preencher(itens, formatarValor)
		for _, filho in lista:GetChildren() do
			if filho:IsA("Frame") then
				filho:Destroy()
			end
		end
		if #itens == 0 then
			local vazio = criar("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = lista })
			rotulo({ Text = "Ninguém aqui ainda... seja o primeiro!", TextColor3 = COR.cinza, Parent = vazio }, { limiteTexto(18) })
			return
		end
		for i, item in itens do
			local linha = criar("Frame", {
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 42),
				BackgroundColor3 = i % 2 == 0 and COR.fundo2 or COR.fundo3,
				Parent = lista,
			}, { canto(10) })
			if item.voce then
				borda(COR.verde, 2).Parent = linha
			end
			rotulo({ Text = "#" .. i, Font = FONTE_TITULO, TextColor3 = MEDALHAS[i] or COR.texto, Size = UDim2.new(0, 50, 1, -10), Position = UDim2.fromOffset(6, 5), Parent = linha }, { contornoTexto(1.5) })
			rotulo({ Text = item.nome, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.55, -60, 1, -14), Position = UDim2.fromOffset(62, 7), Parent = linha })
			rotulo({ Text = formatarValor(item.valor), Font = FONTE_TITULO, TextColor3 = COR.amarelo, TextXAlignment = Enum.TextXAlignment.Right,
				Size = UDim2.new(0.45, -12, 1, -12), Position = UDim2.new(0.55, 0, 0, 6), Parent = linha }, { contornoTexto(1.5) })
		end
	end

	function atualizarRankingPainel(automatico)
		if automatico and abaAtual ~= "Servidor" then
			return -- o ranking global só atualiza quando o jogador pede
		end
		for id, b in botoesAba do
			b.BackgroundColor3 = id == abaAtual and COR.amarelo or COR.desligado
		end
		if abaAtual == "Servidor" then
			aviso.Text = "Mais ricos deste servidor agora"
			local itens = {}
			for _, outro in Players:GetPlayers() do
				table.insert(itens, { nome = outro.DisplayName, valor = outro:GetAttribute("Dinheiro") or 0, voce = outro == jogador })
			end
			table.sort(itens, function(a, b)
				return a.valor > b.valor
			end)
			preencher(itens, formatar)
		else
			aviso.Text = "Carregando..."
			local categoria = abaAtual
			task.spawn(function()
				local ok, dados = pcall(function()
					return ObterRanking:InvokeServer()
				end)
				if abaAtual ~= categoria then
					return
				end
				if not ok or type(dados) ~= "table" then
					aviso.Text = "Não foi possível carregar o ranking."
					preencher({}, tostring)
					return
				end
				aviso.Text = dados.disponivel and "🌎 Top 10 do mundo inteiro"
					or "Mostrando este servidor (o ranking global aparece quando o jogo for publicado)"
				local itens = {}
				for _, item in dados[categoria] or {} do
					table.insert(itens, { nome = item.nome, valor = item.valor, voce = item.nome == jogador.DisplayName })
				end
				preencher(itens, categoria == "Dinheiro" and formatar or Config.formatarNumero)
			end)
		end
	end

	for i, aba in ABAS do
		botoesAba[aba.id] = botao({
			LayoutOrder = i,
			Text = aba.texto,
			Cor = COR.desligado,
			Size = UDim2.new(0.25, -5, 1, 0),
			Parent = abas,
		}, function()
			abaAtual = aba.id
			atualizarRankingPainel()
		end)
	end
	painel.aoAbrir = function()
		atualizarRankingPainel()
	end
end

--------------------------------------------------------------------------
-- PAINEL: RENASCER
--------------------------------------------------------------------------
local atualizarRenascer
do
	local painel = criarPainel("Renascer", "♻️ RENASCER", COR.roxo)
	local corpo = painel.corpo
	local titulo = rotulo({ Text = "", Font = FONTE_TITULO, Size = UDim2.new(1, 0, 0, 34), Parent = corpo }, { contornoTexto(2) })
	local multiplicadores = rotulo({
		Text = "",
		Font = FONTE_TITULO,
		TextColor3 = COR.verde,
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 38),
		Parent = corpo,
	}, { contornoTexto(2) })
	local progresso = barraProgresso(corpo, UDim2.fromOffset(0, 78), UDim2.new(1, 0, 0, 30), COR.roxo)
	rotulo({
		Text = "❌ Você PERDE: seu dinheiro e seus heróis\n✅ Você MANTÉM: melhorias da Loja e o Índice\n⭐ Bônus: +50% de renda PARA SEMPRE!",
		Font = FONTE_TEXTO,
		TextColor3 = COR.cinza,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 72),
		Position = UDim2.fromOffset(0, 118),
		Parent = corpo,
	}, { limiteTexto(18) })

	local confirmando = false
	local botaoRenascer
	botaoRenascer = botao({
		Text = "RENASCER",
		Cor = COR.roxo,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.7, 0, 0, 56),
		Parent = corpo,
	}, function()
		if not confirmando then
			confirmando = true
			botaoRenascer.Text = "TEM CERTEZA? CLIQUE DE NOVO"
			task.delay(3, function()
				confirmando = false
				atualizarRenascer()
			end)
			return
		end
		confirmando = false
		local ok, mensagem = invocar("Renascer")
		notificar(mensagem, ok and "especial" or "erro")
		if ok then
			fecharPainel()
		end
		atualizarRenascer()
	end)

	function atualizarRenascer()
		local renascimentos = atributo("Renascimentos", 0)
		local dinheiro = atributo("Dinheiro", 0)
		local custo = Config.custoRenascimento(renascimentos)
		titulo.Text = "Renascimentos: " .. renascimentos
		multiplicadores.Text = "Renda " .. formatarMultiplicador(Config.multiplicadorRenascimento(renascimentos))
			.. "  ➜  " .. formatarMultiplicador(Config.multiplicadorRenascimento(renascimentos + 1))
		progresso(dinheiro / custo, formatar(dinheiro) .. " / " .. formatar(custo))
		if not confirmando then
			botaoRenascer.Text = "RENASCER (" .. formatar(custo) .. ")"
		end
		botaoRenascer.BackgroundColor3 = dinheiro >= custo and COR.roxo or COR.desligado
		alertasMenu.Renascer.Visible = dinheiro >= custo
	end
	painel.aoAbrir = atualizarRenascer
end

--------------------------------------------------------------------------
-- PAINEL: RECOMPENSA DIÁRIA
--------------------------------------------------------------------------
local atualizarDiario
do
	local painel = criarPainel("Diario", "🎁 RECOMPENSA DIÁRIA", COR.rosa)
	local corpo = painel.corpo
	local linhaDias = criar("Frame", { Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1, Parent = corpo }, {
		criar("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
	local dias = {}
	for dia = 1, 7 do
		local cartao = criar("Frame", { LayoutOrder = dia, Size = UDim2.new(1 / 7, -6, 1, 0), BackgroundColor3 = COR.fundo2, Parent = linhaDias }, { canto(12) })
		local contorno = borda(COR.rosa, 2, 0.7)
		contorno.Parent = cartao
		rotulo({ Text = "Dia " .. dia, Font = FONTE_TITULO, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 6), Parent = cartao }, { contornoTexto(1.5) })
		local icone = rotulo({ Text = dia == 7 and "👑" or "💰", Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 32), Parent = cartao })
		local valor = rotulo({ Text = "", TextColor3 = COR.verde, Size = UDim2.new(1, -8, 0, 20), Position = UDim2.fromOffset(4, 82), Parent = cartao }, { contornoTexto(1.2) })
		dias[dia] = { cartao = cartao, contorno = contorno, icone = icone, valor = valor }
	end
	rotulo({
		Text = "Entre todos os dias para aumentar a sequência. O Dia 7 vale o DOBRO! Ficar mais de 2 dias sem entrar reinicia a sequência.",
		Font = FONTE_TEXTO,
		TextColor3 = COR.cinza,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 130),
		Parent = corpo,
	}, { limiteTexto(16) })

	local botaoResgatar = botao({
		Text = "RESGATAR",
		Cor = COR.verde,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.7, 0, 0, 56),
		Parent = corpo,
	}, function()
		local ok, mensagem = invocar("Diaria")
		notificar(mensagem, ok and "sucesso" or "aviso")
		atualizarDiario()
	end)

	function atualizarDiario()
		local agora = workspace:GetServerTimeNow()
		local ultima = atributo("UltimaDiaria", 0)
		local sequencia = atributo("SequenciaDiaria", 0)
		local renascimentos = atributo("Renascimentos", 0)
		local proxima = ultima + Config.Diaria.IntervaloHoras * 3600
		local disponivel = agora >= proxima
		local continua = ultima > 0 and (agora - ultima) <= Config.Diaria.PerdeSequenciaHoras * 3600
		local diaAtual
		if disponivel then
			diaAtual = continua and (sequencia % 7) + 1 or 1
		else
			diaAtual = (math.max(sequencia, 1) - 1) % 7 + 1
		end
		for dia, item in dias do
			item.valor.Text = formatar(Config.recompensaDiaria(dia, renascimentos))
			local pego = dia < diaAtual or (not disponivel and dia == diaAtual)
			item.icone.Text = pego and "✅" or (dia == 7 and "👑" or "💰")
			item.contorno.Transparency = dia == diaAtual and 0 or 0.75
			item.contorno.Color = dia == diaAtual and COR.amarelo or COR.rosa
			item.cartao.BackgroundColor3 = dia == diaAtual and COR.fundo3 or COR.fundo2
		end
		if disponivel then
			botaoResgatar.Text = "RESGATAR DIA " .. diaAtual
			botaoResgatar.BackgroundColor3 = COR.verde
		else
			botaoResgatar.Text = "Volte em " .. Config.formatarTempo(proxima - agora)
			botaoResgatar.BackgroundColor3 = COR.desligado
		end
		alertasMenu.Diario.Visible = disponivel and jogador:GetAttribute("UltimaDiaria") ~= nil
	end
	painel.aoAbrir = atualizarDiario
end

--------------------------------------------------------------------------
-- PAINEL: CONFIGURAÇÕES
--------------------------------------------------------------------------
local atualizarConfig
local mostrarTutorial
do
	local painel = criarPainel("Config", "⚙️ OPÇÕES", COR.desligado)
	local corpo = painel.corpo
	criar("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = corpo })

	local interruptores = {}
	local function linhaInterruptor(ordem, chave, texto)
		local linha = criar("Frame", { LayoutOrder = ordem, Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = COR.fundo2, Parent = corpo }, { canto(12) })
		rotulo({
			Text = texto,
			Font = FONTE_TITULO,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -150, 0, 30),
			Position = UDim2.fromOffset(14, 12),
			Parent = linha,
		}, { limiteTexto(24) })
		interruptores[chave] = botao({
			Text = "",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(120, 40),
			Parent = linha,
		}, function()
			configLocal[chave] = not configLocal[chave]
			aplicarMusica()
			atualizarConfig()
			invocar("Config", configLocal)
		end)
	end
	linhaInterruptor(1, "musica", "🎵 Música de fundo")
	linhaInterruptor(2, "sons", "🔊 Efeitos sonoros")

	botao({
		LayoutOrder = 3,
		Text = "📘 Ver tutorial de novo",
		Cor = COR.azul,
		Size = UDim2.new(1, 0, 0, 48),
		Parent = corpo,
	}, function()
		mostrarTutorial()
	end)

	rotulo({
		LayoutOrder = 4,
		Text = "Controles: E = comprar/roubar (segure) • F = vender • 1 = Luva Heroica (clique para socar)",
		Font = FONTE_TEXTO,
		TextColor3 = COR.cinza,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = corpo,
	}, { limiteTexto(16) })

	function atualizarConfig()
		for chave, b in interruptores do
			local ligado = configLocal[chave]
			b.Text = ligado and "LIGADO" or "DESLIGADO"
			b.BackgroundColor3 = ligado and COR.verde or COR.vermelho
		end
	end
	painel.aoAbrir = atualizarConfig
end

--------------------------------------------------------------------------
-- PAINÉIS ESPECIAIS: TUTORIAL E BEM-VINDO DE VOLTA
--------------------------------------------------------------------------
do
	local painel = criarPainel("Tutorial", "📘 COMO JOGAR", COR.azul)
	local corpo = painel.corpo
	local PAGINAS = {
		{ "🦸", "Bem-vindo ao ROUBE UM HERÓI!", "Heróis saem do portal e andam pela passarela vermelha. Chegue perto de um e aperte E para comprar. Ele vai sozinho para a sua base." },
		{ "💰", "Ganhe dinheiro", "Cada herói gera dinheiro por segundo. O dinheiro fica guardado no botão verde na frente do pedestal: pise nele para coletar!" },
		{ "🦹", "Roube heróis!", "Entre na base de outro jogador e SEGURE E perto de um herói. Corra de volta para a sua base carregando ele. Você fica mais lento!" },
		{ "🥊", "Defenda sua base", "Use a Luva Heroica (tecla 1) e clique para socar: o ladrão derruba o herói. Pise no botão verde da entrada para trancar sua base." },
		{ "🚀", "Fique cada vez mais forte", "Compre melhorias na Loja, complete o Índice, resgate o prêmio diário e Renasça para multiplicar sua renda. Bom jogo, herói!" },
	}
	local pagina = 1
	local icone = rotulo({ Text = "", Size = UDim2.new(1, 0, 0, 70), Parent = corpo })
	local titulo = rotulo({ Text = "", Font = FONTE_TITULO, TextColor3 = COR.amarelo, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 74), Parent = corpo }, { contornoTexto(2) })
	local texto = rotulo({
		Text = "",
		Font = FONTE_TEXTO,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 1, -190),
		Position = UDim2.fromOffset(0, 114),
		Parent = corpo,
	}, { limiteTexto(20) })
	local indicador = rotulo({ Text = "", TextColor3 = COR.cinza, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -76), Parent = corpo })

	local botaoProximo
	local function mostrarPagina()
		local dados = PAGINAS[pagina]
		icone.Text = dados[1]
		titulo.Text = dados[2]
		texto.Text = dados[3]
		indicador.Text = pagina .. " / " .. #PAGINAS
		botaoProximo.Text = pagina == #PAGINAS and "COMEÇAR! 🚀" or "PRÓXIMO ➜"
	end
	botao({
		Text = "Pular",
		Cor = COR.desligado,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(0.3, 0, 0, 50),
		Parent = corpo,
	}, fecharPainel)
	botaoProximo = botao({
		Text = "",
		Cor = COR.verde,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, -4),
		Size = UDim2.new(0.6, 0, 0, 50),
		Parent = corpo,
	}, function()
		if pagina < #PAGINAS then
			pagina += 1
			mostrarPagina()
		else
			fecharPainel()
		end
	end)

	painel.aoAbrir = function()
		pagina = 1
		mostrarPagina()
	end
	painel.aoFechar = function()
		if not atributo("TutorialFeito", false) then
			invocar("Tutorial")
		end
	end
	mostrarTutorial = function()
		if painelAberto ~= "Tutorial" then
			abrirPainel("Tutorial")
		end
	end
end

local mostrarBemVindo
do
	local painel = criarPainel("BemVindo", "👋 BEM-VINDO DE VOLTA!", COR.verde)
	local corpo = painel.corpo
	rotulo({ Text = "💰", Size = UDim2.new(1, 0, 0, 80), Parent = corpo })
	local texto = rotulo({
		Text = "",
		Font = FONTE_TITULO,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 1, -170),
		Position = UDim2.fromOffset(0, 90),
		Parent = corpo,
	}, { limiteTexto(26), contornoTexto(2) })
	botao({
		Text = "OBA! 🎉",
		Cor = COR.verde,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(0.6, 0, 0, 54),
		Parent = corpo,
	}, fecharPainel)
	mostrarBemVindo = function(valor, segundos)
		texto.Text = "Enquanto você esteve fora (" .. Config.formatarTempo(segundos) .. "), seus heróis geraram "
			.. formatar(valor) .. "!\nColete nos botões verdes dos pedestais."
		abrirPainel("BemVindo")
	end
end

--------------------------------------------------------------------------
-- AVISO DE "LEVE ATÉ A SUA BASE" + SETA
--------------------------------------------------------------------------
local avisoCarregando = rotulo({
	Text = "",
	Font = FONTE_TITULO,
	TextColor3 = COR.amarelo,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -120),
	Size = UDim2.new(0.7, 0, 0, 44),
	Visible = false,
	Parent = gui,
}, { contornoTexto(3), criar("UISizeConstraint", { MaxSize = Vector2.new(760, 44) }) })
local feixe, anexoSeta = nil, nil

local function atualizarCarregando()
	if feixe then
		feixe:Destroy()
		feixe = nil
	end
	if anexoSeta then
		anexoSeta:Destroy()
		anexoSeta = nil
	end
	local nomeHeroi = jogador:GetAttribute("Carregando")
	avisoCarregando.Visible = nomeHeroi ~= nil
	if not nomeHeroi then
		return
	end
	avisoCarregando.Text = "🏃 LEVE " .. string.upper(tostring(nomeHeroi)) .. " ATÉ A SUA BASE!"

	local mapa = workspace:FindFirstChild("MapaHerois")
	local pastaBases = mapa and mapa:FindFirstChild("Bases")
	local base = pastaBases and pastaBases:FindFirstChild("Base" .. tostring(atributo("BaseIndice", 0)))
	local alvoEntrega = base and base:FindFirstChild("AlvoEntrega")
	local alvo = alvoEntrega and alvoEntrega:FindFirstChild("Alvo")
	local raiz = jogador.Character and jogador.Character:FindFirstChild("HumanoidRootPart")
	if alvo and raiz then
		anexoSeta = criar("Attachment", { Name = "AnexoSeta", Parent = raiz })
		feixe = criar("Beam", {
			Name = "SetaBase",
			Attachment0 = anexoSeta,
			Attachment1 = alvo,
			Color = ColorSequence.new(COR.amarelo, COR.verde),
			Transparency = NumberSequence.new(0.15),
			LightEmission = 1,
			FaceCamera = true,
			Width0 = 0.9,
			Width1 = 0.9,
			Segments = 20,
			Parent = raiz,
		})
	end
end

--------------------------------------------------------------------------
-- EFEITOS
--------------------------------------------------------------------------
local function textoFlutuante(texto, posicao, cor)
	local ancora = criar("Part", {
		Name = "TextoFlutuante",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.one * 0.2,
		CFrame = CFrame.new(posicao + Vector3.new(0, 2, 0)),
		Parent = workspace,
	})
	local placa = criar("BillboardGui", { Size = UDim2.fromOffset(220, 54), AlwaysOnTop = true, LightInfluence = 0, Adornee = ancora, Parent = ancora })
	local contorno = contornoTexto(2.5)
	local rotuloTexto = rotulo({ Text = texto, Font = FONTE_TITULO, TextColor3 = cor, Parent = placa }, { contorno })
	local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(placa, info, { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(rotuloTexto, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	TweenService:Create(contorno, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	Debris:AddItem(ancora, 1.3)
end

local function confete()
	for _ = 1, 70 do
		local tamanho = math.random(8, 15)
		local pedaco = criar("Frame", {
			Size = UDim2.fromOffset(tamanho, tamanho),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			BackgroundColor3 = Color3.fromHSV(math.random(), 0.8, 1),
			BorderSizePixel = 0,
			Rotation = math.random(0, 360),
			ZIndex = 40,
			Parent = gui,
		})
		local destino = UDim2.new(pedaco.Position.X.Scale + (math.random() - 0.5) * 0.25, 0, 1.1, 0)
		TweenService:Create(pedaco, TweenInfo.new(math.random(18, 32) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = destino,
			Rotation = pedaco.Rotation + math.random(-360, 360),
		}):Play()
		Debris:AddItem(pedaco, 3.4)
	end
end

local function piscarAlarme(ladrao, heroi)
	anunciar("🚨 " .. tostring(ladrao) .. " está roubando seu " .. tostring(heroi) .. "! Soque ele com a Luva!", COR.vermelho, 5)
	task.spawn(function()
		for _ = 1, 3 do
			tocar("alarme")
			telaAlarme.BackgroundTransparency = 0.6
			TweenService:Create(telaAlarme, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
			task.wait(0.55)
		end
	end)
end

local function tremerCamera(duracao, forca)
	local humanoid = jogador.Character and jogador.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local inicio = os.clock()
	local conexao
	conexao = RunService.RenderStepped:Connect(function()
		if os.clock() - inicio > duracao or not humanoid.Parent then
			humanoid.CameraOffset = Vector3.zero
			conexao:Disconnect()
			return
		end
		humanoid.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * forca
	end)
end

-- Heróis com mutação Arco-íris mudam de cor sem parar
local arcoIris = {}
local function registrarArcoIris(modelo)
	task.defer(function()
		local partes = {}
		for _, objeto in modelo:GetDescendants() do
			if objeto:IsA("BasePart") and objeto:GetAttribute("Pintavel") then
				table.insert(partes, objeto)
			end
		end
		arcoIris[modelo] = { partes = partes, texto = modelo:FindFirstChild("TextoArcoIris", true) }
	end)
end
CollectionService:GetInstanceAddedSignal("HeroiArcoIris"):Connect(registrarArcoIris)
CollectionService:GetInstanceRemovedSignal("HeroiArcoIris"):Connect(function(modelo)
	arcoIris[modelo] = nil
end)
for _, modelo in CollectionService:GetTagged("HeroiArcoIris") do
	registrarArcoIris(modelo)
end

--------------------------------------------------------------------------
-- BOTÕES "ROUBAR" E "VENDER": cada jogador só vê o que faz sentido
--------------------------------------------------------------------------
local function filtrarPrompt(prompt)
	local modelo = prompt:FindFirstAncestorOfClass("Model")
	if not modelo then
		return
	end
	local souDono = modelo:GetAttribute("DonoId") == jogador.UserId
	if prompt.Name == "PromptRoubar" then
		prompt.Enabled = not souDono
	elseif prompt.Name == "PromptVender" then
		prompt.Enabled = souDono
	end
end

local function observarObjeto(objeto)
	if objeto:IsA("ProximityPrompt") and (objeto.Name == "PromptRoubar" or objeto.Name == "PromptVender") then
		filtrarPrompt(objeto)
		local modelo = objeto:FindFirstAncestorOfClass("Model")
		if modelo then
			modelo:GetAttributeChangedSignal("DonoId"):Connect(function()
				if objeto.Parent then
					filtrarPrompt(objeto)
				end
			end)
		end
	end
end
workspace.DescendantAdded:Connect(observarObjeto)
for _, objeto in workspace:GetDescendants() do
	observarObjeto(objeto)
end

--------------------------------------------------------------------------
-- MENSAGENS DO SERVIDOR
--------------------------------------------------------------------------
Notificar.OnClientEvent:Connect(notificar)

Anuncio.OnClientEvent:Connect(function(mensagem, cor)
	anunciar(mensagem, cor)
end)

Efeito.OnClientEvent:Connect(function(tipo, a, b)
	if tipo == "coleta" then
		tocar("moeda")
		textoFlutuante("+" .. formatar(a), b, COR.verde)
	elseif tipo == "som" then
		tocar(a)
	elseif tipo == "alarme" then
		piscarAlarme(a, b)
	elseif tipo == "renascer" then
		confete()
		tocar("compra")
	elseif tipo == "offline" then
		mostrarBemVindo(a, b)
	end
end)

Empurrao.OnClientEvent:Connect(function(velocidade)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	local humanoid = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if not raiz or not raiz:IsA("BasePart") or not humanoid then
		return
	end
	humanoid.PlatformStand = true
	raiz.AssemblyLinearVelocity = velocidade
	tremerCamera(0.35, 0.8)
	task.delay(0.8, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end)

--------------------------------------------------------------------------
-- ATUALIZAÇÕES QUANDO OS DADOS DO JOGADOR MUDAM
--------------------------------------------------------------------------
jogador.AttributeChanged:Connect(function(nome)
	if nome == "Dinheiro" then
		local novo = atributo("Dinheiro", 0)
		if novo > alvoDinheiro then
			escalaHud.Scale = escalaMenu.Scale * 1.07
			TweenService:Create(escalaHud, TweenInfo.new(0.2), { Scale = escalaMenu.Scale }):Play()
		end
		alvoDinheiro = novo
		if painelAberto == "Loja" then
			atualizarLoja()
		end
		atualizarRenascer()
	elseif nome == "RendaPorSegundo" or nome == "Multiplicador" then
		atualizarRenda()
	elseif string.sub(nome, 1, 5) == "Nivel" or nome == "PasseDobro" then
		atualizarLoja()
	elseif nome == "Renascimentos" then
		atualizarRenascer()
		atualizarLoja()
		atualizarDiario()
	elseif nome == "Descobertos" then
		atualizarIndice()
	elseif nome == "UltimaDiaria" or nome == "SequenciaDiaria" then
		atualizarDiario()
	elseif nome == "Carregando" then
		atualizarCarregando()
	elseif nome == "Musica" or nome == "Sons" then
		configLocal.musica = atributo("Musica", true)
		configLocal.sons = atributo("Sons", true)
		aplicarMusica()
		atualizarConfig()
	end
end)

jogador.CharacterAdded:Connect(function()
	task.wait(0.5)
	atualizarCarregando()
end)

-- Todo frame: contador de dinheiro animado e cores do arco-íris
RunService.RenderStepped:Connect(function(dt)
	if valorExibido ~= alvoDinheiro then
		valorExibido += (alvoDinheiro - valorExibido) * math.min(1, dt * 10)
		if math.abs(alvoDinheiro - valorExibido) < 1 then
			valorExibido = alvoDinheiro
		end
		textoDinheiro.Text = formatar(valorExibido)
	end

	local tom = (os.clock() * 0.3) % 1
	for _, info in arcoIris do
		for i, parte in info.partes do
			parte.Color = Color3.fromHSV((tom + i * 0.04) % 1, 0.75, 1)
		end
		if info.texto and info.texto:IsA("TextLabel") then
			info.texto.TextColor3 = Color3.fromHSV(tom, 0.6, 1)
		end
	end

	if avisoCarregando.Visible then
		avisoCarregando.TextTransparency = 0.25 + math.sin(os.clock() * 8) * 0.25
	end
end)

-- Todo segundo: barra de evento, contagem da diária, ranking do servidor
task.spawn(function()
	while true do
		local idEvento = workspace:GetAttribute("EventoId")
		local fim = workspace:GetAttribute("EventoFim")
		local evento = idEvento and Config.EventoPorId[idEvento]
		if evento and fim then
			barraEvento.Visible = true
			barraEvento.BackgroundColor3 = evento.cor
			textoEvento.Text = evento.icone .. " " .. evento.nome .. "  •  " .. Config.formatarTempo(fim - workspace:GetServerTimeNow())
		else
			barraEvento.Visible = false
		end
		atualizarDiario()
		if painelAberto == "Ranking" then
			atualizarRankingPainel(true)
		end
		task.wait(1)
	end
end)

--------------------------------------------------------------------------
-- TELA DE ABERTURA E PRIMEIRA ATUALIZAÇÃO
--------------------------------------------------------------------------
do
	local abertura = criar("ScreenGui", {
		Name = "Abertura",
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		ResetOnSpawn = false,
		Parent = playerGui,
	})
	local fundo = criar("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = abertura }, {
		gradiente(Color3.fromRGB(70, 30, 130), Color3.fromRGB(10, 10, 25), 90),
	})
	local titulo = rotulo({
		Text = "ROUBE UM HERÓI",
		Font = FONTE_TITULO,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.8, 0.18),
		Parent = fundo,
	}, {
		gradiente(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 30), 90),
		criar("UIStroke", { Thickness = 5, Color = Color3.fromRGB(80, 20, 0) }),
	})
	local subtitulo = rotulo({
		Text = "🦸 Carregando a cidade dos heróis... 🦹",
		Font = FONTE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.6),
		Size = UDim2.fromScale(0.6, 0.05),
		Parent = fundo,
	})
	local escalaTitulo = criar("UIScale", { Scale = 0.6, Parent = titulo })
	TweenService:Create(escalaTitulo, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.3, function()
		local info = TweenInfo.new(0.6)
		TweenService:Create(fundo, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(titulo, info, { TextTransparency = 1 }):Play()
		TweenService:Create(subtitulo, info, { TextTransparency = 1 }):Play()
		for _, objeto in titulo:GetChildren() do
			if objeto:IsA("UIStroke") then
				TweenService:Create(objeto, info, { Transparency = 1 }):Play()
			end
		end
		task.wait(0.7)
		abertura:Destroy()
	end)
end

ajustarEscala()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
end

alvoDinheiro = atributo("Dinheiro", 0)
valorExibido = alvoDinheiro
textoDinheiro.Text = formatar(valorExibido)
configLocal.musica = atributo("Musica", true)
configLocal.sons = atributo("Sons", true)
aplicarMusica()
atualizarRenda()
atualizarLoja()
atualizarIndice()
atualizarRenascer()
atualizarDiario()
atualizarConfig()
atualizarCarregando()

-- Mostra o tutorial para quem está jogando pela primeira vez
task.spawn(function()
	local inicio = os.clock()
	while jogador:GetAttribute("TutorialFeito") == nil and os.clock() - inicio < 20 do
		task.wait(0.5)
	end
	task.wait(3)
	if jogador:GetAttribute("TutorialFeito") == false and painelAberto == nil then
		mostrarTutorial()
	end
end)
