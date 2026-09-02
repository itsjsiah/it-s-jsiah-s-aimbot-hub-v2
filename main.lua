--[[
    jsiahs aimbot v2 hub
    Universal for all Roblox games & executors
    Sticky Aim | Silent Aim | Highlights + Nametags | Custom Config System | Keep Script
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SCRIPT_URL = "https://raw.githubusercontent.com/itsjsiah/it-s-jsiah-s-aimbot-hub-v2/refs/heads/main/main.lua"

-- ── Library ──────────────────────────────────────────────────────────────
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

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

-- ═══════════════════════════════════════════════════════════════
-- CUSTOM CONFIG SYSTEM (fully working + persistent)
-- ═══════════════════════════════════════════════════════════════
local CONFIG_FOLDER = "jsiahsAimbotV2"
local CONFIGS_FOLDER = CONFIG_FOLDER .. "/configs"
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/autoload.txt"

local function ensureFolders()
    if isfolder then
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        if not isfolder(CONFIGS_FOLDER) then makefolder(CONFIGS_FOLDER) end
    end
end

local function getConfigList()
    ensureFolders()
    local list = {}
    if listfiles then
        local success, files = pcall(listfiles, CONFIGS_FOLDER)
        if success and files then
            for _, file in ipairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(list, name)
                end
            end
        end
    end
    table.sort(list)
    return list
end

local function collectCurrentSettings()
    local data = {}

    -- Safely collect all toggles
    if Toggles then
        for name, toggle in pairs(Toggles) do
            if toggle and toggle.Value ~= nil then
                data["toggle_" .. name] = toggle.Value
            end
        end
    end

    -- Safely collect all options
    if Options then
        for name, option in pairs(Options) do
            if option and option.Value ~= nil then
                local v = option.Value
                if typeof(v) == "Color3" then
                    data["option_" .. name] = {r = v.R, g = v.G, b = v.B}
                else
                    data["option_" .. name] = v
                end
            end
        end
    end

    return data
end

local function applySettings(data)
    if type(data) ~= "table" then return end

    task.defer(function()
        task.wait(0.4)

        if Toggles then
            for name, toggle in pairs(Toggles) do
                local key = "toggle_" .. name
                if data[key] ~= nil and toggle.SetValue then
                    pcall(function() toggle:SetValue(data[key]) end)
                end
            end
        end

        if Options then
            for name, option in pairs(Options) do
                local key = "option_" .. name
                if data[key] ~= nil and option.SetValue then
                    pcall(function()
                        local v = data[key]
                        if type(v) == "table" and v.r and v.g and v.b then
                            option:SetValue(Color3.new(v.r, v.g, v.b))
                        else
                            option:SetValue(v)
                        end
                    end)
                end
            end
        end
    end)
end

local function saveConfig(name)
    if not name or name == "" then return false end
    ensureFolders()

    local data = collectCurrentSettings()
    local success = pcall(function()
        writefile(CONFIGS_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return success
end

local function loadConfig(name)
    if not name or name == "" then return false end
    ensureFolders()

    local path = CONFIGS_FOLDER .. "/" .. name .. ".json"
    if not isfile or not isfile(path) then return false end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if success and type(data) == "table" then
        applySettings(data)
        return true
    end
    return false
end

local function deleteConfig(name)
    if not name or name == "" then return false end
    ensureFolders()
    local path = CONFIGS_FOLDER .. "/" .. name .. ".json"
    if isfile and isfile(path) then
        return pcall(function() delfile(path) end)
    end
    return false
end

local function setAutoload(name)
    ensureFolders()
    if name and name ~= "" then
        pcall(function() writefile(AUTOLOAD_FILE, name) end)
    else
        pcall(function()
            if isfile and isfile(AUTOLOAD_FILE) then delfile(AUTOLOAD_FILE) end
        end)
    end
end

local function getAutoload()
    if isfile and isfile(AUTOLOAD_FILE) then
        local success, name = pcall(readfile, AUTOLOAD_FILE)
        if success and name and name ~= "" then
            return name
        end
    end
    return nil
end

-- Auto load on script start
task.spawn(function()
    task.wait(1.2)
    local autoName = getAutoload()
    if autoName then
        if loadConfig(autoName) then
            Library:Notify("Autoloaded config: " .. autoName, 3)
        end
    end
end)

-- ── Keep Script ──────────────────────────────────────────────────────────
local function getQueueFunction()
    if queue_on_teleport then return queue_on_teleport end
    if syn and syn.queue_on_teleport then return syn.queue_on_teleport end
    if fluxus and fluxus.queue_on_teleport then return fluxus.queue_on_teleport end
    if getgenv and getgenv().queue_on_teleport then return getgenv().queue_on_teleport end
    return nil
end

local function applyKeepScript(enabled)
    local queueFunc = getQueueFunction()
    if not queueFunc then
        Library:Notify("Executor does not support queue_on_teleport", 3)
        return
    end

    if enabled then
        -- Save current settings to autoload config
        local autoName = getAutoload() or "KeepScriptAuto"
        saveConfig(autoName)
        setAutoload(autoName)

        local code = string.format([[loadstring(game:HttpGet("%s"))()]], SCRIPT_URL)
        pcall(function() queueFunc(code) end)
        Library:Notify("Keep Script ON - Settings will restore on next game", 3)
    else
        pcall(function() queueFunc("") end)
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

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hum or not head then return false end
    if aimDeadCheck and hum.Health <= 0 then return false end
    if aimTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    if aimMaxDistance > 0 then
        local myRoot = getRoot()
        if myRoot and (myRoot.Position - head.Position).Magnitude > aimMaxDistance then return false end
    end
    if aimWallCheck then
        local origin = Camera.CFrame.Position
        local direction = (head.Position - origin).Unit * 2000
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {getCharacter() or {}}
        params.IgnoreWater = true
        local result = Workspace:Raycast(origin, direction, params)
        if result and not result.Instance:IsDescendantOf(char) then return false end
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

-- ── Aimbot Tab ───────────────────────────────────────────────────────────
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
    Callback = function(Value) aimbotMode = Value end,
})

AimbotMain:AddDropdown("AimbotLock", {
    Values = {"Head", "UpperTorso", "HumanoidRootPart"},
    Default = 1,
    Multi = false,
    Text = "Lock Target",
    Callback = function(Value) aimbotLock = Value end,
})

AimbotMain:AddToggle("StickyAimToggle", {
    Text = "Sticky Aim",
    Default = false,
    Callback = function(Value)
        stickyAimEnabled = Value
        if not Value then stickyTarget = nil end
    end,
})

AimbotMain:AddToggle("AimbotPrediction", {
    Text = "Movement Prediction",
    Default = false,
    Callback = function(Value) aimbotPrediction = Value end,
})

AimbotMain:AddSlider("AimbotSensitivity", {
    Text = "Sensitivity (Legit)",
    Default = 1, Min = 0.1, Max = 5, Rounding = 1,
    Callback = function(Value) aimbotSensitivity = Value end,
})

AimbotMain:AddDropdown("AimPriority", {
    Values = {"Distance", "Health"},
    Default = 1, Multi = false, Text = "Priority",
    Callback = function(Value) aimPriority = Value end,
})

AimbotMain:AddSlider("AimMaxDistance", {
    Text = "Max Distance", Default = 0, Min = 0, Max = 3000, Rounding = 0, Suffix = " studs",
    Callback = function(Value) aimMaxDistance = Value end,
})

AimbotMain:AddToggle("AimDeadCheck", {Text = "Dead Check", Default = true, Callback = function(V) aimDeadCheck = V end})
AimbotMain:AddToggle("AimWallCheck", {Text = "Wall Check", Default = true, Callback = function(V) aimWallCheck = V end})
AimbotMain:AddToggle("AimTeamCheck", {Text = "Team Check", Default = true, Callback = function(V) aimTeamCheck = V end})

AimbotMain:AddDivider()
AimbotMain:AddToggle("KeepScriptToggle", {
    Text = "Keep Script + Settings",
    Tooltip = "Re-injects script and restores your autoload config on new game/server",
    Default = false,
    Callback = function(Value) applyKeepScript(Value) end,
})

AimbotFOV:AddSlider("AimFOV", {
    Text = "Aimbot FOV", Default = 500, Min = 50, Max = 2000, Rounding = 0,
    Callback = function(Value) aimFOV = Value end,
})

AimbotFOV:AddToggle("SilentAimToggle", {
    Text = "Silent Aim", Default = false,
    Callback = function(Value) silentAimEnabled = Value end,
})

AimbotFOV:AddSlider("SilentAimHitchance", {
    Text = "Silent Aim Hitchance", Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = "%",
    Callback = function(Value) silentAimHitchance = Value end,
})

-- Aimbot Loop
connections["Aimbot"] = RunService:BindToRenderStep("Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local active = aimbotEnabled or aimbotKeyActive
    if not active then stickyTarget = nil return end

    local targetPlayer = nil
    if stickyAimEnabled and stickyTarget and isValidTarget(stickyTarget) then
        targetPlayer = stickyTarget
    else
        targetPlayer = getClosestPlayer(aimFOV)
        if stickyAimEnabled and targetPlayer then stickyTarget = targetPlayer end
    end

    if not targetPlayer or not targetPlayer.Character then stickyTarget = nil return end

    local targetPart = targetPlayer.Character:FindFirstChild(aimbotLock)
        or targetPlayer.Character:FindFirstChild("Head")
        or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local prediction = aimbotPrediction and (targetPart.AssemblyLinearVelocity * 0.13) or Vector3.zero
    local targetPos = targetPart.Position + prediction

    if aimbotMode == "Rage" or stickyAimEnabled then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    else
        local currentLook = Camera.CFrame.LookVector
        local targetLook = (targetPos - Camera.CFrame.Position).Unit
        local smooth = math.clamp(aimbotSensitivity * dt * 14, 0.01, 0.4)
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + currentLook:Lerp(targetLook, smooth))
    end
end)

-- Silent Aim hooks
safeCall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if silentAimEnabled and method == "Raycast" and math.random(100) <= silentAimHitchance then
            local closest = stickyTarget or getClosestPlayer(aimFOV)
            if closest and closest.Character then
                local part = closest.Character:FindFirstChild(aimbotLock) or closest.Character:FindFirstChild("Head")
                if part and #args >= 2 then
                    local origin = args[1]
                    local mag = (typeof(args[2]) == "Vector3") and args[2].Magnitude or 2000
                    args[2] = (part.Position - origin).Unit * mag
                end
            end
        end
        return oldNamecall(self, table.unpack(args))
    end)
    setreadonly(mt, true)
