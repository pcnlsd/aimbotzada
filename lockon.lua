--[[
    Lock-On
    By: Pcnlsd
    Versão: 1.0
]]

-- Configurações que podem ser alteradas pelo usuário
local Settings = {
    FOVRadius = 300,                    -- Raio do FOV (100-500)
    LockSmoothness = 0.1,                 -- Suavidade da câmera (0-1)
    Keybind = "E",                       -- Tecla para ativar/desativar
    ShowUI = true,                       -- Mostrar interface gráfica
    OutlineColor = Color3.fromRGB(255, 50, 50),    -- Cor do outline
    TargetColor = Color3.fromRGB(255, 100, 100)    -- Cor do indicador
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- Variáveis principais
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local isLockedOn = false
local currentTarget = nil
local canSwitchTarget = true
local connections = {}
local uiElements = {}

-- Função para criar UI simplificada (mais compatível)
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LockOnSystem"
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 80)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -40)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Cantos arredondados
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Gradiente
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    })
    gradient.Rotation = 90
    gradient.Parent = mainFrame
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🎯 LOCK-ON SYSTEM"
    title.TextColor3 = Color3.fromRGB(200, 220, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Botão LOCK
    local lockButton = Instance.new("TextButton")
    lockButton.Name = "LockButton"
    lockButton.Size = UDim2.new(0.8, 0, 0, 35)
    lockButton.Position = UDim2.new(0.1, 0, 0, 35)
    lockButton.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    lockButton.Text = "🔒 LOCK"
    lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockButton.TextScaled = true
    lockButton.Font = Enum.Font.GothamBold
    lockButton.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = lockButton
    
    -- Instruções
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, 0, 0, 20)
    instructions.Position = UDim2.new(0, 0, 1, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Scroll: Trocar alvo | " .. Settings.Keybind .. ": Ativar"
    instructions.TextColor3 = Color3.fromRGB(150, 150, 180)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.Gotham
    instructions.Parent = mainFrame
    
    return {
        screenGui = screenGui,
        lockButton = lockButton
    }
end

-- Criar círculo FOV
local function createFOVCircle()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FOVCircle"
    billboard.Size = UDim2.new(0, 400, 0, 400)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = character:WaitForChild("Head")
    
    local circle = Instance.new("ImageLabel")
    circle.Size = UDim2.new(1, 0, 1, 0)
    circle.BackgroundTransparency = 1
    circle.Image = "rbxassetid://3570695787" -- Círculo
    circle.ImageColor3 = Color3.fromRGB(100, 200, 255)
    circle.ImageTransparency = 0.5
    circle.Parent = billboard
    
    return billboard
end

-- Criar indicador de alvo
local function createTargetIndicator()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TargetIndicator"
    billboard.Size = UDim2.new(0, 120, 0, 120)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard
    
    -- Círculo externo
    local outerCircle = Instance.new("ImageLabel")
    outerCircle.Name = "OuterCircle"
    outerCircle.Size = UDim2.new(1, 0, 1, 0)
    outerCircle.BackgroundTransparency = 1
    outerCircle.Image = "rbxassetid://3570695787"
    outerCircle.ImageColor3 = Settings.TargetColor
    outerCircle.ImageTransparency = 0.3
    outerCircle.Parent = container
    
    -- Círculo interno
    local innerCircle = Instance.new("ImageLabel")
    innerCircle.Name = "InnerCircle"
    innerCircle.Size = UDim2.new(0.6, 0, 0.6, 0)
    innerCircle.Position = UDim2.new(0.2, 0, 0.2, 0)
    innerCircle.BackgroundTransparency = 1
    innerCircle.Image = "rbxassetid://3570695787"
    innerCircle.ImageColor3 = Settings.TargetColor
    innerCircle.ImageTransparency = 0.5
    innerCircle.Parent = container
    
    return billboard
end

-- Adicionar outline
local function addOutline(target)
    if not target then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "LockOnHighlight"
    highlight.FillColor = Settings.OutlineColor
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Settings.OutlineColor
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    
    return highlight
end

-- Encontrar alvos
local function findTargets()
    local targets = {}
    local char = player.Character
    if not char then return targets end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not rootPart then return targets end
    
    local charPos = rootPart.Position
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("Humanoid") and otherChar.Humanoid.Health > 0 then
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart") or otherChar:FindFirstChild("Torso")
                if otherRoot then
                    local distance = (otherRoot.Position - charPos).Magnitude
                    if distance <= Settings.FOVRadius then
                        table.insert(targets, otherChar)
                    end
                end
            end
        end
    end
    
    return targets
end

-- Atualizar alvo
local function updateTarget(newTarget, oldTarget)
    if oldTarget then
        local oldHighlight = oldTarget:FindFirstChild("LockOnHighlight")
        if oldHighlight then oldHighlight:Destroy() end
    end
    
    if newTarget then
        addOutline(newTarget)
    end
end

-- Animar indicador
local function animateIndicator()
    if not uiElements.targetIndicator or not uiElements.targetIndicator.Parent then return end
    
    local outer = uiElements.targetIndicator:FindFirstChild("OuterCircle", true)
    local inner = uiElements.targetIndicator:FindFirstChild("InnerCircle", true)
    
    if outer then
        TweenService:Create(outer, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
            Rotation = 360
        }):Play()
    end
    
    if inner then
        TweenService:Create(inner, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Size = UDim2.new(0.8, 0, 0.8, 0),
            ImageTransparency = 0.3
        }):Play()
    end
