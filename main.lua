--[[
    jsiahs aimbot v2 hub
    Universal for all Roblox games & executors
    Sticky Aim | Silent Aim | Highlights | WalkSpeed | Fly | TriggerBot | Keep Script
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════
--  PASTE YOUR RAW GITHUB / PASTEBIN LINK HERE
-- ═══════════════════════════════════════════════════════════════
local SCRIPT_URL = "https://raw.githubusercontent.com/itsjsiah/its-jsiahs-aimbot-v2-hub/main/main.lua"
-- ═══════════════════════════════════════════════════════════════

-- ── Library ──────────────────────────────────────────────────────────────
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- ── Window ───────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title = "jsiahs aimbot v2 hub",
    Footer = "UNIVERSAL",
    Icon = 123123,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Aimbot = Window:AddTab("Aimbot", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Movement = Window:AddTab("Movement", "running"),
    Protection = Window:AddTab("Protection", "shield"),
    Extras = Window:AddTab("Extras", "gear"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ── Utility ──────────────────────────────────────────────────────────────
local connections = {}

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = getCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function safeCall(fn)
    local ok, result = pcall(fn)
    return ok and result
end

-- ── Keep Script (queue_on_teleport) ──────────────────────────────────────
local keepScriptEnabled = false

local function getQueueFunction()
    if queue_on_teleport then return queue_on_teleport end
    if syn and syn.queue_on_teleport then return syn.queue_on_teleport end
    if fluxus and fluxus.queue_on_teleport then return fluxus.queue_on_teleport end
    if getgenv and getgenv().queue_on_teleport then return getgenv().queue_on_teleport end
    if KRNL_LOADED and queue_on_teleport then return queue_on_teleport end
    return nil
end

local function applyKeepScript(enabled)
    keepScriptEnabled = enabled
    local queueFunc = getQueueFunction()

    if not queueFunc then
        Library:Notify("Your executor does not support queue_on_teleport", 3)
        return
    end

    if enabled then
        local code = string.format([[
            loadstring(game:HttpGet("%s"))()
        ]], SCRIPT_URL)

        pcall(function()
            queueFunc(code)
        end)
        Library:Notify("Keep Script ON – will reinject on next game/server", 3)
    else
        pcall(function()
            queueFunc("") -- clear queue on most executors
        end)
        Library:Notify("Keep Script OFF", 2)
    end
end

-- ── Aimbot State ─────────────────────────────────────────────────────────
local aimbotEnabled = false
local aimbotKeyActive = false
local aimbotMode = "Rage"
local aimbotLock = "Head"
local stickyAimEnabled = false
local aimbotPrediction = false
local aimbotSensitivity = 1
local aimPriority = "Distance"
local aimFOV = 500
local aimMaxDistance = 0
local aimDeadCheck = true
local aimWallCheck = true
local aimTeamCheck = true

local silentAimEnabled = false
local silentAimHitchance = 100

local stickyTarget = nil

-- ── Target Validation (universal) ────────────────────────────────────────
local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hum or not head then return false end
    if aimDeadCheck and hum.Health <= 0 then return false end

    if aimTeamCheck then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            return false
        end
    end

    if aimMaxDistance > 0 then
        local myRoot = getRoot()
        if myRoot then
            local dist = (myRoot.Position - head.Position).Magnitude
            if dist > aimMaxDistance then return false end
        end
    end

    if aimWallCheck then
        local origin = Camera.CFrame.Position
        local direction = (head.Position - origin).Unit * 2000
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {getCharacter() or {}}
        params.IgnoreWater = true
        local result = Workspace:Raycast(origin, direction, params)
        if result and not result.Instance:IsDescendantOf(char) then
            return false
        end
    end

    return true
end

local function getClosestPlayer(fov)
    local closest, closestValue = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if not isValidTarget(player) then continue end
        local head = player.Character.Head
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen or pos.Z <= 0 then continue end

        local dist = (center - Vector2.new(pos.X, pos.Y)).Magnitude
        if dist > (fov or math.huge) then continue end

        local value = (aimPriority == "Distance") and dist or player.Character:FindFirstChildOfClass("Humanoid").Health
        if value < closestValue then
            closestValue = value
            closest = player
        end
    end
    return closest
end

-- ── Aimbot Tab (First Tab) ───────────────────────────────────────────────
local AimbotMain = Tabs.Aimbot:AddLeftGroupbox("Aimbot Main")
local AimbotFOV = Tabs.Aimbot:AddRightGroupbox("Silent / FOV")

AimbotMain:AddToggle("AimbotToggle", {
    Text = "Enable Aimbot",
    Default = false,
    Callback = function(Value)
        aimbotEnabled = Value
        if not Value then stickyTarget = nil end
    end,
})

AimbotMain:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", {
    Default = "E",
    Mode = "Toggle",
    Text = "Aimbot Key",
    NoUI = false,
    SyncToggleState = false,
    Callback = function(Value)
        aimbotKeyActive = Value
        if not Value then stickyTarget = nil end
    end,
})

AimbotMain:AddDropdown("AimbotMode", {
    Values = {"Rage", "Legit"},
    Default = 1,
    Multi = false,
    Text = "Aimbot Mode",
    Callback = function(Value)
        aimbotMode = Value
    end,
})

AimbotMain:AddDropdown("AimbotLock", {
    Values = {"Head", "UpperTorso", "HumanoidRootPart"},
    Default = 1,
    Multi = false,
    Text = "Lock Target",
    Callback = function(Value)
        aimbotLock = Value
    end,
})

AimbotMain:AddToggle("StickyAimToggle", {
    Text = "Sticky Aim",
    Tooltip = "Locks onto target and refuses to let go",
    Default = false,
    Callback = function(Value)
        stickyAimEnabled = Value
        if not Value then stickyTarget = nil end
    end,
})

AimbotMain:AddToggle("AimbotPrediction", {
    Text = "Movement Prediction",
    Default = false,
    Callback = function(Value)
        aimbotPrediction = Value
    end,
})

AimbotMain:AddSlider("AimbotSensitivity", {
    Text = "Sensitivity (Legit)",
    Default = 1,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        aimbotSensitivity = Value
    end,
})

AimbotMain:AddDropdown("AimPriority", {
    Values = {"Distance", "Health"},
    Default = 1,
    Multi = false,
    Text = "Priority",
    Callback = function(Value)
        aimPriority = Value
    end,
})

AimbotMain:AddSlider("AimMaxDistance", {
    Text = "Max Distance",
    Default = 0,
    Min = 0,
    Max = 3000,
    Rounding = 0,
    Suffix = " studs",
    Tooltip = "0 = unlimited",
    Callback = function(Value)
        aimMaxDistance = Value
    end,
})

AimbotMain:AddToggle("AimDeadCheck", {
    Text = "Dead Check",
    Default = true,
    Callback = function(Value)
        aimDeadCheck = Value
    end,
})

AimbotMain:AddToggle("AimWallCheck", {
    Text = "Wall Check",
    Default = true,
    Callback = function(Value)
        aimWallCheck = Value
    end,
})

AimbotMain:AddToggle("AimTeamCheck", {
    Text = "Team Check",
    Default = true,
    Callback = function(Value)
        aimTeamCheck = Value
    end,
})

-- ── KEEP SCRIPT (added to first tab) ─────────────────────────────────────
AimbotMain:AddDivider()
AimbotMain:AddToggle("KeepScriptToggle", {
    Text = "Keep Script",
    Tooltip = "Auto re-injects the script when you join another game or server",
    Default = false,
    Callback = function(Value)
        applyKeepScript(Value)
    end,
})

AimbotFOV:AddSlider("AimFOV", {
    Text = "Aimbot FOV",
    Default = 500,
    Min = 50,
    Max = 2000,
    Rounding = 0,
    Callback = function(Value)
        aimFOV = Value
    end,
})

AimbotFOV:AddToggle("SilentAimToggle", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(Value)
        silentAimEnabled = Value
    end,
})

AimbotFOV:AddSlider("SilentAimHitchance", {
    Text = "Silent Aim Hitchance",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(Value)
        silentAimHitchance = Value
    end,
})

-- ── Aimbot Loop ──────────────────────────────────────────────────────────
connections["Aimbot"] = RunService:BindToRenderStep("Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local active = aimbotEnabled or aimbotKeyActive
    if not active then
        stickyTarget = nil
        return
    end

    local targetPlayer = nil

    if stickyAimEnabled and stickyTarget and isValidTarget(stickyTarget) then
        targetPlayer = stickyTarget
    else
        targetPlayer = getClosestPlayer(aimFOV)
        if stickyAimEnabled and targetPlayer then
            stickyTarget = targetPlayer
        end
    end

    if not targetPlayer or not targetPlayer.Character then
        stickyTarget = nil
        return
    end

    local targetPart = targetPlayer.Character:FindFirstChild(aimbotLock)
        or targetPlayer.Character:FindFirstChild("Head")
        or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local prediction = Vector3.zero
    if aimbotPrediction then
        prediction = targetPart.AssemblyLinearVelocity * 0.13
    end
    local targetPos = targetPart.Position + prediction

    if aimbotMode == "Rage" or stickyAimEnabled then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    else
        local currentLook = Camera.CFrame.LookVector
        local targetLook = (targetPos - Camera.CFrame.Position).Unit
        local smooth = math.clamp(aimbotSensitivity * dt * 14, 0.01, 0.4)
        local newLook = currentLook:Lerp(targetLook, smooth)
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
    end
end)

-- ── Silent Aim (universal hooks) ─────────────────────────────────────────
local function hookSilentAim()
    safeCall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        if modules then
            local utility = modules:FindFirstChild("Utility")
            if utility then
                local mod = require(utility)
                if mod and type(mod.Raycast) == "function" then
                    local old = mod.Raycast
                    mod.Raycast = function(...)
                        local args = {...}
                        if silentAimEnabled and math.random(100) <= silentAimHitchance then
                            local closest = stickyTarget or getClosestPlayer(aimFOV)
                            if closest and closest.Character then
                                local part = closest.Character:FindFirstChild(aimbotLock) or closest.Character:FindFirstChild("Head")
                                if part then
                                    if #args >= 3 then args[3] = part.Position
                                    elseif #args >= 2 then args[2] = part.Position end
                                end
                            end
                        end
                        return old(table.unpack(args))
                    end
                end
            end
        end
    end)

    safeCall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if silentAimEnabled and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                if math.random(100) <= silentAimHitchance then
                    local closest = stickyTarget or getClosestPlayer(aimFOV)
                    if closest and closest.Character then
                        local part = closest.Character:FindFirstChild(aimbotLock) or closest.Character:FindFirstChild("Head")
                        if part and method == "Raycast" and #args >= 2 then
                            local origin = args[1]
                            local mag = (typeof(args[2]) == "Vector3") and args[2].Magnitude or 2000
                            args[2] = (part.Position - origin).Unit * mag
                        end
                    end
                end
            end
            return oldNamecall(self, table.unpack(args))
        end)

        setreadonly(mt, true)
    end)
