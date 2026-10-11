--[[
	ROUBE UM HERÓI - Script principal do servidor

	Onde colocar: ServerScriptService -> Script (nome: JogoHerois)
	Precisa também de: ServerScriptService/Mapa, ServerScriptService/Dados,
	ServerScriptService/ModelosHerois e ReplicatedStorage/ConfigHerois (ModuleScripts).

	Cuida de toda a lógica do jogo:
	  - heróis saindo do portal e andando pela passarela (com mutações)
	  - compra, renda por segundo, coleta nos pedestais, venda
	  - roubo (segurar E), carregar o herói até a sua base, Luva Heroica (5 níveis)
	  - bases de 3 andares com elevador, tenda da Loja e Roleta da Sorte
	  - tranca da base, melhorias, renascimento, recompensa diária
	  - eventos, ciclo dia/noite, coroa do mais rico
	  - salvamento (DataStore), ranking global e compras com Robux
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("ConfigHerois"))
local Mapa = require(script.Parent:WaitForChild("Mapa"))
local Dados = require(script.Parent:WaitForChild("Dados"))
local Modelos = require(script.Parent:WaitForChild("ModelosHerois"))

local G = Config.Geral
local formatar = Config.formatar

local NOME_LUVA = "Luva Heroica"

local function ordemRaridade(id)
	local raridade = Config.RaridadePorId[id] or Config.Raridades[#Config.Raridades]
	return raridade.ordem
end
local ORDEM_ANUNCIO_SPAWN = ordemRaridade(G.AnunciarSpawnAPartirDe)
local ORDEM_ANUNCIO_COMPRA = ordemRaridade(G.AnunciarCompraAPartirDe)
local ORDEM_ANUNCIO_ROUBO = ordemRaridade(G.AnunciarRouboAPartirDe)
local ORDEM_LENDARIO = ordemRaridade("Lendario")

--------------------------------------------------------------------------
-- COMUNICAÇÃO COM OS JOGADORES (RemoteEvents)
--------------------------------------------------------------------------
local antigos = ReplicatedStorage:FindFirstChild("RemotesHerois")
if antigos then
	antigos:Destroy()
end
local remotes = Instance.new("Folder")
remotes.Name = "RemotesHerois"
local function criarRemoto(classe, nome)
	local remoto = Instance.new(classe)
	remoto.Name = nome
	remoto.Parent = remotes
	return remoto
end
local Notificar = criarRemoto("RemoteEvent", "Notificar")
local Anuncio = criarRemoto("RemoteEvent", "Anuncio")
local Efeito = criarRemoto("RemoteEvent", "Efeito")
local Empurrao = criarRemoto("RemoteEvent", "Empurrao")
local Acao = criarRemoto("RemoteFunction", "Acao")
local ObterRanking = criarRemoto("RemoteFunction", "ObterRanking")
local AbrirLoja = criarRemoto("RemoteEvent", "AbrirLoja")
local RoletaGiro = criarRemoto("RemoteEvent", "RoletaGiro")
remotes.Parent = ReplicatedStorage

--------------------------------------------------------------------------
-- MAPA E ESTADO
--------------------------------------------------------------------------
Dados.iniciar(Config)
local mapa = Mapa.construir(Config, Modelos)
local bases = mapa.bases

local sessoes = {} -- [jogador] = sessão (dados salvos + base + controles)
local herois = {} -- [modelo] = herói
local carregando = {} -- [jogador] = herói que ele está roubando
local eventoAtual = nil
local tokenEvento = 0
local rankingGlobal = { disponivel = false, Dinheiro = {}, Roubos = {}, Renascimentos = {} }

--------------------------------------------------------------------------
-- AJUDANTES
--------------------------------------------------------------------------
local function notificar(jogador, mensagem, tipo)
	if jogador and jogador.Parent then
		Notificar:FireClient(jogador, mensagem, tipo or "info")
	end
end

local function anunciar(mensagem, cor)
	Anuncio:FireAllClients(mensagem, cor or Color3.fromRGB(255, 200, 40))
end

local function efeito(jogador, tipo, ...)
	if jogador and jogador.Parent then
		Efeito:FireClient(jogador, tipo, ...)
	end
end

local function multEvento(campo)
	if eventoAtual and eventoAtual[campo] then
		return eventoAtual[campo]
	end
	return 1
end

local function humanoidDe(jogador)
	local personagem = jogador.Character
	return personagem and personagem:FindFirstChildOfClass("Humanoid")
end

local function raizDe(jogador)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function dentroDaBase(base, posicao)
	local local_ = base.cframe:PointToObjectSpace(posicao)
	return math.abs(local_.X) <= Mapa.METADE_BASE and math.abs(local_.Z) <= Mapa.METADE_BASE
end

--------------------------------------------------------------------------
-- DINHEIRO E ATRIBUTOS DO JOGADOR
--------------------------------------------------------------------------
local function nivel(jogador, id)
	local sessao = sessoes[jogador]
	return sessao and (sessao.dados.niveis[id] or 0) or 0
end

local function velocidadeJogador(jogador)
	local velocidade = Config.velocidadeDoNivel(nivel(jogador, "Velocidade"))
	local sessao = sessoes[jogador]
	if sessao and os.time() < (sessao.boostVelocidadeAte or 0) then
		velocidade *= 1.5
	end
	return velocidade
end

-- Aplica velocidade e pulo (Mola Turbo, bônus da roleta e peso do herói roubado)
local function aplicarMovimento(jogador)
	local humanoid = humanoidDe(jogador)
	if not humanoid then
		return
	end
	local velocidade = velocidadeJogador(jogador)
	if carregando[jogador] then
		velocidade *= G.MultiplicadorCarregando
	end
	humanoid.WalkSpeed = velocidade
	local pulo = Config.puloDoNivel(nivel(jogador, "Velocidade"))
	humanoid.JumpHeight = pulo
	humanoid.JumpPower = math.sqrt(2 * workspace.Gravity * pulo)
end

local function pedestaisJogador(jogador)
	return Config.pedestaisDoNivel(nivel(jogador, "Pedestais"))
end

local function multiplicadorJogador(jogador)
	local sessao = sessoes[jogador]
	if not sessao then
		return 1
	end
	local multiplicador = Config.multiplicadorRenascimento(sessao.dados.renascimentos)
	if sessao.passeDobro then
		multiplicador *= 2
	end
	if os.time() < (sessao.boostRendaAte or 0) then
		multiplicador *= 2
	end
	return multiplicador
end

local function atualizarDinheiro(jogador)
	local sessao = sessoes[jogador]
	if not sessao then
		return
	end
	jogador:SetAttribute("Dinheiro", sessao.dados.dinheiro)
	sessao.statDinheiro.Value = math.floor(math.min(sessao.dados.dinheiro, 9e18))
end

local function atualizarAtributos(jogador)
	local sessao = sessoes[jogador]
	if not sessao then
		return
	end
	local d = sessao.dados
	atualizarDinheiro(jogador)
	jogador:SetAttribute("Renascimentos", d.renascimentos)
	jogador:SetAttribute("Multiplicador", multiplicadorJogador(jogador))
	jogador:SetAttribute("Roubos", d.roubos)
	for id, valor in d.niveis do
		jogador:SetAttribute("Nivel" .. id, valor)
	end
	jogador:SetAttribute("UltimaDiaria", d.ultimaDiaria)
	jogador:SetAttribute("SequenciaDiaria", d.sequenciaDiaria)
	jogador:SetAttribute("TutorialFeito", d.tutorial)
	jogador:SetAttribute("Musica", d.config.musica)
	jogador:SetAttribute("Sons", d.config.sons)
	jogador:SetAttribute("PasseDobro", sessao.passeDobro == true)
	jogador:SetAttribute("BaseIndice", sessao.base and sessao.base.indice or 0)
	local descobertos = {}
	for id in d.descobertos do
		table.insert(descobertos, id)
	end
	jogador:SetAttribute("Descobertos", HttpService:JSONEncode(descobertos))
	local luvas = {}
	for id in d.luvas do
		table.insert(luvas, id)
	end
	jogador:SetAttribute("Luvas", HttpService:JSONEncode(luvas))
	jogador:SetAttribute("LuvaEquipada", d.luvaEquipada)
	jogador:SetAttribute("UltimaRoleta", d.ultimaRoleta)
	jogador:SetAttribute("BoostRenda", sessao.boostRendaAte or 0)
	jogador:SetAttribute("BoostVelocidade", sessao.boostVelocidadeAte or 0)
	sessao.statRoubos.Value = d.roubos
	sessao.statRenascimentos.Value = d.renascimentos
end

local function ganhar(jogador, valor)
	local sessao = sessoes[jogador]
	if not sessao or valor <= 0 then
		return
	end
	sessao.dados.dinheiro += valor
	sessao.dados.totalGanho += valor
	atualizarDinheiro(jogador)
end

local function gastar(jogador, valor)
	local sessao = sessoes[jogador]
	if not sessao or sessao.dados.dinheiro < valor then
		return false
	end
	sessao.dados.dinheiro -= valor
	atualizarDinheiro(jogador)
	return true
end

local function descobrir(jogador, def)
	local sessao = sessoes[jogador]
	if sessao and not sessao.dados.descobertos[def.id] then
		sessao.dados.descobertos[def.id] = true
		atualizarAtributos(jogador)
		notificar(jogador, "📖 Novo herói no Índice: " .. def.nome .. "!", "especial")
	end
end

--------------------------------------------------------------------------
-- HERÓIS: CRIAR, REMOVER, BOTÕES (ProximityPrompt)
--------------------------------------------------------------------------
local function valorHeroi(h)
	return h.def.preco * h.mutacao.multiplicador
end

local function rendaHeroi(h)
	return h.def.renda * h.mutacao.multiplicador
end

local function nomeCompleto(h)
	if h.mutacao.id ~= "Normal" then
		return h.def.nome .. " " .. h.mutacao.nome
	end
	return h.def.nome
end

local function novoHeroi(def, mutacaoId)
	local mutacao = Config.MutacaoPorId[mutacaoId] or Config.MutacaoPorId.Normal
	local modelo, raiz = Modelos.heroi(def, mutacao, Config)
	modelo.Parent = mapa.pastaHerois
	local raridade = Config.RaridadePorId[def.raridade]
	local h = {
		modelo = modelo,
		raiz = raiz,
		def = def,
		mutacao = mutacao,
		raridade = raridade,
		altura = 2.03 * raridade.escala, -- distância do tronco até a sola da bota
		estado = "novo", -- novo | andando | indo | base | carregado | removido
		distancia = 0,
	}
	herois[modelo] = h
	return h
end

local function removerHeroi(h)
	h.estado = "removido"
	herois[h.modelo] = nil
	h.modelo:Destroy()
end

local function limparPrompts(h)
	for _, filho in h.raiz:GetChildren() do
		if filho:IsA("ProximityPrompt") then
			filho:Destroy()
		end
	end
end

local function criarPrompt(h, nome, acao, objeto, tecla, segurar, aoAtivar)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = nome
	prompt.ActionText = acao
	prompt.ObjectText = objeto
	prompt.KeyboardKeyCode = tecla
	prompt.HoldDuration = segurar
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = h.raiz
	prompt.Triggered:Connect(function(jogador)
		aoAtivar(h, jogador)
	end)
	return prompt
end

--------------------------------------------------------------------------
-- BASES: PEDESTAIS, COLETA E TRANCA
--------------------------------------------------------------------------
local function slotLivre(base, quantidade)
	for i = 1, math.min(quantidade, #base.slots) do
		local slot = base.slots[i]
		if not slot.heroi then
			return slot
		end
	end
	return nil
end

local function atualizarPad(slot)
	if slot.acumulado >= 1 then
		slot.guiPad.Enabled = true
		slot.textoPad.Text = "💰 " .. formatar(slot.acumulado)
	else
		slot.guiPad.Enabled = false
	end
end

local function atualizarSlots(base)
	local dono = base.dono
	local liberados = dono and pedestaisJogador(dono) or #base.slots
	for i, slot in base.slots do
		local liberado = i <= liberados
		slot.pedestal.Transparency = liberado and 0 or 0.65
		slot.anel.Color = liberado and base.cor or Color3.fromRGB(90, 90, 100)
		slot.pad.Transparency = liberado and 0 or 1
		slot.guiCadeado.Enabled = dono ~= nil and not liberado
	end
end

local function atualizarBarreira(base)
	local trancada = os.clock() < base.trancadaAte
	base.barreira.CanCollide = trancada
	base.barreira.Transparency = trancada and 0.45 or 1
end

local function trancarBase(base, jogador)
	local agora = os.clock()
	if agora < base.recargaAte then
		return
	end
	local duracao = Config.trancaDoNivel(nivel(jogador, "Tranca"))
	base.trancadaAte = agora + duracao
	base.recargaAte = base.trancadaAte + G.RecargaTranca
	atualizarBarreira(base)

	-- Quem estava dentro é jogado para fora
	for _, outro in Players:GetPlayers() do
		local raiz = raizDe(outro)
		if outro ~= jogador and raiz and outro.Character and dentroDaBase(base, raiz.Position) then
			outro.Character:PivotTo(base.saida)
			notificar(outro, "🔒 A base foi trancada e você foi expulso!", "aviso")
		end
	end
	notificar(jogador, "🔒 Base trancada por " .. duracao .. " segundos!", "sucesso")
	efeito(jogador, "som", "compra")
end

-- Tira todos os heróis de uma base (quando o dono sai ou renasce)
local function limparHeroisDaBase(base)
	for _, slot in base.slots do
		local h = slot.heroi
		if h then
			if h.estado == "carregado" then
				if h.slot == slot then
					-- alguém está roubando: o ladrão continua com ele
					slot.heroi = nil
					h.base = nil
					h.slot = nil
				end
			else
				slot.heroi = nil
				removerHeroi(h)
			end
		end
		slot.acumulado = 0
		atualizarPad(slot)
	end
end

--------------------------------------------------------------------------
-- COLOCAR NA BASE, ROUBAR, DEVOLVER, ENTREGAR
--------------------------------------------------------------------------
local aoRoubar, aoVender -- definidas mais abaixo

local function colocarNaBase(h, base, slot, animar)
	limparPrompts(h)
	slot.heroi = h
	h.base = base
	h.slot = slot
	h.modelo:SetAttribute("DonoId", base.dono and base.dono.UserId or 0)
	h.raiz.Anchored = true

	local destino = slot.topo * CFrame.new(0, h.altura, 0)
	local valorVenda = math.floor(valorHeroi(h) * G.PorcentagemVenda)

	local function finalizar()
		h.estado = "base"
		h.raiz.CFrame = destino
		criarPrompt(h, "PromptRoubar", "Roubar", nomeCompleto(h), Enum.KeyCode.E, G.TempoParaRoubar, aoRoubar)
		criarPrompt(h, "PromptVender", "Vender por " .. formatar(valorVenda), nomeCompleto(h), Enum.KeyCode.F, 0.6, aoVender)
	end

	if animar then
		h.estado = "indo"
		local tween = TweenService:Create(h.raiz, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = destino })
		tween.Completed:Connect(function()
			if h.estado == "indo" and h.slot == slot then
				finalizar()
			end
		end)
		tween:Play()
	else
		finalizar()
	end
end

local function marcarLadrao(jogador, ligar)
	local personagem = jogador.Character
	if not personagem then
		return
	end
	local marca = personagem:FindFirstChild("MarcaLadrao")
	if ligar and not marca then
		local destaque = Instance.new("Highlight")
		destaque.Name = "MarcaLadrao"
		destaque.FillColor = Color3.fromRGB(255, 40, 40)
		destaque.FillTransparency = 0.75
		destaque.OutlineColor = Color3.fromRGB(255, 60, 60)
		destaque.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		destaque.Parent = personagem
	elseif not ligar and marca then
		marca:Destroy()
	end
end

-- Solta o herói das costas do ladrão. Retorna o pedestal que estava reservado na base do ladrão.
local function terminarCarregar(h)
	local ladrao = h.ladrao
	if h.conexaoMorte then
		h.conexaoMorte:Disconnect()
		h.conexaoMorte = nil
	end
	h.raiz.Anchored = true
	local solda = h.raiz:FindFirstChild("SoldaRoubo")
	if solda then
		solda:Destroy()
	end
	if ladrao then
		carregando[ladrao] = nil
		marcarLadrao(ladrao, false)
		ladrao:SetAttribute("Carregando", nil)
		aplicarMovimento(ladrao)
	end
	h.ladrao = nil
	local slotDestino = h.slotDestino
	h.slotDestino = nil
	return slotDestino
end

-- O roubo falhou: o herói volta para o pedestal de onde saiu
local function devolver(h, motivo)
	if h.estado ~= "carregado" then
		return
	end
	local ladrao = h.ladrao
	local slotDestino = terminarCarregar(h)
	if slotDestino and slotDestino.heroi == h then
		slotDestino.heroi = nil
	end
	if not h.base or not h.base.dono or not h.slot then
		removerHeroi(h) -- o dono saiu ou renasceu
		return
	end
	colocarNaBase(h, h.base, h.slot, false)
	if motivo and ladrao then
		notificar(ladrao, motivo, "erro")
	end
	notificar(h.base.dono, "🛡️ Seu " .. nomeCompleto(h) .. " voltou para a base!", "sucesso")
end

-- O ladrão chegou na própria base: o herói agora é dele
local function entregar(h)
	local ladrao = h.ladrao
	local donoAntigo = h.base and h.base.dono
	local slotDestino = terminarCarregar(h)
	if h.slot and h.slot.heroi == h then
		h.slot.heroi = nil
	end
	colocarNaBase(h, slotDestino.base, slotDestino, false)

	local sessao = sessoes[ladrao]
	if sessao then
		sessao.dados.roubos += 1
		atualizarAtributos(ladrao)
	end
	descobrir(ladrao, h.def)
	notificar(ladrao, "🦹 Você roubou " .. nomeCompleto(h) .. "!", "sucesso")
	efeito(ladrao, "som", "compra")
	if donoAntigo then
		notificar(donoAntigo, "😱 " .. ladrao.DisplayName .. " roubou seu " .. nomeCompleto(h) .. "!", "erro")
	end
	if h.raridade.ordem >= ORDEM_ANUNCIO_ROUBO then
		anunciar("🦹 " .. ladrao.DisplayName .. " roubou " .. nomeCompleto(h) .. " (" .. h.raridade.nome .. ")!", h.raridade.cor)
	end
end

local function verificarCarregado(h)
	local ladrao = h.ladrao
	local raiz = ladrao and raizDe(ladrao)
	if not raiz or not h.slotDestino then
		devolver(h, "Você perdeu o herói!")
		return
	end
	if dentroDaBase(h.slotDestino.base, raiz.Position) then
		entregar(h)
		return
	end
	if G.RecuperarEncostando then
		local dono = h.base and h.base.dono
		local raizDono = dono and raizDe(dono)
		if raizDono and (raizDono.Position - raiz.Position).Magnitude < 6 then
			devolver(h, dono.DisplayName .. " pegou o herói de volta!")
		end
	end
end

function aoRoubar(h, ladrao)
	if h.estado ~= "base" then
		return
	end
	local base = h.base
	if not base or base.dono == ladrao then
		return
	end
	local sessao = sessoes[ladrao]
	if not sessao or not sessao.base then
		notificar(ladrao, "Você precisa de uma base para roubar.", "erro")
		return
	end
	if carregando[ladrao] then
		notificar(ladrao, "Você já está carregando um herói!", "aviso")
		return
	end
	if os.clock() < base.trancadaAte then
		notificar(ladrao, "🔒 Esta base está trancada!", "erro")
		return
	end
	local slotDestino = slotLivre(sessao.base, pedestaisJogador(ladrao))
	if not slotDestino then
		notificar(ladrao, "Sua base está cheia! Venda um herói ou compre mais pedestais.", "aviso")
		return
	end
	local raiz = raizDe(ladrao)
	local humanoid = humanoidDe(ladrao)
	if not raiz or not humanoid or humanoid.Health <= 0 then
		return
	end

	limparPrompts(h)
	slotDestino.heroi = h -- reserva o pedestal na base do ladrão
	h.slotDestino = slotDestino
	h.estado = "carregado"
	h.ladrao = ladrao
	carregando[ladrao] = h

	-- Gruda o herói em cima da cabeça do ladrão
	h.raiz.CFrame = raiz.CFrame * CFrame.new(0, 3.2 + h.altura, 0)
	local solda = Instance.new("WeldConstraint")
	solda.Name = "SoldaRoubo"
	solda.Part0 = raiz
	solda.Part1 = h.raiz
	solda.Parent = h.raiz
	h.raiz.Anchored = false

	aplicarMovimento(ladrao)
	h.conexaoMorte = humanoid.Died:Connect(function()
		devolver(h, "💀 Você caiu e perdeu o herói!")
	end)
	marcarLadrao(ladrao, true)
	ladrao:SetAttribute("Carregando", nomeCompleto(h))

	notificar(ladrao, "🏃 Corra para a sua base!", "aviso")
	if base.dono then
		efeito(base.dono, "alarme", ladrao.DisplayName, nomeCompleto(h))
	end
end

function aoVender(h, jogador)
	if h.estado ~= "base" or not h.base or h.base.dono ~= jogador then
		return
	end
	local valor = math.floor(valorHeroi(h) * G.PorcentagemVenda)
	h.slot.heroi = nil
	removerHeroi(h)
	ganhar(jogador, valor)
	notificar(jogador, "💵 Vendido por " .. formatar(valor) .. "!", "sucesso")
	efeito(jogador, "som", "moeda")
end

local function aoComprar(h, jogador)
	if h.estado ~= "andando" then
		return
	end
	local sessao = sessoes[jogador]
	if not sessao or not sessao.base then
		notificar(jogador, "Você precisa de uma base para comprar.", "erro")
		return
	end
	local preco = valorHeroi(h)
	if sessao.dados.dinheiro < preco then
		notificar(jogador, "💸 Dinheiro insuficiente! Custa " .. formatar(preco), "erro")
		return
	end
	local slot = slotLivre(sessao.base, pedestaisJogador(jogador))
	if not slot then
		notificar(jogador, "Sua base está cheia! Venda um herói ou compre mais pedestais na Loja.", "aviso")
		return
	end
	gastar(jogador, preco)
	colocarNaBase(h, sessao.base, slot, true)
	descobrir(jogador, h.def)
	notificar(jogador, "✅ Você comprou " .. nomeCompleto(h) .. "!", "sucesso")
	efeito(jogador, "som", "compra")
	if h.raridade.ordem >= ORDEM_ANUNCIO_COMPRA then
		anunciar("🤑 " .. jogador.DisplayName .. " comprou " .. nomeCompleto(h) .. " (" .. h.raridade.nome .. ")!", h.raridade.cor)
	end
end

--------------------------------------------------------------------------
-- PASSARELA
--------------------------------------------------------------------------
local function colocarNaPassarela(h)
	h.estado = "andando"
	h.distancia = 0
	local posicao = mapa.inicio + Vector3.new(0, h.altura, 0)
	h.raiz.CFrame = CFrame.lookAt(posicao, posicao + Vector3.xAxis)
	criarPrompt(h, "PromptComprar", "Comprar por " .. formatar(valorHeroi(h)), nomeCompleto(h), Enum.KeyCode.E, 0, aoComprar)
end

local function sortearHeroi()
	local multRaros = multEvento("multRaros")
	local pesos = {}
	local total = 0
	for i, def in Config.Herois do
		local raridade = Config.RaridadePorId[def.raridade]
		local peso = raridade.chance / raridade.quantidade
		if raridade.ordem >= ORDEM_LENDARIO then
			peso *= multRaros
		end
		pesos[i] = peso
		total += peso
	end
	local sorteio = math.random() * total
	for i, def in Config.Herois do
		sorteio -= pesos[i]
		if sorteio <= 0 then
			return def
		end
	end
	return Config.Herois[1]
end

local function sortearMutacao()
	local mult = multEvento("multMutacao")
	local sorteio = math.random()
	local acumulado = 0
	for _, mutacao in Config.Mutacoes do
		if mutacao.chance > 0 then
			acumulado += mutacao.chance * mult
			if sorteio < acumulado then
				return mutacao.id
			end
		end
	end
	return "Normal"
end

--------------------------------------------------------------------------
-- LUVA HEROICA (soco). O modelo 3D da luva é colocado na mão quando equipa.
--------------------------------------------------------------------------
local function luvaDoJogador(jogador)
	local sessao = sessoes[jogador]
	local id = sessao and sessao.dados.luvaEquipada or "Basica"
	return Config.LuvaPorId[id] or Config.Luvas[1]
end

local function criarLuva()
	local existente = StarterPack:FindFirstChild(NOME_LUVA)
	if existente then
		existente:Destroy()
	end
	local luva = Instance.new("Tool")
	luva.Name = NOME_LUVA
	luva.CanBeDropped = false
	luva.ToolTip = "Clique para socar! Ladrões socados derrubam o herói."

	-- A alça é invisível: o que aparece é a luva 3D colocada na mão
	local alca = Instance.new("Part")
	alca.Name = "Handle"
	alca.Size = Vector3.new(0.4, 0.4, 0.4)
	alca.Transparency = 1
	alca.CanCollide = false
	alca.CanTouch = false
	alca.Massless = true
	alca.Parent = luva

	local som = Instance.new("Sound")
	som.Name = "SomSoco"
	som.SoundId = Config.Sons.Soco
	som.Volume = 0.8
	som.Parent = alca

	luva.Parent = StarterPack
end
criarLuva()

local function tirarLuvaVisual(personagem)
	local antiga = personagem:FindFirstChild("LuvaVisual")
	if antiga then
		antiga:Destroy()
	end
end

local function vestirLuva(jogador)
	local personagem = jogador.Character
	if not personagem then
		return
	end
	tirarLuvaVisual(personagem)
	if not personagem:FindFirstChild(NOME_LUVA) then
		return -- só aparece com a luva equipada
	end
	local mao = personagem:FindFirstChild("RightHand") or personagem:FindFirstChild("Right Arm")
	if not mao or not mao:IsA("BasePart") then
		return
	end
	local modelo, raiz = Modelos.luva(luvaDoJogador(jogador), 1.4)
	modelo.Name = "LuvaVisual"
	local alvo = mao.CFrame * (mao.Name == "RightHand" and CFrame.new(0, -0.15, 0) or CFrame.new(0, -0.95, 0))
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.CFrame = alvo * parte.CFrame
			parte.Anchored = false
			parte.Massless = true
			parte.CanCollide = false
			parte.CanTouch = false
			parte.CanQuery = false
		end
	end
	modelo.Parent = personagem
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = mao
	solda.Part1 = raiz
	solda.Parent = raiz
end

local function socar(jogador, luva)
	local sessao = sessoes[jogador]
	if not sessao then
		return
	end
	local def = luvaDoJogador(jogador)
	local agora = os.clock()
	if agora - sessao.ultimoSoco < def.recarga then
		return
	end
	sessao.ultimoSoco = agora
	local raiz = raizDe(jogador)
	if not raiz then
		return
	end

	-- Animação padrão de ataque do Roblox
	local animacao = Instance.new("StringValue")
	animacao.Name = "toolanim"
	animacao.Value = "Slash"
	animacao.Parent = luva
	Debris:AddItem(animacao, 1)
	local alca = luva:FindFirstChild("Handle")
	local som = alca and alca:FindFirstChild("SomSoco")
	if som and som:IsA("Sound") then
		som:Play()
	end

	for _, outro in Players:GetPlayers() do
		local raizOutro = raizDe(outro)
		local humanoidOutro = humanoidDe(outro)
		if outro ~= jogador and raizOutro and humanoidOutro and humanoidOutro.Health > 0 then
			local delta = raizOutro.Position - raiz.Position
			if delta.Magnitude <= def.alcance then
				local plano = Vector3.new(delta.X, 0, delta.Z)
				local direcao = plano.Magnitude > 0.1 and plano.Unit or raiz.CFrame.LookVector
				if raiz.CFrame.LookVector:Dot(direcao) > 0.2 then
					Empurrao:FireClient(outro, direcao * def.forca + Vector3.new(0, 35, 0), def.atordoar)
					local h = carregando[outro]
					if h then
						devolver(h, "🥊 " .. jogador.DisplayName .. " te deu um soco e você derrubou o herói!")
						notificar(jogador, "🥊 Você fez " .. outro.DisplayName .. " derrubar o herói!", "sucesso")
					end
				end
			end
		end
	end
end

local luvasConectadas = setmetatable({}, { __mode = "k" })
local function conectarLuva(jogador, objeto)
	if objeto:IsA("Tool") and objeto.Name == NOME_LUVA then
		if not luvasConectadas[objeto] then
			luvasConectadas[objeto] = true
			objeto.Activated:Connect(function()
				socar(jogador, objeto)
			end)
		end
		vestirLuva(jogador)
	end
end

--------------------------------------------------------------------------
-- EVENTOS
--------------------------------------------------------------------------
local function terminarEvento()
	if not eventoAtual then
		return
	end
	anunciar("O evento " .. eventoAtual.nome .. " acabou!", Color3.fromRGB(200, 200, 210))
	eventoAtual = nil
	workspace:SetAttribute("EventoId", nil)
	workspace:SetAttribute("EventoFim", nil)
	TweenService:Create(mapa.correcaoCor, TweenInfo.new(3), { TintColor = Color3.new(1, 1, 1) }):Play()
end

local function iniciarEvento(evento)
	tokenEvento += 1
	local meuToken = tokenEvento
	local duracao = G.DuracaoEventoMinutos * 60
	eventoAtual = evento
	workspace:SetAttribute("EventoId", evento.id)
	workspace:SetAttribute("EventoFim", workspace:GetServerTimeNow() + duracao)
	anunciar(evento.icone .. " " .. evento.nome .. "! " .. evento.descricao, evento.cor)
	TweenService:Create(mapa.correcaoCor, TweenInfo.new(3), { TintColor = Color3.new(1, 1, 1):Lerp(evento.cor, 0.25) }):Play()
	task.delay(duracao, function()
		if tokenEvento == meuToken then
			terminarEvento()
		end
	end)
end

--------------------------------------------------------------------------
-- AÇÕES PEDIDAS PELA INTERFACE (Loja, Renascer, Diária...)
--------------------------------------------------------------------------
local MENSAGEM_LOJA = "🎪 Vá até a tenda da Loja (no meio do mapa) para comprar!"

local function pertoDaLoja(jogador)
	local raiz = raizDe(jogador)
	return raiz ~= nil and (raiz.Position - mapa.loja.centro).Magnitude <= G.DistanciaLoja
end

local function comprarMelhoria(jogador, id)
	local melhoria = type(id) == "string" and Config.MelhoriaPorId[id]
	if not melhoria then
		return false, "Melhoria inválida"
	end
	if not pertoDaLoja(jogador) then
		return false, MENSAGEM_LOJA
	end
	local sessao = sessoes[jogador]
	local atual = sessao.dados.niveis[id] or 0
	if atual >= #melhoria.precos then
		return false, "Nível máximo!"
	end
	local preco = melhoria.precos[atual + 1]
	if not gastar(jogador, preco) then
		return false, "Dinheiro insuficiente! Custa " .. formatar(preco)
	end
	sessao.dados.niveis[id] = atual + 1

	if id == "Velocidade" then
		aplicarMovimento(jogador)
	elseif id == "Pedestais" and sessao.base then
		atualizarSlots(sessao.base)
	end
	atualizarAtributos(jogador)
	efeito(jogador, "som", "compra")
	return true, melhoria.icone .. " " .. melhoria.nome .. " agora é nível " .. (atual + 1) .. "!"
end

local function comprarLuva(jogador, id)
	local def = type(id) == "string" and Config.LuvaPorId[id]
	if not def then
		return false, "Luva inválida"
	end
	local d = sessoes[jogador].dados
	if d.luvas[id] then
		d.luvaEquipada = id
		vestirLuva(jogador)
		atualizarAtributos(jogador)
		return true, def.icone .. " " .. def.nome .. " equipada!"
	end
	if not pertoDaLoja(jogador) then
		return false, MENSAGEM_LOJA
	end
	if not gastar(jogador, def.preco) then
		return false, "Dinheiro insuficiente! Custa " .. formatar(def.preco)
	end
	d.luvas[id] = true
	d.luvaEquipada = id
	vestirLuva(jogador)
	atualizarAtributos(jogador)
	efeito(jogador, "som", "compra")
	return true, def.icone .. " Você comprou a " .. def.nome .. "! Equipe a luva (tecla 1) e soque os ladrões."
end

local function renascer(jogador)
	local sessao = sessoes[jogador]
	local d = sessao.dados
	local custo = Config.custoRenascimento(d.renascimentos)
	if d.dinheiro < custo then
		return false, "Você precisa de " .. formatar(custo) .. " para renascer."
	end
	local h = carregando[jogador]
	if h then
		devolver(h, nil)
	end
	if sessao.base then
		limparHeroisDaBase(sessao.base)
	end
	d.renascimentos += 1
	d.dinheiro = Config.dinheiroInicial(d.renascimentos)
	atualizarAtributos(jogador)
	efeito(jogador, "renascer")
	anunciar("♻️ " .. jogador.DisplayName .. " RENASCEU! (" .. d.renascimentos .. "x)", Color3.fromRGB(170, 90, 255))
	return true, "♻️ Você renasceu! Sua renda agora é x" .. multiplicadorJogador(jogador)
end

local function resgatarDiaria(jogador)
	local d = sessoes[jogador].dados
	local agora = os.time()
	local intervalo = Config.Diaria.IntervaloHoras * 3600
	if agora < d.ultimaDiaria + intervalo then
		return false, "Volte em " .. Config.formatarTempo(d.ultimaDiaria + intervalo - agora)
	end
	if d.ultimaDiaria > 0 and agora - d.ultimaDiaria <= Config.Diaria.PerdeSequenciaHoras * 3600 then
		d.sequenciaDiaria += 1
	else
		d.sequenciaDiaria = 1
	end
	local dia = (d.sequenciaDiaria - 1) % 7 + 1
	local valor = Config.recompensaDiaria(dia, d.renascimentos)
	d.ultimaDiaria = agora
	ganhar(jogador, valor)
	atualizarAtributos(jogador)
	efeito(jogador, "som", "moeda")
	return true, "🎁 Dia " .. dia .. ": você ganhou " .. formatar(valor) .. "!"
end

Acao.OnServerInvoke = function(jogador, acao, argumento)
	local sessao = sessoes[jogador]
	if not sessao then
		return false, "Carregando seus dados..."
	end
	local agora = os.clock()
	if agora - sessao.ultimaAcao < 0.25 then
		return false, "Calma! 😅"
	end
	sessao.ultimaAcao = agora

	if acao == "Melhoria" then
		return comprarMelhoria(jogador, argumento)
	elseif acao == "Luva" then
		return comprarLuva(jogador, argumento)
	elseif acao == "Renascer" then
		return renascer(jogador)
	elseif acao == "Diaria" then
		return resgatarDiaria(jogador)
	elseif acao == "Tutorial" then
		sessao.dados.tutorial = true
		atualizarAtributos(jogador)
		return true, ""
	elseif acao == "Config" and type(argumento) == "table" then
		sessao.dados.config.musica = argumento.musica == true
		sessao.dados.config.sons = argumento.sons == true
		atualizarAtributos(jogador)
		return true, ""
	end
	return false, "Ação desconhecida"
end

ObterRanking.OnServerInvoke = function()
	return rankingGlobal
end

--------------------------------------------------------------------------
-- SALVAMENTO
--------------------------------------------------------------------------
local function montarSave(jogador)
	local sessao = sessoes[jogador]
	local d = sessao.dados
	local lista = {}
	if sessao.base then
		for i, slot in sessao.base.slots do
			local h = slot.heroi
			if h and h.base == sessao.base and h.slot == slot and h.estado ~= "removido" then
				table.insert(lista, { slot = i, id = h.def.id, mut = h.mutacao.id })
			end
		end
	end
	d.herois = lista
	d.ultimoLogin = os.time()
	return d
end

local function salvarJogador(jogador)
	local sessao = sessoes[jogador]
	if sessao and sessao.podeSalvar then
		Dados.salvar(jogador.UserId, montarSave(jogador))
	end
end

--------------------------------------------------------------------------
-- ENTRADA E SAÍDA DE JOGADORES
--------------------------------------------------------------------------
local function aoNascer(jogador, personagem)
	local sessao = sessoes[jogador]
	if not sessao then
		return
	end
	local humanoid = personagem:WaitForChild("Humanoid", 10)
	local raiz = personagem:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not raiz or not humanoid:IsA("Humanoid") then
		return
	end
	aplicarMovimento(jogador)

	if sessao.base then
		-- Deixa o dono atravessar a barreira da própria base
		local grupo = sessao.base.grupoDono
		for _, parte in personagem:GetDescendants() do
			if parte:IsA("BasePart") then
				parte.CollisionGroup = grupo
			end
		end
		personagem.DescendantAdded:Connect(function(parte)
			if parte:IsA("BasePart") then
				parte.CollisionGroup = grupo
			end
		end)
	end

	personagem.ChildAdded:Connect(function(objeto)
		conectarLuva(jogador, objeto)
	end)
	personagem.ChildRemoved:Connect(function(objeto)
		if objeto:IsA("Tool") and objeto.Name == NOME_LUVA then
			tirarLuvaVisual(personagem)
		end
	end)
	for _, objeto in personagem:GetChildren() do
		conectarLuva(jogador, objeto)
	end

	if sessao.base then
		task.wait(0.2)
		if personagem.Parent then
			personagem:PivotTo(sessao.base.spawn)
		end
	end
end

local function criarLeaderstats(jogador)
	local pasta = Instance.new("Folder")
	pasta.Name = "leaderstats"
	local dinheiro = Instance.new("IntValue")
	dinheiro.Name = "Dinheiro"
	dinheiro.Parent = pasta
	local roubos = Instance.new("IntValue")
	roubos.Name = "Roubos"
	roubos.Parent = pasta
	local renascimentos = Instance.new("IntValue")
	renascimentos.Name = "Renasc."
	renascimentos.Parent = pasta
	pasta.Parent = jogador
	return dinheiro, roubos, renascimentos
end

local function aoEntrar(jogador)
	local statDinheiro, statRoubos, statRenascimentos = criarLeaderstats(jogador)
	local dados, carregou = Dados.carregar(jogador.UserId)
	if not jogador.Parent then
		return
	end
	if dados.ultimoLogin == 0 and dados.dinheiro == 0 then
		dados.dinheiro = Config.dinheiroInicial(0)
	end
	-- Heróis da versão antiga viram os novos
	for _, salvo in dados.herois do
		salvo.id = Config.IdsAntigos[salvo.id] or salvo.id
	end
	local descobertos = {}
	for id in dados.descobertos do
		descobertos[Config.IdsAntigos[id] or id] = true
	end
	dados.descobertos = descobertos
	dados.luvas.Basica = true
	if not Config.LuvaPorId[dados.luvaEquipada] or not dados.luvas[dados.luvaEquipada] then
		dados.luvaEquipada = "Basica"
	end

	local sessao = {
		dados = dados,
		podeSalvar = carregou,
		statDinheiro = statDinheiro,
		statRoubos = statRoubos,
		statRenascimentos = statRenascimentos,
		ultimaAcao = 0,
		ultimoSoco = 0,
		passeDobro = false,
		base = nil,
	}
	sessoes[jogador] = sessao

	if Config.Robux.PasseDinheiroDobrado ~= 0 then
		local ok, tem = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(jogador.UserId, Config.Robux.PasseDinheiroDobrado)
		end)
		sessao.passeDobro = ok and tem == true
	end

	for _, base in bases do
		if not base.dono then
			base.dono = jogador
			sessao.base = base
			break
		end
	end

	local offline = nil
	if sessao.base then
		local base = sessao.base
		atualizarSlots(base)
		local liberados = pedestaisJogador(jogador)
		for _, salvo in dados.herois do
			local def = Config.HeroiPorId[salvo.id]
			local slot = base.slots[salvo.slot]
			if def and slot and salvo.slot <= liberados and not slot.heroi then
				colocarNaBase(novoHeroi(def, salvo.mut or "Normal"), base, slot, false)
			end
		end

		-- Renda enquanto o jogador estava fora
		if dados.ultimoLogin > 0 then
			local segundos = math.clamp(os.time() - dados.ultimoLogin, 0, G.HorasOfflineMaximo * 3600)
			if segundos >= 60 then
				local mult = multiplicadorJogador(jogador) * G.PorcentagemOffline
				local total = 0
				for _, slot in base.slots do
					local h = slot.heroi
					if h and h.estado == "base" then
						local valor = rendaHeroi(h) * mult * segundos
						slot.acumulado += valor
						total += valor
						atualizarPad(slot)
					end
				end
				if total >= 1 then
					offline = { total, segundos }
				end
			end
		end
	end
	dados.ultimoLogin = os.time()
	atualizarAtributos(jogador)

	jogador.CharacterAdded:Connect(function(personagem)
		aoNascer(jogador, personagem)
	end)
	if jogador.Character then
		task.spawn(aoNascer, jogador, jogador.Character)
	end

	-- Avisos depois que a interface do jogador carregar
	task.delay(4, function()
		if not jogador.Parent then
			return
		end
		if not sessao.base then
			notificar(jogador, "😢 Servidor cheio: todas as bases estão ocupadas.", "erro")
		end
		if not carregou then
			local motivo = Dados.desativado and "publique o jogo e ative o acesso às APIs" or "erro ao carregar seus dados"
			notificar(jogador, "⚠️ Seu progresso NÃO será salvo (" .. motivo .. ")", "aviso")
		end
		if offline then
			efeito(jogador, "offline", offline[1], offline[2])
		end
	end)
end

local function aoSair(jogador)
	local h = carregando[jogador]
	if h then
		devolver(h, nil)
	end
	local sessao = sessoes[jogador]
	if not sessao then
		return
	end
	local base = sessao.base
	if base then
		-- Coleta automaticamente o que ficou nos pedestais
		for _, slot in base.slots do
			if slot.acumulado >= 1 then
				ganhar(jogador, math.floor(slot.acumulado))
			end
		end
	end
	local dadosFinais = sessao.podeSalvar and montarSave(jogador) or nil
	if base then
		limparHeroisDaBase(base)
		base.dono = nil
		base.trancadaAte = 0
		base.recargaAte = 0
		atualizarBarreira(base)
		atualizarSlots(base)
	end
	sessoes[jogador] = nil
	if dadosFinais then
		Dados.salvar(jogador.UserId, dadosFinais)
		Dados.atualizarRanking(jogador.UserId, {
			Dinheiro = dadosFinais.totalGanho,
			Roubos = dadosFinais.roubos,
			Renascimentos = dadosFinais.renascimentos,
		})
	end
end

--------------------------------------------------------------------------
-- COMANDOS DE TESTE (no chat: !dinheiro 1000000 | !evento | !heroi HeroiSupremo Cosmico | !roleta)
--------------------------------------------------------------------------
local function processarComando(jogador, mensagem)
	if not G.ComandosDeTeste or not (RunService:IsStudio() or jogador.UserId == game.CreatorId) then
		return
	end
	local partes = string.split(mensagem, " ")
	local comando = string.lower(partes[1] or "")
	if comando == "!dinheiro" then
		local valor = tonumber(partes[2]) or 1000000
		ganhar(jogador, valor)
		notificar(jogador, "💰 +" .. formatar(valor), "sucesso")
	elseif comando == "!evento" then
		local evento = Config.EventoPorId[partes[2] or ""] or Config.Eventos[math.random(#Config.Eventos)]
		iniciarEvento(evento)
	elseif comando == "!roleta" then
		local sessao = sessoes[jogador]
		if sessao then
			sessao.dados.ultimaRoleta = 0
			atualizarAtributos(jogador)
			notificar(jogador, "🎡 Roleta liberada!", "sucesso")
		end
	elseif comando == "!heroi" then
		local def = Config.HeroiPorId[partes[2] or ""]
		if not def then
			notificar(jogador, "Use: !heroi IdDoHeroi [Mutacao]  (ex: !heroi AranhaEscarlate Ouro)", "aviso")
			return
		end
		local mutacao = Config.MutacaoPorId[partes[3] or ""] and partes[3] or "Normal"
		colocarNaPassarela(novoHeroi(def, mutacao))
		notificar(jogador, "🌀 " .. def.nome .. " saiu do portal!", "sucesso")
	end
end

Players.PlayerAdded:Connect(function(jogador)
	jogador.Chatted:Connect(function(mensagem)
		processarComando(jogador, mensagem)
	end)
	aoEntrar(jogador)
end)
for _, jogador in Players:GetPlayers() do
	jogador.Chatted:Connect(function(mensagem)
		processarComando(jogador, mensagem)
	end)
	task.spawn(aoEntrar, jogador)
end
Players.PlayerRemoving:Connect(aoSair)

game:BindToClose(function()
	if Dados.desativado then
		return
	end
	local pendentes = 0
	for jogador, sessao in sessoes do
		if sessao.podeSalvar then
			pendentes += 1
			task.spawn(function()
				salvarJogador(jogador)
				pendentes -= 1
			end)
		end
	end
	local inicio = os.clock()
	while pendentes > 0 and os.clock() - inicio < 25 do
		task.wait(0.5)
	end
end)

--------------------------------------------------------------------------
-- ROBUX
--------------------------------------------------------------------------
if Config.Robux.PasseDinheiroDobrado ~= 0 then
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(jogador, passeId, comprou)
		local sessao = sessoes[jogador]
		if comprou and passeId == Config.Robux.PasseDinheiroDobrado and sessao then
			sessao.passeDobro = true
			atualizarAtributos(jogador)
			notificar(jogador, "💎 Dinheiro em Dobro ativado! Obrigado!", "especial")
		end
	end)
end

local temProdutos = false
for _, produto in Config.Robux.Produtos do
	if produto.id ~= 0 then
		temProdutos = true
	end
end
if temProdutos then
	MarketplaceService.ProcessReceipt = function(recibo)
		local jogador = Players:GetPlayerByUserId(recibo.PlayerId)
		local sessao = jogador and sessoes[jogador]
		if not sessao then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		for _, produto in Config.Robux.Produtos do
			if produto.id ~= 0 and produto.id == recibo.ProductId then
				local valor = Config.valorProduto(produto, sessao.dados.renascimentos)
				ganhar(jogador, valor)
				notificar(jogador, produto.icone .. " " .. produto.nome .. ": +" .. formatar(valor) .. "!", "especial")
				task.spawn(salvarJogador, jogador)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

--------------------------------------------------------------------------
-- LIGAR BOTÕES DAS BASES
--------------------------------------------------------------------------
for _, base in bases do
	base.dono = nil
	base.trancadaAte = 0
	base.recargaAte = 0

	base.botao.Touched:Connect(function(parteTocada)
		local jogador = Players:GetPlayerFromCharacter(parteTocada.Parent)
		if jogador and jogador == base.dono then
			trancarBase(base, jogador)
		end
	end)

	for _, slot in base.slots do
		slot.pad.Touched:Connect(function(parteTocada)
			local dono = base.dono
			if not dono or slot.acumulado < 1 then
				return
			end
			if Players:GetPlayerFromCharacter(parteTocada.Parent) ~= dono then
				return
			end
			local valor = math.floor(slot.acumulado)
			slot.acumulado -= valor
			ganhar(dono, valor)
			atualizarPad(slot)
			efeito(dono, "coleta", valor, slot.pad.Position)
		end)
	end
	-- Elevador: subir e descer entre os andares
	for _, elevador in base.elevadores do
		local function botaoElevador(nome, texto, tecla, destino)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = nome
			prompt.ActionText = texto
			prompt.ObjectText = "Elevador"
			prompt.KeyboardKeyCode = tecla
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Parent = elevador.plataforma
			prompt.Triggered:Connect(function(jogador)
				local personagem = jogador.Character
				if personagem then
					personagem:PivotTo(base.elevadores[destino].saida)
				end
			end)
		end
		if elevador.andar < #base.elevadores then
			botaoElevador("Subir", "⬆ Subir para o " .. (elevador.andar + 1) .. "º", Enum.KeyCode.E, elevador.andar + 1)
		end
		if elevador.andar > 1 then
			botaoElevador("Descer", "⬇ Descer para o " .. (elevador.andar - 1) .. "º", Enum.KeyCode.R, elevador.andar - 1)
		end
	end
	atualizarSlots(base)
	atualizarBarreira(base)
end

--------------------------------------------------------------------------
-- TENDA DA LOJA
--------------------------------------------------------------------------
do
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AbrirLoja"
	prompt.ActionText = "Abrir loja"
	prompt.ObjectText = "Loja dos Heróis"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = mapa.loja.balcao
	prompt.Triggered:Connect(function(jogador)
		AbrirLoja:FireClient(jogador)
	end)
end

--------------------------------------------------------------------------
-- ROLETA DA SORTE (a cada 12 horas)
--------------------------------------------------------------------------
local roletaGirando = false
local anguloRoleta = 0

local function sortearPremio()
	local total = 0
	for _, premio in Config.Roleta.Premios do
		total += premio.peso
	end
	local sorteio = math.random() * total
	for _, premio in Config.Roleta.Premios do
		sorteio -= premio.peso
		if sorteio <= 0 then
			return premio
		end
	end
	return Config.Roleta.Premios[1]
end

local function darPremio(jogador, premio)
	local sessao = sessoes[jogador]
	if not sessao then
		return ""
	end
	local d = sessao.dados
	if premio.tipo == "dinheiro" then
		local renda = jogador:GetAttribute("RendaPorSegundo") or 0
		local valor = math.max(premio.minimo * (1 + d.renascimentos), renda * 60 * premio.minutos)
		ganhar(jogador, valor)
		return premio.icone .. " " .. premio.nome .. ": +" .. formatar(valor) .. "!"
	elseif premio.tipo == "boostRenda" then
		sessao.boostRendaAte = math.max(os.time(), sessao.boostRendaAte or 0) + premio.minutos * 60
		atualizarAtributos(jogador)
		return "⚡ Sua renda está em DOBRO por " .. premio.minutos .. " minutos!"
	elseif premio.tipo == "boostVelocidade" then
		sessao.boostVelocidadeAte = math.max(os.time(), sessao.boostVelocidadeAte or 0) + premio.minutos * 60
		aplicarMovimento(jogador)
		atualizarAtributos(jogador)
		task.delay(premio.minutos * 60 + 1, function()
			if jogador.Parent then
				aplicarMovimento(jogador)
			end
		end)
		return "🌀 Super velocidade por " .. premio.minutos .. " minutos!"
	elseif premio.tipo == "heroi" then
		local opcoes = {}
		for _, def in Config.Herois do
			if def.raridade == premio.raridade then
				table.insert(opcoes, def)
			end
		end
		local def = opcoes[math.random(#opcoes)]
		local slot = sessao.base and slotLivre(sessao.base, pedestaisJogador(jogador))
		if slot then
			colocarNaBase(novoHeroi(def, "Normal"), sessao.base, slot, false)
			descobrir(jogador, def)
			return "🦸 Você ganhou " .. def.nome .. "! Ele já está na sua base."
		end
		ganhar(jogador, def.preco)
		return "🦸 Sua base estava cheia: você ganhou " .. formatar(def.preco) .. " no lugar de " .. def.nome .. "!"
	elseif premio.tipo == "girarDeNovo" then
		d.ultimaRoleta = 0
		atualizarAtributos(jogador)
		return "🔁 Você pode girar a roleta de novo agora!"
	end
	return ""
end

local function girarRoleta(jogador)
	local sessao = sessoes[jogador]
	if not sessao then
		return
	end
	local d = sessao.dados
	local agora = os.time()
	local proxima = d.ultimaRoleta + Config.Roleta.IntervaloHoras * 3600
	if agora < proxima then
		notificar(jogador, "🎡 A roleta libera de novo em " .. Config.formatarTempo(proxima - agora), "aviso")
		return
	end
	if roletaGirando then
		notificar(jogador, "🎡 A roleta está girando, espere um pouquinho!", "aviso")
		return
	end
	roletaGirando = true
	d.ultimaRoleta = agora
	atualizarAtributos(jogador)

	local premio = sortearPremio()
	local volta = math.pi * 2
	local alvo = (premio.indice - 1) * (volta / #Config.Roleta.Premios)
	local final = anguloRoleta - (anguloRoleta % volta) + 5 * volta + alvo
	local duracao = Config.Roleta.DuracaoGiro
	RoletaGiro:FireAllClients(mapa.roleta.cf0, anguloRoleta, final, duracao)
	notificar(jogador, "🎡 Girando a roleta...", "info")

	task.delay(duracao, function()
		anguloRoleta = final
		mapa.roleta.eixo.CFrame = mapa.roleta.cf0 * CFrame.Angles(0, 0, final % volta)
		roletaGirando = false
		if not jogador.Parent then
			return
		end
		local mensagem = darPremio(jogador, premio)
		efeito(jogador, "premio", premio.icone, mensagem)
		if (premio.tipo == "heroi" and premio.raridade == "Lendario") or premio.id == "MoedasG" then
			anunciar("🎡 " .. jogador.DisplayName .. " ganhou " .. premio.nome .. " na Roleta da Sorte!", premio.cor)
		end
	end)
end

do
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GirarRoleta"
	prompt.ActionText = "Girar a roleta"
	prompt.ObjectText = "Roleta da Sorte"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = mapa.roleta.botao
	prompt.Triggered:Connect(girarRoleta)
end

--------------------------------------------------------------------------
-- RANKING
--------------------------------------------------------------------------
local nomesCache = {}
local function nomeDoUsuario(userId)
	if nomesCache[userId] then
		return nomesCache[userId]
	end
	local jogador = Players:GetPlayerByUserId(userId)
	local nome
	if jogador then
		nome = jogador.DisplayName
	else
		local ok, resultado = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		nome = ok and resultado or ("Jogador " .. userId)
	end
	nomesCache[userId] = nome
	return nome
end

local function valorRanking(categoria, d)
	if categoria == "Dinheiro" then
		return d.totalGanho
	elseif categoria == "Roubos" then
		return d.roubos
	end
	return d.renascimentos
end

local function atualizarRanking()
	for jogador, sessao in sessoes do
		if sessao.podeSalvar then
			Dados.atualizarRanking(jogador.UserId, {
				Dinheiro = sessao.dados.totalGanho,
				Roubos = sessao.dados.roubos,
				Renascimentos = sessao.dados.renascimentos,
			})
		end
	end

	local algumGlobal = false
	for _, categoria in Mapa.CATEGORIAS_RANKING do
		local lista = Dados.obterTop(categoria.id, 10)
		local resultado = {}
		if lista then
			algumGlobal = true
			for i, item in lista do
				resultado[i] = { nome = nomeDoUsuario(item.userId), valor = item.valor }
			end
		else
			-- Sem DataStore (Studio): mostra o ranking do servidor
			for jogador, sessao in sessoes do
				table.insert(resultado, { nome = jogador.DisplayName, valor = valorRanking(categoria.id, sessao.dados) })
			end
			table.sort(resultado, function(a, b)
				return a.valor > b.valor
			end)
		end
		rankingGlobal[categoria.id] = resultado

		local quadro = mapa.quadros[categoria.id]
		for i, linha in quadro.linhas do
			local item = resultado[i]
			linha.nome.Text = item and item.nome or "—"
			if item then
				linha.valor.Text = categoria.id == "Dinheiro" and formatar(item.valor) or Config.formatarNumero(item.valor)
			else
				linha.valor.Text = ""
			end
		end
		quadro.rodape.Text = lista and ("🌎 Ranking global • atualiza a cada " .. math.floor(G.IntervaloRanking / 60) .. " min")
			or "Ranking do servidor (o global aparece quando o jogo for publicado)"
	end
	rankingGlobal.disponivel = algumGlobal
end

--------------------------------------------------------------------------
-- LOOPS DO JOGO
--------------------------------------------------------------------------

-- Todo frame: move os heróis da passarela e confere os roubos
RunService.Heartbeat:Connect(function(dt)
	for _, h in herois do
		if h.estado == "andando" then
			h.distancia += G.VelocidadePassarela * dt
			if h.distancia >= mapa.comprimento then
				removerHeroi(h)
			else
				local pulo = math.abs(math.sin(h.distancia * 0.9)) * 0.5
				local posicao = mapa.inicio + Vector3.new(h.distancia, h.altura + pulo, 0)
				h.raiz.CFrame = CFrame.lookAt(posicao, posicao + Vector3.xAxis)
			end
		elseif h.estado == "carregado" then
			verificarCarregado(h)
		end
	end
end)

-- Todo segundo: renda, placas, botões de tranca
task.spawn(function()
	while true do
		task.wait(1)
		local agora = os.clock()
		local multRenda = multEvento("multRenda")
		for _, base in bases do
			local dono = base.dono
			local sessao = dono and sessoes[dono]
			if sessao then
				local mult = multiplicadorJogador(dono) * multRenda
				local coletorAutomatico = (sessao.dados.niveis.Coletor or 0) > 0
				local rendaTotal = 0
				local direto = 0
				for _, slot in base.slots do
					local h = slot.heroi
					if h and h.estado == "base" and h.base == base and h.slot == slot then
						local renda = rendaHeroi(h) * mult
						rendaTotal += renda
						slot.acumulado += renda
					end
					if coletorAutomatico and slot.acumulado > 0 then
						direto += slot.acumulado
						slot.acumulado = 0
					end
					atualizarPad(slot)
				end
				if direto > 0 then
					ganhar(dono, direto)
				end
				dono:SetAttribute("RendaPorSegundo", rendaTotal)
				dono:SetAttribute("Multiplicador", multiplicadorJogador(dono))
				base.textoPlaca.Text = "BASE DE " .. string.upper(dono.DisplayName)
				base.textoRenda.Text = "+" .. formatar(rendaTotal) .. "/s"
			else
				base.textoPlaca.Text = "BASE LIVRE"
				base.textoRenda.Text = ""
			end

			atualizarBarreira(base)
			if agora < base.trancadaAte then
				base.textoBotao.Text = "🔒 TRANCADA " .. math.ceil(base.trancadaAte - agora) .. "s"
				base.textoBotao.TextColor3 = Color3.fromRGB(255, 80, 80)
			elseif agora < base.recargaAte then
				base.textoBotao.Text = "⏳ RECARGA " .. math.ceil(base.recargaAte - agora) .. "s"
				base.textoBotao.TextColor3 = Color3.fromRGB(255, 210, 60)
			else
				base.textoBotao.Text = "🔒 TRANCAR BASE"
				base.textoBotao.TextColor3 = Color3.fromRGB(110, 255, 130)
			end
		end
	end
end)

-- Heróis saindo do portal
task.spawn(function()
	while true do
		local h = novoHeroi(sortearHeroi(), sortearMutacao())
		colocarNaPassarela(h)
		if h.raridade.ordem >= ORDEM_ANUNCIO_SPAWN or h.mutacao.multiplicador >= 5 then
			anunciar("🌀 Um herói " .. string.upper(h.raridade.nome) .. " saiu do portal: " .. nomeCompleto(h) .. "!", h.raridade.cor)
		end
		task.wait(G.IntervaloSpawn / multEvento("multSpawn"))
	end
end)

-- Eventos automáticos
task.spawn(function()
	while true do
		task.wait(G.IntervaloEventoMinutos * 60)
		if not eventoAtual then
			iniciarEvento(Config.Eventos[math.random(#Config.Eventos)])
		end
	end
end)

-- Ciclo de dia e noite (a noite passa mais rápido)
if G.CicloDiaNoite then
	task.spawn(function()
		local passo = 24 / (G.DuracaoDiaMinutos * 60) * 0.5
		while true do
			task.wait(0.5)
			local hora = Lighting.ClockTime
			local noite = hora >= 19 or hora < 5.5
			Lighting.ClockTime = (hora + passo * (noite and 2 or 1)) % 24
		end
	end)
end

-- Coroa para o jogador mais rico do servidor
task.spawn(function()
	while true do
		task.wait(3)
		local maisRico, maior = nil, -1
		for jogador, sessao in sessoes do
			if sessao.dados.dinheiro > maior then
				maior = sessao.dados.dinheiro
				maisRico = jogador
			end
		end
		local variosJogadores = #Players:GetPlayers() > 1
		for jogador in sessoes do
			local cabeca = jogador.Character and jogador.Character:FindFirstChild("Head")
			if cabeca then
				local coroa = cabeca:FindFirstChild("CoroaRei")
				if jogador == maisRico and variosJogadores then
					if not coroa then
						local gui = Instance.new("BillboardGui")
						gui.Name = "CoroaRei"
						gui.Size = UDim2.fromOffset(60, 60)
						gui.StudsOffset = Vector3.new(0, 2.8, 0)
						gui.MaxDistance = 120
						local rotulo = Instance.new("TextLabel")
						rotulo.BackgroundTransparency = 1
						rotulo.Size = UDim2.fromScale(1, 1)
						rotulo.Text = "👑"
						rotulo.TextScaled = true
						rotulo.Parent = gui
						gui.Parent = cabeca
					end
				elseif coroa then
					coroa:Destroy()
				end
			end
		end
	end
end)

-- Salvamento automático
task.spawn(function()
	while true do
		task.wait(G.IntervaloAutoSave)
		for jogador in sessoes do
			task.spawn(salvarJogador, jogador)
		end
	end
end)

-- Ranking (global com DataStore, ou do servidor no Studio)
task.spawn(function()
	task.wait(5)
	while true do
		atualizarRanking()
		task.wait(Dados.desativado and 10 or G.IntervaloRanking)
	end
end)

print("[Roube um Herói] Servidor pronto! Salvamento: " .. (Dados.desativado and ("DESATIVADO - " .. Dados.motivo) or "ativo"))
