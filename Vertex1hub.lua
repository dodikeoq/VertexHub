-- узел: meridian/roblox_delta_combat_esp
-- среда: Delta Executor (Luau Client Environment)
-- параметры: AutoHit (дист. 15), LiteHit (дист. 6), Трехконтурный ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local targetGui = gethui and gethui() or CoreGui

-- Очистка предыдущих сессий UI
if targetGui:FindFirstChild("Morn_ControlTerminal") then
    targetGui["Morn_ControlTerminal"]:Destroy()
end

-- Глобальная конфигурация состояний
local Config = {
    AutoHit = false,
    LiteHit = false,
    ESP_Players = false,
    ESP_Brainrots = false,
    ESP_Bases = false
}

-- Хранилище объектов ESP для своевременной очистки
local ESP_Cache = {
    Players = {},
    Brainrots = {},
    Bases = {}
}

-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ КОМБАТ-МОДУЛЯ
local function GetClosestPlayer(maxDistance)
    local closestPlayer = nil
    local shortestDistance = maxDistance
    
    local localChar = LocalPlayer.Character
    if not localChar then return nil end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return nil end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if targetHRP and targetHum and targetHum.Health > 0 then
                local distance = (localHRP.Position - targetHRP.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- ЦИКЛ АВТО-УДАРОВ (AutoHIT)
RunService.Heartbeat:Connect(function()
    if not Config.AutoHit then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Проверка наличия биты в руках
    local activeTool = character:FindFirstChildOfClass("Tool")
    local hasBat = activeTool and (string.find(string.lower(activeTool.Name), "bat") or string.find(string.lower(activeTool.Name), "бита") or string.find(string.lower(activeTool.Name), "wooden"))
    
    if hasBat then
        local targetPlayer = GetClosestPlayer(15) -- Дистанция работы AutoHIT
        if targetPlayer and targetPlayer.Character then
            local localHRP = character:FindFirstChild("HumanoidRootPart")
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if localHRP and targetHRP then
                -- Наведение (разворот к цели по оси Y)
                local targetPosition = Vector3.new(targetHRP.Position.X, localHRP.Position.Y, targetHRP.Position.Z)
                localHRP.CFrame = CFrame.new(localHRP.Position, targetPosition)
                
                -- Активация инструмента
                activeTool:Activate()
            end
        end
    end
end)

-- ЦИКЛ ИМПУЛЬСНОГО ВЫТАЛКИВАНИЯ (Lite-hit)
RunService.Heartbeat:Connect(function()
    if not Config.LiteHit then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    local localHRP = character:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end
    
    local targetPlayer = GetClosestPlayer(6) -- Сближение впритык
    if targetPlayer and targetPlayer.Character then
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            -- Классический физический флинг через контролируемый импульс скорости коллизии
            local oldVelocity = localHRP.AssemblyLinearVelocity
            
            -- Генерируем критический вектор направления удара битой
            local direction = (targetHRP.Position - localHRP.Position).Unit
            local flingForce = direction * 5000 + Vector3.new(0, 2000, 0)
            
            localHRP.AssemblyLinearVelocity = flingForce
            task.wait(0.05)
            if localHRP then
                localHRP.AssemblyLinearVelocity = oldVelocity
            end
        end
    end
end)

-- УПРАВЛЕНИЕ СИСТЕМАМИ СКАНИРОВАНИЯ (ESP)
local function ClearESPGroup(groupName)
    for _, item in pairs(ESP_Cache[groupName]) do
        if item then item:Destroy() end
    end
    ESP_Cache[groupName] = {}
end

local function UpdateESP()
    -- 1. ESP Игроков
    if Config.ESP_Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not ESP_Cache.Players[player.Name] or not ESP_Cache.Players[player.Name].Parent then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ESP_" .. player.Name
                    highlight.FillColor = Color3.fromRGB(255, 50, 50)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = player.Character
                    highlight.Parent = targetGui
                    ESP_Cache.Players[player.Name] = highlight
                end
            end
        end
    else
        ClearESPGroup("Players")
    end

    -- 2. ESP Брейнротов (Доходные объекты на сервере)
    if Config.ESP_Brainrots then
        -- Сканирование Workspace на наличие предметов с ключевыми именами
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local lowerName = string.lower(obj.Name)
                if string.find(lowerName, "brainrot") or string.find(lowerName, "income") or string.find(lowerName, "доход") or obj:FindFirstChild("Income") then
                    if not ESP_Cache.Brainrots[obj] then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Size = UDim2.new(0, 100, 0, 40)
                        billboard.AlwaysOnTop = true
                        billboard.ExtentsOffset = Vector3.new(0, 3, 0)
                        billboard.Adornee = obj
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = "[⚡ BRAINROT / MAX]"
                        label.TextColor3 = Color3.fromRGB(0, 255, 150)
                        label.Font = Enum.Font.Code
                        label.TextSize = 10
                        label.Parent = billboard
                        
                        billboard.Parent = targetGui
                        ESP_Cache.Brainrots[obj] = billboard
                    end
                end
            end
        end
    else
        ClearESPGroup("Brainrots")
    end

    -- 3. ESP Баз (Время удержания / Статус)
    if Config.ESP_Bases then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (string.find(string.lower(obj.Name), "base") or string.find(string.lower(obj.Name), "база") or string.find(string.lower(obj.Name), "tycoon")) then
                if not ESP_Cache.Bases[obj] then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 120, 0, 40)
                    billboard.AlwaysOnTop = true
                    billboard.ExtentsOffset = Vector3.new(0, 5, 0)
                    billboard.Adornee = obj
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "[🔒 BASE // TIME ACTIVE]"
                    label.TextColor3 = Color3.fromRGB(0, 180, 255)
                    label.Font = Enum.Font.Code
                    label.TextSize = 10
                    label.Parent = billboard
                    
                    billboard.Parent = targetGui
                    ESP_Cache.Bases[obj] = billboard
                end
            end
        end
    else
        ClearESPGroup("Bases")
    end