end
hookSilentAim()

-- ── Universal TriggerBot ─────────────────────────────────────────────────
local triggerBotEnabled = false
local triggerBotDelay = 0
local triggerBotLastShot = 0

AimbotMain:AddToggle("TriggerBotToggle", {
    Text = "TriggerBot",
    Tooltip = "Universal - works on every game",
    Default = false,
    Callback = function(Value)
        triggerBotEnabled = Value
    end,
})

AimbotMain:AddSlider("TriggerBotDelay", {
    Text = "TriggerBot Delay",
    Default = 0,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Suffix = "ms",
    Callback = function(Value)
        triggerBotDelay = Value / 1000
    end,
})

local function fireWeapon()
    local char = getCharacter()
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            safeCall(function() tool:Activate() end)
        end
    end

    safeCall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.025)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)

    safeCall(function()
        if mouse1click then mouse1click() end
    end)

    safeCall(function()
        if mouse1press then
            mouse1press()
            task.wait(0.02)
            mouse1release()
        end
    end)
end

connections["TriggerBot"] = RunService.Heartbeat:Connect(function()
    if not triggerBotEnabled then return end
    if tick() - triggerBotLastShot < triggerBotDelay then return end

    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector * 2000
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {getCharacter() or {}}
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    if not result then return end

    local character = result.Instance:FindFirstAncestorOfClass("Model")
    if not character then return end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end
    if aimTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return end

    triggerBotLastShot = tick()
    fireWeapon()
end)

