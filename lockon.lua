--[[
    LOCK-ON SIMPLES (100% FUNCIONAL)
    By: Pcnlsd
]]

-- Configurações
local FOV = 50  -- Distância máxima
local Tecla = "E"  -- Vamos começar com E que é mais fácil

-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Variáveis
local player = Players.LocalPlayer
local alvo = nil
local ativado = false

-- Função para achar o inimigo mais próximo
local function acharInimigoProximo()
    local char = player.Character
    if not char then return nil end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return nil end
    
    local posJogador = root.Position
    local inimigoProximo = nil
    local distanciaMenor = FOV + 1
    
    for _, outroJogador in ipairs(Players:GetPlayers()) do
        if outroJogador ~= player then
            local outroChar = outroJogador.Character
            if outroChar and outroChar:FindFirstChild("Humanoid") and outroChar.Humanoid.Health > 0 then
                local outroRoot = outroChar:FindFirstChild("HumanoidRootPart") or outroChar:FindFirstChild("Torso")
                if outroRoot then
                    local distancia = (outroRoot.Position - posJogador).Magnitude
                    if distancia <= FOV and distancia < distanciaMenor then
                        distanciaMenor = distancia
                        inimigoProximo = outroChar
                    end
                end
            end
        end
    end
    
    return inimigoProximo
end

-- Função para criar outline vermelho
local function criarOutline(personagem)
    if not personagem then return end
    
    -- Remove outline antigo se existir
    local antigo = personagem:FindFirstChild("OutlineLock")
    if antigo then antigo:Destroy() end
    
    local outline = Instance.new("Highlight")
    outline.Name = "OutlineLock"
    outline.FillColor = Color3.fromRGB(255, 0, 0)
    outline.FillTransparency = 0.8
    outline.OutlineColor = Color3.fromRGB(255, 0, 0)
    outline.OutlineTransparency = 0
    outline.OutlineThickness = 0.1
    outline.Parent = personagem
end

-- Função para remover outline
local function removerOutline()
    if alvo and alvo:FindFirstChild("OutlineLock") then
        alvo.OutlineLock:Destroy()
    end
end

-- Atalho de teclado
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then  -- TECLA E
        ativado = not ativado
        
        if ativado then
            -- Ativou: procura alvo
            local novoAlvo = acharInimigoProximo()
            if novoAlvo then
                -- Remove outline do alvo anterior
                removerOutline()
                -- Seta novo alvo
                alvo = novoAlvo
                criarOutline(alvo)
                print("✅ Alvo travado: " .. tostring(alvo.Parent.Name))
            else
                print("❌ Nenhum inimigo por perto")
                ativado = false
            end
        else
            -- Desativou: remove outline
            removerOutline()
            alvo = nil
            print("🔓 Lock-on desativado")
        end
    end
end)

-- Câmera segue o alvo
RunService.RenderStepped:Connect(function()
    if ativado and alvo and player.Character then
        local rootAlvo = alvo:FindFirstChild("HumanoidRootPart") or alvo:FindFirstChild("Torso")
        if rootAlvo then
            local posAlvo = rootAlvo.Position
            local novaCamera = CFrame.lookAt(Camera.CFrame.Position, posAlvo)
            Camera.CFrame = Camera.CFrame:Lerp(novaCamera, 0.1)
        else
            -- Se perdeu o alvo (morreu, etc)
            removerOutline()
            alvo = nil
            ativado = false
        end
    end
end)

-- Limpeza quando morre
if player.Character then
    player.Character.Humanoid.Died:Connect(function()
        removerOutline()
        alvo = nil
        ativado = false
    end)
end

print("=== LOCK-ON CARREGADO ===")
print("✅ Pressione E para ativar")
print("📏 Distância: " .. FOV .. " studs")
