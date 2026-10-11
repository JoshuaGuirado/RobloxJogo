--[[
	ROUBE UM PERSONAGEM - script do jogador (cliente)

	Onde colocar: StarterPlayer -> StarterPlayerScripts -> LocalScript (nome: RouboCliente)

	Os personagens da base tem dois botoes: "Roubar" (E) e "Vender" (F).
	Este script esconde o botao errado:
	  - na SUA base voce so ve "Vender"
	  - na base dos OUTROS voce so ve "Roubar"
]]

local Players = game:GetService("Players")

local jogador = Players.LocalPlayer

local function atualizar(prompt)
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

local function observar(objeto)
	if not objeto:IsA("ProximityPrompt") then
		return
	end
	if objeto.Name ~= "PromptRoubar" and objeto.Name ~= "PromptVender" then
		return
	end
	atualizar(objeto)
	local modelo = objeto:FindFirstAncestorOfClass("Model")
	if modelo then
		modelo:GetAttributeChangedSignal("DonoId"):Connect(function()
			if objeto.Parent then
				atualizar(objeto)
			end
		end)
	end
end

workspace.DescendantAdded:Connect(observar)
for _, objeto in workspace:GetDescendants() do
	observar(objeto)
end