-- ── Highlights ESP ───────────────────────────────────────────────────────
local highlightEnabled = false
local highlightTeamCheck = false
local highlightFillAlpha = 0.55
local highlightEnemyColor = Color3.fromRGB(255, 60, 60)
local highlightTeamColor = Color3.fromRGB(60, 180, 255)
local highlightMaxDist = 0
local highlights = {}

local function ensureHighlight(player)
    if not highlights[player] then
        local hl = Instance.new("Highlight")
        hl.FillTransparency = highlightFillAlpha
        hl.OutlineTransparency = 0
        hl.Enabled = false
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = Workspace
        highlights[player] = hl
    end
    return highlights[player]
end

local function cleanupHighlight(player)
    if highlights[player] then
        safeCall(function() highlights[player]:Destroy() end)
        highlights[player] = nil
    end
end

Players.PlayerRemoving:Connect(cleanupHighlight)

local VisualsLeft = Tabs.Visuals:AddLeftGroupbox("Highlights ESP")
local VisualsRight = Tabs.Visuals:AddRightGroupbox("Colors / Distance")

VisualsLeft:AddToggle("HighlightToggle", {
    Text = "Enable Highlights",
    Default = false,
    Callback = function(Value)
        highlightEnabled = Value
        if not Value then
            for _, hl in pairs(highlights) do
                hl.Enabled = false
            end
        end
    end,
})

