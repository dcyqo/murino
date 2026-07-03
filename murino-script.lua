local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/dcyqo/Rayfield/refs/heads/main/source.lua'))()

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

-- ==================== ПЕРЕМЕННЫЕ ====================
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
local DefaultSettings = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local BodyVelocity = nil
local BodyGyro = nil
local FlyConnection = nil

-- ==================== ФУНКЦИИ ====================

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
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
    if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end

    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.PlatformStand = false
    end
end

local function StartFlying()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local root = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")

    StopFlying()

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "FlyVelocity"
    BodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.Parent = root

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "FlyGyro"
    BodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    BodyGyro.P = 12500
    BodyGyro.D = 1000
    BodyGyro.Parent = root

    humanoid.PlatformStand = true

    FlyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not FlyEnabled or not root.Parent then 
            StopFlying()
            return 
        end

        local moveDirection = Vector3.new(0, 0, 0)
        local camera = workspace.CurrentCamera
        local uis = game:GetService("UserInputService")

        -- ПК управление (WASD)
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDirection += camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDirection -= camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDirection -= camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDirection += camera.CFrame.RightVector end

        -- Мобильное управление (джойстик)
        if humanoid.MoveDirection.Magnitude > 0 then
            moveDirection += camera.CFrame:VectorToWorldSpace(humanoid.MoveDirection)
        end

        -- Вертикальное управление
        if uis:IsKeyDown(Enum.KeyCode.Space) then 
            moveDirection += Vector3.new(0,1,0) 
        end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then 
            moveDirection -= Vector3.new(0,1,0) 
        end

        -- На мобильных можно использовать прыжок для подъёма (если есть)
        if humanoid.Jump then
            moveDirection += Vector3.new(0,1,0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        BodyVelocity.Velocity = moveDirection * FlySpeed
        BodyGyro.CFrame = camera.CFrame
    end)
end

local function TeleportToShkaf()
    if IsTeleporting then return end
    IsTeleporting = true
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local closestShkaf = nil
        local minDistance = math.huge
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Shkaf" and obj:IsA("Model") then
                local success, pos = pcall(function() return obj:GetPivot().Position end)
                if success then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestShkaf = obj
                    end
                end
            end
        end
        
        if closestShkaf then
            hrp.Anchored = true
            hrp.CFrame = closestShkaf:GetPivot()
            task.wait(0.1)
            local prompt = closestShkaf:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                prompt.HoldDuration = 0
                fireproximityprompt(prompt)
            end
            hrp.Anchored = false
        end
    end
    
    task.wait(2) 
    IsTeleporting = false
end

local function HandleFlick(sound)
    if sound:IsA("Sound") and sound.SoundId == FlickSoundID then
        sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
            if sound.IsPlaying and AutoHideRushDrunsEnabled then
                TeleportToShkaf()
            end
        end)
        if sound.IsPlaying and AutoHideRushDrunsEnabled then
            TeleportToShkaf()
        end
    end
end

local function HandleArtur(arturObj)
    if not AutoHiEnabled or IsTeleporting then return end
    IsTeleporting = true
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local oldPos = hrp.CFrame
        
        local function executeTeleport()
            if not arturObj or not arturObj.Parent then return end
            hrp.Anchored = true
            local endTime = os.clock() + 1
            while os.clock() < endTime do
                if not arturObj or not arturObj.Parent then break end
                local success, targetPivot = pcall(function() return arturObj:GetPivot() end)
                if success then
                    local offsetCFrame = targetPivot * CFrame.new(0, 0, -4)
                    hrp.CFrame = CFrame.lookAt(offsetCFrame.Position, targetPivot.Position)
                end
                task.wait(0.05)
            end
            hrp.Anchored = false
            hrp.CFrame = oldPos
        end
        executeTeleport()
    end
    task.wait(0.5)
    IsTeleporting = false
end

-- ==================== СОЕДИНЕНИЯ ====================

game:GetService("RunService").Stepped:Connect(function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipEnabled then
                    part.CanCollide = false
                else
                    if part.Name == "HumanoidRootPart" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Torso" then
                        part.CanCollide = true
                    end
                end
            end
        end
        if character:FindFirstChild("Humanoid") then
            local currentTargetSpeed = TargetSpeed
            if IsTeleporting then currentTargetSpeed = 0 end
            if character.Humanoid.WalkSpeed ~= currentTargetSpeed then
                character.Humanoid.WalkSpeed = currentTargetSpeed
            end
        end
    end
end)

workspace.DescendantAdded:Connect(function(child)
    HandleFlick(child)
    if child.Name == "Artur" then
        task.wait(0.1)
        HandleArtur(child)
    end
end)

for _, v in ipairs(game:GetDescendants()) do
    pcall(function() HandleFlick(v) end)
end

Lighting.Changed:Connect(function()
    if FullBrightEnabled then
        ApplyFullBright()
    end
end)

-- ==================== UI ====================

TabGame:CreateSlider({ Name = "Скорость ходьбы✓", Range = {16, 100}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Callback = function(Value) TargetSpeed = Value end })

TabGame:CreateToggle({ Name = "Полное освещение✓", CurrentValue = false, Callback = function(Value) FullBrightEnabled = Value if not Value then Lighting.Ambient = DefaultSettings.Ambient Lighting.Brightness = DefaultSettings.Brightness Lighting.OutdoorAmbient = DefaultSettings.OutdoorAmbient else ApplyFullBright() end end })

TabGame:CreateToggle({ Name = "Сквозь препятствия✓", CurrentValue = false, Callback = function(Value) NoclipEnabled = Value end })

-- === Полёт (с поддержкой мобильных) ===
TabGame:CreateToggle({
    Name = "Полёт×",
    CurrentValue = false,
    Callback = function(Value)
        FlyEnabled = Value
        if FlyEnabled then
            StartFlying()
        else
            StopFlying()
        end
    end,
})

TabGame:CreateSlider({
    Name = "Скорость полёта",
    Range = {20, 200},
    Increment = 1,
    Suffix = "Stud/s",
    CurrentValue = 50,
    Callback = function(Value) FlySpeed = Value end,
})

TabMonster:CreateToggle({ Name = "Авто | Приветствие Артура×", CurrentValue = false, Callback = function(Value) AutoHiEnabled = Value end })
TabMonster:CreateToggle({ Name = "Авто | Укрытие от раш-друна✓", CurrentValue = false, Callback = function(Value) AutoHideRushDrunsEnabled = Value end })

-- Основное вкладка (без изменений)
TabMain:CreateParagraph({ Title = "ЙОУ😎", Content = "Привет, Друн!\n\nЯ очень благодарен тебе за использование моего скрипта." })
TabMain:CreateParagraph({ Title = "ПРАВИЛА СОГЛАШЕНИЯ", Content = "ЗАПУСКАЯ СКРИПТ ВЫ АВТОМАТИЧЕСКИ СОГЛАШАЕТЕСЬ С ПРАВИЛАМИ..." })
TabMain:CreateParagraph({ Title = "ОБНОВЛЕНИЯ", Content = "Все обновления скрипта будут выходить в Discord сервере." })
TabMain:CreateParagraph({ Title = "❔ВЕРСИЯ", Content = "v0.6 | Alpha script" })
TabMain:CreateLabel("✓ – Значит полностью рабочий.\n× – Значит неполностью/полностью нерабочий")
TabMain:CreateButton({ Name = "Discord Server", Callback = function() setclipboard("https://discord.gg/VbwR3pmNAb") Rayfield:Notify({Title = "Invited in Discord", Content = "Ссылка скопирована!", Duration = 5}) end })
