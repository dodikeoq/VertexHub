-- узел: meridian/roblox_delta_injector
-- среда: Delta Executor (Luau Client Environment)
-- параметры: MaxSpeed = 100, BypassTarget = Humanoid State

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Переменные состояний
local Config = {
    Speed = 16,
    InfJump = false
}

-- Контур обхода (Metatable Spoofing)
-- Защищает изменённые параметры от локальных проверок античита, возвращая им стандартные значения при попытке чтения сторонними скриптами
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local targetGui = gethui and gethui() or CoreGui

-- Удаление старой сессии интерфейса, если она существовала
if targetGui:FindFirstChild("Morn_RadialMenu") then
    targetGui["Morn_RadialMenu"]:Destroy()
end

-- Инициализация защиты метатаблицы
local rawMT = getrawmetatable(game)
local oldIndex = rawMT.__index
local oldNewIndex = rawMT.__newindex

if setreadonly then setreadonly(rawMT, false) elseif make_writeable then make_writeable(rawMT) end

rawMT.__index = newcclosure(function(self, key)
    if not checkcaller() and self and typeof(self) == "Instance" and self:IsA("Humanoid") then
        if key == "WalkSpeed" then
            return 16 -- Спуфим стандартную скорость для античита
        end
    end
    return oldIndex(self, key)
end)

rawMT.__newindex = newcclosure(function(self, key, value)
    if not checkcaller() and self and typeof(self) == "Instance" and self:IsA("Humanoid") then
        if key == "WalkSpeed" then
            return -- Блокируем попытки античита вернуть скорость назад скрытно
        end
    end
    return oldNewIndex(self, key, value)
end)

if setreadonly then setreadonly(rawMT, true) elseif make_readonly then make_readonly(rawMT) end

-- Поддержание параметров скорости (Обход принудительного сброса игровым циклом)
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Config.Speed
        end
    end
end)

-- Контур Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Создание UI (Круглое меню управления)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Morn_RadialMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = targetGui

-- Кнопка активации / Главный переключатель
local MainButton = Instance.new("TextButton")
MainButton.Name = "MainCenter"
MainButton.Size = UDim2.new(0, 60, 0, 60)
MainButton.Position = UDim2.new(0.05, 0, 0.5, -30)
MainButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainButton.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainButton.BorderSizePixel = 2
MainButton.Text = "MORN"
MainButton.TextColor3 = Color3.fromRGB(0, 255, 150)
MainButton.Font = Enum.Font.Code
MainButton.TextSize = 14
MainButton.Active = true
MainButton.Draggable = true
MainButton.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(1, 0)
MainCorner.Parent = MainButton

-- Главная круглая панель меню (скрыта по умолчанию)
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuContainer"
MenuFrame.Size = UDim2.new(0, 220, 0, 220)
MenuFrame.Position = UDim2.new(0.5, -110, 0.5, -110)
MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MenuFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MenuFrame.BorderSizePixel = 1
MenuFrame.Visible = false
MenuFrame.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(1, 0)
MenuCorner.Parent = MenuFrame

-- Заголовок меню внутри круга
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 160, 0, 20)
TitleLabel.Position = UDim2.new(0.5, -80, 0.15, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "CORE_SYSTEM // AKTIV"
TitleLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 12
TitleLabel.Parent = MenuFrame

-- Кнопка переключения Infinite Jump
local JumpToggle = Instance.new("TextButton")
JumpToggle.Name = "JumpToggle"
JumpToggle.Size = UDim2.new(0, 140, 0, 30)
JumpToggle.Position = UDim2.new(0.5, -70, 0.3, 0)
JumpToggle.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
JumpToggle.Text = "INF JUMP: OFF"
JumpToggle.TextColor3 = Color3.fromRGB(255, 80, 80)
JumpToggle.Font = Enum.Font.Code
JumpToggle.TextSize = 12
JumpToggle.Parent = MenuFrame

local JumpCorner = Instance.new("UICorner")
JumpCorner.CornerRadius = UDim.new(0, 6)
JumpCorner.Parent = JumpToggle

-- Слайдер скорости: Контейнер
local SliderFrame = Instance.new("Frame")
SliderFrame.Name = "SliderContainer"
SliderFrame.Size = UDim2.new(0, 140, 0, 40)
SliderFrame.Position = UDim2.new(0.5, -70, 0.55, 0)
SliderFrame.BackgroundTransparency = 1
SliderFrame.Parent = MenuFrame

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, 0, 0, 15)
SliderLabel.Position = UDim2.new(0, 0, 0, 0)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "SPEED: 16"
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.Font = Enum.Font.Code
SliderLabel.TextSize = 11
SliderLabel.Parent = SliderFrame

local SliderBar = Instance.new("TextButton")
SliderBar.Name = "SliderBar"
SliderBar.Size = UDim2.new(1, 0, 0, 8)
SliderBar.Position = UDim2.new(0, 0, 0.7, 0)
SliderBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
SliderBar.Text = ""
SliderBar.AutoButtonColor = false
SliderBar.Parent = SliderFrame

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(0, 4)
BarCorner.Parent = SliderBar

local SliderFill = Instance.new("Frame")
SliderFill.Name = "SliderFill"
SliderFill.Size = UDim2.new(0.16, 0, 1, 0) -- Дефолтное заполнение под скорость 16 (16/100)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBar

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 4)
FillCorner.Parent = SliderFill

-- Логика слайдера скорости
local IsSliding = false

local function UpdateSlider()
    local relativeX = Mouse.X - SliderBar.AbsolutePosition.X
    local percentage = math.clamp(relativeX / SliderBar.AbsoluteSize.X, 0, 1)
    
    -- Вычисление скорости от 0 до 100
    local targetSpeed = math.round(percentage * 100)
    if targetSpeed < 16 then targetSpeed = 16 end -- Ограничение снизу для предотвращения полной остановки
    
    Config.Speed = targetSpeed
    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    SliderLabel.Text = "SPEED: " .. tostring(targetSpeed)
end

SliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsSliding = true
        UpdateSlider()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsSliding = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if IsSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider()
    end
end)

-- Логика переключателя прыжков
JumpToggle.MouseButton1Click:Connect(function()
    Config.InfJump = not Config.InfJump
    if Config.InfJump then
        JumpToggle.Text = "INF JUMP: ON"
        JumpToggle.TextColor3 = Color3.fromRGB(0, 255, 150)
        JumpToggle.BackgroundColor3 = Color3.fromRGB(20, 35, 25)
    else
        JumpToggle.Text = "INF JUMP: OFF"
        JumpToggle.TextColor3 = Color3.fromRGB(255, 80, 80)
        JumpToggle.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    end
end)

-- Открытие / Закрытие меню при нажатии на центральную кнопку MORN
MainButton.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
    if MenuFrame.Visible then
        MenuFrame.Position = UDim2.new(0, MainButton.AbsolutePosition.X + 80, 0, MainButton.AbsolutePosition.Y - 80)
    end
end)