VisualsLeft:AddToggle("HighlightTeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(Value)
        highlightTeamCheck = Value
    end,
})

VisualsLeft:AddSlider("HighlightFillAlpha", {
    Text = "Fill Transparency",
    Default = 5.5,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        highlightFillAlpha = Value / 10
    end,
})

VisualsRight:AddSlider("HighlightMaxDist", {
    Text = "Max Distance",
    Default = 0,
    Min = 0,
    Max = 3000,
    Rounding = 0,
    Suffix = " studs",
    Tooltip = "0 = unlimited",
    Callback = function(Value)
        highlightMaxDist = Value
    end,
})

VisualsRight:AddDropdown("EnemyColor", {
    Values = {"Red", "Orange", "Yellow", "Purple", "White"},
    Default = 1,
    Multi = false,
    Text = "Enemy Color",
    Callback = function(Value)
        local map = {
            Red = Color3.fromRGB(255, 60, 60),
            Orange = Color3.fromRGB(255, 140, 30),
            Yellow = Color3.fromRGB(255, 220, 50),
            Purple = Color3.fromRGB(180, 50, 255),
            White = Color3.fromRGB(255, 255, 255),
        }
        highlightEnemyColor = map[Value] or highlightEnemyColor
    end,
})

VisualsRight:AddDropdown("TeamColor", {
    Values = {"Blue", "Green", "Cyan", "White"},
    Default = 1,
    Multi = false,
    Text = "Team Color",
    Callback = function(Value)
        local map = {
            Blue = Color3.fromRGB(60, 150, 255),
            Green = Color3.fromRGB(60, 255, 100),
            Cyan = Color3.fromRGB(0, 255, 220),
            White = Color3.fromRGB(255, 255, 255),
        }
        highlightTeamColor = map[Value] or highlightTeamColor
    end,
})