end

-- Асинхронный контур обновления разметки ESP (раз в 1 секунду для экономии ресурсов)
task.spawn(function()
    while true do
        UpdateESP()
        task.wait(1)
    end
end)

-- Очистка ESP при удалении игроков из сессии
Players.PlayerRemoving:Connect(function(player)
    if ESP_Cache.Players[player.Name] then
        ESP_Cache.Players[player.Name]:Destroy()
        ESP_Cache.Players[player.Name] = nil
    end
end)


-- ПРОЕКТИРОВАНИЕ ИНТЕРФЕЙСА ТЕРМИНАЛА (Rectangular UI Window)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Morn_ControlTerminal"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = targetGui

-- Точка быстрого вызова (Мини-кнопка MORN для восстановления окна)
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenTrigger"
OpenButton.Size = UDim2.new(0, 50, 0, 30)
OpenButton.Position = UDim2.new(0.02, 0, 0.2, 0)
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
OpenButton.BorderColor3 = Color3.fromRGB(0, 255, 150)
OpenButton.BorderSizePixel = 1
OpenButton.Text = "MORN"
OpenButton.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenButton.Font = Enum.Font.Code
OpenButton.TextSize = 12
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

-- Главное прямоугольное окно управления
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 320)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderColor3 = Color3.fromRGB(40, 40, 45)
MainFrame.BorderSizePixel = 1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 4)
UICorner.Parent = MainFrame

-- Шапка окна (Header)
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 30)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
HeaderFrame.BorderSizePixel = 0
HeaderFrame.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 4)
HeaderCorner.Parent = HeaderFrame

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0.7, 0, 1, 0)
HeaderTitle.Position = UDim2.new(0.05, 0, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "MORN // SYSTEM CONTROL"
HeaderTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
HeaderTitle.Font = Enum.Font.Code
HeaderTitle.TextSize = 12
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = HeaderFrame

-- Кнопка закрытия (Крестик 'X')
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(150, 150, 160)
CloseButton.Font = Enum.Font.Code
CloseButton.TextSize = 14
CloseButton.Parent = HeaderFrame

-- Контейнер для списка функций
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -45)
ContentFrame.Position = UDim2.new(0, 10, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ContentFrame

-- Функция фабрикации кнопок переключения (Toggle Buttons)
local function CreateToggleButton(name, text, configKey)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    button.BorderColor3 = Color3.fromRGB(35, 35, 40)
    button.BorderSizePixel = 1
    button.Text = text .. ": OFF"
    button.TextColor3 = Color3.fromRGB(255, 80, 80)
    button.Font = Enum.Font.Code
    button.TextSize = 12
    button.Parent = ContentFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        if Config[configKey] then
            button.Text = text .. ": ON"
            button.TextColor3 = Color3.fromRGB(0, 255, 150)
            button.BackgroundColor3 = Color3.fromRGB(20, 30, 25)
            button.BorderColor3 = Color3.fromRGB(0, 150, 90)
        else
            button.Text = text .. ": OFF"
            button.TextColor3 = Color3.fromRGB(255, 80, 80)
            button.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            button.BorderColor3 = Color3.fromRGB(35, 35, 40)
        end
        UpdateESP()
    end)
    return button
end

-- Инициализация элементов управления
CreateToggleButton("Btn_AutoHit", "COMBAT // AutoHIT", "AutoHit")
CreateToggleButton("Btn_LiteHit", "PHYSICS // lLte-hit", "LiteHit")
CreateToggleButton("Btn_ESP_Players", "ESP // PLAYERS", "ESP_Players")
CreateToggleButton("Btn_ESP_Brainrots", "ESP // BRAINROTS", "ESP_Brainrots")
CreateToggleButton("Btn_ESP_Bases", "ESP // BASES TIMERS", "ESP_Bases")

-- Логика переключения видимости интерфейса
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)