end)

-- TriggerBot
local triggerBotEnabled = false
local triggerBotDelay = 0
local triggerBotLastShot = 0

AimbotMain:AddToggle("TriggerBotToggle", {
    Text = "TriggerBot", Default = false,
    Callback = function(Value) triggerBotEnabled = Value end,
})

AimbotMain:AddSlider("TriggerBotDelay", {
    Text = "TriggerBot Delay", Default = 0, Min = 0, Max = 500, Rounding = 0, Suffix = "ms",
    Callback = function(Value) triggerBotDelay = Value / 1000 end,
})

local function fireWeapon()
    local char = getCharacter()
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then safeCall(function() tool:Activate() end) end
    end
    safeCall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.025)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
    safeCall(function() if mouse1click then mouse1click() end end)
end

connections["TriggerBot"] = RunService.Heartbeat:Connect(function()
    if not triggerBotEnabled then return end
    if tick() - triggerBotLastShot < triggerBotDelay then return end

    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector * 2000
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {getCharacter() or {}}
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

-- ═══════════════════════════════════════════════════════════════
-- HIGHLIGHTS + NAMETAGS ESP
-- ═══════════════════════════════════════════════════════════════
local highlightEnabled = false
local nametagEnabled = false
local highlightTeamCheck = false
local highlightFillAlpha = 0.55
local highlightEnemyColor = Color3.fromRGB(255, 60, 60)
local highlightTeamColor = Color3.fromRGB(60, 180, 255)
local highlightMaxDist = 0
local highlights = {}
local nametags = {}

local function cleanupESP(player)
    if highlights[player] then
        safeCall(function() highlights[player]:Destroy() end)
        highlights[player] = nil
    end
    if nametags[player] then
        safeCall(function() nametags[player]:Destroy() end)
        nametags[player] = nil
    end
end

local function ensureHighlight(player)
    if not highlights[player] then
        local hl = Instance.new("Highlight")
        hl.FillTransparency = highlightFillAlpha
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = false
        hl.Parent = Workspace
        highlights[player] = hl
    end
    return highlights[player]
end

local function ensureNametag(player)
    if not nametags[player] then
        local bill = Instance.new("BillboardGui")
        bill.Name = "jsiahNametag"
        bill.Size = UDim2.new(0, 200, 0, 40)
        bill.StudsOffset = Vector3.new(0, 3.2, 0)
        bill.AlwaysOnTop = true
        bill.Enabled = false

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Parent = bill

        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "DistLabel"
        distLabel.Size = UDim2.new(1, 0, 0.45, 0)
        distLabel.Position = UDim2.new(0, 0, 0.55, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextStrokeTransparency = 0.4
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextSize = 12
        distLabel.Parent = bill

        nametags[player] = bill
    end
    return nametags[player]
end

Players.PlayerRemoving:Connect(cleanupESP)

local VisualsLeft = Tabs.Visuals:AddLeftGroupbox("Highlights ESP")
local VisualsRight = Tabs.Visuals:AddRightGroupbox("Nametags / Colors")

VisualsLeft:AddToggle("HighlightToggle", {
    Text = "Enable Highlights",
    Default = false,
    Callback = function(Value)
        highlightEnabled = Value
        if not Value then
            for _, hl in pairs(highlights) do hl.Enabled = false end
        end
    end,
})

VisualsLeft:AddToggle("NametagToggle", {
    Text = "Enable Nametags",
    Default = false,
    Callback = function(Value)
        nametagEnabled = Value
        if not Value then
            for _, tag in pairs(nametags) do tag.Enabled = false end
        end
    end,
})

VisualsLeft:AddToggle("HighlightTeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(Value) highlightTeamCheck = Value end,
})

VisualsLeft:AddSlider("HighlightFillAlpha", {
    Text = "Fill Transparency", Default = 5.5, Min = 0, Max = 10, Rounding = 1,
    Callback = function(Value) highlightFillAlpha = Value / 10 end,
})

VisualsLeft:AddSlider("HighlightMaxDist", {
    Text = "Max Distance", Default = 0, Min = 0, Max = 3000, Rounding = 0, Suffix = " studs",
    Callback = function(Value) highlightMaxDist = Value end,
})

VisualsRight:AddDropdown("EnemyColor", {
    Values = {"Red", "Orange", "Yellow", "Purple", "White"},
    Default = 1, Multi = false, Text = "Enemy Color",
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
    Default = 1, Multi = false, Text = "Team Color",
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

connections["ESP"] = RunService.Heartbeat:Connect(function()
    if not highlightEnabled and not nametagEnabled then return end
    local myRoot = getRoot()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not char or not hum or not root or hum.Health <= 0 then
            if highlights[player] then highlights[player].Enabled = false end
            if nametags[player] then nametags[player].Enabled = false end
            continue
        end

        if highlightTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            if highlights[player] then highlights[player].Enabled = false end
            if nametags[player] then nametags[player].Enabled = false end
            continue
        end

        local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0
        if highlightMaxDist > 0 and dist > highlightMaxDist then
            if highlights[player] then highlights[player].Enabled = false end
            if nametags[player] then nametags[player].Enabled = false end
            continue
        end

        local isTeam = player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
        local color = isTeam and highlightTeamColor or highlightEnemyColor

        -- Highlight
        if highlightEnabled then
            local hl = ensureHighlight(player)
            hl.Adornee = char
            hl.FillColor = color
            hl.OutlineColor = color
            hl.FillTransparency = highlightFillAlpha
            hl.Enabled = true
        end

        -- Nametag
        if nametagEnabled then
            local tag = ensureNametag(player)
            tag.Adornee = head or root
            tag.Parent = char
            tag.Enabled = true

            local nameLabel = tag:FindFirstChild("NameLabel")
            local distLabel = tag:FindFirstChild("DistLabel")
            if nameLabel then
                nameLabel.Text = player.DisplayName or player.Name
                nameLabel.TextColor3 = color
            end
            if distLabel then
                distLabel.Text = math.floor(dist) .. " studs"
            end
        end
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

MovementLeft:AddToggle("WalkSpeedToggle", {
    Text = "WalkSpeed", Default = false,
    Callback = function(Value)
        walkSpeedEnabled = Value
        local hum = getHumanoid()
        if hum then
            if Value then captureOriginalSpeed() hum.WalkSpeed = walkSpeedValue
            else hum.WalkSpeed = originalWalkSpeed end
        end
    end,
})

MovementLeft:AddInput("WalkSpeedInput", {
    Default = "16", Numeric = true, Finished = true, Text = "WalkSpeed Value",
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

local flyEnabled = false
local flySpeed = 50
local flyBodyVelocity, flyBodyGyro

local function enableFly()
    local root = getRoot()
    if not root then return end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = root
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.P = 3000
    flyBodyGyro.Parent = root
end

local function disableFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

MovementLeft:AddToggle("FlyHackToggle", {
    Text = "Fly", Default = false,
    Callback = function(Value)
        flyEnabled = Value
        if Value then enableFly() else disableFly() end
    end,
})

MovementLeft:AddSlider("FlySpeed", {
    Text = "Fly Speed", Default = 50, Min = 10, Max = 1000, Rounding = 0,
    Callback = function(Value) flySpeed = Value end,
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
    if hum and hum.MoveDirection.Magnitude > 0.05 then move = move + hum.MoveDirection end

    flyBodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
    if flyBodyGyro then
        flyBodyGyro.CFrame = CFrame.new(root.Position, root.Position + Camera.CFrame.LookVector)
    end
end)

local infJumpConn
MovementRight:AddToggle("InfiniteJumpToggle", {
    Text = "Infinite Jump", Default = false,
    Callback = function(Value)
        if Value then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = getHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        elseif infJumpConn then
            infJumpConn:Disconnect()
            infJumpConn = nil
        end
    end,
})

local noClipEnabled = false
MovementRight:AddToggle("NoClipToggle", {
    Text = "NoClip", Default = false,
    Callback = function(Value) noClipEnabled = Value end,
})

connections["NoClip"] = RunService.Stepped:Connect(function()
    if not noClipEnabled then return end
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end)

local bunnyHopEnabled = false
MovementRight:AddToggle("BunnyHopToggle", {
    Text = "Bunny Hop", Default = false,
    Callback = function(Value) bunnyHopEnabled = Value end,
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
    Text = "Anti-Aim", Default = false,
    Callback = function(Value) antiAimEnabled = Value end,
})

ProtectionLeft:AddDropdown("AntiAimMode", {
    Values = {"Spin", "Jitter", "Random"}, Default = 1, Multi = false, Text = "Mode",
    Callback = function(Value) antiAimMode = Value end,
})

ProtectionLeft:AddSlider("AntiAimSpeed", {
    Text = "Spin Speed", Default = 12, Min = 1, Max = 60, Rounding = 0,
    Callback = function(Value) antiAimSpeed = Value end,
})

local forceThirdPerson = false
local originalCameraType, originalMaxZoom, originalMinZoom

ProtectionLeft:AddToggle("ForceThirdPerson", {
    Text = "Force Third Person", Default = false,
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
                root.CFrame = root.CFrame * CFrame.Angles(math.rad(math.random(-8, 8)), math.rad(math.random(-180, 180)), math.rad(math.random(-8, 8)))
            end
        end
    end
end)

-- ── Extras ───────────────────────────────────────────────────────────────
local ExtrasLeft = Tabs.Extras:AddLeftGroupbox("Performance")

ExtrasLeft:AddToggle("FPSBoostToggle", {
    Text = "FPS Boost", Default = false,
    Callback = function(Value)
        if Value then
            safeCall(function()
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        end
    end,
})

ExtrasLeft:AddButton("Fullbright", function()
    local lighting = game:GetService("Lighting")
    lighting.Brightness = 2
    lighting.ClockTime = 14
    lighting.FogEnd = 1e5
    lighting.GlobalShadows = false
    Library:Notify("Fullbright", 2)
end)

-- ── Overlay ──────────────────────────────────────────────────────────────
local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = "jsiahsOverlay"
OverlayGui.ResetOnSpawn = false
OverlayGui.IgnoreGuiInset = true
OverlayGui.DisplayOrder = 999
OverlayGui.Parent = PlayerGui

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.fromOffset(100, 38)
hideBtn.Position = UDim2.new(0, 20, 0, 90)
hideBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hideBtn.Text = "HIDE GUI"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 14
hideBtn.Parent = OverlayGui
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)

local guiVisible = true
hideBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    safeCall(function() if Library.Toggle then Library:Toggle() end end)
    hideBtn.Text = guiVisible and "HIDE GUI" or "SHOW GUI"
end)

-- ── UI Settings + Working Config System ──────────────────────────────────
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
local ConfigGroup = Tabs["UI Settings"]:AddRightGroupbox("Config System")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = false, Text = "Open Keybind Menu",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})

MenuGroup:AddDivider()
MenuGroup:AddButton("Unload", function() Library:Unload() end)
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", NoUI = true, Text = "Menu keybind",
})
Library.ToggleKeybind = Options.MenuKeybind

-- Custom Config UI
ConfigGroup:AddInput("ConfigName", {
    Default = "",
    Numeric = false,
    Finished = false,
    Text = "Config Name",
    Placeholder = "MyPreset",
})

ConfigGroup:AddButton("Save Config", function()
    local name = Options.ConfigName.Value
    if name == "" then
        Library:Notify("Enter a name first", 2)
        return
    end
    if saveConfig(name) then
        Library:Notify("Saved: " .. name, 2)
    else
        Library:Notify("Failed to save", 2)
    end
end)

ConfigGroup:AddButton("Load Config", function()
    local name = Options.ConfigName.Value
    if name == "" then
        Library:Notify("Enter a name first", 2)
        return
    end
    if loadConfig(name) then
        Library:Notify("Loaded: " .. name, 2)
    else
        Library:Notify("Config not found", 2)
    end
end)

ConfigGroup:AddButton("Delete Config", function()
    local name = Options.ConfigName.Value
    if name == "" then return end
    if deleteConfig(name) then
        Library:Notify("Deleted: " .. name, 2)
    end
end)

ConfigGroup:AddDivider()
ConfigGroup:AddButton("Set as Autoload", function()
    local name = Options.ConfigName.Value
    if name == "" then
        Library:Notify("Enter a name first", 2)
        return
    end
    saveConfig(name)
    setAutoload(name)
    Library:Notify("Autoload set to: " .. name, 3)
end)

ConfigGroup:AddButton("Clear Autoload", function()
    setAutoload(nil)
    Library:Notify("Autoload cleared", 2)
end)

ConfigGroup:AddLabel("Current Autoload: " .. (getAutoload() or "None"))

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("jsiahsAimbotV2")
ThemeManager:ApplyToTab(Tabs["UI Settings"])

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
    for player in pairs(highlights) do cleanupESP(player) end
    disableFly()
    if infJumpConn then infJumpConn:Disconnect() end
    if OverlayGui then OverlayGui:Destroy() end
    Library:Notify("jsiahs aimbot v2 hub unloaded", 3)
end)

Library:Notify("jsiahs aimbot v2 hub loaded — Config + Nametags ready", 4)