end

-- Atualizar câmera
local function updateCamera()
    if not (currentTarget and isLockedOn) then return end
    if not player.Character then return end
    
    local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChild("Torso")
    local charRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
    
    if targetRoot and charRoot then
        local targetPos = targetRoot.Position
        local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.LockSmoothness)
    end
end

-- Limpar tudo
local function cleanup()
    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end
    connections = {}
    
    if uiElements.targetIndicator then
        pcall(function() uiElements.targetIndicator:Destroy() end)
    end
    if uiElements.fovCircle then
        pcall(function() uiElements.fovCircle:Destroy() end)
    end
    if uiElements.screenGui then
        pcall(function() uiElements.screenGui:Destroy() end)
    end
end

-- Inicializar sistema
local function init()
    cleanup() -- Limpar execuções anteriores
    
    -- Criar UI
    if Settings.ShowUI then
        uiElements = createUI()
    end
    
    -- Criar elementos visuais
    uiElements.fovCircle = createFOVCircle()
    uiElements.targetIndicator = createTargetIndicator()
    
    -- Botão LOCK
    if uiElements.lockButton then
        table.insert(connections, uiElements.lockButton.MouseButton1Click:Connect(function()
            isLockedOn = not isLockedOn
            
            -- Animação do botão
            TweenService:Create(uiElements.lockButton, TweenInfo.new(0.3), {
                BackgroundColor3 = isLockedOn and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(30, 40, 60),
                Text = isLockedOn and "🔓 UNLOCK" or "🔒 LOCK"
            }):Play()
            
            uiElements.fovCircle.Enabled = not isLockedOn
            
            if not isLockedOn and currentTarget then
                updateTarget(nil, currentTarget)
                if uiElements.targetIndicator.Parent then
                    uiElements.targetIndicator.Parent = nil
                end
                currentTarget = nil
            elseif isLockedOn then
                local targets = findTargets()
                if #targets > 0 then
                    currentTarget = targets[1]
                    updateTarget(currentTarget, nil)
                    local head = currentTarget:FindFirstChild("Head")
                    if head then
                        uiElements.targetIndicator.Parent = head
                        animateIndicator()
                    end
                else
                    isLockedOn = false
                    if uiElements.lockButton then
                        uiElements.lockButton.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
                        uiElements.lockButton.Text = "🔒 LOCK"
                    end
                end
            end
        end))
    end
    
    -- Tecla de atalho
    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode[Settings.Keybind] then
            if uiElements.lockButton then
                uiElements.lockButton.MouseButton1Click:Fire()
            end
        end
    end))
    
    -- Trocar alvo com scroll
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel and isLockedOn and canSwitchTarget then
            canSwitchTarget = false
            
            local targets = findTargets()
            if #targets > 0 then
                local currentIndex = 1
                for i, target in ipairs(targets) do
                    if target == currentTarget then
                        currentIndex = i
                        break
                    end
                end
                
                if input.Position.Z > 0 then
                    currentIndex = currentIndex % #targets + 1
                else
                    currentIndex = currentIndex - 1
                    if currentIndex < 1 then currentIndex = #targets end
                end
                
                local newTarget = targets[currentIndex]
                updateTarget(newTarget, currentTarget)
                currentTarget = newTarget
                local head = currentTarget:FindFirstChild("Head")
                if head then
                    uiElements.targetIndicator.Parent = head
                end
            end
            
            task.wait(0.2)
            canSwitchTarget = true
        end
    end))
    
    -- Loop da câmera
    table.insert(connections, RunService.RenderStepped:Connect(updateCamera))
    
    -- Quando o personagem morrer
    if player.Character then
        player.Character.Humanoid.Died:Connect(function()
            isLockedOn = false
            currentTarget = nil
            if uiElements.targetIndicator then
                uiElements.targetIndicator.Parent = nil
            end
        end)
    end
    
    print("=== LOCK-ON SYSTEM CARREGADO ===")
    print("🎯 Botão LOCK na interface")
    print("⌨️ Tecla: " .. Settings.Keybind .. " para ativar/desativar")
    print("🖱️ Scroll do mouse para trocar alvo")
    print("⚙️ Configurações disponíveis no topo do script")
end

-- Executar com proteção de erros
local function execute()
    local success, err = pcall(function()
        init()
    end)
    
    if not success then
        warn("Erro no Lock-On System:", err)
        cleanup()
    end
end

-- Iniciar
execute()

-- Retornar função para reiniciar se necessário
return {
    restart = execute,
    stop = cleanup,
    settings = Settings
}