connections["Highlights"] = RunService.Heartbeat:Connect(function()
    if not highlightEnabled then return end
    local myRoot = getRoot()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        local hl = ensureHighlight(player)

        if not char or not char:FindFirstChild("HumanoidRootPart") then
            hl.Enabled = false
            continue
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            hl.Enabled = false
            continue
        end

        if highlightTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            hl.Enabled = false
            continue
        end

        if highlightMaxDist > 0 and myRoot then
            local dist = (myRoot.Position - char.HumanoidRootPart.Position).Magnitude
            if dist > highlightMaxDist then
                hl.Enabled = false
                continue
            end
        end

        local isTeam = player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
        local color = isTeam and highlightTeamColor or highlightEnemyColor
        hl.Adornee = char
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = highlightFillAlpha
        hl.Enabled = true
    end
end)

-- ── Movement ─────────────────────────────────────────────────────────────
local MovementLeft = Tabs.Movement:AddLeftGroupbox("Fly / Speed")
local MovementRight = Tabs.Movement:AddRightGroupbox("Other")

local walkSpeedEnabled = false
local walkSpeedValue = 16
local originalWalkSpeed = 16

local function captureOriginalSpeed()
    local hum = getHumanoid()
    if hum then originalWalkSpeed = hum.WalkSpeed end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)
    captureOriginalSpeed()
    if walkSpeedEnabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = walkSpeedValue end
    end
end)

if LocalPlayer.Character then
    task.spawn(function()
        task.wait(0.6)
        captureOriginalSpeed()
    end)
end

MovementLeft:AddToggle("WalkSpeedToggle", {
    Text = "WalkSpeed",
    Default = false,
    Callback = function(Value)
        walkSpeedEnabled = Value
        local hum = getHumanoid()
        if not hum then return end
        if Value then
            captureOriginalSpeed()
            hum.WalkSpeed = walkSpeedValue
        else
            hum.WalkSpeed = originalWalkSpeed
        end
    end,
})

MovementLeft:AddInput("WalkSpeedInput", {
    Default = "16",
    Numeric = true,
    Finished = true,
    Text = "WalkSpeed Value",
    Placeholder = "16",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            walkSpeedValue = num
            if walkSpeedEnabled then
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = walkSpeedValue end
            end
        end
    end,
})

connections["WalkSpeed"] = RunService.Heartbeat:Connect(function()
    if walkSpeedEnabled then
        local hum = getHumanoid()
        if hum and math.abs(hum.WalkSpeed - walkSpeedValue) > 0.05 then
            hum.WalkSpeed = walkSpeedValue
        end
    end
end)

-- Fly
local flyEnabled = false
local flySpeed = 50
local flyBodyVelocity
local flyBodyGyro

local function enableFly()
    local root = getRoot()
    if not root then return end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.P = 1250
    flyBodyVelocity.Parent = root

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.P = 3000
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root
end

local function disableFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

MovementLeft:AddToggle("FlyHackToggle", {
    Text = "Fly",
    Default = false,
    Callback = function(Value)
        flyEnabled = Value
        if Value then enableFly() else disableFly() end
    end,
})

MovementLeft:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        flySpeed = Value
    end,
})

MovementLeft:AddLabel("Fly Key"):AddKeyPicker("FlyKeybind", {
    Default = "F",
    Mode = "Toggle",
    Text = "Fly Key",
    NoUI = false,
    Callback = function(Value)
        flyEnabled = Value
        if Toggles.FlyHackToggle then Toggles.FlyHackToggle:SetValue(Value) end
        if Value then enableFly() else disableFly() end
    end,
})

