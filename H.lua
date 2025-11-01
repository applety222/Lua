--// === VapeV4 Loader + Rival Hub + Full Features (Silent Aim, Aimbot, ESP, etc.) ===
local isfile = isfile or function(file)
	local suc, res = pcall(readfile, file)
	return suc and res ~= nil and res ~= ''
end

local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local commit = isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or 'main'
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/'..commit..'/'..path:gsub('newvape/', ''), true)
		end)
		if not suc or res == '404: Not Found' then
			error("Failed to download: "..path.." | "..(res or "Unknown"))
		end
		if path:find('.lua') then
			res = '--VapeWatermark\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) then
			local head = readfile(file):sub(1, 100)
			if head:find('--VapeWatermark') or head:find('--This watermark') then
				delfile(file)
			end
		end
	end
end

-- Create folders
for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/rival'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Update check
if not shared.VapeDeveloper then
	local _, page = pcall(game.HttpGet, game, 'https://github.com/7GrandDadPGN/VapeV4ForRoblox')
	local commit = page and page:match('currentOid.-([a-f0-9]+)') or 'main'
	commit = (#commit == 40 and commit) or 'main'
	local old = isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or ''
	if old ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
		writefile('newvape/profiles/commit.txt', commit)
	end
end

--// === RIVAL HUB CORE (Full Features: Silent Aim + More) ===
local Rival = {}
Rival.Settings = {
    SilentAim = {Enabled = true, FOV = 200, HitChance = 100, TargetPart = "Head", TeamCheck = true, VisibleCheck = false},
    Aimbot = {Enabled = false, Smoothness = 0.1},
    ESP = {Enabled = true, Boxes = true, Tracers = false, Distance = true},
    Movement = {Fly = false, Speed = 16, Noclip = false},
    Combat = {KillAura = false, AutoFarm = false}
}

-- Universal Silent Aim Module (Averiias 기반, Universal Raycast)
local function loadSilentAim()
    if isfile('newvape/rival/modules/silentaim.lua') then return end
    local silentAimCode = game:HttpGet('https://raw.githubusercontent.com/Averiias/Universal-SilentAim/main/SilentAim.lua')
    writefile('newvape/rival/modules/silentaim.lua', '--Rival Silent Aim\n' .. silentAimCode)
    loadstring(silentAimCode)()
    
    -- Settings Integration
    getgenv().SilentAimSettings = Rival.Settings.SilentAim
    -- FOV Circle (Visual)
    local fovCircle = Drawing.new("Circle")
    fovCircle.Radius = Rival.Settings.SilentAim.FOV
    fovCircle.Color = Color3.fromRGB(255, 0, 0)
    fovCircle.Thickness = 2
    fovCircle.NumSides = 30
    fovCircle.Filled = false
    fovCircle.Transparency = 1
    fovCircle.Visible = true
    fovCircle.Position = game.Players.LocalPlayer:GetMouse().Hit.Position
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if Rival.Settings.SilentAim.Enabled then
            fovCircle.Position = game.Players.LocalPlayer:GetMouse().Hit.Position
            fovCircle.Radius = Rival.Settings.SilentAim.FOV
        else
            fovCircle.Visible = false
        end
    end)
end

-- ESP Module (Universal)
local function loadESP()
    if isfile('newvape/rival/modules/esp.lua') then return end
    local espCode = [[
        local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/UI"))()
        ESP:Toggle(true)
        ESP.Boxes = true
        ESP.Tracers = ]] .. tostring(Rival.Settings.ESP.Tracers) .. [[
        ESP.Distances = ]] .. tostring(Rival.Settings.ESP.Distance) .. [[
    ]]
    writefile('newvape/rival/modules/esp.lua', '--Rival ESP\n' .. espCode)
    loadstring(espCode)()
end

-- Aimbot Module (Smooth Aiming)
local function loadAimbot()
    if isfile('newvape/rival/modules/aimbot.lua') then return end
    local aimbotCode = game:HttpGet('https://raw.githubusercontent.com/Exunys/Aimbot-Script/main/Aimbot.lua')
    writefile('newvape/rival/modules/aimbot.lua', '--Rival Aimbot\n' .. aimbotCode)
    loadstring(aimbotCode)()
    getgenv().AimbotSmoothness = Rival.Settings.Aimbot.Smoothness
end

-- Movement Modules (Fly, Speed, Noclip)
local function loadMovement()
    if isfile('newvape/rival/modules/movement.lua') then return end
    local moveCode = [[
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local Mouse = LocalPlayer:GetMouse()
        
        -- Fly
        local flySpeed = ]] .. Rival.Settings.Movement.Speed .. [[
        local flying = false
        local flyConnection
        Mouse.KeyDown:Connect(function(key)
            if key == "f" and Rival.Settings.Movement.Fly then
                flying = not flying
                if flying then
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    bodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
                    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                        local cam = workspace.CurrentCamera
                        local vel = bodyVelocity.Velocity
                        if flying then
                            vel = vel + (cam.CFrame.LookVector * flySpeed * (Mouse.KeyDown:connect(function(k) if k=="w" then vel = vel + cam.CFrame.LookVector * flySpeed end end) and 1 or 0))
                            -- Add other keys (a,d,s, space, etc.)
                        end
                        bodyVelocity.Velocity = vel
                    end)
                else
                    flyConnection:Disconnect()
                end
            end
        end)
        
        -- Speed
        if Rival.Settings.Movement.Speed > 16 then
            LocalPlayer.Character.Humanoid.WalkSpeed = Rival.Settings.Movement.Speed
        end
        
        -- Noclip
        if Rival.Settings.Movement.Noclip then
            local noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        end
    ]]
    writefile('newvape/rival/modules/movement.lua', '--Rival Movement\n' .. moveCode)
    loadstring(moveCode)()
