--[[
	ROUBE UM HERÓI - Salvamento de dados (DataStore) e ranking global

	Onde colocar: ServerScriptService -> ModuleScript (nome: Dados)

	IMPORTANTE: para salvar no Studio, publique o jogo e ative
	Configurações do jogo > Segurança > "Permitir acesso do Studio aos serviços de API".
	Sem isso o jogo funciona normalmente, só não salva o progresso.
]]

local DataStoreService = game:GetService("DataStoreService")

local Dados = {}
Dados.desativado = false
Dados.motivo = ""

local loja = nil
local ordenados = {}

local CATEGORIAS = { "Dinheiro", "Roubos", "Renascimentos" }

function Dados.padrao()
	return {
		versao = 1,
		dinheiro = 0,
		totalGanho = 0,
		renascimentos = 0,
		roubos = 0,
		niveis = { Velocidade = 0, Pedestais = 0, Tranca = 0, Coletor = 0 },
		herois = {}, -- { {slot = 1, id = "FormigaAtomica", mut = "Normal"}, ... }
		descobertos = {}, -- [id] = true
		luvas = { Basica = true }, -- [id] = true
		luvaEquipada = "Basica",
		ultimaRoleta = 0,
		ultimaDiaria = 0,
		sequenciaDiaria = 0,
		ultimoLogin = 0,
		tutorial = false,
		config = { musica = true, sons = true },
	}
end

local function copiar(valor)
	if type(valor) ~= "table" then
		return valor
	end
	local copia = {}
	for chave, item in valor do
		copia[chave] = copiar(item)
	end
	return copia
end

-- Completa campos que não existiam em saves antigos
local function reconciliar(dados, padrao)
	for chave, valor in padrao do
		if dados[chave] == nil then
			dados[chave] = copiar(valor)
		elseif type(valor) == "table" and type(dados[chave]) == "table" and next(valor) ~= nil and #valor == 0 then
			reconciliar(dados[chave], valor)
		end
	end
end

local function erroSemAcesso(mensagem)
	mensagem = tostring(mensagem)
	return mensagem:find("403") ~= nil
		or mensagem:find("StudioAccessToApisNotAllowed") ~= nil
		or mensagem:find("publish") ~= nil
		or mensagem:find("API Services") ~= nil
end

local function desativar(motivo)
	if not Dados.desativado then
		warn("[Dados] Salvamento desativado: " .. tostring(motivo))
	end
	Dados.desativado = true
	Dados.motivo = tostring(motivo)
end

function Dados.iniciar(Config)
	if not Config.Geral.SalvarDados then
		desativar("SalvarDados = false no ConfigHerois")
		return
	end
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore(Config.Geral.NomeDataStore)
	end)
	if not ok then
		desativar(resultado)
		return
	end
	loja = resultado
	for _, categoria in CATEGORIAS do
		local ok2, ordenado = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.Geral.NomeDataStore .. "_Rank_" .. categoria)
		end)
		if ok2 then
			ordenados[categoria] = ordenado
		end
	end
end

local function chave(userId)
	return "Jogador_" .. tostring(userId)
end

-- Retorna (dados, conseguiuCarregar). Se não conseguir, o jogo não salva por cima.
function Dados.carregar(userId)
	local padrao = Dados.padrao()
	if Dados.desativado or not loja then
		return padrao, false
	end
	for tentativa = 1, 3 do
		local ok, resultado = pcall(function()
			return loja:GetAsync(chave(userId))
		end)
		if ok then
			if type(resultado) == "table" then
				reconciliar(resultado, padrao)
				return resultado, true
			end
			return padrao, true -- jogador novo
		end
		warn(string.format("[Dados] Erro ao carregar %s (tentativa %d): %s", tostring(userId), tentativa, tostring(resultado)))
		if erroSemAcesso(resultado) then
			desativar(resultado)
			break
		end
		task.wait(1.5)
	end
	return padrao, false
end

function Dados.salvar(userId, dados)
	if Dados.desativado or not loja then
		return false
	end
	for tentativa = 1, 3 do
		local ok, erro = pcall(function()
			loja:UpdateAsync(chave(userId), function()
				return dados
			end)
		end)
		if ok then
			return true
		end
		warn(string.format("[Dados] Erro ao salvar %s (tentativa %d): %s", tostring(userId), tentativa, tostring(erro)))
		if erroSemAcesso(erro) then
			desativar(erro)
			return false
		end
		task.wait(1.5)
	end
	return false
end

-- valores = { Dinheiro = n, Roubos = n, Renascimentos = n }
function Dados.atualizarRanking(userId, valores)
	if Dados.desativado or userId <= 0 then
		return
	end
	for categoria, valor in valores do
		local ordenado = ordenados[categoria]
		if ordenado and valor > 0 then
			local inteiro = math.floor(math.min(valor, 9e15))
			pcall(function()
				ordenado:SetAsync(tostring(userId), inteiro)
			end)
		end
	end
end

-- Retorna lista { {userId = n, valor = n}, ... } ou nil se indisponível
function Dados.obterTop(categoria, quantidade)
	if Dados.desativado then
		return nil
	end
	local ordenado = ordenados[categoria]
	if not ordenado then
		return nil
	end
	local ok, pagina = pcall(function()
		return ordenado:GetSortedAsync(false, quantidade):GetCurrentPage()
	end)
	if not ok then
		warn("[Dados] Erro no ranking " .. categoria .. ": " .. tostring(pagina))
		return nil
	end
	local lista = {}
	for _, item in pagina do
		table.insert(lista, { userId = tonumber(item.key) or 0, valor = item.value })
	end
	return lista
end

return Dados
