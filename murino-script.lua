local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/dcyqo/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "Скрипт: Мурино Хоррор",
    LoadingTitle = "C00Lfloppa Panel",
    LoadingSubtitle = "by @imfloppa",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "GeminiScripts",
       FileName = "MainConfig"
    }
})

local TabMain = Window:CreateTab("Основное", 4483362458)
local TabGame = Window:CreateTab("Игра", 4483362458)
local TabMonster = Window:CreateTab("Монстры", 4483362458)

-- Переменные
local AutoHiEnabled = false
local AutoHideRushDrunsEnabled = false 
local IsTeleporting = false
local FullBrightEnabled = false
local NoclipEnabled = false
local TargetSpeed = 16
local FlyEnabled = false
local FlySpeed = 50
local FlickSoundID = "rbxassetid://118519596761992"

local Lighting = game:GetService("Lighting")
local DefaultSettings = { Ambient = Lighting.Ambient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient }

local BodyVelocity, BodyGyro, FlyConnection = nil, nil, nil
local ArturDebounce = false

-- Функции
local function ApplyFullBright()
    if FullBrightEnabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end
end

local function StopFlying()
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
    if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
end

local function StartFlying()
    local char = game.Players.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    StopFlying()

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
    BodyVelocity.Parent = root

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    BodyGyro.P = 12500
    BodyGyro.Parent = root

    hum.PlatformStand = true

    FlyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not FlyEnabled or not root.Parent then StopFlying() return end
        local move = Vector3.new(0,0,0)
        local cam = workspace.CurrentCamera
        local uis = game:GetService("UserInputService")

        if uis:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end

        if hum.MoveDirection.Magnitude > 0 then
            move += cam.CFrame.LookVector * hum.MoveDirection.Z
            move += cam.CFrame.RightVector * hum.MoveDirection.X
        end

        if uis:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

        if move.Magnitude > 0 then move = move.Unit end
        BodyVelocity.Velocity = move * FlySpeed
        BodyGyro.CFrame = cam.CFrame
    end)
end

local function TeleportToShkaf()
    if IsTeleporting then return end
    IsTeleporting = true
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local closest, minDist = nil, math.huge
        for _, obj in workspace:GetDescendants() do
            if obj.Name == "Shkaf" and obj:IsA("Model") then
                local pos = obj:GetPivot().Position
                local dist = (hrp.Position - pos).Magnitude
                if dist < minDist then minDist = dist closest = obj end
            end
        end
        if closest then
            hrp.Anchored = true
            hrp.CFrame = closest:GetPivot()
            task.wait(0.1)
            local prompt = closest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then fireproximityprompt(prompt) end
            hrp.Anchored = false
        end
    end
    task.wait(2)
    IsTeleporting = false
end

local function HandleFlick(sound)
    if sound:IsA("Sound") and sound.SoundId == FlickSoundID and AutoHideRushDrunsEnabled then
        TeleportToShkaf()
    end
end

local function HandleArtur(arturObj)
    if not AutoHiEnabled or ArturDebounce then return end
    ArturDebounce = true
    IsTeleporting = true
    task.wait(1.5)
    ArturDebounce = false
    IsTeleporting = false
end

-- RunService
game:GetService("RunService").Stepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        local speed = IsTeleporting and 0 or TargetSpeed
        hum.WalkSpeed = speed
    end
end)

workspace.DescendantAdded:Connect(function(child)
    HandleFlick(child)
    if child.Name == "Artur" then task.wait(0.2) HandleArtur(child) end
end)

Lighting.Changed:Connect(function()
    if FullBrightEnabled then ApplyFullBright() end
end)

-- UI
TabGame:CreateSlider({Name = "Скорость ходьбы✓", Range = {16, 100}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Callback = function(v) TargetSpeed = v end})
TabGame:CreateToggle({Name = "Полное освещение✓", CurrentValue = false, Callback = function(v) FullBrightEnabled = v if not v then for k,v in DefaultSettings do Lighting[k] = v end else ApplyFullBright() end end})
TabGame:CreateToggle({Name = "Сквозь препятствия✓", CurrentValue = false, Callback = function(v) NoclipEnabled = v end})
TabGame:CreateToggle({Name = "Полёт ✓", CurrentValue = false, Callback = function(v) FlyEnabled = v if v then StartFlying() else StopFlying() end end})
TabGame:CreateSlider({Name = "Скорость полёта", Range = {20, 200}, Increment = 1, Suffix = "Stud/s", CurrentValue = 50, Callback = function(v) FlySpeed = v end})

TabMonster:CreateToggle({Name = "Авто | Приветствие Артура", CurrentValue = false, Callback = function(v) AutoHiEnabled = v end})
TabMonster:CreateToggle({Name = "Авто | Укрытие от раш-друна (Исправно)✓", CurrentValue = false, Callback = function(v) AutoHideRushDrunsEnabled = v end})

TabMain:CreateButton({Name = "Discord Server", Callback = function() setclipboard("https://discord.gg/ТВОЯ_ССЫЛКА") Rayfield:Notify({Title = "Скопировано", Content = "Ссылка в буфере", Duration = 5}) end})

print("Мурино Хоррор скрипт загружен!")