connections["Fly"] = RunService.Heartbeat:Connect(function()
    if not flyEnabled then return end
    local root = getRoot()
    if not root then return end
    if not flyBodyVelocity or not flyBodyVelocity.Parent then enableFly() end

    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end

    local hum = getHumanoid()
    if hum and hum.MoveDirection.Magnitude > 0.05 then
        move = move + hum.MoveDirection
    end

    if move.Magnitude > 0 then
        flyBodyVelocity.Velocity = move.Unit * flySpeed
    else
        flyBodyVelocity.Velocity = Vector3.zero
    end

    if flyBodyGyro then
        flyBodyGyro.CFrame = CFrame.new(root.Position, root.Position + Camera.CFrame.LookVector)
    end
end)

local infJumpEnabled = false
local infJumpConn

MovementRight:AddToggle("InfiniteJumpToggle", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(Value)
        infJumpEnabled = Value
        if Value then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = getHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
        end
    end,
})

local noClipEnabled = false
MovementRight:AddToggle("NoClipToggle", {
    Text = "NoClip",
    Default = false,
    Callback = function(Value)
        noClipEnabled = Value
    end,
})

connections["NoClip"] = RunService.Stepped:Connect(function()
    if not noClipEnabled then return end
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

local bunnyHopEnabled = false
MovementRight:AddToggle("BunnyHopToggle", {
    Text = "Bunny Hop",
    Default = false,
    Callback = function(Value)
        bunnyHopEnabled = Value
    end,
})

connections["BunnyHop"] = RunService.Heartbeat:Connect(function()
    if not bunnyHopEnabled then return end
    local hum = getHumanoid()
    if hum and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ── Protection ───────────────────────────────────────────────────────────
local ProtectionLeft = Tabs.Protection:AddLeftGroupbox("Anti-Aim / Camera")

local antiAimEnabled = false
local antiAimMode = "Spin"
local antiAimSpeed = 12

ProtectionLeft:AddToggle("AntiAimToggle", {
    Text = "Anti-Aim",
    Default = false,
    Callback = function(Value)
        antiAimEnabled = Value
    end,
})

ProtectionLeft:AddDropdown("AntiAimMode", {
    Values = {"Spin", "Jitter", "Random"},
    Default = 1,
    Multi = false,
    Text = "Mode",
    Callback = function(Value)
        antiAimMode = Value
    end,
})

ProtectionLeft:AddSlider("AntiAimSpeed", {
    Text = "Spin Speed",
    Default = 12,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Callback = function(Value)
        antiAimSpeed = Value
    end,
})

local forceThirdPerson = false
local originalCameraType, originalMaxZoom, originalMinZoom

ProtectionLeft:AddToggle("ForceThirdPerson", {
    Text = "Force Third Person",
    Default = false,
    Callback = function(Value)
        forceThirdPerson = Value
        if Value then
            originalCameraType = LocalPlayer.CameraMode
            originalMaxZoom = LocalPlayer.CameraMaxZoomDistance
            originalMinZoom = LocalPlayer.CameraMinZoomDistance
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 50
            LocalPlayer.CameraMinZoomDistance = 5
        else
            if originalCameraType then LocalPlayer.CameraMode = originalCameraType end
            if originalMaxZoom then LocalPlayer.CameraMaxZoomDistance = originalMaxZoom end
            if originalMinZoom then LocalPlayer.CameraMinZoomDistance = originalMinZoom end
        end
    end,
})

connections["Protection"] = RunService.Heartbeat:Connect(function()
    if forceThirdPerson and LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
    end
    if antiAimEnabled then
        local root = getRoot()
        if root then
            if antiAimMode == "Spin" then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(antiAimSpeed), 0)
            elseif antiAimMode == "Jitter" then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
            else
                root.CFrame = root.CFrame * CFrame.Angles(
                    math.rad(math.random(-8, 8)),
                    math.rad(math.random(-180, 180)),
                    math.rad(math.random(-8, 8))
                )
            end
        end
    end
end)

-- ── Extras ───────────────────────────────────────────────────────────────
local ExtrasLeft = Tabs.Extras:AddLeftGroupbox("Performance")

ExtrasLeft:AddToggle("FPSBoostToggle", {
    Text = "FPS Boost",
    Default = false,
    Callback = function(Value)
        if Value then
            safeCall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                        v.Enabled = false
                    end
                end
            end)
            Library:Notify("FPS Boost on", 2)
        else
            safeCall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = true
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            end)
        end
    end,
})