end

-- Combat Modules (Kill Aura, Auto Farm)
local function loadCombat()
    if isfile('newvape/rival/modules/combat.lua') then return end
    local combatCode = [[
        -- Kill Aura
        if Rival.Settings.Combat.KillAura then
            local RunService = game:GetService("RunService")
            RunService.Heartbeat:Connect(function()
                for _, player in pairs(game.Players:GetPlayers()) do
                    if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local distance = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if distance < 10 then
                            -- Simulate attack (game-specific, e.g., tool:Activate())
                            if game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") then
                                game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):Activate()
                            end
                        end
                    end
                end
            end)
        end
        
        -- Auto Farm (Universal: Collect items)
        if Rival.Settings.Combat.AutoFarm then
            local RunService = game:GetService("RunService")
            RunService.Heartbeat:Connect(function()
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Part") and obj.Name:find("Coin") or obj.Name:find("Gem") then  -- Game-specific
                        obj.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end)
        end
    ]]
    writefile('newvape/rival/modules/combat.lua', '--Rival Combat\n' .. combatCode)
    loadstring(combatCode)()
end

-- Load All Modules
loadSilentAim()
loadESP()
loadAimbot()
loadMovement()
loadCombat()

--// === Rival GUI (Integrated with Vape) ===
if not isfile('newvape/rival/ui/gui.lua') then
    local guiCode = game:HttpGet('https://raw.githubusercontent.com/rbxdest/catalog/main/gui.lua')  -- Simple GUI lib (e.g., Kavo UI)
    writefile('newvape/rival/ui/gui.lua', '--Rival GUI\n' .. guiCode)
end
local RivalGUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/rbxdest/catalog/main/gui.lua'))()

local Window = RivalGUI:CreateLib("Rival Hub + Vape", "DarkTheme")

-- Silent Aim Tab
local SilentTab = Window:NewTab("Silent Aim")
local SilentSection = SilentTab:NewSection("Settings")
SilentSection:NewToggle("Enabled", "Toggle Silent Aim", function(state)
    Rival.Settings.SilentAim.Enabled = state
end)
SilentSection:NewSlider("FOV", "Field of View", 200, 50, function(s)
    Rival.Settings.SilentAim.FOV = s
end)
SilentSection:NewSlider("HitChance", "Hit Chance %", 100, 0, function(s)
    Rival.Settings.SilentAim.HitChance = s
end)
SilentSection:NewDropdown("TargetPart", "Target Part", {"Head", "HumanoidRootPart", "Random"}, function(current)
    Rival.Settings.SilentAim.TargetPart = current
end)
SilentSection:NewToggle("TeamCheck", "Team Check", function(state)
    Rival.Settings.SilentAim.TeamCheck = state
end)

-- Aimbot Tab
local AimbotTab = Window:NewTab("Aimbot")
local AimbotSection = AimbotTab:NewSection("Settings")
AimbotSection:NewToggle("Enabled", "Toggle Aimbot", function(state)
    Rival.Settings.Aimbot.Enabled = state
end)
AimbotSection:NewSlider("Smoothness", "Smoothness", 0.1, 0.01, function(s)
    Rival.Settings.Aimbot.Smoothness = s
end)

-- ESP Tab
local ESPTab = Window:NewTab("ESP")
local ESPSection = ESPTab:NewSection("Settings")
ESPSection:NewToggle("Enabled", "Toggle ESP", function(state)
    Rival.Settings.ESP.Enabled = state
    loadESP()  -- Reload
end)
ESPSection:NewToggle("Boxes", "Show Boxes", function(state)
    Rival.Settings.ESP.Boxes = state
end)

-- Movement Tab
local MoveTab = Window:NewTab("Movement")
local MoveSection = MoveTab:NewSection("Settings")
MoveSection:NewToggle("Fly", "Toggle Fly (F Key)", function(state)
    Rival.Settings.Movement.Fly = state
    loadMovement()
end)
MoveSection:NewSlider("Speed", "Walk Speed", 16, 100, function(s)
    Rival.Settings.Movement.Speed = s
    loadMovement()
end)
MoveSection:NewToggle("Noclip", "Toggle Noclip", function(state)
    Rival.Settings.Movement.Noclip = state
    loadMovement()
end)

-- Combat Tab
local CombatTab = Window:NewTab("Combat")
local CombatSection = CombatTab:NewSection("Settings")
CombatSection:NewToggle("KillAura", "Toggle Kill Aura", function(state)
    Rival.Settings.Combat.KillAura = state
    loadCombat()
end)
CombatSection:NewToggle("AutoFarm", "Toggle Auto Farm", function(state)
    Rival.Settings.Combat.AutoFarm = state
    loadCombat()
end)

--// === Load Vape Main (Merged with Rival) ===
local VapeMain = downloadFile('newvape/main.lua')
-- Merge: Add Rival to Vape's shared (GUI 병합 가정)
shared.Rival = Rival
loadstring(VapeMain)()

print("Rival Hub + Silent Aim Loaded! Use GUI to toggle features.")
