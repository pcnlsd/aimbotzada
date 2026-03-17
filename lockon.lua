--[[
    Lock-On Simples
    By: Pcnlsd
    Versão: 3.0 - Só outline, sem firulas
]]

-- Configurações
local Settings = {
    FOVRadius = 50,              -- Distância pra pegar alvo
    LockSmoothness = 0.1,         -- Suavidade da câmera
    Keybind = "LeftAlt",          -- AGORA É ALT (LeftAlt = ALT esquerdo)
    ShowUI = true,                
    OutlineColor = Color3.fromRGB(255, 0, 0)  -- Vermelho puro
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- Variáveis
local player = Players.LocalPlayer
local isLockedOn = false
local currentTarget = nil
local connections = {}
local uiElements = {}

-- UI simples
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LockOnSystem"
    screenGui.Parent = CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 150, 0, 60)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -30)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🎯 LOCK-ON"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = mainFrame
    
    local lockButton = Instance.new("TextButton")
    lockButton.Size = UDim2.new(0.8, 0, 0, 25)
    lockButton.Position = UDim2.new(0.1, 0, 0, 27)
    lockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    lockButton.Text = "🔒 LOCK"
    lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockButton.Font = Enum.Font.GothamBold
    lockButton.TextScaled = true
    lockButton.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = lockButton
    
    -- Instrução do ALT
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 15)
    info.Position = UDim2.new(0, 0, 1, 0)
    info.BackgroundTransparency = 1
    info.Text = "ALT: Ativar"
    info.TextColor3 = Color3.fromRGB(150, 150, 150)
    info.TextScaled = true
    info.Font = Enum.Font.Gotham
    info.Parent = mainFrame
    
    return {
        screenGui = screenGui,
        lockButton = lockButton
    }
end

-- SÓ OUTLINE (SEM BOLA)
local function addOutline(target)
    if not target then return end
    
    -- Remove outline antigo se existir
    if target:FindFirstChild("LockOnHighlight") then
        target.LockOnHighlight:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "LockOnHighlight"
    highlight.FillColor = Settings.OutlineColor
    highlight.FillTransparency = 0.8  -- Quase transparente por dentro
    highlight.OutlineColor = Settings.OutlineColor
    highlight.OutlineTransparency = 0  -- Outline sólido
    highlight.OutlineThickness = 0.1   -- Grossura do outline
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    
    return highlight
end

-- Encontrar alvo mais próximo
local function findClosestTarget()
    local char = player.Character
    if not char then return nil end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not rootPart then return nil end
    
    local charPos = rootPart.Position
    local closestTarget = nil
    local closestDistance = Settings.FOVRadius + 1
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("Humanoid") and otherChar.Humanoid.Health > 0 then
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart") or otherChar:FindFirstChild("Torso")
                if otherRoot then
                    local distance = (otherRoot.Position - charPos).Magnitude
                    
                    if distance <= Settings.FOVRadius then
                        if distance < closestDistance then
                            closestDistance = distance
                            closestTarget = otherChar
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

-- Atualizar alvo
local function updateTarget(newTarget)
    -- Remove outline do alvo anterior
    if currentTarget and currentTarget:FindFirstChild("LockOnHighlight") then
        currentTarget.LockOnHighlight:Destroy()
    end
    
    currentTarget = newTarget
    
    if currentTarget then
        addOutline(currentTarget)
    end
end

-- Atualizar câmera
local function updateCamera()
    if not (currentTarget and isLockedOn) then return end
    if not player.Character then return end
    
    local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChild("Torso")
    if targetRoot then
        local targetPos = targetRoot.Position
        local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.LockSmoothness)
    end
end

-- Limpar
local function cleanup()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    
    if currentTarget and currentTarget:FindFirstChild("LockOnHighlight") then
        currentTarget.LockOnHighlight:Destroy()
    end
    
    if uiElements.screenGui then
        pcall(function() uiElements.screenGui:Destroy() end)
    end
end

-- Iniciar
local function init()
    cleanup()
    
    if Settings.ShowUI then
        uiElements = createUI()
    end
    
    -- Botão LOCK
    if uiElements.lockButton then
        table.insert(connections, uiElements.lockButton.MouseButton1Click:Connect(function()
            isLockedOn = not isLockedOn
            
            -- Animação do botão
            TweenService:Create(uiElements.lockButton, TweenInfo.new(0.3), {
                BackgroundColor3 = isLockedOn and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(40, 40, 60),
                Text = isLockedOn and "🔓 UNLOCK" or "🔒 LOCK"
            }):Play()
            
            if not isLockedOn then
                -- Remove outline
                if currentTarget and currentTarget:FindFirstChild("LockOnHighlight") then
                    currentTarget.LockOnHighlight:Destroy()
                end
                currentTarget = nil
            else
                -- Pega o alvo mais próximo
                local target = findClosestTarget()
                if target then
                    updateTarget(target)
                else
                    -- Se não tem ninguém perto, desativa
                    isLockedOn = false
                    uiElements.lockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                    uiElements.lockButton.Text = "🔒 LOCK"
                end
            end
        end))
    end
    
    -- KEYBIND DO ALT (CORRIGIDO)
    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        -- Verifica se é o ALT esquerdo
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            if uiElements.lockButton then
                uiElements.lockButton.MouseButton1Click:Fire()
            end
        end
    end))
    
    -- Loop da câmera
    table.insert(connections, RunService.RenderStepped:Connect(updateCamera))
    
    -- Quando o personagem morrer
    if player.Character then
        player.Character.Humanoid.Died:Connect(function()
            isLockedOn = false
            if currentTarget and currentTarget:FindFirstChild("LockOnHighlight") then
                currentTarget.LockOnHighlight:Destroy()
            end
            currentTarget = nil
        end)
    end
    
    print("=== LOCK-ON CARREGADO ===")
    print("🎯 ALT para ativar/desativar")
    print("📏 Distância: " .. Settings.FOVRadius .. " studs")
end

-- Executar
local success, err = pcall(init)
if not success then
    warn("Erro: " .. tostring(err))
    cleanup()
end