ExtrasLeft:AddButton("Remove Textures", function()
    for _, v in pairs(Workspace:GetDescendants()) do
        safeCall(function()
            if v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            end
        end)
    end
    Library:Notify("Textures stripped", 2)
end)

ExtrasLeft:AddButton("Fullbright", function()
    local lighting = game:GetService("Lighting")
    lighting.Brightness = 2
    lighting.ClockTime = 14
    lighting.FogEnd = 1e5
    lighting.GlobalShadows = false
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Library:Notify("Fullbright", 2)
end)

ExtrasLeft:AddButton("Remove Fog", function()
    local lighting = game:GetService("Lighting")
    lighting.FogEnd = 1e5
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("Atmosphere") then v:Destroy() end
    end
    Library:Notify("Fog gone", 2)
end)

-- ── Overlay GUI ──────────────────────────────────────────────────────────
local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "jsiahsOverlay"
OverlayGui.ResetOnSpawn = false
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OverlayGui.IgnoreGuiInset = true
OverlayGui.DisplayOrder = 999
OverlayGui.Parent = PlayerGui

local hideBtn = Instance.new("TextButton")
hideBtn.Name = "HideGUI"
hideBtn.Size = UDim2.fromOffset(100, 38)
hideBtn.Position = UDim2.new(0, 20, 0, 90)
hideBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hideBtn.BackgroundTransparency = 0.15
hideBtn.BorderSizePixel = 0
hideBtn.Text = "HIDE GUI"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 14
hideBtn.AutoButtonColor = true
hideBtn.Parent = OverlayGui

Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", hideBtn).Color = Color3.fromRGB(80, 80, 80)

local guiVisible = true

local function setLibraryVisible(visible)
    safeCall(function()
        if Library.Toggle then Library:Toggle() return end
    end)
    safeCall(function()
        if Library.MainFrame then Library.MainFrame.Visible = visible end
        if Window and Window.MainFrame then Window.MainFrame.Visible = visible end
    end)
    safeCall(function()
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui ~= OverlayGui then
                local name = gui.Name:lower()
                if name:find("obsidian") or name:find("library") or name:find("linoria") or name:find("window") then
                    for _, child in ipairs(gui:GetDescendants()) do
                        if child:IsA("Frame") and (child.Name == "Main" or child.Name == "MainFrame" or child.Name:find("Outer")) then
                            child.Visible = visible
                        end
                    end
                end
            end
        end
    end)
    safeCall(function()
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui ~= OverlayGui then
                for _, child in ipairs(gui:GetChildren()) do
                    if child:IsA("Frame") and child.Size.X.Offset > 280 then
                        child.Visible = visible
                    end
                end
            end
        end
    end)
end

hideBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    setLibraryVisible(guiVisible)
    hideBtn.Text = guiVisible and "HIDE GUI" or "SHOW GUI"
    hideBtn.BackgroundColor3 = guiVisible and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(40, 120, 40)
end)

do
    local dragging, dragStart, startPos
    hideBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = hideBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            hideBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local mobileAimBtn = Instance.new("TextButton")
mobileAimBtn.Name = "MobileAimbot"
mobileAimBtn.Size = UDim2.fromOffset(120, 50)
mobileAimBtn.Position = UDim2.new(1, -140, 0.5, -25)
mobileAimBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
mobileAimBtn.BackgroundTransparency = 0.1
mobileAimBtn.BorderSizePixel = 0
mobileAimBtn.Text = "AIMBOT OFF"
mobileAimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileAimBtn.Font = Enum.Font.GothamBold
mobileAimBtn.TextSize = 15
mobileAimBtn.Visible = false
mobileAimBtn.Parent = OverlayGui

Instance.new("UICorner", mobileAimBtn).CornerRadius = UDim.new(0, 10)

local mobileAimActive = false
mobileAimBtn.MouseButton1Click:Connect(function()
    mobileAimActive = not mobileAimActive
    aimbotKeyActive = mobileAimActive
    if not mobileAimActive then stickyTarget = nil end
    mobileAimBtn.Text = mobileAimActive and "AIMBOT ON" or "AIMBOT OFF"
    mobileAimBtn.BackgroundColor3 = mobileAimActive and Color3.fromRGB(40, 160, 60) or Color3.fromRGB(180, 40, 40)
end)

do
    local dragging, dragStart, startPos
    mobileAimBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mobileAimBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mobileAimBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

AimbotMain:AddToggle("MobileAimButton", {
    Text = "Mobile Aimbot Button",
    Default = false,
    Callback = function(Value)
        mobileAimBtn.Visible = Value
    end,
})

-- ── UI Settings ──────────────────────────────────────────────────────────
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
local ConfigGroup = Tabs["UI Settings"]:AddRightGroupbox("Config")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = false,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = 2,
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind",
})

Library.ToggleKeybind = Options.MenuKeybind

ConfigGroup:AddLabel("Config Management")
ConfigGroup:AddDivider()
ConfigGroup:AddInput("ConfigName", {
    Default = "",
    Numeric = false,
    Finished = false,
    Text = "Config Name",
    Placeholder = "MyConfig",
})

ConfigGroup:AddButton("Save Config", function()
    local name = Options.ConfigName.Value
    if name == "" then Library:Notify("Enter a name first", 2) return end
    SaveManager:Save(name)
    Library:Notify("Saved " .. name, 2)
end)

ConfigGroup:AddButton("Load Config", function()
    local name = Options.ConfigName.Value
    if name == "" then Library:Notify("Enter a name first", 2) return end
    if SaveManager:Load(name) then
        Library:Notify("Loaded " .. name, 2)
    else
        Library:Notify("Not found", 2)
    end
end)

ConfigGroup:AddButton("Delete Config", function()
    local name = Options.ConfigName.Value
    if name == "" then return end
    if SaveManager:Delete(name) then
        Library:Notify("Deleted " .. name, 2)
    end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind", "ConfigName"})
ThemeManager:SetFolder("jsiahsAimbotV2")
SaveManager:SetFolder("jsiahsAimbotV2/configs")
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- ── Cleanup ──────────────────────────────────────────────────────────────
Library:OnUnload(function()
    for name, conn in pairs(connections) do
        safeCall(function()
            if name == "Aimbot" then
                RunService:UnbindFromRenderStep("Aimbot")
            elseif typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end)
    end
    connections = {}
    for player in pairs(highlights) do
        cleanupHighlight(player)
    end
    disableFly()
    if infJumpConn then infJumpConn:Disconnect() end
    if originalCameraType then LocalPlayer.CameraMode = originalCameraType end
    if originalMaxZoom then LocalPlayer.CameraMaxZoomDistance = originalMaxZoom end
    if originalMinZoom then LocalPlayer.CameraMinZoomDistance = originalMinZoom end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = originalWalkSpeed end
    if OverlayGui then OverlayGui:Destroy() end
    Library:Notify("jsiahs aimbot v2 hub unloaded", 3)
end)

Library:Notify("jsiahs aimbot v2 hub loaded — universal", 4)
