--[[
This script was made with Claude, so I'm keeping it open-source.
You can use parts of it, but if possible, please don't just change the name and claim it's yours. 🙂
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if player.Team == nil then
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Marines")
    end)
    task.wait(2)
end

local utilitiesUrl = "https://raw.githubusercontent.com/Axlkz/scripts/refs/heads/main/Utilities/"

local function loadRemote(p, value)
    local current = nil
    for i = 1, 3 do
        local success, result = pcall(function()
            return game:HttpGet(p)
        end)
        if success and type(result) == "string" and #result > 0 then
            current = result
            break
        end
        task.wait(1)
    end

    if not current then
        if value then
            error("Axl Hub: could not download " .. p)
        end
        warn("Axl Hub: could not download " .. p)
        return function() end
    end

    local loadstring2, value2 = loadstring(current)
    if not loadstring2 then
        if value then
            error("Axl Hub: could not load " .. p .. " (" .. tostring(value2) .. ")")
        end
        warn("Axl Hub: could not load " .. p .. " (" .. tostring(value2) .. ")")
        return function() end
    end

    return loadstring2
end

local libraryUrls = {
    "https://pastefy.app/yntfqpyZ/raw",
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua",
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua",
}
local libraryResults = {}
local pendingLibraries = #libraryUrls

for i, url in ipairs(libraryUrls) do
    task.spawn(function()
        local success, result = pcall(loadRemote, url, true)
        libraryResults[i] = { ok = success, compiled = result }
        pendingLibraries -= 1
    end)
end

while pendingLibraries > 0 do
    task.wait()
end

for i, result in ipairs(libraryResults) do
    if not result or not result.ok or type(result.compiled) ~= "function" then
        error("Axl Hub: failed to load required UI library #" .. tostring(i))
    end
end

local Fluent, SaveManager, InterfaceManager = libraryResults[1].compiled(), libraryResults[2].compiled(), libraryResults[3].compiled()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

do
    local localPlayer = Players.LocalPlayer

    task.spawn(function()
        local waitForChild = localPlayer:WaitForChild("PlayerGui"):WaitForChild("Notifications", 30)
        if not waitForChild then return end
        waitForChild.ChildAdded:Connect(function(value)
            task.defer(function()
                if value:IsA("TextLabel") and value.Text:lower():find("fish", 1, true) then
                    value:Destroy()
                end
            end)
        end)
    end)

    pcall(function()
        local value;value = hookmetamethod(game, "__namecall", newcclosure(function(value2, ...)
            local namecallmethod = getnamecallmethod()

            if namecallmethod == "Destroy" and tostring(value2) == "PlayerGui" then
                return warn("Override PlayerGui:", namecallmethod)
            end

            if namecallmethod == "Emit" and value2:IsA("ParticleEmitter") then
                return value(value2, 1)
            end

            return value(value2, ...)
        end))
    end)
end

local localPlayer = Players.LocalPlayer
local value = ReplicatedStorage

local loopDelay = 1
local autoBuso = true
local lockedPosition = nil
local bringMobsEnabled = true
local farmHeight = 15

local placeId = game.PlaceId
local isSea1 = (placeId == 2753915549 or placeId == 85211729168715)
local isSea2 = (placeId == 4442272183 or placeId == 79091703265657)
local isSea3 = (placeId == 7449423635 or placeId == 100117331123089)

_G.RaceClickAutov3 = false
_G.RaceClickAutov4 = false
_G.OtherAutoAttack = true
_G.OtherDoubleAttack = false
_G.SelectWeapon = "Melee"
_G.UseDragonstorm = false
_G.StartFarm = false
_G.AutoFarm_Bone = false
_G.AutoFarm_Cake = false
_G.Level = false
_G.AcceptQuest = false
_G.IgnoreBoss = false
_G.AutoBerry = false
_G.FarmEliteHunt = false
_G.AutoTyrant = false
_G.AutoFarmChest = false
_G.AutoBoss = false
_G.FarmAllBoss = false
_G.AutoRipIndra = false
_G.AutoFactory = false
_G.AutoRaidCastle = false
_G.AutoDarkbeard = false
_G.AutoCursedCaptain = false
_G.Auto_Random_Bone = false
_G.AutoHytHallow = false
_G.AutoMasterySwords = false
_G.AutoTushita = false
_G.AutoYama = false

_G.SelectChip = "Flame"
_G.AutoRaid = false
_G.AutoGrabCheapFruits = false
_G.KillH = false
_G.Auto_Awakener = false
_G.RemoveDamage = false

_G.TweenIsland = false
_G.TPNpc = false

_G.AutoLawKak = false
_G.Tp_MasterA = false
_G.AutoBuyStyle = false

getgenv().OnFarm = false
getgenv().AutoMaterial = false
getgenv().SelectMaterial = nil

local function facingCFrame(target, target2)
    local position = target.Position
    local lookVector = target.LookVector
    local position2 = Vector3.new(lookVector.X, 0, lookVector.Z)
    if position2.Magnitude < 0.05 then
        local new = target2 and target2.CFrame.LookVector or Vector3.new(0, 0, -1)
        position2 = Vector3.new(new.X, 0, new.Z)
        if position2.Magnitude < 0.05 then
            position2 = Vector3.new(0, 0, -1)
        end
    end
    return CFrame.new(position, position + position2.Unit)
end

local function resetVelocity(target)
    if not target then return end
    target.CFrame = facingCFrame(target.CFrame, target)
    target.AssemblyAngularVelocity = Vector3.zero
    target.AssemblyLinearVelocity = Vector3.zero
end

local collisionParts = { Head = true, UpperTorso = true, LowerTorso = true, Torso = true }

local function restoreCollision(value2)
    if not value2 then return end
    for index, item in ipairs(value2:GetChildren()) do
        if item:IsA("BasePart") and collisionParts[item.Name] then
            item.CanCollide = true
        end
    end
end

getgenv().TweenManager = {
    currentTween = nil,
    currentPart = nil,
    currentGoal = nil,
    TweenRunning = false,
    CancelTweenOnly = function()
        local activeTween = TweenManager.currentTween
        if activeTween then
            pcall(function()
                activeTween:Cancel()
                activeTween:Destroy()
            end)
        end
        TweenManager.currentTween = nil
        TweenManager.currentPart = nil
        TweenManager.currentGoal = nil
        TweenManager.TweenRunning = false
        getgenv().Tween = nil
    end,
    PlayTween = function(value2, value3, target, value4)
        if not value2 or not value3 or not target or not target.CFrame then
            return
        end
        local targetEpsilon = (value4 or {}).TargetEpsilon or 12
        if TweenManager.currentTween and TweenManager.currentPart == value2 and TweenManager.currentGoal and targetEpsilon >= (TweenManager.currentGoal.Position - target.CFrame.Position).Magnitude then
            return TweenManager.currentTween
        end
        TweenManager.CancelTweenOnly()
        local tween = TweenService:Create(value2, value3, target)
        TweenManager.currentTween = tween
        TweenManager.currentPart = value2
        TweenManager.currentGoal = target.CFrame
        TweenManager.TweenRunning = true
        getgenv().Tween = tween
        tween.Completed:Connect(function()
            if TweenManager.currentTween == tween then
                TweenManager.currentTween = nil
                TweenManager.currentPart = nil
                TweenManager.currentGoal = nil
                TweenManager.TweenRunning = false
                getgenv().Tween = nil
                pcall(function() tween:Destroy() end)
            end
        end)
        tween:Play()
        return tween
    end,
    CancelCurrent = function()
        local character = Players.LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if TweenManager.currentTween or getgenv().Tween or (rootPart and rootPart:FindFirstChild("FloatForce")) then
            TweenManager.CancelTweenOnly()
            pcall(function()
                if not character then return end
                restoreCollision(character)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
                if rootPart and rootPart:FindFirstChild("FloatForce") then
                    rootPart.FloatForce:Destroy()
                end
                if rootPart then
                    resetVelocity(rootPart)
                end
            end)
        end
    end,
}
local TweenControl = getgenv().TweenManager

local currentTarget = nil

local farmPaused = true

local function isFarming(combatOnly)
    if farmPaused then return false end
    if _G.StartFarm and (_G.AutoFarm_Bone or _G.AutoFarm_Cake or _G.Level or _G.AutoTyrant) then
        return true
    end
    if getgenv().AutoMaterial then return true end
    if _G.AutoRaid then return true end
    if _G.FarmEliteHunt then return true end
    if _G.TweenIsland or _G.TPNpc or _G.FishingTp then return true end
    if _G.TpPly then return true end
    if _G.AutoLawKak or _G.Tp_MasterA then return true end
    if _G.AutoBuyStyle then return true end
    if _G.AutoFarmChest then return true end
    if _G.AutoBoss or _G.FarmAllBoss then return true end
    if _G.AutoRipIndra or _G.AutoDarkbeard or _G.AutoCursedCaptain then return true end
    if _G.AutoFactory or _G.AutoRaidCastle then return true end
    if _G.AutoHytHallow then return true end
    if _G.AutoMasterySwords then return true end
    if _G.FarmMastery_Dev or _G.FarmMastery_G then return true end
    if _G.SeaFarm2 or _G.SeaFarm3 then return true end
    if _G.AutoTushita then return true end
    if _G.AutoYama then return true end
    if not combatOnly and (_G.AutoAfkJoinFruit or _G.AutoCollectFruit or _G.AutoBerry) then return true end
    if _G.AutoTtk then return true end
    return false
end

local function stopFarming()
    getgenv().OnFarm = false
    currentTarget = nil
    lockedPosition = nil
    TweenControl.CancelTweenOnly()
    local character = Players.LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if rootPart then
        for index, item in ipairs(rootPart:GetChildren()) do
            if item.Name == "FloatForce" then
                item:Destroy()
            end
        end
        rootPart.Anchored = false
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        resetVelocity(rootPart)
    end
    restoreCollision(character)
    if humanoid then
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

_tp = function(target)
    if not isFarming() then return end

    local localPlayer2 = Players.LocalPlayer
    local character = localPlayer2.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")

    if humanoid and humanoid.Sit then
        humanoid.Jump = true
        humanoid.Sit = false
        task.wait(.1)
    end

    if not isFarming() then return end

    getgenv().OnFarm = true

    local value2 = typeof(target) == "CFrame" and target.Position or target
    local new = typeof(target) == "CFrame" and target or CFrame.new(value2)
    new = facingCFrame(new, humanoidRootPart)

    if not humanoidRootPart:FindFirstChild("FloatForce") then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FloatForce"
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = humanoidRootPart
    end

    local position = Vector3.new(11538.599609375, -2154.7021484375, 9827.3125)

    if isSea3 and (value2 - position).Magnitude <= 3000 and (position - humanoidRootPart.Position).Magnitude > 3000 then
        local cframe = CFrame.new(
            -16269.4082, 23.9799957, 1371.66235,
            -0.999388933, 0, -0.0349550731,
            0, 1, 0,
            0.0349550731, 0, -0.999388933
        )
        local distance = (cframe.Position - humanoidRootPart.Position).Magnitude
        if distance < 8 then
            game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer(unpack({ [1] = "TravelToSubmergedIsland" }))
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack({ [1] = "SetLastSpawnPoint", [2] = "SubmergedIsland" }))
            TweenControl.CancelCurrent()
        else
            local value3 = distance / 170
            TweenControl.PlayTween(humanoidRootPart, TweenInfo.new(value3, Enum.EasingStyle.Linear), { CFrame = cframe })
        end
        return
    end

    if isSea3 and (value2 - position).Magnitude > 3000 and (position - humanoidRootPart.Position).Magnitude <= 3000 then
        local cframe = CFrame.new(
            11427.9189, -2156.36401, 9726.24023,
            -0.929097056, -7.17796156E-34, 0.369835705,
            -7.17796156E-34, 1, 1.37611875E-34,
            -0.369835705, -1.37611875E-34, -0.929097056
        )
        local distance = (cframe.Position - humanoidRootPart.Position).Magnitude
        if distance < 8 then
            game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineTransportation"):InvokeServer(unpack({ [1] = "GetAvailableLocations" }))
            game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/SubmarineTransportation"):InvokeServer(unpack({ [1] = "InitiateTeleport", [2] = "Tiki Outpost" }))
            TweenControl.CancelCurrent()
        else
            local value3 = distance / 170
            TweenControl.PlayTween(humanoidRootPart, TweenInfo.new(value3, Enum.EasingStyle.Linear), { CFrame = cframe })
        end
        return
    end

    local distance = (value2 - humanoidRootPart.Position).Magnitude
    if distance <= 15 then
        TweenControl.CancelCurrent()
        humanoidRootPart.CFrame = new
        return
    end

    local amount = 170
    local value2 = distance / amount

    TweenControl.PlayTween(humanoidRootPart, TweenInfo.new(value2, Enum.EasingStyle.Linear), { CFrame = new })
end

local function equipWeaponType(value2)
    local character = localPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local function helper(value3)
        if value2 == "Fruit" then
            return value3.ToolTip == "Blox Fruit"
        end
        return value3:GetAttribute("WeaponType") == value2
    end

    local tool = character:FindFirstChildOfClass("Tool")
    if tool and helper(tool) then return true end

    for index, item in ipairs(localPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and helper(item) then
            humanoid:EquipTool(item)
            break
        end
    end
    return false
end

local function equipToolByName(value2)
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if character:FindFirstChild(value2) then return end
    local firstChild = localPlayer.Backpack:FindFirstChild(value2)
    if firstChild then
        humanoid:EquipTool(firstChild)
        local startTime = tick()
        repeat
            task.wait()
        until character:FindFirstChild(value2) or tick() - startTime > 1
    end
end

local toggleDebounce = {}

local function guardToggle(value2, value3, value4, value5)
    return function(value6)
        if toggleDebounce[value2] then return end

        if value6 == true and not value3 then

            if farmPaused then return end

            Fluent:Notify({ Title = "Axl Hub", Content = value4, Duration = 5 })
            toggleDebounce[value2] = true
            pcall(function() Fluent.Options[value2]:SetValue(false) end)
            task.delay(0.3, function() toggleDebounce[value2] = nil end)
            return
        end

        value5(value6)
    end
end

local function syncFarmMode()
    local options = Fluent.Options
    local value2 = options.Character and options.Character.Value
    local value3 = options.StartFarm and options.StartFarm.Value

    if value3 and (value2 == "Farm Bone" or value2 == "Farm Katakuri" or value2 == "Farm Tyrant") and not isSea3 then
        Fluent:Notify({ Title = "Axl Hub", Content = value2 .. " only works in Sea 3", Duration = 5 })
        value3 = false
        task.defer(function()
            pcall(function() Fluent.Options.StartFarm:SetValue(false) end)
        end)
    end

    _G.StartFarm = value3
    _G.AutoFarm_Bone = false
    _G.AutoFarm_Cake = false
    _G.Level = false
    _G.AutoTyrant = false
    if value3 then
        if value2 == "Farm Bone" then
            _G.AutoFarm_Bone = true
        elseif value2 == "Farm Katakuri" then
            _G.AutoFarm_Cake = true
        elseif value2 == "Farm Level" then
            _G.Level = true
        elseif value2 == "Farm Tyrant" then
            _G.AutoTyrant = true
        end
    else
        if not isFarming() then
            stopFarming()
        end
    end
end

local Mob = {}
Mob.__index = Mob

Mob.Alive = function(target)
    if not target then return false end
    local humanoid = target:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function findEnemyByName(value2)
    local list = { value, Workspace:FindFirstChild("Enemies") }
    for index, item in ipairs(list) do
        for index, item2 in ipairs(item:GetChildren()) do
            if item2:IsA("Model") and item2.Name == value2 and Mob.Alive(item2) and item2:FindFirstChild("HumanoidRootPart") then
                return item2
            end
        end
    end
    return nil
end

local function lookAtCFrame(value2, value3)
    local position = Vector3.new(value3.X, value2.Y, value3.Z)
    if (position - value2).Magnitude < 0.1 then
        position = value2 + Vector3.new(0, 0, 1)
    end
    return CFrame.new(value2, position)
end

local function zeroVelocity(value2)
    local character = Players.LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            rootPart.Velocity = Vector3.zero
            rootPart.RotVelocity = Vector3.zero
        end
    end
end

Mob.Kill = function(value2, value3, value4)
    if value2 and value3 then
        if currentTarget ~= value2 then
            currentTarget = value2
            if value2:GetAttribute("Locked") then
                value2:SetAttribute("Locked", nil)
            end
        end
        if not value2 or not value2:FindFirstChild("Humanoid") or value2.Humanoid.Health <= 0 then
            currentTarget = nil
            return
        end
        if not value2:GetAttribute("Locked") then
            value2:SetAttribute("Locked", value2.HumanoidRootPart.CFrame)
        end
        lockedPosition = (value2:GetAttribute("Locked")).Position

        local value3
        if value4 then
            value3 = value4
        else
            local position = value2.HumanoidRootPart.Position
            local new = position + Vector3.new(0, farmHeight, 0)
            value3 = lookAtCFrame(new, position)
        end

        zeroVelocity(value3)
        if _tp then _tp(value3) end
    end
end

localPlayer.CharacterAdded:Connect(function(value2)
    value2:WaitForChild("HumanoidRootPart", 5)
    TweenControl.CancelCurrent()
    currentTarget = nil
    lockedPosition = nil
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if isFarming() then return end
            local character = Players.LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if getgenv().OnFarm or TweenControl.TweenRunning or (rootPart and rootPart:FindFirstChild("FloatForce")) then
                stopFarming()
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local map = Workspace:FindFirstChild("Map")
            if map and map:FindFirstChild("WaterBase-Plane") then
                map["WaterBase-Plane"].Size = Vector3.new(1000, 112, 1000)
            end
        end)
    end
end)

local Window = Fluent:CreateWindow({
    Title = "Axl Hub",
    SubTitle = "Blox Fruit",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

_G.AxlKeyGuard = 0

local originalMinimize
pcall(function()
    local minimize = Window.Minimize
    originalMinimize = minimize
    Window.Minimize = function(value2, ...)
        if (_G.AxlKeyGuard or 0) > 0 then return end
        return minimize(value2, ...)
    end
end)

do
    local BUTTON_SIZE = 38

    local parentGui
    pcall(function()
        parentGui = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not parentGui then
        parentGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local oldGui = parentGui:FindFirstChild("AxlToggleButton")
    if oldGui then oldGui:Destroy() end

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "AxlToggleButton"
    toggleGui.ResetOnSpawn = false
    toggleGui.DisplayOrder = 999
    toggleGui.IgnoreGuiInset = true
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(toggleGui) end
    end)
    toggleGui.Parent = parentGui

    local button = Instance.new("ImageButton")
    button.Name = "Toggle"
    button.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
    button.Position = UDim2.new(0, 20, 0.5, -BUTTON_SIZE / 2)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.AutoButtonColor = false
    button.Image = ""
    button.BorderSizePixel = 0
    button.ClipsDescendants = true
    button.Parent = toggleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    button.ClipsDescendants = false

    local baseGradient = Instance.new("UIGradient")
    baseGradient.Rotation = 50
    baseGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(6, 0, 0)),
        ColorSequenceKeypoint.new(0.62, Color3.fromRGB(170, 12, 12)),
        ColorSequenceKeypoint.new(0.82, Color3.fromRGB(35, 2, 2)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    baseGradient.Parent = button

    local swirl = Instance.new("Frame")
    swirl.Name = "Swirl"
    swirl.AnchorPoint = Vector2.new(0.5, 0.5)
    swirl.Position = UDim2.fromScale(0.6, 0.62)
    swirl.Size = UDim2.fromScale(0.6, 0.6)
    swirl.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
    swirl.BorderSizePixel = 0
    swirl.Active = false
    swirl.Parent = button
    local swirlCorner = Instance.new("UICorner")
    swirlCorner.CornerRadius = UDim.new(1, 0)
    swirlCorner.Parent = swirl
    local swirlGradient = Instance.new("UIGradient")
    swirlGradient.Rotation = 90
    swirlGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    swirlGradient.Parent = swirl

    local gloss = Instance.new("Frame")
    gloss.Name = "Gloss"
    gloss.AnchorPoint = Vector2.new(0.5, 0)
    gloss.Position = UDim2.fromScale(0.5, 0.1)
    gloss.Size = UDim2.fromScale(0.55, 0.28)
    gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gloss.BorderSizePixel = 0
    gloss.Active = false
    gloss.Parent = button
    local glossCorner = Instance.new("UICorner")
    glossCorner.CornerRadius = UDim.new(1, 0)
    glossCorner.Parent = gloss
    local glossGradient = Instance.new("UIGradient")
    glossGradient.Rotation = 90
    glossGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 1),
    })
    glossGradient.Parent = gloss

    local function toggleUI()
        if originalMinimize then
            pcall(originalMinimize, Window)
        else
            pcall(function() Window:Minimize() end)
        end
    end

    local UserInputService = game:GetService("UserInputService")
    local dragging, dragStart, startPos, moved = false, nil, nil, false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = button.Position
            TweenService:Create(button, TweenInfo.new(0.1), {
                Size = UDim2.fromOffset(BUTTON_SIZE - 4, BUTTON_SIZE - 4)
            }):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            if moved then
                button.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(button, TweenInfo.new(0.1), {
                Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
            }):Play()
            if not moved then
                toggleUI()
            end
        end
    end)
end

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "rbxassetid://10734964441" }),
    Main = Window:AddTab({ Title = "Main", Icon = "rbxassetid://127561653320876" }),
    Stack = Window:AddTab({ Title = "Stack Farming", Icon = "rbxassetid://72448332143088" }),
    Raid = Window:AddTab({ Title = "Raid/Fruit", Icon = "rbxassetid://10709790875" }),
    Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "rbxassetid://10734975692" }),
    Fish = Window:AddTab({ Title = "Fish", Icon = "rbxassetid://127664059821666" }),
    Sea = Window:AddTab({ Title = "Sea Event", Icon = "rbxassetid://10747376931" }),
    Hop = Window:AddTab({ Title = "Hop", Icon = "rbxassetid://10734975486" }),
    Travel = Window:AddTab({ Title = "Travel", Icon = "rbxassetid://10734886004" }),
    LocalPlayer = Window:AddTab({ Title = "Local Player", Icon = "rbxassetid://98870151777863" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "rbxassetid://10734952479" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "rbxassetid://10734950309" })
}

local Options = Fluent.Options

do
    Tabs.Home:AddDiscord({
        Title = "Axl Hub",
        Link = "https://discord.gg/GgVsYM4YXj",
        Banner = "105433178320583",
        Icon = "93955881747961",
        Description = "Official Server",
        Button = "Join Discord"
    })
end

do
    Tabs.Main:AddSection("Farming System")

    local characterDropdown = Tabs.Main:AddDropdown("Character", {
        Title = "Method Farm",
        Description = "Select your method",
        Values = { "Farm Level", "Farm Bone", "Farm Katakuri", "Farm Tyrant" },
        Multi = false,
        Default = 1,
    })

    characterDropdown:OnChanged(function(value2)
        syncFarmMode()
    end)

    local startFarmToggle = Tabs.Main:AddToggle("StartFarm", {
        Title = "Start Farm",
        Description = "Start the farming system",
        Default = false
    })

    startFarmToggle:OnChanged(function()
        syncFarmMode()
    end)

    Tabs.Main:AddToggle("AcceptQuest", {
        Title = "Accept Quest",
        Description = "Takes the quest, kills the mobs and takes it again when finished (Bone, Katakuri, Tyrant; Farm Level always uses quests)",
        Default = false
    }):OnChanged(guardToggle("AcceptQuest", isSea3, "Accept Quest only works in Sea 3", function(value2)
        _G.AcceptQuest = value2
    end))

    Tabs.Main:AddToggle("IgnoreBoss", {
        Title = "Ignore Boss Katakuri/Tyrant",
        Description = "Keeps farming only the mobs: Katakuri is not spawned and Tyrant is ignored (even if already alive)",
        Default = false
    }):OnChanged(guardToggle("IgnoreBoss", isSea3, "Ignore Boss Katakuri/Tyrant only works in Sea 3", function(value2)
        _G.IgnoreBoss = value2
    end))

    Tabs.Main:AddSection("Factory & Raid Pirate")

    Tabs.Main:AddToggle("AutoFactory", {
        Title = "Auto Factory",
        Description = "Goes to the Factory and kills the Core (Sea 2)",
        Default = false
    }):OnChanged(guardToggle("AutoFactory", isSea2, "Auto Factory only works in Sea 2", function(value2)
        _G.AutoFactory = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    Tabs.Main:AddToggle("AutoRaidPirate", {
        Title = "Auto Raid Pirate",
        Description = "Defends the castle and kills the raid pirates (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoRaidPirate", isSea3, "Auto Raid Pirate only works in Sea 3", function(value2)
        _G.AutoRaidCastle = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    task.spawn(function()
        local cframe = CFrame.new(448.46756, 199.356781, -441.389252)
        while task.wait(loopDelay) do
            if _G.AutoFactory then
                pcall(function()
                    local f12130 = findEnemyByName("Core")
                    if f12130 and f12130:FindFirstChild("Humanoid") and f12130.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            if not _G.AutoFactory or not f12130.Parent then break end
                            equipWeaponType(_G.SelectWeapon)
                            _tp(cframe)
                        until f12130.Humanoid.Health <= 0 or not _G.AutoFactory
                    else
                        _tp(cframe)
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        local cframe = CFrame.new(-5496.17432, 313.768921, -2841.53027, .924894512, 7.37058015e-009, .380223751, 3.5881019e-008, 1, -1.06665446e-007, -0.380223751, 1.12297109e-007, .924894512)
        local cframe2 = CFrame.new(-5539.3115234375, 313.80053710938, -2972.3723144531)
        local list = {
            "Galley Pirate", "Galley Captain", "Raider", "Mercenary", "Vampire", "Zombie",
            "Snow Trooper", "Winter Warrior", "Lab Subordinate", "Horned Warrior", "Magma Ninja", "Lava Pirate",
            "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer", "Arctic Warrior", "Snow Lurker",
            "Sea Soldier", "Water Fighter",
        }
        while task.wait(loopDelay) do
            if _G.AutoRaidCastle then
                pcall(function()
                    local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end

                    if (cframe2.Position - rootPart.Position).Magnitude <= 500 then
                        for index, item in ipairs(Workspace.Enemies:GetChildren()) do
                            if not _G.AutoRaidCastle then break end
                            if item:FindFirstChild("HumanoidRootPart") and item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 then
                                if (item.HumanoidRootPart.Position - rootPart.Position).Magnitude <= 2000 then
                                    repeat
                                        task.wait()
                                        Mob.Kill(item, _G.AutoRaidCastle)
                                    until not _G.AutoRaidCastle or not item.Parent or not item:FindFirstChild("Humanoid") or item.Humanoid.Health <= 0
                                end
                            end
                        end
                    else
                        for index, item in ipairs(value:GetChildren()) do
                            if table.find(list, item.Name) then
                                _tp(cframe)
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    Tabs.Main:AddSection("Collect")

    Tabs.Main:AddToggle("AutoCollectChest", {
        Title = "Auto Collect Chest",
        Description = "Tweens to the nearest chest and collects it",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoFarmChest = value2
        if not value2 and not isFarming() then stopFarming() end
    end)

    task.spawn(function()
        local CollectionService = game:GetService("CollectionService")
        while task.wait(0.2) do
            if _G.AutoFarmChest then
                pcall(function()
                    local character = localPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end
                    local current, huge = nil, math.huge
                    for index, item in ipairs(CollectionService:GetTagged("_ChestTagged")) do
                        if not item:GetAttribute("IsDisabled") then
                            local distance = (item:GetPivot().Position - rootPart.Position).Magnitude
                            if distance < huge then
                                huge = distance
                                current = item
                            end
                        end
                    end
                    if current then
                        _tp(current:GetPivot())
                    end
                end)
            end
        end
    end)
    Tabs.Main:AddSection("Berry")

    Tabs.Main:AddToggle("AutoCollectBerry", {
        Title = "Auto Collect Berry",
        Description = "Collects every berry bush on the whole map, any berry type",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoBerry = value2
        if not value2 and not isFarming() then stopFarming() end
    end)

    task.spawn(function()
        local CollectionService = game:GetService("CollectionService")
        local visited = {}

        local function goTo(cframe, closeEnough, maxTime)
            local startTime = tick()
            repeat
                if not _G.AutoBerry then return false end
                local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return false end
                if (rootPart.Position - cframe.Position).Magnitude <= closeEnough then return true end
                _tp(cframe)
                task.wait(0.1)
            until tick() - startTime > maxTime
            return false
        end

        local function hasInteraction(item)
            return item:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
                or item:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
        end

        local VirtualInputManager = game:GetService("VirtualInputManager")

        local function promptCFrame(prompt, fallback)
            local parent = prompt.Parent
            if parent then
                if parent:IsA("BasePart") then return parent.CFrame end
                if parent:IsA("Attachment") then return parent.WorldCFrame end
                if parent:IsA("PVInstance") then return parent:GetPivot() end
            end
            return fallback
        end

        local function promptStillThere(prompt)
            return prompt.Parent ~= nil and prompt:IsDescendantOf(Workspace) and prompt.Enabled
        end

        local function collectBerry(berry)
            local prompt = berry:FindFirstChildWhichIsA("ProximityPrompt", true)
            local clicker = berry:FindFirstChildWhichIsA("ClickDetector", true)
            local fallback = berry:IsA("PVInstance") and berry:GetPivot() or nil

            if prompt then
                local target = promptCFrame(prompt, fallback)
                if target and not goTo(target, 4, 8) then return end

                pcall(function()
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 30)
                end)

                if fireproximityprompt then
                    pcall(fireproximityprompt, prompt)
                    task.wait(0.15)
                end

                if promptStillThere(prompt) then
                    local key = prompt.KeyboardKeyCode
                    if key == Enum.KeyCode.Unknown then key = Enum.KeyCode.E end
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, key, false, game)
                        task.wait(0.15)
                        VirtualInputManager:SendKeyEvent(false, key, false, game)
                    end)
                    task.wait(0.15)
                end

                if promptStillThere(prompt) then
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(0.1)
                        prompt:InputHoldEnd()
                    end)
                end
            elseif fallback then
                goTo(fallback, 6, 8)
            end

            if clicker then
                pcall(fireclickdetector, clicker)
            end
            task.wait(0.1)
        end

        local function getBerryTargets()
            local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            local entries = {}
            if not rootPart then return entries end
            for index, bush in ipairs(CollectionService:GetTagged("BerryBush")) do
                if bush.Parent and next(bush:GetAttributes()) ~= nil then
                    local loaded = 0
                    for index2, berry in ipairs(bush:GetChildren()) do
                        if berry:IsA("PVInstance") and hasInteraction(berry) then
                            loaded = loaded + 1
                            if not (visited[berry] and tick() - visited[berry] < 20) then
                                entries[#entries + 1] = {
                                    berry = berry,
                                    distance = (berry:GetPivot().Position - rootPart.Position).Magnitude
                                }
                            end
                        end
                    end
                    if loaded == 0 and not (visited[bush] and tick() - visited[bush] < 5) then
                        if bush:IsA("PVInstance") and hasInteraction(bush) then
                            entries[#entries + 1] = {
                                berry = bush,
                                distance = (bush:GetPivot().Position - rootPart.Position).Magnitude
                            }
                        else
                            entries[#entries + 1] = {
                                bush = bush,
                                distance = (bush.Parent:GetPivot().Position - rootPart.Position).Magnitude
                            }
                        end
                    end
                end
            end
            table.sort(entries, function(first, second) return first.distance < second.distance end)
            return entries
        end

        local berryCache, berryCacheTime = false, 0
        _G.AxlBerryHasWork = function()
            if tick() - berryCacheTime > 0.5 then
                berryCacheTime = tick()
                local success, entries = pcall(getBerryTargets)
                berryCache = success and #entries > 0
            end
            return berryCache
        end

        while task.wait(0.1) do
            if _G.AutoBerry then
                pcall(function()

                    local entries = getBerryTargets()
                    local entry = entries[1]
                    if not entry then return end
                    if entry.berry then
                        collectBerry(entry.berry)
                        visited[entry.berry] = tick()
                    else
                        goTo(entry.bush.Parent:GetPivot(), 15, 30)
                        visited[entry.bush] = tick()
                    end
                end)
            end
        end
    end)

    local list = { "Angel Wings", "Leather + Scrap Metal", "Magma Ore", "Fish Tail" }
    if isSea2 then
        list = { "Leather + Scrap Metal", "Magma Ore", "Ectoplasm", "Mystic Droplet", "Radioactive Material", "Vampire Fang" }
    elseif isSea3 then
        list = { "Scrap Metal", "Fish Tail", "Conjured Cocoa", "Dragon Scale", "Gunpowder", "Mini Tusk", "Demonic Wisp" }
    end

    getgenv().SelectMaterial = list[1]

    Tabs.Main:AddSection("Material")

    local selectMaterialDropdown = Tabs.Main:AddDropdown("SelectMaterial", {
        Title = "Select Material",
        Description = "Select the material to farm",
        Values = list,
        Multi = false,
        Default = 1,
    })

    selectMaterialDropdown:OnChanged(function(value2)
        getgenv().SelectMaterial = value2
    end)

    local autoMaterialToggle = Tabs.Main:AddToggle("AutoMaterial", {
        Title = "Auto Farm",
        Description = "Automatically farms the selected material",
        Default = false
    })

    autoMaterialToggle:OnChanged(function(value2)
        getgenv().AutoMaterial = value2
        if not value2 then
            if not isFarming() then
                stopFarming()
            end
        end
    end)
end

do
    Tabs.Main:AddSection("Boss Farm")

    local list = { "Gorilla King", "Bobby", "Yeti", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Saber Expert", "Greybeard" }
    if isSea2 then
        list = { "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Cursed Captain", "Darkbeard", "Order", "Awakened Ice Admiral", "Tide Keeper" }
    elseif isSea3 then
        list = { "Stone", "Island Empress", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Longma", "Cake Queen", "Soul Reaper", "rip_indra", "Cake Prince", "Dough King", "Tyrant of the Skies" }
    end

    local list2 = {}
    for index, item in ipairs({
        "Gorilla King", "Bobby", "Yeti", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Saber Expert", "Greybeard",
        "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Cursed Captain", "Darkbeard", "Order", "Awakened Ice Admiral", "Tide Keeper",
        "Stone", "Island Empress", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Longma", "Cake Queen", "Soul Reaper", "rip_indra", "Cake Prince", "Dough King", "Tyrant of the Skies"
    }) do
        list2[item] = true
    end

    local value2 = list[1]
    local flag = false

    local function helper(target)
        local rootPart = target:FindFirstChild("HumanoidRootPart")
        if rootPart then return rootPart end
        if target:IsA("Model") and target.PrimaryPart then return target.PrimaryPart end
        return target:FindFirstChildWhichIsA("BasePart", true)
    end

    local function helper2(target)
        if not isSea3 and string.find(target.Name, "rip_indra", 1, true) then return false end
        return target:IsA("Model") and (target:GetAttribute("IsBoss") == true or list2[target.Name] == true)
    end

    local function helper3(target)
        local humanoid = target:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then return false end
        return helper(target) ~= nil
    end

    local selectBossDropdown = Tabs.Main:AddDropdown("SelectBoss", {
        Title = "Select Boss",
        Description = "Select the boss to farm",
        Values = list,
        Multi = false,
        Default = 1,
    })

    selectBossDropdown:OnChanged(function(value3)
        value2 = value3
    end)

    local function helper4()
        local list, list3 = {}, {}
        local function helper5(value3)
            if not value3 then return end
            for index, item in ipairs(value3:GetChildren()) do
                if not list3[item.Name] and helper2(item) and helper3(item) then
                    list3[item.Name] = true
                    table.insert(list, item.Name)
                end
            end
        end
        helper5(Workspace:FindFirstChild("Enemies"))
        helper5(value)
        table.sort(list)
        if #list == 0 then
            list = { "None" }
        end
        local value3 = value2
        pcall(function()
            selectBossDropdown:SetValues(list)
            selectBossDropdown:SetValue(table.find(list, value3) and value3 or list[1])
        end)
        value2 = table.find(list, value3) and value3 or list[1]
    end
    _G.AxlRefreshBoss = helper4

    Tabs.Main:AddButton({
        Title = "Refresh Boss List",
        Description = "Shows only the bosses that are alive",
        Callback = helper4
    })

    task.spawn(function()
        task.wait(1)
        pcall(helper4)
    end)

    Tabs.Main:AddToggle("FarmSelectedBoss", {
        Title = "Farm Selected Boss",
        Description = "Goes to the selected boss and kills it",
        Default = false
    }):OnChanged(function(value3)
        if flag then return end
        _G.AutoBoss = value3
        if value3 and _G.FarmAllBoss then
            _G.FarmAllBoss = false
            flag = true
            pcall(function() Fluent.Options.FarmAllBosses:SetValue(false) end)
            flag = false
        end
        if not value3 and not isFarming() then stopFarming() end
    end)

    Tabs.Main:AddToggle("FarmAllBosses", {
        Title = "Farm All Bosses",
        Description = "Kills every boss that is available, nearest first",
        Default = false
    }):OnChanged(function(value3)
        if flag then return end
        _G.FarmAllBoss = value3
        if value3 and _G.AutoBoss then
            _G.AutoBoss = false
            flag = true
            pcall(function() Fluent.Options.FarmSelectedBoss:SetValue(false) end)
            flag = false
        end
        if not value3 and not isFarming() then stopFarming() end
    end)

    local function helper3()
        return _G.AutoBoss or _G.FarmAllBoss
    end

    task.spawn(function()
        while task.wait() do
            if not helper3() then continue end
            pcall(function()
                local character = localPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local enemies = Workspace:FindFirstChild("Enemies")
                local current, huge = nil, math.huge
                local current2, huge2 = nil, math.huge

                if _G.AutoBoss then
                    local firstChild = enemies and enemies:FindFirstChild(value2)
                    if firstChild and Mob.Alive(firstChild) and firstChild:FindFirstChild("HumanoidRootPart") then
                        current = firstChild
                    else
                        local firstChild = value:FindFirstChild(value2)
                        local f15234 = firstChild and helper(firstChild)
                        if f15234 then current2 = f15234 end
                    end
                else
                    if enemies then
                        for index, item in ipairs(enemies:GetChildren()) do
                            if helper2(item) and Mob.Alive(item) and item:FindFirstChild("HumanoidRootPart") then
                                local distance = (item.HumanoidRootPart.Position - rootPart.Position).Magnitude
                                if distance < huge then
                                    huge = distance
                                    current = item
                                end
                            end
                        end
                    end
                    if not current then
                        for index, item in ipairs(value:GetChildren()) do
                            if list2[item.Name] and (isSea3 or item.Name ~= "rip_indra") then
                                local f15234 = helper(item)
                                if f15234 then
                                    local distance = (f15234.Position - rootPart.Position).Magnitude
                                    if distance < huge2 then
                                        huge2 = distance
                                        current2 = f15234
                                    end
                                end
                            end
                        end
                    end
                end

                if current then
                    repeat
                        task.wait()
                        Mob.Kill(current, helper3())
                    until not helper3() or not current.Parent or not current:FindFirstChild("Humanoid")
                        or current.Humanoid.Health <= 0 or not rootPart.Parent
                elseif current2 then
                    _tp(current2.CFrame)
                end
            end)
        end
    end)
end

do
    local J = {
        "Cookie Crafter",
        "Head Baker",
        "Baking Staff",
        "Cake Guard",
    }
    local w = {
        "Reborn Skeleton",
        "Posessed Mummy",
        "Demonic Soul",
        "Living Zombie",
    }

    local T = {
        "Skull Slayer",
        "Serpent Hunter",
        "Isle Champion",
        "Sun-kissed Warrior",
        "Island Boy",
        "Isle Outlaw",
    }

    local VIM = game:GetService("VirtualInputManager")
    local masteryAim = nil
    local masteryHealth = 70
    local masteryMethod = "Bone"
    local masteryKeys = {}
    local masteryLock = false
    local masteryFails = 0
    local masteryMob = nil

    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local aim = masteryAim or _G.SeaAim
            if not aim then return old(self, ...) end
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local args = table.pack(...)
                if typeof(args[1]) == "Vector3" then
                    args[1] = aim
                    return old(self, table.unpack(args, 1, args.n))
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)

    local function keyList(p)
        local picked = {}
        if type(p) == "table" then
            for k, v in pairs(p) do
                if type(k) == "number" then
                    picked[v] = true
                elseif v then
                    picked[k] = true
                end
            end
        end
        local out = {}
        for index, name in ipairs({ "Z", "X", "C", "V", "F" }) do
            if picked["Fruit Skill " .. name] then
                table.insert(out, name)
            end
        end
        return out
    end

    local function pressKey(key)
        _G.AxlKeyGuard = (_G.AxlKeyGuard or 0) + 1
        task.delay(0.6, function()
            _G.AxlKeyGuard = math.max((_G.AxlKeyGuard or 1) - 1, 0)
        end)
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        end)
    end

    local function equipTip(tip)
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return nil end
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == tip then return tool end
        for index, item in ipairs(localPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and item.ToolTip == tip then
                humanoid:EquipTool(item)
                task.wait(0.15)
                if item.Parent == character then return item end
                return nil
            end
        end
        return nil
    end

    local GROUP_RANGE = 45
    local hoverPos = nil
    local hoverTime = 0

    local function setHover(position)
        hoverPos = position
        hoverTime = tick()
    end

    local function scan(names)
        local list = {}
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return list end
        for index, item in ipairs(enemies:GetChildren()) do
            local humanoid = item:FindFirstChild("Humanoid")
            local root = item:FindFirstChild("HumanoidRootPart")
            if table.find(names, item.Name) and humanoid and root and humanoid.Health > 0 then
                table.insert(list, { mob = item, root = root, hum = humanoid })
            end
        end
        return list
    end

    local function isLow(entry)
        return entry.hum.Health <= entry.hum.MaxHealth * (masteryHealth / 100)
    end

    local function nearestEntry(list, position)
        local best, bestDistance = nil, math.huge
        for index, entry in ipairs(list) do
            local distance = (entry.root.Position - position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                best = entry
            end
        end
        return best
    end

    local function resolve(list, cur)
        if not isLow(cur) then return cur.mob, false end
        local best, bestDistance = nil, GROUP_RANGE
        for index, entry in ipairs(list) do
            if not isLow(entry) then
                local distance = (entry.root.Position - cur.root.Position).Magnitude
                if distance <= bestDistance then
                    bestDistance = distance
                    best = entry
                end
            end
        end
        if best then return best.mob, false end
        return cur.mob, true
    end

    local function choose(names)
        local list = scan(names)
        if #list == 0 then return nil end
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return nil end
        local cur = nil
        if masteryMob then
            for index, entry in ipairs(list) do
                if entry.mob == masteryMob then
                    cur = entry
                    break
                end
            end
        end
        cur = cur or nearestEntry(list, rootPart.Position)
        local mob, finish = resolve(list, cur)
        masteryMob = mob
        return mob, finish
    end

    local function resetFinish()
        masteryAim = nil
        hoverPos = nil
        _G.MasteryFinish = false
        _G.MasteryWeapon = nil
        _G.MasteryHold = nil
    end

    local function onTop(position)
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end
        return (rootPart.Position - position).Magnitude <= 12
    end

    local function equipFailed()
        masteryFails = masteryFails + 1
        if masteryFails >= 5 then
            masteryAim = nil
            _G.MasteryFinish = false
            _G.MasteryWeapon = "Melee"
            _G.MasteryHold = nil
        end
    end

    local function idleSpot()
        if masteryMethod == "Cake" then
            return CFrame.new(-1943.6765, 251.5095, -12337.8808)
        elseif masteryMethod == "Tyrant" then
            local level = localPlayer.Data.Level.Value
            if level >= 2575 then
                return CFrame.new(-16709.49, 419.68, 1751.09)
            elseif level > 2550 then
                return CFrame.new(-16645.64, 163.09, 1352.87)
            elseif level >= 2525 then
                return CFrame.new(-16602.1015625, 130.38734436035, 1087.2456054688)
            elseif level >= 2500 then
                return CFrame.new(-16347, 64, 984)
            elseif level >= 2475 then
                return CFrame.new(-16670, 43, -270)
            end
            return CFrame.new(-16350, 45, -180)
        end
        return CFrame.new(-9495.6806, 453.5862, 5977.3486)
    end

    local function attack(mob, mode, finish)
        local root = mob.HumanoidRootPart
        local humanoid = mob.Humanoid
        local canFinish = not (mode == "Fruit" and #masteryKeys == 0)
        _G.MasteryHold = canFinish and (masteryHealth / 100) or nil

        if not (finish and canFinish) then
            masteryAim = nil
            masteryFails = 0
            _G.MasteryFinish = false
            _G.MasteryWeapon = "Melee"
            equipTip("Melee")
            local position = root.Position + Vector3.new(0, 30, 0)
            setHover(position)
            Mob.Kill(mob, true, CFrame.new(position))
            return
        end

        local offset = mode == "Fruit" and Vector3.new(0, 20, 0) or Vector3.new(0, 35, 8)
        _G.MasteryFinish = true
        _G.MasteryWeapon = nil
        local position = root.Position + offset
        setHover(position)
        Mob.Kill(mob, true, CFrame.new(position))
        if not onTop(position) then
            masteryAim = nil
            return
        end

        if mode == "Fruit" then
            local tool = equipTip("Blox Fruit")
            if not tool then
                equipFailed()
                return
            end
            masteryFails = 0
            for index, key in ipairs(masteryKeys) do
                if not _G.FarmMastery_Dev or humanoid.Health <= 0 or not mob.Parent then break end
                setHover(root.Position + offset)
                if not onTop(root.Position + offset) then break end
                masteryAim = root.Position
                pressKey(key)
                task.wait(0.15)
                masteryAim = nil
            end
        else
            local tool = equipTip("Gun")
            if not tool then
                equipFailed()
                return
            end
            masteryFails = 0
            for index, key in ipairs({ "Z", "X" }) do
                if not _G.FarmMastery_G or humanoid.Health <= 0 or not mob.Parent then break end
                setHover(root.Position + offset)
                if not onTop(root.Position + offset) then break end
                masteryAim = root.Position
                pressKey(key)
                task.wait(0.15)
                masteryAim = nil
            end
            local shoot = getgenv().AxlGunShoot
            if shoot and humanoid.Health > 0 and mob.Parent and onTop(root.Position + offset) then
                setHover(root.Position + offset)
                masteryAim = root.Position
                shoot(tool, root)
                task.wait(0.05)
                masteryAim = nil
            end
        end
    end

    local function step(mode)
        if masteryMethod == "Tyrant" then
            local enemies = Workspace:FindFirstChild("Enemies")
            local boss = enemies and enemies:FindFirstChild("Tyrant of the Skies")
            if boss and boss:FindFirstChild("Humanoid") and boss:FindFirstChild("HumanoidRootPart") and boss.Humanoid.Health > 0 then
                resetFinish()
                Mob.Kill(boss, true)
                return
            end
        end

        local names = (masteryMethod == "Cake" and J) or (masteryMethod == "Tyrant" and T) or w
        local mob, finish = choose(names)
        if not mob then
            resetFinish()
            _tp(idleSpot())
            return
        end
        attack(mob, mode, finish)
    end

    _G.AxlMasteryAttack = function(mob)
        local mode = (_G.FarmMastery_Dev and "Fruit") or (_G.FarmMastery_G and "Gun") or nil
        if not mode or not mob or not mob:FindFirstChild("HumanoidRootPart") or not mob:FindFirstChild("Humanoid") then return end
        pcall(function()
            local list = scan({ mob.Name })
            local cur = nil
            for index, entry in ipairs(list) do
                if entry.mob == mob then
                    cur = entry
                    break
                end
            end
            if not cur then return end
            local target, finish = resolve(list, cur)
            attack(target, mode, finish)
        end)
    end

    game:GetService("RunService").Heartbeat:Connect(function()
        if not hoverPos or tick() - hoverTime > 0.4 then return end
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart and (rootPart.Position - hoverPos).Magnitude <= 20 then
            rootPart.CFrame = CFrame.new(hoverPos) * rootPart.CFrame.Rotation
            rootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    task.spawn(function()
        while true do
            local mode = (_G.FarmMastery_Dev and "Fruit") or (_G.FarmMastery_G and "Gun") or nil
            if mode and masteryMethod == "Level" then
                _G.MasteryLevel = true
                task.wait(0.5)
            elseif mode then
                _G.MasteryLevel = false
                pcall(step, mode)
                task.wait(0.1)
            else
                _G.MasteryLevel = false
                if masteryAim or hoverPos or _G.MasteryFinish or _G.MasteryWeapon or _G.MasteryHold then
                    resetFinish()
                end
                masteryMob = nil
                task.wait(0.5)
            end
        end
    end)

    Tabs.Main:AddSection("Mastery")

    Tabs.Main:AddDropdown("MasteryMethod", {
        Title = "Select Method",
        Description = "Where the mastery is farmed: Cake, Bone, Tyrant (mobs only) or Level (normal level farm)",
        Values = { "Cake", "Bone", "Tyrant", "Level" },
        Multi = false,
        Default = 2,
    }):OnChanged(function(value2)
        masteryMethod = value2
    end)

    Tabs.Main:AddToggle("AutoFarmMasteryFruit", {
        Title = "Auto Farm Mastery Fruit",
        Description = "Lowers the mob HP and finishes it with the selected fruit skills",
        Default = false
    }):OnChanged(guardToggle("AutoFarmMasteryFruit", isSea3, "Auto Farm Mastery only works in Sea 3", function(value2)
        if masteryLock then return end
        _G.FarmMastery_Dev = value2
        if value2 and _G.FarmMastery_G then
            _G.FarmMastery_G = false
            masteryLock = true
            pcall(function() Fluent.Options.AutoFarmMasteryGun:SetValue(false) end)
            masteryLock = false
        end
        if not value2 then
            resetFinish()
            if not isFarming() then stopFarming() end
        end
    end))

    Tabs.Main:AddToggle("AutoFarmMasteryGun", {
        Title = "Auto Farm Mastery Gun",
        Description = "Lowers the mob HP and finishes it with your gun or Dragonstorm",
        Default = false
    }):OnChanged(guardToggle("AutoFarmMasteryGun", isSea3, "Auto Farm Mastery only works in Sea 3", function(value2)
        if masteryLock then return end
        _G.FarmMastery_G = value2
        if value2 and _G.FarmMastery_Dev then
            _G.FarmMastery_Dev = false
            masteryLock = true
            pcall(function() Fluent.Options.AutoFarmMasteryFruit:SetValue(false) end)
            masteryLock = false
        end
        if not value2 then
            resetFinish()
            if not isFarming() then stopFarming() end
        end
    end))

    Tabs.Main:AddSlider("SkillUsageHp", {
        Title = "Skill Usage HP (%)",
        Description = "Uses the fruit or gun when the mob is at or below this HP",
        Default = 70,
        Min = 10,
        Max = 100,
        Rounding = 0,
        Callback = function(value2)
            masteryHealth = tonumber(value2) or 70
        end
    })

    Tabs.Main:AddDropdown("SelectFruitSkills", {
        Title = "Select Fruit Skills",
        Description = "Skills used to finish the mob in Fruit mode",
        Values = { "Fruit Skill Z", "Fruit Skill X", "Fruit Skill C", "Fruit Skill V", "Fruit Skill F" },
        Multi = true,
        Default = {},
    }):OnChanged(function(p)
        masteryKeys = keyList(p)
    end)
end

do
    Tabs.Stack:AddSection("Elite Hunter")

    Tabs.Stack:AddToggle("FarmEliteHunt", {
        Title = "Farm Elite Hunter",
        Description = "Takes the quest, goes to the Elite and kills it",
        Default = false
    }):OnChanged(guardToggle("FarmEliteHunt", isSea3, "Elite Hunter only works in Sea 3", function(value2)
        _G.FarmEliteHunt = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    Tabs.Stack:AddSection("Haki")

    Tabs.Stack:AddButton({
        Title = "Buy Buso Colors",
        Description = "Buys the Buso Colors (Sea 2 and 3)",
        Callback = function()
            if not (isSea2 or isSea3) then
                Fluent:Notify({ Title = "Axl Hub", Content = "Buy Buso Colors only works in Sea 2 and Sea 3", Duration = 5 })
                return
            end
            value.Remotes.CommF_:InvokeServer("ColorsDealer", "2")
        end
    })

    Tabs.Stack:AddToggle("TpBarista", {
        Title = "Teleport Barista Haki",
        Description = "Automatic teleport to the Haki NPC (Sea 2 and 3)",
        Default = false
    }):OnChanged(guardToggle("TpBarista", isSea2 or isSea3, "Teleport Barista Haki only works in Sea 2 and Sea 3", function(value2)
        _G.Tp_MasterA = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    task.spawn(function()
        while task.wait() do
            if _G.Tp_MasterA then
                pcall(function()
                    for index, item in pairs(value.NPCs:GetChildren()) do
                        if string.find(item.Name, "Barista") and item:FindFirstChild("HumanoidRootPart") then
                            _tp(item.HumanoidRootPart.CFrame)
                        end
                    end
                end)
            end
        end
    end)

end

do
    Tabs.Stack:AddSection("Boss Raid")

    local flag = false

    local function helper(value2)
        return localPlayer.Backpack:FindFirstChild(value2) or (localPlayer.Character and localPlayer.Character:FindFirstChild(value2))
    end

    Tabs.Stack:AddToggle("AutoRipIndra", {
        Title = "Auto Farm Rip Indra",
        Description = "Goes to the altar and kills rip_indra (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoRipIndra", isSea3, "Auto Farm Rip Indra only works in Sea 3", function(value2)
        _G.AutoRipIndra = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    Tabs.Stack:AddToggle("AutoDarkbeard", {
        Title = "Auto Farm Darkbeard",
        Description = "Collects chests for the Fist of Darkness and kills Darkbeard (Sea 2)",
        Default = false
    }):OnChanged(guardToggle("AutoDarkbeard", isSea2, "Auto Farm Darkbeard only works in Sea 2", function(value2)
        _G.AutoDarkbeard = value2
        if not value2 then
            if flag then
                flag = false
                _G.AutoFarmChest = false
            end
            if not isFarming() then stopFarming() end
        end
    end))

    Tabs.Stack:AddToggle("AutoCursedCaptain", {
        Title = "Auto Farm Cursed Captain",
        Description = "Goes to the Cursed Ship and kills the Cursed Captain (Sea 2)",
        Default = false
    }):OnChanged(guardToggle("AutoCursedCaptain", isSea2, "Auto Farm Cursed Captain only works in Sea 2", function(value2)
        _G.AutoCursedCaptain = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    task.spawn(function()
        while task.wait() do
            if not _G.AutoRipIndra then continue end
            pcall(function()
                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local value2
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for index, item in ipairs(enemies:GetChildren()) do
                        if item.Name == "rip_indra True Form" and item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 then
                            value2 = item
                            break
                        end
                    end
                end

                if value2 then
                    if value2:FindFirstChild("HumanoidRootPart") then
                        _tp(value2.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                        Mob.Kill(value2, _G.AutoRipIndra)
                    end
                else
                    if helper("God's Chalice") then
                        _tp(CFrame.new(-5561, 314, -2663))
                    else
                        _tp(CFrame.new(-5333, 424, -2673))
                    end
                end
            end)
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            if not _G.AutoDarkbeard then continue end
            pcall(function()
                local enemies = Workspace:FindFirstChild("Enemies")
                local darkbeard = enemies and enemies:FindFirstChild("Darkbeard")
                local f12130 = findEnemyByName("Darkbeard")
                local f33431 = helper("Fist of Darkness")

                if f33431 and not darkbeard then
                    if flag then
                        flag = false
                        _G.AutoFarmChest = false
                    end
                    _tp(CFrame.new(3677.08203125, 62.751937866211, -3144.8332519531))
                elseif f12130 then
                    if flag then
                        flag = false
                        _G.AutoFarmChest = false
                    end
                    repeat
                        task.wait()
                        Mob.Kill(f12130, _G.AutoDarkbeard)
                    until not _G.AutoDarkbeard or not f12130.Parent or not f12130:FindFirstChild("Humanoid") or f12130.Humanoid.Health <= 0
                else
                    if not _G.AutoFarmChest then
                        _G.AutoFarmChest = true
                        flag = true
                    end
                end
            end)
        end
    end)

    task.spawn(function()
        while task.wait() do
            if not _G.AutoCursedCaptain then continue end
            pcall(function()
                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local value2
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for index, item in ipairs(enemies:GetChildren()) do
                        if item.Name == "Cursed Captain" and item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 then
                            value2 = item
                            break
                        end
                    end
                end

                if not value2 then
                    local cframe = CFrame.new(921.4840087890625, 181.46876525878906, 33306.66796875)
                    local map = Workspace:FindFirstChild("Map")
                    local ghostShip = map and map:FindFirstChild("GhostShip")
                    local teleport = ghostShip and ghostShip:FindFirstChild("Teleport")

                    if not teleport then
                        _tp(cframe)
                        return
                    end

                    local pivot = teleport:GetPivot()
                    local distance = (rootPart.Position - cframe.Position).Magnitude
                    local distance2 = (rootPart.Position - pivot.Position).Magnitude

                    if distance <= distance2 then
                        _tp(cframe)
                    elseif distance2 > 15 then
                        _tp(pivot)
                    else
                        task.wait(1.3)
                        _tp(cframe)
                    end
                    return
                end

                if value2:FindFirstChild("HumanoidRootPart") then
                    repeat
                        task.wait()
                        if value2:FindFirstChild("HumanoidRootPart") then
                            _tp(value2.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                        end
                        Mob.Kill(value2, _G.AutoCursedCaptain)
                    until not _G.AutoCursedCaptain or not value2.Parent or not value2:FindFirstChild("Humanoid") or value2.Humanoid.Health <= 0 or not rootPart.Parent
                end
            end)
        end
    end)

    Tabs.Stack:AddSection("Bones")

    Tabs.Stack:AddToggle("AutoRandomBone", {
        Title = "Auto Random Bones",
        Description = "Automatically rolls random Bones (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoRandomBone", isSea3, "Auto Random Bones only works in Sea 3", function(value2)
        _G.Auto_Random_Bone = value2
    end))

    Tabs.Stack:AddToggle("AutoSoulReaper", {
        Title = "Auto Farm Soul Reaper",
        Description = "Buys the Hallow Essence, goes to the altar and kills Soul Reaper (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoSoulReaper", isSea3, "Auto Farm Soul Reaper only works in Sea 3", function(value2)
        _G.AutoHytHallow = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    task.spawn(function()
        while task.wait(loopDelay) do
            if _G.Auto_Random_Bone then
                pcall(function()
                    value.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1)
                end)
            end
        end
    end)

    task.spawn(function()
        local cframe = CFrame.new(-8932.32, 146.83, 6062.55)
        while task.wait(loopDelay) do
            if _G.AutoHytHallow then
                pcall(function()
                    local f12130 = findEnemyByName("Soul Reaper")
                    if f12130 then
                        repeat
                            task.wait()
                            Mob.Kill(f12130, _G.AutoHytHallow)
                        until not _G.AutoHytHallow or not f12130.Parent or not f12130:FindFirstChild("Humanoid") or f12130.Humanoid.Health <= 0
                    else
                        if not helper("Hallow Essence") then
                            repeat
                                task.wait(.1)
                                value.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1)
                            until not _G.AutoHytHallow or helper("Hallow Essence")
                        else
                            local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if rootPart and (rootPart.Position - cframe.Position).Magnitude > 10 then
                                repeat
                                    task.wait(.1)
                                    _tp(cframe)
                                    rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                                until not _G.AutoHytHallow or not rootPart or (rootPart.Position - cframe.Position).Magnitude <= 10
                            end
                            if _G.AutoHytHallow then
                                equipToolByName("Hallow Essence")
                            end
                        end
                    end
                end)
            end
        end
    end)

    Tabs.Stack:AddSection("Sword")

    Tabs.Stack:AddToggle("AutoMasterySwords", {
        Title = "Auto 600 Mastery All Swords",
        Description = "Farms Bones with each sword you own until it reaches 600 mastery, then loads the next one (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoMasterySwords", isSea3, "Auto 600 Mastery All Swords only works in Sea 3", function(value2)
        _G.AutoMasterySwords = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    local amount = 600
    local cframe = CFrame.new(-9495.6806, 453.5862, 5977.3486)
    local list = { "Reborn Skeleton", "Posessed Mummy", "Demonic Soul", "Living Zombie" }

    local list2 = {
        "Katana", "Cutlass", "Dual-Headed Blade", "Iron Mace", "Triple Katana", "Pipe",
        "Dual Katana", "Soul Cane", "Bisento", "Saber", "Rengoku", "Midnight Blade",
        "Dragon Trident", "Yama", "Buddy Sword", "Canvander", "Spikey Trident", "Shisui",
        "Saddi", "Wando", "Tushita", "Hallow Scythe", "Dark Dagger", "Cursed Dual Katana",
        "True Triple Katana", "Koko", "Fox Lamp", "Longsword", "Shark Anchor"
    }
    local list3 = {}
    for index, item in ipairs(list2) do
        list3[item] = { Order = index }
    end

    local current = nil
    local function helper()
        if current then return current end
        local firstChild = value:FindFirstChild("ItemConfig", true)
        if not (firstChild and firstChild:IsA("ModuleScript")) and getloadedmodules then
            for index, item in ipairs(getloadedmodules()) do
                if item.Name == "ItemConfig" then
                    firstChild = item
                    break
                end
            end
        end
        if firstChild and firstChild:IsA("ModuleScript") then
            local success, result = pcall(require, firstChild)
            if success and type(result) == "table" then
                current = result
            end
        end
        return current
    end

    local function helper2(value2)
        local character = localPlayer.Character
        if character and character:FindFirstChild(value2) then return true end
        return localPlayer.Backpack:FindFirstChild(value2) ~= nil
    end

    local current = nil
    local flag = false
    local current2 = nil

    local function helper3(value2)
        current = nil
        _G.AutoMasterySwords = false
        Fluent:Notify({ Title = "Axl Hub", Content = value2, Duration = 6 })
        toggleDebounce["AutoMasterySwords"] = true
        pcall(function() Fluent.Options.AutoMasterySwords:SetValue(false) end)
        task.delay(0.3, function() toggleDebounce["AutoMasterySwords"] = nil end)
        if not isFarming() then stopFarming() end
    end

    local function helper4()
        local f34473 = helper()
        if not f34473 then
            if not flag then
                flag = true
                Fluent:Notify({ Title = "Axl Hub", Content = "ItemConfig module not found, cannot read sword mastery", Duration = 6 })
            end
            return
        end

        local success, result = pcall(function()
            current2 = current2 or require(value:WaitForChild("Modules"):WaitForChild("Net"))
            return current2:RemoteFunction("GetAllItemValues"):InvokeServer()
        end)
        if not success or not result then return end

        local list2 = {}
        for index, item in next, result, nil do
            local tostring2 = tostring(item.ItemId) .. "_" .. tostring(item.NetworkedUID)
            list2[tostring2] = list2[tostring2] or { ItemId = item.ItemId, Attributes = {} }
            if item.Value ~= nil then
                list2[tostring2].Attributes[item.Key] = item.Value
            end
        end

        local list4 = {}
        for index, item in next, list2, nil do
            local attributes = item.Attributes
            if attributes.IsOwned == true and attributes.Mastery ~= nil then
                local success, result = pcall(function()
                    return f34473.match(item.ItemId)
                end)
                if success and result and result:isOk() then
                    local value2 = tostring(result:unwrap().Index.DebugLabel)
                    local value3 = value2:match("^(.-)%s*%[") or value2
                    local value2 = list3[value3]
                    if value2 then
                        table.insert(list4, { Name = value3, Mastery = attributes.Mastery, Order = value2.Order })
                    end
                end
            end
        end

        table.sort(list4, function(value2, value3)
            if value2.Order == value3.Order then
                return value2.Mastery < value3.Mastery
            end
            return value2.Order < value3.Order
        end)

        for index, item in next, list4, nil do
            if helper2(item.Name) and item.Mastery < amount then
                current = item.Name
                return
            end
        end

        for index, item in next, list4, nil do
            if item.Mastery < amount then
                if not helper2(item.Name) then
                    pcall(function()
                        value.Remotes.CommF_:InvokeServer("LoadItem", item.Name)
                    end)
                    task.wait(0.5)
                end
                current = item.Name
                return
            end
        end

        helper3(#list4 == 0 and "No swords found to farm mastery" or "All swords are at 600 mastery")
    end

    task.spawn(function()
        while task.wait(10) do
            if _G.AutoMasterySwords and not farmPaused then
                pcall(helper4)
            else
                current = nil
            end
        end
    end)

    task.spawn(function()
        while task.wait() do
            if not _G.AutoMasterySwords or farmPaused then continue end
            pcall(function()
                local character = localPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not rootPart or not humanoid or humanoid.Health <= 0 then return end
                if not current then return end

                equipToolByName(current)

                local enemies = Workspace:FindFirstChild("Enemies")
                local current3, huge = nil, math.huge
                if enemies then
                    for index, item in ipairs(enemies:GetChildren()) do
                        local humanoid2 = item:FindFirstChild("Humanoid")
                        local rootPart2 = item:FindFirstChild("HumanoidRootPart")
                        if humanoid2 and rootPart2 and humanoid2.Health > 0 and table.find(list, item.Name) then
                            local distance = (rootPart2.Position - rootPart.Position).Magnitude
                            if distance < huge then
                                huge = distance
                                current3 = item
                            end
                        end
                    end
                end

                if current3 then
                    repeat
                        task.wait()
                        equipToolByName(current)
                        Mob.Kill(current3, _G.AutoMasterySwords)
                        BringEnemy()
                    until not _G.AutoMasterySwords or not current3.Parent
                        or not current3:FindFirstChild("Humanoid") or current3.Humanoid.Health <= 0
                        or not rootPart.Parent or humanoid.Health <= 0
                else
                    _tp(cframe)
                end
            end)
        end
    end)

    Tabs.Stack:AddSection("Cursed Swords")

    Tabs.Stack:AddToggle("AutoTushita", {
        Title = "Auto Tushita Fully",
        Description = "Does the Tushita puzzle and defeats Longma (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoTushita", isSea3, "Auto Tushita Fully only works in Sea 3", function(value2)
        _G.AutoTushita = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    Tabs.Stack:AddToggle("AutoYama", {
        Title = "Auto Yama Fully",
        Description = "Farms 30 Elite Hunter kills and pulls the Sealed Katana (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoYama", isSea3, "Auto Yama only works in Sea 3", function(value2)
        _G.AutoYama = value2
        if not value2 then
            local farmEliteHunt = Fluent.Options.FarmEliteHunt
            _G.FarmEliteHunt = farmEliteHunt and farmEliteHunt.Value or false
            if not isFarming() then stopFarming() end
        end
    end))

    local amount = 0
    local flag = false

    local function helper2()
        if tick() - amount < 10 then
            return flag
        end
        amount = tick()

        local f34473 = helper()
        if not f34473 then
            return flag
        end

        local success, result = pcall(function()
            current2 = current2 or require(value:WaitForChild("Modules"):WaitForChild("Net"))
            return current2:RemoteFunction("GetAllItemValues"):InvokeServer()
        end)
        if not success or not result then
            return flag
        end

        local list = {}
        for index, item in next, result, nil do
            local tostring2 = tostring(item.ItemId) .. "_" .. tostring(item.NetworkedUID)
            list[tostring2] = list[tostring2] or { ItemId = item.ItemId, Attributes = {} }
            if item.Value ~= nil then
                list[tostring2].Attributes[item.Key] = item.Value
            end
        end

        local flag2 = false
        for index, item in next, list, nil do
            if item.Attributes.IsOwned == true then
                local success, result = pcall(function()
                    return f34473.match(item.ItemId)
                end)
                if success and result and result:isOk() then
                    local value2 = tostring(result:unwrap().Index.DebugLabel)
                    local value3 = value2:match("^(.-)%s*%[") or value2
                    if value3:lower() == "tushita" then
                        flag2 = true
                        break
                    end
                end
            end
        end

        flag = flag2
        return flag
    end

    local flag = false
    local flag2 = false
    local flag3 = false
    local flag4 = false
    local amount = 0

    local function helper3()
        local success, result = pcall(function()
            return value.Remotes.CommF_:InvokeServer("TushitaProgress")
        end)
        if success and type(result) == "table" then
            flag4 = result.OpenedDoor == true
            return result
        end
        return nil
    end

    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoTushita or farmPaused then
                    flag = false
                    flag2 = false
                    _G.AxlTushitaDoing = false
                    return
                end

                if helper2() then
                    Fluent:Notify({ Title = "Auto Tushita", Content = "You already have this item", Duration = 5 })
                    _G.AutoTushita = false
                    pcall(function() Fluent.Options.AutoTushita:SetValue(false) end)
                    if not isFarming() then stopFarming() end
                    return
                end

                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not rootPart or not humanoid then return end

                if not flag3 then
                    helper3()
                    flag3 = true
                end

                if not flag4 then
                    if tick() - amount > 1.5 then
                        amount = tick()
                        task.spawn(helper3)
                    end
                    if flag4 then return end

                    local ripindraTrueForm = Workspace.Enemies:FindFirstChild("rip_indra True Form") or value:FindFirstChild("rip_indra True Form")
                    if not ripindraTrueForm then
                        _G.AxlTushitaDoing = false
                        if not flag then
                            Fluent:Notify({ Title = "Auto Tushita", Content = "Waiting for Rip Indra to spawn", Duration = 5 })
                            flag = true
                        end
                        return
                    end
                    flag = false
                    _G.AxlTushitaDoing = true

                    local holyTorch = character:FindFirstChild("Holy Torch") or localPlayer.Backpack:FindFirstChild("Holy Torch")
                    if not holyTorch then
                        local position = Vector3.new(5713, 19, 255)
                        if (rootPart.Position - position).Magnitude > 10 then
                            _tp(CFrame.new(position))
                        end
                    else
                        if localPlayer.Backpack:FindFirstChild("Holy Torch") then
                            humanoid:EquipTool(localPlayer.Backpack:FindFirstChild("Holy Torch"))
                        end
                        local commF = value.Remotes.CommF_
                        local server = commF:InvokeServer("TushitaProgress")
                        if type(server) == "table" then
                            flag4 = server.OpenedDoor == true
                            if not server.OpenedDoor and type(server.Torches) == "table" then
                                for index, item in ipairs(server.Torches) do
                                    if not item then
                                        commF:InvokeServer("TushitaProgress", "Torch", index)
                                    end
                                end
                            end
                        end
                    end
                else
                    local longma = Workspace.Enemies:FindFirstChild("Longma") or value:FindFirstChild("Longma")
                    _G.AxlTushitaDoing = (longma ~= nil and longma:FindFirstChild("Humanoid") ~= nil and longma.Humanoid.Health > 0)
                    if longma and longma:FindFirstChild("Humanoid") and longma.Humanoid.Health > 0 then
                        if longma:FindFirstChild("HumanoidRootPart") then
                            Mob.Kill(longma, _G.AutoTushita)
                        end
                    end
                end
            end)
        end
    end)

    local list = {}

    local function helper2(value2)
        local value3 = list[value2]
        if not value3 then
            value3 = { Tick = 0, Owned = false }
            list[value2] = value3
        end
        if tick() - value3.Tick < 10 then
            return value3.Owned
        end
        value3.Tick = tick()

        local f34473 = helper()
        if not f34473 then
            return value3.Owned
        end

        local success, result = pcall(function()
            current2 = current2 or require(value:WaitForChild("Modules"):WaitForChild("Net"))
            return current2:RemoteFunction("GetAllItemValues"):InvokeServer()
        end)
        if not success or not result then
            return value3.Owned
        end

        local list = {}
        for index, item in next, result, nil do
            local tostring2 = tostring(item.ItemId) .. "_" .. tostring(item.NetworkedUID)
            list[tostring2] = list[tostring2] or { ItemId = item.ItemId, Attributes = {} }
            if item.Value ~= nil then
                list[tostring2].Attributes[item.Key] = item.Value
            end
        end

        local flag = false
        for index, item in next, list, nil do
            if item.Attributes.IsOwned == true then
                local success, result = pcall(function()
                    return f34473.match(item.ItemId)
                end)
                if success and result and result:isOk() then
                    local value4 = tostring(result:unwrap().Index.DebugLabel)
                    local value5 = value4:match("^(.-)%s*%[") or value4
                    if value5:lower() == value2:lower() then
                        flag = true
                        break
                    end
                end
            end
        end

        value3.Owned = flag
        return flag
    end

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local cframe = CFrame.new(5248.48828, 16.9484062, 453.278839, .0454210564, -9.33278059e-008, -0.998967946, -4.74314845e-008, 1, -9.61904192e-008, .998968005, 5.12186276e-008, .0454210676)
    local amount = 0
    local amount2 = 0
    local amount3 = 0

    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoYama or farmPaused then return end

                if helper2("Yama") then
                    Fluent:Notify({ Title = "Auto Yama", Content = "You already have this item", Duration = 5 })
                    _G.AutoYama = false
                    local farmEliteHunt = Fluent.Options.FarmEliteHunt
                    _G.FarmEliteHunt = farmEliteHunt and farmEliteHunt.Value or false
                    pcall(function() Fluent.Options.AutoYama:SetValue(false) end)
                    return
                end

                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                if tick() - amount2 > 3 then
                    amount2 = tick()
                    local success, result = pcall(function()
                        return value.Remotes.CommF_:InvokeServer("EliteHunter", "Progress")
                    end)
                    if success then
                        amount = tonumber(result) or 0
                    end
                end

                if amount >= 30 then
                    _G.AxlYamaState = "katana"
                    local farmEliteHunt = Fluent.Options.FarmEliteHunt
                    _G.FarmEliteHunt = farmEliteHunt and farmEliteHunt.Value or false

                    if (rootPart.Position - cframe.Position).Magnitude > 5 then
                        _tp(cframe)
                    else
                        local map = Workspace:FindFirstChild("Map")
                        local waterfall = map and map:FindFirstChild("Waterfall")
                        local sealedKatana = waterfall and waterfall:FindFirstChild("SealedKatana")
                        local hitbox = sealedKatana and sealedKatana:FindFirstChild("Hitbox")
                        if hitbox then
                            hitbox.CFrame = rootPart.CFrame
                            if hitbox:FindFirstChild("ClickDetector") then
                                fireclickdetector(hitbox.ClickDetector)
                            end
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                            task.wait(.05)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        end
                    end
                else
                    _G.FarmEliteHunt = true
                    local enemies = Workspace:FindFirstChild("Enemies")
                    local flag = false
                    for index, item in ipairs({ "Diablo", "Deandre", "Urban" }) do
                        if value:FindFirstChild(item) or (enemies and enemies:FindFirstChild(item)) then
                            flag = true
                            break
                        end
                    end
                    _G.AxlYamaState = flag and "elite" or "waiting"
                    if not flag and tick() - amount3 > 10 then
                        amount3 = tick()
                        Fluent:Notify({ Title = "Auto Yama", Content = "Waiting for Elite Hunter...", Duration = 5 })
                    end
                end
            end)
        end
    end)
end

do
    Tabs.Raid:AddDropdown("SelectChip", {
        Title = "Select Chip",
        Description = "Choose the raid type",
        Values = {
            "Flame", "Ice", "Quake", "Light", "Dark",
            "String", "Rumble", "Magma", "Human: Buddha",
            "Sand", "Bird: Phoenix", "Dough"
        },
        Multi = false,
        Default = 1,
    }):OnChanged(function(value2)
        _G.SelectChip = value2
    end)

    Tabs.Raid:AddToggle("AutoRaid", {
        Title = "Auto Raid",
        Description = "Automatically buys chips and starts the raid loop",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoRaid = value2
        if not value2 then
            if not isFarming() then
                stopFarming()
            end
        end
    end)

    local cheapFruitPrices = {}
    local function loadFruitPrices()
        pcall(function()
            local fruits = value.Remotes.CommF_:InvokeServer("GetFruits", false)
            if type(fruits) == "table" then
                for index, item in pairs(fruits) do
                    if type(item) == "table" and item.Price and item.Name then
                        cheapFruitPrices[string.split(item.Name, "-")[1] .. " Fruit"] = item.Price
                        cheapFruitPrices[item.Name] = item.Price
                    end
                end
            end
        end)
    end

    getgenv().AxlIsCheapFruit = function(name)
        if next(cheapFruitPrices) == nil then loadFruitPrices() end
        local price = cheapFruitPrices[name]
        return price ~= nil and price < 1000000
    end

    getgenv().AxlFruitPrice = function(name)
        if next(cheapFruitPrices) == nil then loadFruitPrices() end
        return cheapFruitPrices[name]
    end

    Tabs.Raid:AddToggle("AutoGrabCheapFruits", {
        Title = "Auto Grab Fruits Under 1M",
        Description = "Uses fruits worth less than 1 million from your own inventory to get the raid chip instead of spending money",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoGrabCheapFruits = value2
    end)

    Tabs.Raid:AddToggle("InstantKillIslands", {
        Title = "Instant Kill (Islands 4-5)",
        Description = "One-shots enemies only on the 4th and 5th islands",
        Default = false
    }):OnChanged(function(value2)
        _G.KillH = value2
    end)

    Tabs.Raid:AddToggle("AutoAwakening", {
        Title = "Auto Awakening",
        Description = "Automatically awakens your fruit",
        Default = false
    }):OnChanged(function(value2)
        _G.Auto_Awakener = value2
    end)

    Tabs.Raid:AddSection("Law Raid")

    Tabs.Raid:AddToggle("AutoLawRaid", {
        Title = "Auto Law Raid",
        Description = "Buys the Law chip, starts the raid and kills Order",
        Default = false
    }):OnChanged(guardToggle("AutoLawRaid", isSea2, "Auto Law Raid only works in Sea 2", function(value2)
        _G.AutoLawKak = value2
        if not value2 and not isFarming() then stopFarming() end
    end))

    task.spawn(function()
        while task.wait(loopDelay) do
            if _G.AutoLawKak then
                pcall(function()
                    value.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2")
                    fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
                    local f12130 = findEnemyByName("Order")
                    if f12130 then
                        repeat
                            task.wait()
                            Mob.Kill(f12130, _G.AutoLawKak)
                        until not _G.AutoLawKak or not f12130.Parent or f12130.Humanoid.Health <= 0
                    else
                        _tp(CFrame.new(-6217.2021484375, 28.047645568848, -5053.1357421875))
                    end
                end)
            end
        end
    end)
    Tabs.Raid:AddSection("Fruit Sniper")

    local fruitRemote = value:WaitForChild("Remotes"):WaitForChild("CommF_")
    local sniperFruitValues = {}

    local function refreshSniperFruitValues()
        local collected = {}
        local success, result = pcall(function()
            return fruitRemote:InvokeServer("GetFruits", false)
        end)
        local success2, result2 = pcall(function()
            return fruitRemote:InvokeServer("GetFruits", true)
        end)

        if success and type(result) == "table" then
            for value2, item in pairs(result) do
                if type(item) == "table" and type(item.Name) == "string" then
                    collected[item.Name] = true
                end
            end
        end
        if success2 and type(result2) == "table" then
            for value2, item in pairs(result2) do
                if type(item) == "table" and type(item.Name) == "string" then
                    collected[item.Name] = true
                end
            end
        end

        local values = {}
        for name in pairs(collected) do
            table.insert(values, name)
        end
        table.sort(values)
        if #values == 0 then
            values = { "Select Fruit" }
        end
        return values
    end

    sniperFruitValues = refreshSniperFruitValues()
    _G.SelectedFruit = nil
    _G.SniperEnabled = false

    Tabs.Raid:AddDropdown("SelectFruit", {
        Title = "Select Sniper Fruit",
        Description = "Choose the fruit to buy when it is in stock",
        Values = sniperFruitValues,
        Multi = false,
        Default = 1,
    }):OnChanged(function(value2)
        if value2 and value2 ~= "Select Fruit" then
            _G.SelectedFruit = value2
        else
            _G.SelectedFruit = nil
        end
    end)

    Tabs.Raid:AddToggle("SniperFruit", {
        Title = "Sniper Fruit",
        Description = "Automatically buys the selected fruit when it is in stock",
        Default = false
    }):OnChanged(function(value2)
        _G.SniperEnabled = value2
    end)

    task.spawn(function()
        while task.wait(3) do
            if _G.SniperEnabled and _G.SelectedFruit then
                pcall(function()
                    local owned = fruitRemote:InvokeServer("GetFruits", false)
                    local stored = fruitRemote:InvokeServer("GetFruits", true)
                    local available = false

                    for value2, list in ipairs({ owned, stored }) do
                        if type(list) == "table" then
                            for value2, item in pairs(list) do
                                if type(item) == "table" and item.Name == _G.SelectedFruit and item.OnSale then
                                    available = true
                                    break
                                end
                            end
                        end
                        if available then break end
                    end

                    if available then
                        fruitRemote:InvokeServer("PurchaseRawFruit", _G.SelectedFruit)
                    end
                end)
            end
        end
    end)

    Tabs.Raid:AddSection("Fruit")

    _G.Random_Auto = false
    _G.StoreF = false
    _G.AutoCollectFruit = false

    Tabs.Raid:AddToggle("AutoRandomFruit", {
        Title = "Random Fruit",
        Description = "Automatically purchases a random fruit",
        Default = false
    }):OnChanged(function(value2)
        _G.Random_Auto = value2
    end)

    task.spawn(function()
        local HttpService = game:GetService("HttpService")
        local SPIN_COOLDOWN = 2 * 60 * 60
        local SPIN_FILE = "AxlHub_RandomFruit.json"
        local accountKey = tostring(localPlayer.UserId)

        local gachaRemote
        pcall(function()
            gachaRemote = value:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/GachaNetworkRF")
        end)

        local Spinner
        pcall(function()
            Spinner = require(value:WaitForChild("Controllers"):WaitForChild("UI"):WaitForChild("Spinner"))
        end)

        local lastSpins = {}
        pcall(function()
            if isfile and isfile(SPIN_FILE) then
                lastSpins = HttpService:JSONDecode(readfile(SPIN_FILE))
            end
        end)
        if type(lastSpins) ~= "table" then lastSpins = {} end

        local function saveSpin()
            lastSpins[accountKey] = os.time()
            pcall(function()
                if writefile then
                    writefile(SPIN_FILE, HttpService:JSONEncode(lastSpins))
                end
            end)
        end

        local function spinnerWindow()
            return localPlayer.PlayerGui:FindFirstChild("SpinnerWindow")
        end

        while task.wait(1) do
            if _G.Random_Auto and gachaRemote then
                pcall(function()
                    local window = spinnerWindow()
                    if window and window.Enabled then

                        local closeButton = window.AboveSpinner.Navigation.CloseButton
                        if closeButton.Visible and Spinner then
                            Spinner:Close()
                        end
                        return
                    end

                    local last = lastSpins[accountKey]
                    if last and os.time() - last < SPIN_COOLDOWN then return end

                    local success, result = pcall(function()
                        return gachaRemote:InvokeServer({
                            Context = "Purchase",
                            BoxName = "ZiolesGacha"
                        })
                    end)
                    local failed = result == false or (type(result) == "table" and result.Success == false)
                    if success and not failed then
                        saveSpin()
                    end
                end)
            end
        end
    end)

    Tabs.Raid:AddToggle("AutoStoreFruit", {
        Title = "Store Fruit",
        Description = "Automatically stores devil fruits in your inventory",
        Default = false
    }):OnChanged(function(value2)
        _G.StoreF = value2
    end)

    task.spawn(function()
        while task.wait(math.max(1, tonumber(loopDelay) or 1)) do
            if _G.StoreF then
                pcall(function()
                    local tools = {}
                    for value2, tool in ipairs(localPlayer.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit")) then
                            table.insert(tools, tool)
                        end
                    end
                    local character = localPlayer.Character
                    if character then
                        for value2, tool in ipairs(character:GetChildren()) do
                            if tool:IsA("Tool") and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit")) then
                                table.insert(tools, tool)
                            end
                        end
                    end

                    for value2, tool in ipairs(tools) do
                        if not _G.StoreF then break end
                        local original = tool:GetAttribute("OriginalName") or tool.Name
                        fruitRemote:InvokeServer("StoreFruit", original, tool)
                        task.wait(0.25)
                    end
                end)
            end
        end
    end)

    Tabs.Raid:AddToggle("AutoCollectFruit", {
        Title = "Collect Fruit",
        Description = "Automatically moves to and collects fruits on the map",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoCollectFruit = value2
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if _G.AutoCollectFruit then
                local targetFruit, handle
                pcall(function()
                    for value2, item in ipairs(Workspace:GetChildren()) do
                        if item:IsA("Tool") and (item.ToolTip == "Blox Fruit" or item.Name:find("Fruit")) then
                            local itemHandle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                            if itemHandle then
                                targetFruit, handle = item, itemHandle
                                break
                            end
                        end
                    end
                end)

                if targetFruit and handle and handle:IsDescendantOf(Workspace) then
                    pcall(function()
                        _tp(handle.CFrame)
                        local started = tick()
                        repeat
                            task.wait(0.15)
                            local character = localPlayer.Character
                            local root = character and character:FindFirstChild("HumanoidRootPart")
                            if not _G.AutoCollectFruit or not targetFruit:IsDescendantOf(Workspace) or not root then
                                break
                            end
                            if (root.Position - handle.Position).Magnitude <= 10 then
                                firetouchinterest(root, handle, 0)
                                task.wait(0.1)
                                firetouchinterest(root, handle, 1)
                                break
                            end
                        until tick() - started >= 15
                    end)
                    task.wait(0.5)
                end
            end
        end
    end)

    Tabs.Raid:AddSection("Hop Fruit")

    Tabs.Raid:AddToggle("AutoAfkJoinFruit", {
        Title = "Auto Collect Fruit Hop",
        Description = "Collects all fruits in the current server, stores them, then hops and repeats",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoAfkJoinFruit = value2
        if type(getgenv().ResetHopFruitTimer) == "function" then
            getgenv().ResetHopFruitTimer()
        end
        if not value2 and not isFarming() then
            stopFarming()
        end
    end)

end

do
    _G.AutoDungeonFull = false
    _G.AutoDungeonShrine = false
    _G.AutoCardsDungeon = false
    _G.AutoUnlockDifficulties = false
    _G.AutoBuyTrinkets = false
    _G.AutoFuseTrinkets = false
    _G.AutoRefineTrinkets = false
    _G.AutoScrapTrinkets = false

    local dgBuffs = {
        { key = "AllCooldown", display = "All Cooldowns", rarity = 5 },
        { key = "AttackSpeedMultiplier", display = "HYPER! (Attack Speed)", rarity = 5 },
        { key = "Overflow", display = "Overflow", rarity = 5 },
        { key = "Shadow", display = "Shadow", rarity = 5 },
        { key = "Fortress", display = "Fortress", rarity = 5 },
        { key = "Lifesteal", display = "Lifesteal", rarity = 4 },
        { key = "Sniper", display = "Sniper", rarity = 4 },
        { key = "Unbreakable", display = "Unbreakable", rarity = 4 },
        { key = "RageGain", display = "Fruit Meter", rarity = 4 },
        { key = "RaceEnergy", display = "Race Meter", rarity = 4 },
        { key = "FruitTAPCooldown", display = "Fruit M1 Speed", rarity = 4 },
        { key = "Armor", display = "Armor", rarity = 3 },
        { key = "Size", display = "Size", rarity = 3 },
        { key = "ConstructHealth", display = "Healing Constructs", rarity = 3 },
        { key = "GunCooldown", display = "Gun Cooldowns", rarity = 3 },
        { key = "SwordCooldown", display = "Sword Cooldowns", rarity = 3 },
        { key = "MeleeCooldown", display = "Melee Cooldowns", rarity = 3 },
        { key = "FruitCooldown", display = "Fruit Cooldowns", rarity = 3 },
        { key = "GunZCooldown", display = "Gun Cooldown (Z Skill)", rarity = 3 },
        { key = "GunXCooldown", display = "Gun Cooldown (X Skill)", rarity = 3 },
        { key = "SwordZCooldown", display = "Sword Cooldown (Z Skill)", rarity = 3 },
        { key = "SwordXCooldown", display = "Sword Cooldown (X Skill)", rarity = 3 },
        { key = "MeleeZCooldown", display = "Melee Cooldown (Z Skill)", rarity = 3 },
        { key = "MeleeXCooldown", display = "Melee Cooldown (X Skill)", rarity = 3 },
        { key = "MeleeCCooldown", display = "Melee Cooldown (C Skill)", rarity = 3 },
        { key = "FruitZCooldown", display = "Fruit Cooldown (Z Skill)", rarity = 3 },
        { key = "FruitXCooldown", display = "Fruit Cooldown (X Skill)", rarity = 3 },
        { key = "FruitCCooldown", display = "Fruit Cooldown (C Skill)", rarity = 3 },
        { key = "FruitVCooldown", display = "Fruit Cooldown (V Skill)", rarity = 3 },
        { key = "Skyjumps", display = "Skyjumps", rarity = 2 },
        { key = "Gun", display = "Gun Stat", rarity = 2 },
        { key = "Sword", display = "Sword Stat", rarity = 2 },
        { key = "Melee", display = "Melee Stat", rarity = 2 },
        { key = "Fruit", display = "Fruit Stat", rarity = 2 },
        { key = "Defense", display = "Defense Stat", rarity = 2 },
    }
    local dgBuffByKey = {}
    local dgBuffByDisplay = {}
    local dgBuffValues = {}
    for value2, b in ipairs(dgBuffs) do
        dgBuffByKey[b.key] = b
        dgBuffByDisplay[b.display] = b
        table.insert(dgBuffValues, b.display)
    end
    local dgCardKeys = {}
    local dgBad = setmetatable({}, { __mode = "k" })
    local dgStart = setmetatable({}, { __mode = "k" })
    local dgNet = nil
    local dgActive = false
    local dgTween = nil
    local dgGoal = nil
    local dgReady = false
    local dgSayKey = nil
    local dgSayTick = 0
    local dgAtkRemote = nil
    local dgAtkId = nil
    local dgHakiTick = 0
    local dgTouchTick = 0
    local dgPlace = game.PlaceId == 73902483975735
    local dgBusy = {}
    local dgMsg = "You need to be inside the Dungeon to use this option"

    task.delay(8, function()
        dgReady = true
    end)

    local function dgSay(key, text)
        if dgSayKey == key and tick() - dgSayTick < 10 then return end
        dgSayKey = key
        dgSayTick = tick()
        Fluent:Notify({ Title = "Dungeon", Content = text, Duration = 4 })
    end

    local function dgRoot()
        local ch = localPlayer.Character
        return ch and ch:FindFirstChild("HumanoidRootPart")
    end

    local function dgDungeon()
        local map = Workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("Dungeon")
    end

    local function dgNetMod()
        if dgNet then return dgNet end
        local success, result = pcall(function()
            return require(value:WaitForChild("Modules"):WaitForChild("Net"))
        end)
        if success then dgNet = result end
        return dgNet
    end

    local function dgCancel()
        if dgTween then
            local tw = dgTween
            dgTween = nil
            dgGoal = nil
            pcall(function()
                tw:Cancel()
                tw:Destroy()
            end)
        end
    end

    local function dgFloat(root, on)
        local loadRemote2 = root:FindFirstChild("DgFloat")
        if on and not loadRemote2 then
            loadRemote2 = Instance.new("BodyVelocity")
            loadRemote2.Name = "DgFloat"
            loadRemote2.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            loadRemote2.Velocity = Vector3.zero
            loadRemote2.Parent = root
        elseif not on and loadRemote2 then
            loadRemote2:Destroy()
        end
    end

    local function dgStop()
        dgActive = false
        dgCancel()
        local ch = localPlayer.Character
        local root = dgRoot()
        if root then
            dgFloat(root, false)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if ch then
            for value2, name in ipairs({ "Head", "UpperTorso", "LowerTorso", "Torso" }) do
                local part = ch:FindFirstChild(name)
                if part then part.CanCollide = true end
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end

    local function dgTo(cf)
        local root = dgRoot()
        if not root then return end
        local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            hum.Jump = true
        end
        dgActive = true
        dgFloat(root, true)
        local dist = (cf.Position - root.Position).Magnitude
        if dist <= 15 then
            dgCancel()
            root.CFrame = cf
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return
        end
        if dgTween and dgGoal and (dgGoal - cf.Position).Magnitude <= 12 then return end
        dgCancel()
        dgGoal = cf.Position
        local tw = TweenService:Create(root, TweenInfo.new(dist / 170, Enum.EasingStyle.Linear), { CFrame = cf })
        dgTween = tw
        tw.Completed:Connect(function()
            if dgTween == tw then
                dgTween = nil
                dgGoal = nil
            end
        end)
        tw:Play()
    end

    local dgCacheChar, dgCacheParts, dgCacheT = nil, {}, 0
    RunService.Stepped:Connect(function()
        if not dgActive then return end
        local ch = localPlayer.Character
        if not ch then return end
        if ch ~= dgCacheChar or tick() - dgCacheT > 2 then
            dgCacheChar, dgCacheT, dgCacheParts = ch, tick(), {}
            for value2, part in ipairs(ch:GetDescendants()) do
                if part:IsA("BasePart") then
                    dgCacheParts[#dgCacheParts + 1] = part
                end
            end
        end
        for value2, part in ipairs(dgCacheParts) do
            if part.Parent then part.CanCollide = false end
        end
    end)

    localPlayer.CharacterAdded:Connect(function()
        dgCancel()
    end)

    local function dgHaki()
        if tick() - dgHakiTick < 3 then return end
        dgHakiTick = tick()
        local ch = localPlayer.Character
        if ch and not ch:FindFirstChild("HasBuso") then
            pcall(function()
                value.Remotes.CommF_:InvokeServer("Buso")
            end)
        end
    end

    local function dgZone(dungeon, root)
        local best, bestDist = nil, math.huge
        for value2, zone in ipairs(dungeon:GetChildren()) do
            local zr = zone:FindFirstChild("Root")
            if zr and zone:FindFirstChild("ExitTeleporter") then
                local d = (zr.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = zone
                end
            end
        end
        return best
    end

    local function dgIsShadow(name)
        return string.find(name, "Shadow", 1, true) ~= nil
    end

    local function dgEnemyOk(mob)
        local hum = mob:FindFirstChild("Humanoid")
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return false end
        if mob.Name == "Blank Buddy" or dgIsShadow(mob.Name) then return false end
        return true
    end

    local function dgShrine()
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        for value2, mob in ipairs(enemies:GetChildren()) do
            if mob.Name == "Shrine" and dgEnemyOk(mob) then
                return mob
            end
        end
        return nil
    end

    local function dgClosest(root, skipProps)
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        local best, bestDist = nil, math.huge
        for value2, mob in ipairs(enemies:GetChildren()) do
            if dgEnemyOk(mob) then
                local isProp = mob.Name == "Shrine" or mob.Name == "PropHitboxPlaceholder"
                if not (skipProps and isProp) then
                    local d = (mob.HumanoidRootPart.Position - root.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = mob
                    end
                end
            end
        end
        return best
    end

    local function dgFarmCF(mob)
        local hrp = mob and mob:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local tool = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == "Blox Fruit" then
            return (hrp.CFrame * CFrame.new(0, 10, 0)) * CFrame.Angles(0, math.rad(90), 0)
        end
        return (hrp.CFrame * CFrame.new(0, 30, 0)) * CFrame.Angles(0, math.rad(180), 0)
    end

    local function dgPickBuff(buffs)
        local bestBuff, bestRarity = nil, -1
        if #dgCardKeys > 0 then
            for value2, buff in ipairs(buffs) do
                for value2, key in ipairs(dgCardKeys) do
                    if buff.buffName == key then
                        local data = dgBuffByKey[buff.buffName]
                        if data and data.rarity > bestRarity then
                            bestRarity = data.rarity
                            bestBuff = buff.buffName
                        end
                    end
                end
            end
            if bestBuff then return bestBuff end
        end
        for value2, buff in ipairs(buffs) do
            local data = dgBuffByKey[buff.buffName]
            if data and data.rarity > bestRarity then
                bestRarity = data.rarity
                bestBuff = buff.buffName
            end
        end
        return bestBuff
    end

    getgenv().DgBuffCallback = function(buffs)
        if _G.AutoCardsDungeon then
            local result = dgPickBuff(buffs)
            if result then return result end
        end
        if getgenv().DgOrigBuffCallback then
            return getgenv().DgOrigBuffCallback(buffs)
        end
    end

    local function dgBring(center, skip)
        if not bringMobsEnabled then return end
        local root = dgRoot()
        local enemies = Workspace:FindFirstChild("Enemies")
        if not root or not enemies then return end
        pcall(function()
            sethiddenproperty(localPlayer, "SimulationRadius", 500)
        end)
        for value2, mob in ipairs(enemies:GetChildren()) do
            if mob ~= skip and dgEnemyOk(mob) and mob.Name ~= "Shrine" and mob.Name ~= "PropHitboxPlaceholder" and not mob:GetAttribute("IsBoss") then
                local hrp = mob.HumanoidRootPart
                local hum = mob.Humanoid
                if (hrp.Position - center).Magnitude <= 225 and (hrp.Position - root.Position).Magnitude <= 225 then
                    if not hrp:FindFirstChild("LockMob") then
                        local bv = Instance.new("BodyVelocity")
                        bv.Name = "LockMob"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.zero
                        bv.Parent = hrp
                    end
                    for value2, p in ipairs(mob:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = false
                        end
                    end
                    local anim = hum:FindFirstChild("Animator")
                    if anim then anim:Destroy() end
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    if (hrp.Position - center).Magnitude > 5 then
                        if type(isnetworkowner) == "function" then
                            if isnetworkowner(hrp) then
                                hrp.CFrame = CFrame.new(center)
                            end
                        else
                            hrp.CFrame = CFrame.new(center)
                        end
                    end
                end
            end
        end
    end

    local function dgFindRemote()
        if dgAtkRemote and dgAtkRemote.Parent then
            return dgAtkRemote, dgAtkId
        end
        for value2, name in ipairs({ "Util", "Common", "Remotes", "Assets", "FX" }) do
            local folder = value:FindFirstChild(name)
            if folder then
                for value2, c in ipairs(folder:GetChildren()) do
                    if c:IsA("RemoteEvent") and c:GetAttribute("Id") then
                        dgAtkRemote = c
                        dgAtkId = c:GetAttribute("Id")
                    end
                end
            end
        end
        return dgAtkRemote, dgAtkId
    end

    local function dgFire(list, head, simple)
        local netFolder = value:FindFirstChild("Modules") and value.Modules:FindFirstChild("Net")
        if not netFolder then return end
        local atk = netFolder:FindFirstChild("RE/RegisterAttack")
        local hit = netFolder:FindFirstChild("RE/RegisterHit")
        if not atk or not hit then return end

        simple = simple or list
        if #simple > 0 then
            pcall(function()
                atk:FireServer(0)
                hit:FireServer(simple[1][2], simple)
            end)
        end

        pcall(function()
            local netMod = dgNetMod()
            local remote, id = dgFindRemote()
            local seed = netFolder:FindFirstChild("seed")
            if not netMod or not remote or not id or not seed then return end
            netMod:RemoteEvent("RegisterHit", true)
            atk:FireServer()
            local uid = tostring(localPlayer.UserId):sub(2, 4)
            local co = tostring(coroutine.running()):sub(11, 15)
            hit:FireServer(head, list, {}, uid .. co)
            local k = (string.gsub("RE/RegisterHit", ".", function(c)
                return string.char(bit32.bxor(string.byte(c), math.floor((Workspace:GetServerTimeNow() / 10) % 10) + 1))
            end))
            local sv = seed:InvokeServer() * 2
            local key = bit32.bxor(id + 909090, sv)
            local cr = cloneref or function(x) return x end
            cr(remote):FireServer(k, key, head, list)
        end)
    end

    local function dgProps(zone)
        local props = zone and zone:FindFirstChild("Props")
        if not props then return nil end
        for value2, p in ipairs(props:GetChildren()) do
            if not dgBad[p] and p:IsA("PVInstance") and (p:GetAttribute("KitsuneMarkActive") == true or p:GetAttribute("Speed") == 5) then
                return p
            end
        end
        return nil
    end

    local dgSkillWeapons = { ["Blox Fruit"] = true, Melee = true, Sword = true, Gun = true }
    local dgSkillKeys = {
        ["Blox Fruit"] = { "Z", "X", "C" },
        Melee = { "Z", "X", "C" },
        Sword = { "Z", "X" },
        Gun = { "Z", "X" },
    }
    local dgSkillDelay = 0.3
    local dgAim = nil

    local function dgKeyList(p)
        local picked = {}
        if type(p) == "table" then
            for k, utilitiesUrl2 in pairs(p) do
                if type(k) == "number" then
                    picked[utilitiesUrl2] = true
                elseif utilitiesUrl2 then
                    picked[k] = true
                end
            end
        end
        local out = {}
        for value2, key in ipairs({ "Z", "X", "C", "V", "F" }) do
            if picked[key] then table.insert(out, key) end
        end
        return out
    end

    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if dgAim and (method == "FireServer" or method == "InvokeServer") then
                local args = table.pack(...)
                if typeof(args[1]) == "Vector3" then
                    args[1] = dgAim
                    return old(self, table.unpack(args, 1, args.n))
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)

    local function dgUseSkills(prop)
        local pos = prop:GetPivot().Position
        local vim = game:GetService("VirtualInputManager")
        dgAim = pos
        for value2, tip in ipairs({ "Blox Fruit", "Melee", "Sword", "Gun" }) do
            if _G.AutoDungeonShrine and dgSkillWeapons[tip] and dgSkillKeys[tip] and #dgSkillKeys[tip] > 0 then
                local ch = localPlayer.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then break end
                local tool = ch:FindFirstChildOfClass("Tool")
                if not tool or tool.ToolTip ~= tip then
                    for value2, t in ipairs(localPlayer.Backpack:GetChildren()) do
                        if t:IsA("Tool") and t.ToolTip == tip then
                            hum:EquipTool(t)
                            task.wait(0.4)
                            break
                        end
                    end
                end
                tool = ch:FindFirstChildOfClass("Tool")
                if tool and tool.ToolTip == tip then
                    for value2, key in ipairs(dgSkillKeys[tip]) do
                        if not _G.AutoDungeonShrine then break end
                        _G.AxlKeyGuard = (_G.AxlKeyGuard or 0) + 1
                        pcall(function()
                            vim:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                            task.wait()
                            vim:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                        end)
                        task.delay(0.4, function()
                            _G.AxlKeyGuard = math.max((_G.AxlKeyGuard or 1) - 1, 0)
                        end)
                        task.wait(dgSkillDelay)
                    end
                end
            end
        end
        dgAim = nil
    end

    local function dgAttack()
        local ch = localPlayer.Character
        local root = dgRoot()
        if not ch or not root then return end
        local tool = ch:FindFirstChildOfClass("Tool")
        if tool and tool:GetAttribute("ServerState") ~= nil then return end

        local list = {}
        local closest, closestDist = nil, math.huge
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return end
        for value2, mob in ipairs(enemies:GetChildren()) do
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local hum = mob:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d <= 60 then
                    if d < closestDist then
                        closest = mob
                        closestDist = d
                    end
                    for value2, part in ipairs(mob:GetChildren()) do
                        if part:IsA("BasePart") then
                            table.insert(list, { mob, part })
                        end
                    end
                end
            end
        end
        if #list == 0 or not closest then return end

        local targetHrp = closest:FindFirstChild("HumanoidRootPart")
        local kind = tool and tool.ToolTip
        local wt = tool and tool:GetAttribute("WeaponType")

        if tool and kind == "Blox Fruit" then
            local lc = tool:FindFirstChild("LeftClickRemote")
            if lc then
                if tool.Name == "Blade-Blade" or tool.Name == "Gas-Gas" then
                    pcall(function()
                        lc:FireServer((targetHrp.Position - root.Position).Unit, 1)
                    end)
                else
                    pcall(function()
                        lc:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                    end)
                end
            end
            return
        end

        local netFolder = value:FindFirstChild("Modules") and value.Modules:FindFirstChild("Net")
        if not netFolder then return end

        if tool and kind == "Gun" then
            local shoot = netFolder:FindFirstChild("RE/ShootGunEvent")
            if shoot then
                pcall(function()
                    shoot:FireServer(targetHrp.Position, { targetHrp })
                end)
            end
            return
        end

        if wt ~= "Melee" and wt ~= "Sword" then return end

        local simple = {}
        for value2, entry in ipairs(list) do
            local h = entry[1]:FindFirstChild("Head")
            if h then table.insert(simple, { entry[1], h }) end
        end
        local head = list[1][1]:FindFirstChild("Head")
        if not head then return end
        dgFire(list, head, simple)
    end

    local function dgUnlock()
        pcall(function()
            local shared = value:FindFirstChild("DungeonShared")
            local data = shared and shared:FindFirstChild("DataRemote")
            if data then
                pcall(function() data:InvokeServer("TryUnlockDifficulty", "Simulation", "Hard") end)
                pcall(function() data:InvokeServer("TryUnlockDifficulty", "Simulation", "Challenge") end)
            end
            local rf = value.Modules.Net:FindFirstChild("RF/DungeonNPCNetworkFunction")
            if rf then
                for value2, arg in ipairs({ "UnlockDifficulty", "UnlockNext", "Unlock" }) do
                    pcall(function() rf:InvokeServer(arg) end)
                end
            end
        end)
    end

    local function dgTrinkets()
        local list = {}
        local success, result = pcall(function()
            return dgNetMod():RemoteFunction("GetAllItemValues"):InvokeServer()
        end)
        if success and type(result) == "table" then
            local seen = {}
            for value2, e in next, result do
                if (e.Key == "AccessoryType" or e.Key == "Type") and e.Value == "Trinket" and e.NetworkedUID and not seen[e.NetworkedUID] then
                    seen[e.NetworkedUID] = true
                    table.insert(list, e.NetworkedUID)
                end
            end
        end
        return list
    end

    local function dgAccessory()
        return value:FindFirstChild("Remotes") and value.Remotes:FindFirstChild("AccessoryInteract")
    end

    local function dgGuard(id, fn)
        return function(p)
            if dgBusy[id] then return end
            if p == true and not dgPlace then
                dgBusy[id] = true
                if not farmPaused or dgReady then
                    Fluent:Notify({ Title = "Dungeon", Content = dgMsg, Duration = 5 })
                end
                pcall(function() Fluent.Options[id]:SetValue(false) end)
                task.delay(0.3, function() dgBusy[id] = nil end)
                return
            end
            fn(p)
        end
    end

    local function dgButton(fn)
        return function()
            if not dgPlace then
                Fluent:Notify({ Title = "Dungeon", Content = dgMsg, Duration = 5 })
                return
            end
            fn()
        end
    end

    Tabs.Dungeon:AddSection("Dungeon")

    Tabs.Dungeon:AddToggle("AutoDungeonFull", {
        Title = "Auto Complete Dungeon",
        Description = "Kills every enemy on each island and moves to the next one",
        Default = false
    }):OnChanged(dgGuard("AutoDungeonFull", function(p)
        _G.AutoDungeonFull = p
        if not p and not _G.AutoDungeonShrine then
            dgStop()
            pcall(function()
                if not isFarming() then stopFarming() end
            end)
        end
    end))

    Tabs.Dungeon:AddToggle("AutoDungeonShrine", {
        Title = "Auto Destroy Shrines and Vents",
        Description = "Gives priority to the shrines and vents, then goes back to the dungeon (also works alone)",
        Default = false
    }):OnChanged(dgGuard("AutoDungeonShrine", function(p)
        _G.AutoDungeonShrine = p
        if not p and not _G.AutoDungeonFull then
            dgStop()
        end
    end))

    Tabs.Dungeon:AddDropdown("ShrineWeapons", {
        Title = "Shrine Weapons",
        Description = "Weapon types used to destroy shrines and vents",
        Values = { "Blox Fruit", "Melee", "Sword", "Gun" },
        Multi = true,
        Default = { "Blox Fruit", "Melee", "Sword", "Gun" },
    }):OnChanged(function(p)
        dgSkillWeapons = {}
        if type(p) == "table" then
            for k, utilitiesUrl2 in pairs(p) do
                if type(k) == "number" then
                    dgSkillWeapons[utilitiesUrl2] = true
                elseif utilitiesUrl2 then
                    dgSkillWeapons[k] = true
                end
            end
        end
    end)

    Tabs.Dungeon:AddDropdown("ShrineFruitKeys", {
        Title = "Blox Fruit Skills",
        Values = { "Z", "X", "C", "V", "F" },
        Multi = true,
        Default = { "Z", "X", "C" },
    }):OnChanged(function(p)
        dgSkillKeys["Blox Fruit"] = dgKeyList(p)
    end)

    Tabs.Dungeon:AddDropdown("ShrineMeleeKeys", {
        Title = "Melee Skills",
        Values = { "Z", "X", "C" },
        Multi = true,
        Default = { "Z", "X", "C" },
    }):OnChanged(function(p)
        dgSkillKeys.Melee = dgKeyList(p)
    end)

    Tabs.Dungeon:AddDropdown("ShrineSwordKeys", {
        Title = "Sword Skills",
        Values = { "Z", "X" },
        Multi = true,
        Default = { "Z", "X" },
    }):OnChanged(function(p)
        dgSkillKeys.Sword = dgKeyList(p)
    end)

    Tabs.Dungeon:AddDropdown("ShrineGunKeys", {
        Title = "Gun Skills",
        Values = { "Z", "X" },
        Multi = true,
        Default = { "Z", "X" },
    }):OnChanged(function(p)
        dgSkillKeys.Gun = dgKeyList(p)
    end)

    Tabs.Dungeon:AddSlider("ShrineSkillDelay", {
        Title = "Skill Delay (ms)",
        Description = "Wait between each skill on shrines and vents",
        Default = 300,
        Min = 50,
        Max = 1000,
        Rounding = 0,
        Callback = function(p)
            dgSkillDelay = (tonumber(p) or 300) / 1000
        end
    })

    Tabs.Dungeon:AddSection("Cards")

    Tabs.Dungeon:AddDropdown("CardsSelection", {
        Title = "Select Cards",
        Description = "Preferred cards (the highest rarity is picked when none is selected)",
        Values = dgBuffValues,
        Multi = true,
        Default = {},
    }):OnChanged(function(p)
        dgCardKeys = {}
        if type(p) == "table" then
            for display, on in pairs(p) do
                if on then
                    local data = dgBuffByDisplay[display]
                    if data then
                        table.insert(dgCardKeys, data.key)
                    end
                end
            end
        end
    end)

    Tabs.Dungeon:AddToggle("AutoCardsDungeon", {
        Title = "Auto Select Cards",
        Description = "Picks the best card by itself when the card screen shows up",
        Default = false
    }):OnChanged(dgGuard("AutoCardsDungeon", function(p)
        _G.AutoCardsDungeon = p
    end))

    Tabs.Dungeon:AddSection("Difficulty")

    Tabs.Dungeon:AddToggle("AutoUnlockDifficulties", {
        Title = "Auto Unlock Difficulties",
        Description = "Unlocks Hard and Challenge using Simulation Data",
        Default = false
    }):OnChanged(dgGuard("AutoUnlockDifficulties", function(p)
        _G.AutoUnlockDifficulties = p
    end))

    Tabs.Dungeon:AddButton({
        Title = "Unlock Next Difficulty",
        Description = "Tries to unlock the next difficulty once",
        Callback = dgButton(function()
            dgUnlock()
            Fluent:Notify({ Title = "Dungeon", Content = "Attempted to unlock difficulty", Duration = 4 })
        end)
    })

    Tabs.Dungeon:AddSection("Teleport")

    Tabs.Dungeon:AddButton({
        Title = "Teleport to Dungeon Map",
        Description = "Goes to the dungeon hub (works from any sea)",
        Callback = function()
            pcall(function()
                value.Modules.Net["RF/DungeonNPCNetworkFunction"]:InvokeServer("TeleportToDungeonHub", false)
            end)
        end
    })

    Tabs.Dungeon:AddButton({
        Title = "Return to Previous Sea",
        Description = "Leaves the dungeon map",
        Callback = dgButton(function()
            pcall(function()
                value.Modules.Net["RF/DungeonNPCNetworkFunction"]:InvokeServer("TeleportBack")
            end)
        end)
    })

    Tabs.Dungeon:AddSection("Trinkets")

    Tabs.Dungeon:AddToggle("AutoBuyTrinkets", {
        Title = "Auto Buy Trinkets",
        Description = "Buys trinkets over and over",
        Default = false
    }):OnChanged(dgGuard("AutoBuyTrinkets", function(p)
        _G.AutoBuyTrinkets = p
    end))

    Tabs.Dungeon:AddToggle("AutoFuseTrinkets", {
        Title = "Auto Fuse Trinkets",
        Description = "Fuses 3 trinkets at a time",
        Default = false
    }):OnChanged(dgGuard("AutoFuseTrinkets", function(p)
        _G.AutoFuseTrinkets = p
    end))

    Tabs.Dungeon:AddToggle("AutoRefineTrinkets", {
        Title = "Auto Refine Trinkets",
        Description = "Refines your trinkets",
        Default = false
    }):OnChanged(dgGuard("AutoRefineTrinkets", function(p)
        _G.AutoRefineTrinkets = p
    end))

    Tabs.Dungeon:AddToggle("AutoScrapTrinkets", {
        Title = "Auto Scrap Trinkets",
        Description = "Scraps extra trinkets and keeps the first 3",
        Default = false
    }):OnChanged(dgGuard("AutoScrapTrinkets", function(p)
        _G.AutoScrapTrinkets = p
    end))

    task.spawn(function()
        while task.wait() do
            if not _G.AutoDungeonFull and not _G.AutoDungeonShrine then
                if dgActive then dgStop() end
                continue
            end
            pcall(function()
                local dungeon = dgDungeon()
                if not dungeon then
                    dgSay("nomap", "Dungeon map was not found in Workspace.Map")
                    return
                end

                local char = localPlayer.Character
                local root = dgRoot()
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not root or not hum or hum.Health <= 0 then return end

                dgActive = true
                dgHaki()

                local zone = dgZone(dungeon, root)
                if not zone then
                    dgSay("nozone", "No dungeon zone with an exit teleporter was found")
                    return
                end
                local exitModel = zone:FindFirstChild("ExitTeleporter")
                local exitRoot = exitModel and exitModel:FindFirstChild("Root")
                if not exitRoot then
                    dgSay("noexit", "Exit teleporter root was not found")
                    return
                end

                if _G.AutoDungeonShrine then
                    local prop = dgProps(zone)
                    if prop then
                        if not dgStart[prop] then
                            dgStart[prop] = tick()
                        end
                        if tick() - dgStart[prop] > 60 then
                            dgBad[prop] = true
                            return
                        end
                        dgSay("shrine", "Destroying shrines and vents")
                        local pos = prop:GetPivot().Position
                        if (root.Position - pos).Magnitude > 10 then
                            dgTo(CFrame.new(pos + Vector3.new(0, 5, 0)))
                        else
                            dgCancel()
                            dgUseSkills(prop)
                        end
                        return
                    end
                    local shrine = dgShrine()
                    if shrine then
                        dgSay("shrine", "Destroying the shrine")
                        equipWeaponType(_G.SelectWeapon)
                        local cf = dgFarmCF(shrine)
                        if cf then dgTo(cf) end
                        return
                    end
                end

                if not _G.AutoDungeonFull then return end

                if exitRoot:FindFirstChild("BBG") then
                    dgSay("exit", "Exit is open, going to the exit teleporter")
                    dgTo(exitRoot.CFrame)
                    return
                end

                local target = dgClosest(root, not _G.AutoDungeonShrine)
                if target then
                    if target.Name == "PropHitboxPlaceholder" then
                        target.Humanoid.Health = 0
                        return
                    end
                    dgSay("fight", "Fighting enemies")
                    equipWeaponType(_G.SelectWeapon)
                    local tr = target:FindFirstChild("HumanoidRootPart")
                    if tr then
                        dgBring(tr.Position, target)
                    end
                    local cf = dgFarmCF(target)
                    if cf then dgTo(cf) end
                else
                    dgSay("exit", "No enemies left, going to the exit teleporter")
                    dgTo(exitRoot.CFrame)
                end
            end)
        end
    end)

    task.spawn(function()
        while true do
            if (_G.AutoDungeonFull or _G.AutoDungeonShrine) and _G.OtherAutoAttack then
                pcall(dgAttack)
                task.wait(0.05)
            else
                task.wait(0.5)
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local shared = value:FindFirstChild("DungeonShared")
                local remote = shared and shared:FindFirstChild("BuffSelector")
                if not remote then return end
                local current = getcallbackvalue(remote, "OnClientInvoke")
                if current and current ~= getgenv().DgBuffCallback then
                    getgenv().DgOrigBuffCallback = current
                    remote.OnClientInvoke = getgenv().DgBuffCallback
                end
            end)
        end
    end)

    task.spawn(function()
        while task.wait(5) do
            if _G.AutoUnlockDifficulties and not dgDungeon() then
                dgUnlock()
            end
        end
    end)

    task.spawn(function()
        while task.wait(1.5) do
            if _G.AutoBuyTrinkets then
                pcall(function()
                    local remote = dgAccessory()
                    if remote then remote:InvokeServer("d") end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            if _G.AutoFuseTrinkets then
                pcall(function()
                    local uids = dgTrinkets()
                    local remote = dgAccessory()
                    if remote and #uids >= 3 then
                        remote:InvokeServer("a", uids[1], uids[2], uids[3])
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            if _G.AutoRefineTrinkets then
                pcall(function()
                    local uids = dgTrinkets()
                    local remote = dgAccessory()
                    if remote and #uids >= 1 then
                        remote:InvokeServer("c", uids[1])
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(3) do
            if _G.AutoScrapTrinkets then
                pcall(function()
                    local uids = dgTrinkets()
                    local remote = dgAccessory()
                    if remote and #uids > 3 then
                        local extra = {}
                        for i = 4, math.min(#uids, 10) do
                            table.insert(extra, uids[i])
                        end
                        if #extra > 0 then
                            remote:InvokeServer("b", extra)
                        end
                    end
                end)
            end
        end
    end)
end

do
    Tabs.Travel:AddSection("Travel Worlds")

    Tabs.Travel:AddButton({
        Title = "Teleport Sea 1",
        Description = "",
        Callback = function()
            value.Remotes.CommF_:InvokeServer("TravelMain")
        end
    })

    Tabs.Travel:AddButton({
        Title = "Teleport Sea 2",
        Description = "",
        Callback = function()
            value.Remotes.CommF_:InvokeServer("TravelDressrosa")
        end
    })

    Tabs.Travel:AddButton({
        Title = "Teleport Sea 3",
        Description = "",
        Callback = function()
            value.Remotes.CommF_:InvokeServer("TravelZou")
        end
    })

    Tabs.Travel:AddSection("Islands")

    local islandData = {}
    if isSea1 then
        islandData = {
            ["Start Island"] = CFrame.new(1071.2832, 16.3085976, 1426.86792),
            ["Marine Start"] = CFrame.new(-2573.3374, 6.88881969, 2046.99817),
            ["Middle Town"] = CFrame.new(-655.824158, 7.88708115, 1436.67908),
            Jungle = CFrame.new(-1249.77222, 11.8870859, 341.356476),
            ["Pirate Village"] = CFrame.new(-1122.34998, 4.78708982, 3855.91992),
            Desert = CFrame.new(1094.14587, 6.47350502, 4192.88721),
            ["Frozen Village"] = CFrame.new(1198.00928, 27.0074959, -1211.73376),
            MarineFord = CFrame.new(-4505.375, 20.687294, 4260.55908),
            Colosseum = CFrame.new(-1428.35474, 7.38933945, -3014.37305),
            ["Sky 1st Floor"] = CFrame.new(-4970.21875, 717.707275, -2622.35449),
            ["Sky 2st Floor"] = CFrame.new(-4813.0249, 903.708557, -1912.69055),
            ["Sky 3st Floor"] = CFrame.new(-7952.31006, 5545.52832, -320.704956),
            Prison = CFrame.new(4854.16455, 5.68742752, 740.194641),
            ["Magma Village"] = CFrame.new(-5231.75879, 8.61593437, 8467.87695),
            ["UndeyWater City"] = CFrame.new(61163.8516, 11.7796879, 1819.78418),
            ["Fountain City"] = CFrame.new(5132.7124, 4.53632832, 4037.8562),
            ["House Cyborg's"] = CFrame.new(6262.72559, 71.3003616, 3998.23047),
            ["Shank's Room"] = CFrame.new(-1442.16553, 29.8788261, -28.3547478),
            ["Mob Island"] = CFrame.new(-2850.20068, 7.39224768, 5354.99268),
        }
    elseif isSea2 then
        islandData = {
            ["First Spot"] = CFrame.new(82.9490662, 18.0710983, 2834.98779),
            ["Kingdom of Rose"] = { location = "Kingdom of Rose" },
            ["Dark Ares"] = { location = "Dark Arena" },
            ["Flamingo Mansion"] = CFrame.new(-390.096313, 331.886475, 673.464966),
            ["Flamingo Room"] = CFrame.new(2302.19019, 15.1778421, 663.811035),
            ["Green bit"] = CFrame.new(-2372.14697, 72.9919434, -3166.51416),
            Cafe = CFrame.new(-385.250916, 73.0458984, 297.388397),
            Factroy = CFrame.new(430.42569, 210.019623, -432.504791),
            Colosseum = CFrame.new(-1836.58191, 44.5890656, 1360.30652),
            ["Ghost Island"] = CFrame.new(-5571.84424, 195.182297, -795.432922),
            ["Ghost Island 2nd"] = CFrame.new(-5931.77979, 5.19706631, -1189.6908),
            ["Snow Mountain"] = CFrame.new(1384.68298, 453.569031, -4990.09766),
            ["Hot and Cold"] = CFrame.new(-6026.96484, 14.7461271, -5071.96338),
            ["Magma Side"] = CFrame.new(-5478.39209, 15.9775667, -5246.9126),
            ["Cursed Ship"] = CFrame.new(902.059143, 124.752518, 33071.8125),
            ["Frosted Island"] = CFrame.new(5400.40381, 28.21698, -6236.99219),
            ["Forgotten Island"] = CFrame.new(-3043.31543, 238.881271, -10191.5791),
            ["Usoapp Island"] = CFrame.new(4748.78857, 8.35370827, 2849.57959),
            ["Raids Low"] = CFrame.new(-5554.95313, 329.075623, -5930.31396),
            Minisky = CFrame.new(-260.358917, 49325.7031, -35259.3008),
        }
    elseif isSea3 then
        islandData = {
            ["Port Town"] = CFrame.new(-287, 30, 5388),
            ["Hydar Island"] = CFrame.new(3399.32227, 72.4142914, 1572.99963, -0.809679806, -4.48284467E-8, 0.586871922, 2.42332163E-8, 1, 1.09818842E-7, -0.586871922, 1.0313989E-7, -0.809679806),
            ["Room Enma/Yama & Secret Temple"] = CFrame.new(5247, 7, 1097),
            ["House Hydar Island"] = CFrame.new(5245, 602, 251),
            ["Great Tree"] = CFrame.new(2443, 36, -6573),
            ["Castle on the sea"] = CFrame.new(-5500, 314, -2855),
            Mansion = CFrame.new(-12548, 337, -7481),
            ["Floating Turtle"] = CFrame.new(-10016, 332, -8326),
            ["Haunted Castle"] = CFrame.new(-9509.34961, 142.130661, 5535.16309),
            ["Peanut Island"] = CFrame.new(-2131, 38, -10106),
            ["Ice Cream Island"] = CFrame.new(-950, 59, -10907),
            CakeLoaf = CFrame.new(-1762, 38, -11878),
            Tiki = CFrame.new(-16204.0810546875, 9.0863618850708, 479.2259521484375),
        }
    end

    local list = {}
    for name in pairs(islandData) do
        table.insert(list, name)
    end
    table.sort(list)
    if #list == 0 then
        list = { "None" }
    end

    local value2 = list[1]

    Tabs.Travel:AddDropdown("SelectIsland", {
        Title = "Select Island",
        Description = "Select the island to travel to",
        Values = list,
        Multi = false,
        Default = 1,
    }):OnChanged(function(value3)
        value2 = value3
    end)

    Tabs.Travel:AddToggle("AutoTweenIsland", {
        Title = "Auto Tween to Island",
        Description = "Automatic teleport to the selected island",
        Default = false
    }):OnChanged(function(value3)
        _G.TweenIsland = value3
        if not value3 and not isFarming() then
            stopFarming()
        end
    end)

    task.spawn(function()
        while task.wait(loopDelay) do
            pcall(function()
                if not _G.TweenIsland then return end
                local entry = islandData[value2]
                if typeof(entry) == "table" then

                    local locations = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
                    local location = locations and locations:FindFirstChild(entry.location)
                    entry = location and location.CFrame or nil
                end
                if entry then
                    _tp(entry)
                end
            end)
        end
    end)

    Tabs.Travel:AddSection("NPC")

    local list = {}
    pcall(function()
        for index, item in pairs(value.NPCs:GetChildren()) do
            table.insert(list, item.Name)
        end
    end)
    table.sort(list)
    if #list == 0 then
        list = { "None" }
    end

    local value2 = list[1]

    Tabs.Travel:AddDropdown("SelectNpc", {
        Title = "Select Npc",
        Description = "",
        Values = list,
        Multi = false,
        Default = 1,
    }):OnChanged(function(value3)
        value2 = value3
    end)

    Tabs.Travel:AddToggle("AutoTweenToNpc", {
        Title = "Auto Tween to Npc",
        Description = "Automatic teleport to pos Npc",
        Default = false
    }):OnChanged(function(value3)
        _G.TPNpc = value3
        if not value3 and not isFarming() then
            stopFarming()
        end
    end)

    task.spawn(function()
        while task.wait(loopDelay) do
            if _G.TPNpc then
                pcall(function()
                    for index, item in pairs(value.NPCs:GetChildren()) do
                        if item.Name == value2 and item:FindFirstChild("HumanoidRootPart") then
                            _tp(item.HumanoidRootPart.CFrame)
                        end
                    end
                end)
            end
        end
    end)

    Tabs.Travel:AddSection("Server")

    local serverBrowser = value:FindFirstChild("__ServerBrowser")
    local flag = false

    Tabs.Travel:AddInput("ServerJobId", {
        Title = "Job ID",
        Description = "Paste a Job ID and press Enter to join automatically",
        Default = "",
        Placeholder = "Job ID",
        Numeric = false,
        Finished = true,
    }):OnChanged(function(value2)
        local gsub = tostring(value2 or ""):gsub("[`%s]", "")
        if #gsub < 10 then return end
        if gsub == game.JobId then return end
        if not serverBrowser then
            Fluent:Notify({ Title = "Axl Hub", Content = "Server browser not found", Duration = 5 })
            return
        end
        Fluent:Notify({ Title = "Axl Hub", Content = "Joining server...", Duration = 5 })
        task.spawn(function()
            pcall(function()
                serverBrowser:InvokeServer("teleport", gsub)
            end)
        end)
    end)

    Tabs.Travel:AddButton({
        Title = "Server Hop",
        Description = "Hops to another server with free slots",
        Callback = function()
            if flag then return end
            if not serverBrowser then
                Fluent:Notify({ Title = "Axl Hub", Content = "Server browser not found", Duration = 5 })
                return
            end
            flag = true
            Fluent:Notify({ Title = "Axl Hub", Content = "Searching for a server...", Duration = 5 })
            task.spawn(function()
                local flag2 = false
                for item = 1, 100 do
                    if flag2 then break end
                    task.spawn(function()
                        if flag2 then return end
                        local success, result = pcall(function()
                            return serverBrowser:InvokeServer(item)
                        end)
                        if success and type(result) == "table" then
                            for index, item in pairs(result) do
                                if not flag2 and type(item) == "table" and item.Count and item.Count < 12 and index ~= game.JobId then
                                    flag2 = true
                                    Fluent:Notify({ Title = "Axl Hub", Content = "Server found! Teleporting...", Duration = 5 })
                                    pcall(function()
                                        serverBrowser:InvokeServer("teleport", index)
                                    end)
                                end
                            end
                        end
                    end)
                end
                task.wait(10)
                flag = false
            end)
        end
    })

    Tabs.Travel:AddButton({
        Title = "Rejoin",
        Description = "Rejoins the current server",
        Callback = function()
            if not serverBrowser then
                Fluent:Notify({ Title = "Axl Hub", Content = "Server browser not found", Duration = 5 })
                return
            end
            Fluent:Notify({ Title = "Axl Hub", Content = "Rejoining current server...", Duration = 3 })
            pcall(function()
                serverBrowser:InvokeServer("teleport", game.JobId)
            end)
        end
    })
end

do
    local hopGui = game:GetService("GuiService")
    local hopApi = "https://api.quantumonyx.cc"
    local hopKey = "QnTmOnyX"
    local hopChars = "kQ9mZ2xW7nR4vB1jY6tF3hD8pL5cG0sA"
    local hopDelay = 2
    local hopBusy = false
    local hopTried = {}
    local hopStart = tick()
    local hopFruitName = nil
    local hopLast = { castle = tick(), factory = tick(), boss = tick(), elite = tick(), eliteQuest = 0, fruit = tick() }
    getgenv().ResetHopFruitTimer = function()
        hopLast.fruit = tick()
    end

    local hopBossSlugs = {
        ["Greybeard"] = "greybeard",
        ["Darkbeard"] = "darkbeard",
        ["Cursed Captain"] = "cursedcaptain",
        ["rip_indra True Form"] = "ripindra",
        ["Soul Reaper"] = "soulreaper",
        ["Cake Prince"] = "cakeprince",
        ["Dough King"] = "doughking",
        ["Tyrant of the Skies"] = "tyrant",
    }

    local hopBossValues = { "Greybeard", "Darkbeard" }
    if isSea3 then
        hopBossValues = { "Greybeard", "Darkbeard", "Cursed Captain", "rip_indra True Form", "Soul Reaper", "Cake Prince", "Dough King", "Tyrant of the Skies" }
    end

    local hopBoss = hopBossValues[1]
    local hopSword = "Shizu"

    local hopRaidMobs = {
        "Galley Pirate", "Galley Captain", "Raider", "Mercenary", "Vampire", "Zombie",
        "Snow Trooper", "Winter Warrior", "Lab Subordinate", "Horned Warrior", "Magma Ninja", "Lava Pirate",
        "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer", "Arctic Warrior", "Snow Lurker",
        "Sea Soldier", "Water Fighter",
    }
    local hopCastlePos = Vector3.new(-5539.3115234375, 313.80053710938, -2972.3723144531)

    local function hopNotify(value2)
        Fluent:Notify({ Title = "Axl Hub", Content = value2, Duration = 4 })
    end

    local function hopXor(value2, value3)
        return (value2 - hopKey:byte((value3 - 1) % #hopKey + 1) - value3) % 32
    end

    local function hopDecrypt(value2)
        local cleaned = value2:gsub("^%.", ""):gsub("%.$", "")
        local filtered = {}
        local n = 0
        for i = 1, #cleaned do
            n = n + 1
            if n % 5 ~= 0 then
                table.insert(filtered, cleaned:sub(i, i))
            end
        end
        local joined = table.concat(filtered)
        local out = {}
        local i = 1
        local counter = 1
        while i <= #joined do
            local c1 = joined:sub(i, i)
            local c2 = joined:sub(i + 1, i + 1)
            local a = hopChars:find(c1, 1, true)
            local b = hopChars:find(c2, 1, true)
            if a and b then
                table.insert(out, string.char(hopXor(a - 1, counter) + hopXor(b - 1, counter + 100) * 32))
            end
            i = i + 2
            counter = counter + 1
        end
        return table.concat(out)
    end

    local function hopHttpGet(value2)
        local req = (syn and syn.request) or http_request or request
        if req then
            local success, result = pcall(req, {
                Url = value2,
                Method = "GET",
                Headers = { ["Content-Type"] = "application/json" }
            })
            if success and result then
                return result.StatusCode, result.Body
            end
        end
        local success, result = pcall(function()
            return game:HttpGet(value2)
        end)
        if success and type(result) == "string" then
            return 200, result
        end
        return nil, nil
    end

    local function hopLogs(value2, value3)
        if type(value2) ~= "table" then return nil end
        if type(value2[value3]) == "table" then return value2[value3] end
        if #value2 > 0 then return value2 end
        for value3, value3 in pairs(value2) do
            if type(value3) == "table" and #value3 > 0 then
                return value3
            end
        end
        return nil
    end

    local function hopFetch(value2, value3)
        local status, body = hopHttpGet(hopApi .. "/api/logs/" .. value2)
        if not body or status ~= 200 then return {} end

        local success, result = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if not success or type(result) ~= "table" then return {} end

        local logs = hopLogs(result, value2)
        if not logs then return {} end

        local candidates, matched, seen = {}, {}, {}

        for i = #logs, 1, -1 do
            local entry = logs[i]
            if type(entry) == "table" then
                local raw = entry.jobId or entry.JobId
                if type(raw) == "string" and raw ~= "" then
                    local jobId = raw
                    if not jobId:match("^%x+%-%x+%-%x+%-%x+%-%x+$") then
                        local success, result = pcall(hopDecrypt, raw)
                        jobId = success and result or ""
                    end
                    if #jobId == 36 and jobId ~= game.JobId and not seen[jobId] and (not entry.placeId or tostring(entry.placeId) == tostring(game.PlaceId)) then
                        seen[jobId] = true
                        local item = { jobId = jobId }
                        table.insert(candidates, item)
                        if value3 then
                            local success, result = pcall(function()
                                return HttpService:JSONEncode(entry):lower()
                            end)
                            if success and result:find(value3:lower(), 1, true) then
                                table.insert(matched, item)
                            end
                        end
                    end
                end
            end
        end

        if value3 and #matched > 0 then
            return matched
        end
        return candidates
    end

    local function hopTeleport(value2)
        local browser = value:FindFirstChild("__ServerBrowser")
        if browser then
            local ok = pcall(function()
                browser:InvokeServer("teleport", value2)
            end)
            return ok
        end
        local ok2 = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, value2, localPlayer)
        end)
        return ok2
    end

    local function hopWait(value2)
        local startJob = game.JobId
        local startTime = tick()
        local failed = false
        local conn = TeleportService.TeleportInitFailed:Connect(function()
            failed = true
            pcall(function()
                hopGui:ClearError()
            end)
        end)
        while tick() - startTime < value2 do
            task.wait(0.2)
            if game.JobId ~= startJob then
                pcall(function()
                    conn:Disconnect()
                end)
                return true
            end
            if failed then
                break
            end
        end
        pcall(function()
            conn:Disconnect()
        end)
        return false
    end

    local function hopJoin(value2, value3, value4)
        if hopBusy then return false end
        hopBusy = true
        local joined = false
        pcall(function()
            if not value4 then
                hopNotify("Searching for a server...")
            end
            local candidates = hopFetch(value2, value3)
            local tried = false
            for value2, candidate in ipairs(candidates) do
                local last = hopTried[candidate.jobId]
                if not last or tick() - last > 120 then
                    tried = true
                    hopTried[candidate.jobId] = tick()
                    if not value4 then
                        hopNotify("Server found! Teleporting...")
                    end
                    if hopTeleport(candidate.jobId) and hopWait(6) then
                        joined = true
                        break
                    end
                    task.wait(hopDelay)
                end
            end
            if not tried and not value4 then
                hopNotify("No server available right now")
            end
        end)
        hopBusy = false
        return joined
    end

getgenv().AxlHopJoin = hopJoin
    local function hopButton(value2, value3, value4, value5, value6, value7)
        Tabs.Hop:AddButton({
            Title = value2,
            Description = value3,
            Callback = function()
                if not value4 then
                    hopNotify(value5)
                    return
                end
                local word = nil
                if type(value7) == "function" then
                    word = value7()
                end
                task.spawn(hopJoin, value6, word, false)
            end
        })
    end

    Tabs.Hop:AddSection("Events")

    hopButton("Join Mirage Island Server", "Joins a server with Mirage Island (Sea 3)", isSea3, "Mirage Island only works in Sea 3", "mirage")
    hopButton("Join Kitsune Island Server", "Joins a server with Kitsune Island (Sea 3)", isSea3, "Kitsune Island only works in Sea 3", "kitsune")
    hopButton("Join Prehistoric Island Server", "Joins a server with Prehistoric Island (Sea 3)", isSea3, "Prehistoric Island only works in Sea 3", "prehistoric")
    hopButton("Join Elite Hunter Server", "Joins a server with an Elite Hunter (Sea 3)", isSea3, "Elite Hunter only works in Sea 3", "elites")
    hopButton("Join 4 Hours Server", "Joins a server with 4 hours or more", true, "", "fourhours")

    Tabs.Hop:AddSection("Raids")

    hopButton("Join Factory Raid Server", "Joins a server with the Factory Raid (Sea 2)", isSea2, "Factory Raid only works in Sea 2", "factory")
    hopButton("Join Castle Raid Server", "Joins a server with the Castle Raid (Sea 3)", isSea3, "Castle Raid only works in Sea 3", "pirate")

    Tabs.Hop:AddSection("Legendary Sword")

    Tabs.Hop:AddDropdown("SelectLegendarySword", {
        Title = "Select Legendary Sword",
        Description = "Select the legendary sword (Sea 2)",
        Values = { "Shizu", "Oroshi", "Saishi" },
        Multi = false,
        Default = 1,
    }):OnChanged(function(value2)
        hopSword = value2
    end)

    hopButton("Join Legendary Sword Server", "Joins a server with the selected legendary sword (Sea 2)", isSea2, "Legendary Sword only works in Sea 2", "legendarysword", function()
        return hopSword
    end)

    Tabs.Hop:AddSection("Boss")

    Tabs.Hop:AddDropdown("SelectBosstoHop", {
        Title = "Select Boss",
        Description = "Select the boss to hop to",
        Values = hopBossValues,
        Multi = false,
        Default = 1,
    }):OnChanged(function(value2)
        hopBoss = value2
        _G.SelectBosstoHop = value2
    end)

    Tabs.Hop:AddButton({
        Title = "Join Raid Boss Server",
        Description = "Joins a server with the selected boss",
        Callback = function()
            local slug = hopBossSlugs[hopBoss]
            if not slug then
                hopNotify("Select a boss first")
                return
            end
            task.spawn(hopJoin, slug, nil, false)
        end
    })

    Tabs.Hop:AddSection("Join Servers Afk")

    Tabs.Hop:AddToggle("AutoAfkJoinCastleRaid", {
        Title = "Auto Afk Join Castle Raid",
        Description = "Keeps hopping until a Castle Raid is found (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoAfkJoinCastleRaid", isSea3, "Auto Afk Join Castle Raid only works in Sea 3", function(value2)
        _G.AutoAfkJoinCastleRaid = value2
        hopLast.castle = tick()
    end))

    Tabs.Hop:AddToggle("AutoAfkJoinFactoryRaid", {
        Title = "Auto Afk Join Factory Raid",
        Description = "Keeps hopping until a Factory Raid is found (Sea 2)",
        Default = false
    }):OnChanged(guardToggle("AutoAfkJoinFactoryRaid", isSea2, "Auto Afk Join Factory Raid only works in Sea 2", function(value2)
        _G.AutoAfkJoinFactoryRaid = value2
        hopLast.factory = tick()
    end))

    Tabs.Hop:AddToggle("AutoAfkJoinBossRaid", {
        Title = "Auto Afk Join Boss Raid",
        Description = "Keeps hopping until the selected boss is found",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoAfkJoinBossRaid = value2
        hopLast.boss = tick()
    end)

    Tabs.Hop:AddToggle("AutoAfkJoinEliteHunter", {
        Title = "Auto Afk Join Elite Hunter",
        Description = "Keeps hopping until an Elite Hunter is found (Sea 3)",
        Default = false
    }):OnChanged(guardToggle("AutoAfkJoinEliteHunter", isSea3, "Auto Afk Join Elite Hunter only works in Sea 3", function(value2)
        _G.AutoAfkJoinEliteHunter = value2
        hopLast.elite = tick()
    end))

    Tabs.Hop:AddToggle("StopHopEliteIfChalice", {
        Title = "Stop Hop If Chalice / Fist",
        Description = "Stops the Elite Hunter hop when you have a Chalice or Fist of Darkness",
        Default = true
    })

    local function hopHasTool(value2)
        return (localPlayer.Backpack:FindFirstChild(value2) or (localPlayer.Character and localPlayer.Character:FindFirstChild(value2))) and true or false
    end

    local function hopBossAlive(value2)
        local names = { value2 }
        if value2 == "rip_indra True Form" then
            names = { "rip_indra True Form", "rip_indra" }
        end
        local enemies = Workspace:FindFirstChild("Enemies")
        for value2, name in ipairs(names) do
            for value2, container in ipairs({ enemies, value }) do
                if container then
                    local model = container:FindFirstChild(name)
                    if model then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if not hum or hum.Health > 0 then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    local function hopElitePresent()
        local enemies = Workspace:FindFirstChild("Enemies")
        for value2, name in ipairs({ "Diablo", "Deandre", "Urban" }) do
            if value:FindFirstChild(name) or (enemies and enemies:FindFirstChild(name)) then
                return true
            end
        end
        return false
    end

    local function hopRaidActive()
        for value2, child in ipairs(value:GetChildren()) do
            if table.find(hopRaidMobs, child.Name) then
                return true
            end
        end
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for value2, child in ipairs(enemies:GetChildren()) do
                if table.find(hopRaidMobs, child.Name) then
                    local root = child:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - hopCastlePos).Magnitude <= 2000 then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function hopCoreAlive()
        local enemies = Workspace:FindFirstChild("Enemies")
        return (value:FindFirstChild("Core") or (enemies and enemies:FindFirstChild("Core"))) and true or false
    end

    local hopIgnoredFruits = {}

    local function hopHasFruit(name)
        for value2, container in ipairs({ localPlayer.Backpack, localPlayer.Character }) do
            if container then
                for value2, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and item.Name == name and (item.ToolTip == "Blox Fruit" or item.Name:find("Fruit")) then
                        return true
                    end
                end
            end
        end

        local owned = false
        pcall(function()
            local remote = value:FindFirstChild("Remotes") and value.Remotes:FindFirstChild("CommF_")
            if not remote then return end
            local inventory = remote:InvokeServer("GetFruits", false)
            local storage = remote:InvokeServer("GetFruits", true)
            for value2, list in pairs({ inventory, storage }) do
                if type(list) == "table" then
                    for value2, item in pairs(list) do
                        if type(item) == "table" and item.Name == name then
                            owned = true
                            return
                        end
                    end
                end
            end
        end)
        return owned
    end
    local function hopFindFruit()
        for value2, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Tool") and not hopIgnoredFruits[child] then
                local ok = child.ToolTip == "Blox Fruit" or child.Name:find("Fruit") or child:FindFirstChild("Handle")
                if ok then
                    local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
                    if handle then
                        return child, handle
                    end
                end
            end
        end
        return nil, nil
    end

    task.spawn(function()
        while task.wait(0.4) do
            if farmPaused or tick() - hopStart < 2.5 then
                local now = tick()
                hopLast.castle = now
                hopLast.factory = now
                hopLast.boss = now
                hopLast.elite = now
                hopLast.fruit = now
                continue
            end

            pcall(function()
                if _G.AutoAfkJoinBossRaid and not hopBusy then
                    if hopBoss and hopBossAlive(hopBoss) then
                        hopLast.boss = tick()
                    elseif tick() - hopLast.boss >= 3 then
                        hopLast.boss = tick()
                        local slug = hopBossSlugs[hopBoss]
                        if slug then
                            task.spawn(hopJoin, slug, nil, true)
                        end
                    end
                end

                if _G.AutoAfkJoinEliteHunter and not hopBusy then
                    local stop = Options.StopHopEliteIfChalice and Options.StopHopEliteIfChalice.Value
                    if stop and (hopHasTool("God's Chalice") or hopHasTool("Sweet Chalice") or hopHasTool("Fist of Darkness")) then
                        _G.AutoAfkJoinEliteHunter = false
                        pcall(function()
                            Options.AutoAfkJoinEliteHunter:SetValue(false)
                        end)
                        hopNotify("Chalice / Fist detected! Stopped auto elite hop.")
                    elseif hopElitePresent() then
                        hopLast.elite = tick()
                    else
                        if tick() - hopLast.eliteQuest >= 1.5 then
                            hopLast.eliteQuest = tick()
                            pcall(function()
                                value.Remotes.CommF_:InvokeServer("EliteHunter")
                            end)
                            task.wait(0.2)
                        end
                        if hopElitePresent() then
                            hopLast.elite = tick()
                        elseif tick() - hopLast.elite >= 3 then
                            hopLast.elite = tick()
                            task.spawn(hopJoin, "elites", nil, true)
                        end
                    end
                end

                if _G.AutoAfkJoinCastleRaid and not hopBusy then
                    if hopRaidActive() then
                        hopLast.castle = tick()
                    elseif tick() - hopLast.castle >= 10 then
                        hopLast.castle = tick()
                        task.spawn(hopJoin, "pirate", nil, true)
                    end
                end

                if _G.AutoAfkJoinFactoryRaid and not hopBusy then
                    if hopCoreAlive() then
                        hopLast.factory = tick()
                    elseif tick() - hopLast.factory >= 3 then
                        hopLast.factory = tick()
                        task.spawn(hopJoin, "factory", nil, true)
                    end
                end

                if _G.AutoAfkJoinFruit then
                    local fruit, handle = hopFindFruit()
                    if fruit and handle then
                        if hopHasFruit(fruit.Name) then
                            hopIgnoredFruits[fruit] = true
                        else
                            hopLast.fruit = tick()
                            local existingTools = {}
                            for value2, container in ipairs({ localPlayer.Backpack, localPlayer.Character }) do
                                if container then
                                    for value2, item in ipairs(container:GetChildren()) do
                                        existingTools[item] = true
                                    end
                                end
                            end

                            local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                _tp(handle.CFrame)
                                local started = tick()
                                repeat
                                    task.wait(0.15)
                                    local character = localPlayer.Character
                                    root = character and character:FindFirstChild("HumanoidRootPart")
                                    if not _G.AutoAfkJoinFruit or not fruit:IsDescendantOf(Workspace) or not root then
                                        break
                                    end
                                    if (root.Position - handle.Position).Magnitude <= 10 then
                                        pcall(function()
                                            firetouchinterest(root, handle, 0)
                                            task.wait(0.1)
                                            firetouchinterest(root, handle, 1)
                                        end)
                                        break
                                    end
                                until tick() - started >= 15
                            end

                            local collectedTool
                            local collectStarted = tick()
                            repeat
                                task.wait(0.2)
                                for value2, container in ipairs({ localPlayer.Backpack, localPlayer.Character }) do
                                    if container then
                                        for value2, item in ipairs(container:GetChildren()) do
                                            if item:IsA("Tool") and not existingTools[item] and (item.ToolTip == "Blox Fruit" or item.Name:find("Fruit")) then
                                                collectedTool = item
                                                break
                                            end
                                        end
                                    end
                                    if collectedTool then break end
                                end
                            until collectedTool or tick() - collectStarted >= 3 or not _G.AutoAfkJoinFruit

                            if collectedTool then
                                local original = collectedTool:GetAttribute("OriginalName") or collectedTool.Name
                                pcall(function()
                                    value.Remotes.CommF_:InvokeServer("StoreFruit", original, collectedTool)
                                end)
                                hopLast.fruit = tick()
                            elseif fruit:IsDescendantOf(Workspace) then
                                hopIgnoredFruits[fruit] = true
                            end
                        end
                    elseif tick() - hopLast.fruit >= 3 and not hopBusy then
                        hopLast.fruit = tick()
                        task.spawn(hopJoin, "fruit", nil, true)
                    end
                end
            end)
        end
    end)
end

do
    local localPlayer2 = Tabs.LocalPlayer
    local value2 = localPlayer

    _G.PlayersList = ""
    _G.TargetMode = "Closest Player"
    _G.TpPly = false

    local flag, flag2 = false, false
    local amount, amount2 = 200, 200
    local flag3, amount3 = false, 100
    local current = nil
    local flag4 = false
    local v364m = false
    local amount4 = 1000
    local amount5 = 0.1
    local current2 = nil

    local function helper()
        local list = {}
        for index, item in ipairs(Players:GetPlayers()) do
            if item ~= value2 and not table.find(list, item.Name) then
                table.insert(list, item.Name)
            end
        end
        table.sort(list)
        return list
    end

    local function helper2(target)
        local current3, huge = nil, math.huge
        for index, item in ipairs(Players:GetPlayers()) do
            if item ~= value2 and item.Character then
                local firstChildWhichIsA = item.Character:FindFirstChildWhichIsA("Humanoid")
                local rootPart = item.Character:FindFirstChild("HumanoidRootPart")
                if firstChildWhichIsA and firstChildWhichIsA.Health > 0 and rootPart then
                    local distance = (rootPart.Position - target.Position).Magnitude
                    if distance < huge and distance <= amount4 then
                        huge = distance
                        current3 = item
                    end
                end
            end
        end
        return current3
    end

    local function helper3(target)
        local current3, huge = nil, math.huge
        local v369e = Workspace:FindFirstChild("Enemies")
        if not v369e then return nil end
        for index, item in ipairs(v369e:GetChildren()) do
            local firstChildWhichIsA = item:FindFirstChildWhichIsA("Humanoid")
            local rootPart = item:FindFirstChild("HumanoidRootPart")
            if firstChildWhichIsA and firstChildWhichIsA.Health > 0 and rootPart then
                local distance = (rootPart.Position - target.Position).Magnitude
                if distance < huge and distance <= amount4 then
                    huge = distance
                    current3 = item
                end
            end
        end
        return current3
    end

    local function helper4(value3)
        if _G.TargetMode == "Selected Player" then
            return Players:FindFirstChild(_G.PlayersList or "")
        end
        return helper2(value3)
    end

    local function helper2(target)
        local firstChildWhichIsA = target.Parent and target.Parent:FindFirstChildWhichIsA("Humanoid")
        if not firstChildWhichIsA or firstChildWhichIsA.WalkSpeed < 5 then
            return target.Position
        end
        return target.Position + target.AssemblyLinearVelocity * amount5
    end

    local function helper5(value3)
        if not value3 then return false end
        local playerGui = value2:FindFirstChild("PlayerGui")
        local skills = playerGui and playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Skills")
        local firstChild = skills and skills:FindFirstChild(value3)
        if not firstChild then return false end
        for index, item in ipairs({ "Z", "X", "C", "V" }) do
            local firstChild2 = firstChild:FindFirstChild(item)
            if firstChild2 and firstChild2:FindFirstChild("Cooldown") and firstChild2.Cooldown.Size.X.Scale == 1 then
                return true
            end
        end
        return false
    end

    local function helper6()
        local character = value2.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        if flag and humanoid.WalkSpeed ~= amount then
            humanoid.WalkSpeed = amount
        end
        if flag2 then
            if not humanoid.UseJumpPower then
                humanoid.UseJumpPower = true
            end
            if humanoid.JumpPower ~= amount2 then
                humanoid.JumpPower = amount2
            end
        end
    end

    local function helper7(value3)
        task.spawn(function()
            local waitForChild = value3:WaitForChild("Humanoid", 10)
            if not waitForChild then return end
            waitForChild:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if flag and waitForChild.WalkSpeed ~= amount then
                    waitForChild.WalkSpeed = amount
                end
            end)
            waitForChild:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if flag2 and waitForChild.JumpPower ~= amount2 then
                    waitForChild.JumpPower = amount2
                end
            end)
            helper6()
        end)
    end

    if value2.Character then
        helper7(value2.Character)
    end
    value2.CharacterAdded:Connect(helper7)

    RunService.Heartbeat:Connect(helper6)

    local function helper7(value3)
        current = value3:GetAttribute("DashLength")
    end

    local function helper8(value3)
        if not value3 then return end
        value3:SetAttribute("DashLength", flag3 and amount3 or current)
    end

    if value2.Character then
        helper7(value2.Character)
    end

    value2.CharacterAdded:Connect(function(target)
        task.spawn(function()
            local startTime = tick()
            repeat
                task.wait(0.1)
            until target:GetAttribute("DashLength") ~= nil or tick() - startTime > 3 or not target.Parent
            helper7(target)
            if flag3 then
                helper8(target)
            end
        end)
    end)

    localPlayer2:AddSection("Movement")

    localPlayer2:AddToggle("LPSetWalkSpeed", {
        Title = "Set WalkSpeed",
        Description = "Enable custom WalkSpeed",
        Default = false
    }):OnChanged(function(value3)
        flag = value3
        if value3 then helper6() end
    end)

    localPlayer2:AddInput("LPWalkSpeed", {
        Title = "WalkSpeed Value",
        Description = "",
        Default = "200",
        Placeholder = "200",
        Numeric = true,
        Finished = false,
    }):OnChanged(function(value3)
        local tonumber2 = tonumber(value3)
        if tonumber2 then
            amount = tonumber2
            if flag then helper6() end
        end
    end)

    localPlayer2:AddToggle("LPSetJumpPower", {
        Title = "Set JumpPower",
        Description = "Enable custom JumpPower",
        Default = false
    }):OnChanged(function(value3)
        flag2 = value3
        if value3 then helper6() end
    end)

    localPlayer2:AddInput("LPJumpPower", {
        Title = "JumpPower Value",
        Description = "Value JumpPower",
        Default = "200",
        Placeholder = "200",
        Numeric = true,
        Finished = false,
    }):OnChanged(function(value3)
        local tonumber2 = tonumber(value3)
        if tonumber2 then
            amount2 = tonumber2
            if flag2 then helper6() end
        end
    end)

    localPlayer2:AddToggle("LPSetDash", {
        Title = "Set Dash Length",
        Description = "Enable custom Dash Length",
        Default = false
    }):OnChanged(function(value3)
        local value4 = flag3
        flag3 = value3
        if value3 or value4 then
            helper8(value2.Character)
        end
    end)

    localPlayer2:AddInput("LPDashLength", {
        Title = "Dash Length Value",
        Description = "",
        Default = "100",
        Placeholder = "100",
        Numeric = true,
        Finished = true,
    }):OnChanged(function(value3)
        local tonumber2 = tonumber(value3)
        if tonumber2 then
            amount3 = tonumber2
            if flag3 then
                helper8(value2.Character)
            end
        end
    end)

    localPlayer2:AddSection("Players")

    local f411131 = helper()
    if #f411131 == 0 then
        f411131 = { "No Players Found" }
    end
    local concat = table.concat(f411131, "|")

    local lPSelectPlayersDropdown = localPlayer2:AddDropdown("LPSelectPlayers", {
        Title = "Select Players",
        Description = "Choose a target for teleport and manual lock",
        Values = f411131,
        Multi = false,
        Default = 1,
    })

    lPSelectPlayersDropdown:OnChanged(function(value3)
        _G.PlayersList = value3
    end)

    local function helper6(value3)
        local f411131 = helper()
        if #f411131 == 0 then
            f411131 = { "No Players Found" }
        end
        local concat2 = table.concat(f411131, "|")
        if not value3 and concat2 == concat then return end
        concat = concat2
        local playersList = _G.PlayersList
        pcall(function()
            lPSelectPlayersDropdown:SetValues(f411131)
            lPSelectPlayersDropdown:SetValue(table.find(f411131, playersList) and playersList or f411131[1])
        end)
    end

    localPlayer2:AddButton({
        Title = "Refresh Player List",
        Description = "Update the player list manually",
        Callback = function()
            helper6(true)
        end
    })

    Players.PlayerAdded:Connect(function()
        task.delay(1, function() helper6(false) end)
    end)
    Players.PlayerRemoving:Connect(function()
        task.delay(0.5, function() helper6(false) end)
    end)
    task.spawn(function()
        while task.wait(10) do
            helper6(false)
        end
    end)

    localPlayer2:AddToggle("LPTeleportPlayer", {
        Title = "Teleport to choose players",
        Description = "",
        Default = false
    }):OnChanged(function(value3)
        _G.TpPly = value3
        if not value3 and not isFarming() then stopFarming() end
    end)

    task.spawn(function()
        while task.wait() do
            if _G.TpPly then
                pcall(function()
                    local firstChild = Players:FindFirstChild(_G.PlayersList or "")
                    local rootPart = firstChild and firstChild.Character and firstChild.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        _tp(rootPart.CFrame)
                    end
                end)
            end
        end
    end)

    localPlayer2:AddSection("Aimbot")

    localPlayer2:AddDropdown("LPTargetMode", {
        Title = "Aimbot Target Mode",
        Description = "Priority for Aimbot and Skills",
        Values = { "Closest Player", "Selected Player" },
        Multi = false,
        Default = 1,
    }):OnChanged(function(value3)
        _G.TargetMode = value3
    end)

    localPlayer2:AddToggle("LPAimSkills", {
        Title = "Aimbot Players",
        Description = "",
        Default = false
    }):OnChanged(function(value3)
        flag4 = value3
        if not value3 and not v364m then current2 = nil end
    end)

    localPlayer2:AddToggle("LPAimMobs", {
        Title = "Aimbot Mobs",
        Description = "",
        Default = false
    }):OnChanged(function(value3)
        v364m = value3
        if not value3 and not flag4 then current2 = nil end
    end)

    RunService.RenderStepped:Connect(function()
        if not flag4 and not v364m then
            current2 = nil
            return
        end
        pcall(function()
            local character = value2.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                current2 = nil
                return
            end
            local current = nil
            if flag4 then
                local f431154 = helper4(rootPart)
                current = f431154 and f431154.Character and f431154.Character:FindFirstChild("HumanoidRootPart")
            end
            if not current and v364m then
                local v397m = helper3(rootPart)
                current = v397m and v397m:FindFirstChild("HumanoidRootPart")
            end
            if not current then
                current2 = nil
                return
            end
            current2 = helper2(current)
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and helper5(tool.Name) then
                local position = Vector3.new(current2.X, rootPart.Position.Y, current2.Z) - rootPart.Position
                if position.Magnitude > 0.1 then
                    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + position.Unit)
                end
            end
        end)
    end)

    pcall(function()
        local rawmetatable = getrawmetatable(game)
        setreadonly(rawmetatable, false)
        local namecall = rawmetatable.__namecall
        rawmetatable.__namecall = newcclosure(function(value2, ...)
            local namecallmethod = getnamecallmethod()
            if (flag4 or v364m) and current2 and (namecallmethod == "FireServer" or namecallmethod == "InvokeServer") then
                local args = table.pack(...)
                if typeof(args[1]) == "Vector3" then
                    args[1] = current2
                    return namecall(value2, table.unpack(args, 1, args.n))
                end
            end
            return namecall(value2, ...)
        end)
        setreadonly(rawmetatable, true)
    end)
end

do
    Tabs.Misc:AddSection("Weapon Settings")

    local selectWeaponDropdown = Tabs.Misc:AddDropdown("SelectWeapon", {
        Title = "Select Your Weapon",
        Description = "Select weapon type",
        Values = { "Melee", "Sword", "Fruit" },
        Multi = false,
        Default = 1,
    })

    selectWeaponDropdown:OnChanged(function(value2)
        _G.SelectWeapon = value2
    end)

    Tabs.Misc:AddSection("Combat")

    local autoAttackToggle = Tabs.Misc:AddToggle("AutoAttack", {
        Title = "Auto Attack",
        Description = "Automatically attack enemies",
        Default = true
    })

    autoAttackToggle:OnChanged(function()
        _G.OtherAutoAttack = Options.AutoAttack.Value
    end)

    local doubleAttackToggle = Tabs.Misc:AddToggle("DoubleAttack", {
        Title = "Double Attack",
        Description = "Attacks with Fruit and Melee at the same time (Not supported for Tiger)",
        Default = false
    })

    doubleAttackToggle:OnChanged(function()
        _G.OtherDoubleAttack = Options.DoubleAttack.Value
    end)

    local bringMobsToggle = Tabs.Misc:AddToggle("BringMobs", {
        Title = "Bring Mobs",
        Description = "Bring enemies to the farming position",
        Default = true
    })

    bringMobsToggle:OnChanged(function()
        bringMobsEnabled = Options.BringMobs.Value
    end)

    local useDragonstormToggle = Tabs.Misc:AddToggle("UseDragonstorm", {
        Title = "Use Dragonstorm (Risk)",
        Description = "Uses only Dragonstorm during farm instead of the selected weapon",
        Default = false
    })

    useDragonstormToggle:OnChanged(function(value2)
        _G.UseDragonstorm = value2
    end)

    Tabs.Misc:AddSection("Race Settings")

    local autoV3Toggle = Tabs.Misc:AddToggle("AutoV3", {
        Title = "Auto Active V3",
        Description = "Automatically activate Race V3",
        Default = false
    })

    autoV3Toggle:OnChanged(function()
        _G.RaceClickAutov3 = Options.AutoV3.Value
    end)

    local autoV4Toggle = Tabs.Misc:AddToggle("AutoV4", {
        Title = "Auto Active V4",
        Description = "Automatically activate Race V4",
        Default = false
    })

    autoV4Toggle:OnChanged(function()
        _G.RaceClickAutov4 = Options.AutoV4.Value
    end)

    Tabs.Misc:AddSection("Other Settings")

    local autoKenToggle = Tabs.Misc:AddToggle("AutoKen", {
        Title = "Auto Active Ken",
        Description = "Automatically activate Observation Haki",
        Default = false
    })

    autoKenToggle:OnChanged(function()
        _G.AutoKen = Options.AutoKen.Value
    end)

    task.spawn(function()
        local CollectionService = game:GetService("CollectionService")
        local commE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
        while task.wait(0.2) do
            if _G.AutoKen then
                local char = Players.LocalPlayer.Character
                if char and CollectionService:HasTag(char, "Ken") then
                    pcall(function()
                        commE:FireServer("Ken", true)
                    end)
                end
            end
        end
    end)

    Tabs.Misc:AddSection("Performance")

    Tabs.Misc:AddToggle("FpsBoost", {
        Title = "Fps Boost",
        Description = "Lowers graphics quality to boost FPS",
        Default = false
    }):OnChanged(function(value2)
        _G.FpsBoostOn = value2
        if not value2 then return end
        task.spawn(function()
            pcall(function()
                local flag, value2 = true, game
                local workspace2, lighting = value2.Workspace, value2.Lighting
                local terrain = workspace2.Terrain
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0
                lighting.GlobalShadows = false
                lighting.FogEnd = 9000000000
                lighting.Brightness = 0
                settings().Rendering.QualityLevel = "Level01"
                for index, item in pairs(value2:GetDescendants()) do
                    if item:IsA("Part") or (item:IsA("Union")) or (item:IsA("CornerWedgePart")) or (item:IsA("TrussPart")) then
                        item.Material = "Plastic"
                        item.Reflectance = 0
                    elseif item:IsA("Decal") or item:IsA("Texture") and flag then
                        item.Transparency = 1
                    elseif item:IsA("ParticleEmitter") or item:IsA("Trail") and item.Parent.Name ~= "RelicFire" then
                        item.Lifetime = NumberRange.new(0)
                    elseif item:IsA("Explosion") then
                        item.BlastPressure = 1
                        item.BlastRadius = 1
                    elseif item:IsA("Fire") or (item:IsA("SpotLight")) or (item:IsA("Smoke")) or (item:IsA("Sparkles")) then
                        item.Enabled = false
                    elseif item:IsA("MeshPart") then
                        item.Material = "Plastic"
                        item.Reflectance = 0
                        pcall(function() item.TextureID = 10385902758728956 end)
                    end
                end
                for index, item in pairs(lighting:GetChildren()) do
                    if
                        item:IsA("BlurEffect")
                        or (item:IsA("SunRaysEffect"))
                        or (item:IsA("ColorCorrectionEffect"))
                        or (item:IsA("BloomEffect"))
                        or (item:IsA("DepthOfFieldEffect"))
                    then
                        item.Enabled = false
                    end
                end
                wait(1)
                flag, workspace2, value2 =
                    workspace:WaitForChild("Map"), game.ReplicatedStorage:WaitForChild("Unloaded"), Enum.Material.SmoothPlastic
                lighting = flag:GetDescendants()
                wait(0.5)
                terrain = workspace2:GetDescendants()
                wait(0.5)
                local clock, wait2, isA = os.clock, task.wait, workspace2.IsA
                local v4171235, startTime, amount = clock(), tick(), 0
                flag = v4171235
                for index, item in next, lighting, nil do
                    if isA(item, "BasePart") then
                        item.Material = value2
                        amount += 1
                        if clock() - v4171235 > 0.008333333333333333 then
                            workspace2 = "Working.. " .. amount
                            wait2()
                            wait2()
                            v4171235 = (clock())
                        end
                    elseif item:IsA("Texture") and not item:GetAttribute("Offset") then
                        item:Destroy()
                    end
                end
                for index, item in next, terrain, nil do
                    if isA(item, "BasePart") then
                        item.Material = value2
                        amount += 1
                        if clock() - v4171235 > 0.008333333333333333 then
                            index = "Working.. " .. amount
                            wait2()
                            wait2()
                            v4171235 = (clock())
                        end
                    elseif item:IsA("Texture") and not item:GetAttribute("Offset") then
                        item:Destroy()
                    end
                end
                pcall(function()
                    game.Players.LocalPlayer.PlayerScripts.OptimizerClientActor:SendMessage("Optimize", true)
                end)
                print("Time taken to Fast Mode: ", tick() - startTime, clock() - flag)
            end)
        end)
    end)

    task.spawn(function()
        repeat
            task.wait()
        until game.Workspace:FindFirstChild("_WorldOrigin")
        workspace._WorldOrigin.DescendantAdded:Connect(function(value2)
            if not _G.FpsBoostOn then return end
            if value2:IsA("Part") or (value2:IsA("Union")) or (value2:IsA("CornerWedgePart")) or (value2:IsA("TrussPart")) then
                value2.Transparency = 1
                value2.Material = "Plastic"
                value2.Reflectance = 0
            end
            if value2:IsA("Decal") or value2:IsA("Texture") and decalsyeeted then
                value2.Transparency = 1
            end
            if value2:IsA("ParticleEmitter") or (value2:IsA("Trail")) then
                if value2.Parent.Name ~= "RelicFire" then
                    value2.Enabled = false
                    value2.Lifetime = NumberRange.new(0)
                end
            end
            if value2:IsA("Explosion") then
                value2.Enabled = false
                value2.BlastPressure = 1
                value2.BlastRadius = 1
            end
            if value2:IsA("Fire") or (value2:IsA("SpotLight")) or (value2:IsA("Smoke")) or (value2:IsA("Sparkles")) then
                value2.Enabled = false
            end
            if value2:IsA("MeshPart") then
                value2.Transparency = 1
                value2.Material = "Plastic"
                value2.Reflectance = 0
                pcall(function() value2.TextureID = 10385902758728956 end)
            end
        end)
    end)

    local blackScreenToggle = Tabs.Misc:AddToggle("BlackScreen", {
        Title = "Black Screen",
        Description = "Renders a black screen to reduce rendering strain",
        Default = false
    })

    blackScreenToggle:OnChanged(function(value2)
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        if value2 then
            if playerGui:FindFirstChild("BlackOverlay") then
                playerGui.BlackOverlay:Destroy()
            end
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "BlackOverlay"
            screenGui.IgnoreGuiInset = true
            screenGui.ResetOnSpawn = false
            screenGui.DisplayOrder = -999
            screenGui.Parent = playerGui

            local frame = Instance.new("Frame")
            frame.Name = "Background"
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.Position = UDim2.new(0, 0, 0, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.ZIndex = 0
            frame.Parent = screenGui
        else
            local blackOverlay = playerGui:FindFirstChild("BlackOverlay")
            if blackOverlay then blackOverlay:Destroy() end
        end
    end)

    local removeDamageToggle = Tabs.Misc:AddToggle("RemoveDamage", {
        Title = "Remove Damage Indicators",
        Description = "Disables damage counters & notifications (Reduces lag)",
        Default = false
    })

    removeDamageToggle:OnChanged(function(value2)
        _G.RemoveDamage = value2
    end)
end

do
    getgenv().AutoExecute = false

    Tabs.Misc:AddToggle("AutoExecute", {
        Title = "Auto Execute",
        Description = "Runs the script again automatically when you teleport or hop servers",
        Default = false
    }):OnChanged(function(p)
        getgenv().AutoExecute = p
    end)

    local queue = (syn and syn.queue_on_teleport) or queue_on_teleport or queueteleport
    local executed = false

    if queue then
        localPlayer.OnTeleport:Connect(function()
            if getgenv().AutoExecute and not executed then
                executed = true
                queue([[loadstring(game:HttpGet("https://raw.githubusercontent.com/Axlkz/scripts/refs/heads/main/bf"))()]])
            end
        end)
    end
end

do
    local commF = value.Remotes.CommF_
    local function helper(value2)
        Fluent:Notify({ Title = "Axl Hub", Content = value2, Duration = 4 })
    end

    local function helper2(value2)
        local success, result = pcall(function() return commF:InvokeServer("getInventory") end)
        if success and type(result) == "table" then
            for index, item in pairs(result) do
                if item.Name == value2 then return true end
            end
        end
        return (localPlayer.Backpack:FindFirstChild(value2) or (localPlayer.Character and localPlayer.Character:FindFirstChild(value2))) and true or false
    end

    local function helper3(value2, value3, value4)
        return function()
            if value4 and helper2(value2) then
                helper("You already own " .. value2 .. "!")
                return
            end
            local success, result = pcall(function() return commF:InvokeServer(unpack(value3)) end)
            if success and result ~= false then helper(value2 .. " successfully purchased!") end
        end
    end

    local function helper2(value2, value3)
        return function()
            if tostring(localPlayer.Data.Race.Value) == value2 then
                helper("You already have " .. value2 .. " Race!")
                return
            end
            local success, result = pcall(function() return commF:InvokeServer(unpack(value3)) end)
            if success and result ~= false then helper(value2 .. " Race successfully purchased!") end
        end
    end

    local function helper4(value2, value3, value4)
        Tabs.Shop:AddSection(value2)
        local list, list2 = {}, {}
        for index, item in ipairs(value4) do
            table.insert(list, item[1])
            list2[item[1]] = item[2]
        end
        local value4 = list[1]
        Tabs.Shop:AddDropdown(value3, {
            Title = "Select Item",
            Description = value2,
            Values = list,
            Multi = false,
            Default = 1,
        }):OnChanged(function(value2) value4 = value2 end)
        Tabs.Shop:AddButton({
            Title = "Buy",
            Description = "Buys the selected item",
            Callback = function()
                local value2 = list2[value4]
                if value2 then value2() end
            end
        })
    end

    helper4("Haki", "ShopHaki", {
        { "Buso",   helper3("Buso",   { "BuyHaki", "Buso" }) },
        { "Geppo",  helper3("Geppo",  { "BuyHaki", "Geppo" }) },
        { "Soru",   helper3("Soru",   { "BuyHaki", "Soru" }) },
        { "Ken",    helper3("Ken",    { "KenTalk", "Buy" }) },
    })

    local value2 = isSea1 and 1 or (isSea2 and 2 or 3)
    local map = {
        ["Dark Step"] = { Pos = { [1] = Vector3.new(-988, 13, 3996), [2] = Vector3.new(-4750.61, 35.08, -4846.33), [3] = Vector3.new(-5043.64, 371.35, -3183.4) }, Args = { "BuyBlackLeg" } },
        ["Electric"] = { Pos = { [1] = Vector3.new(-5382.27, 14.15, -2150.34), [2] = Vector3.new(-4863.81, 35.08, -4767.54), [3] = Vector3.new(-4993.2, 314.56, -3198.06) }, Args = { "BuyElectro" } },
        ["Water Kung Fu"] = { Pos = { [1] = Vector3.new(61584.35, 18.85, 988.89), [2] = Vector3.new(-4960.04, 35.08, -4662.67), [3] = Vector3.new(-5017.39, 371.35, -3187.53) }, Args = { "BuyFishmanKarate" } },
        ["Dragon Breath"] = { Pos = { [2] = Vector3.new(1514, 15, -2982) }, Args = { "BlackbeardReward", "DragonClaw", "2" } },
        ["Superhuman"] = { Pos = { [2] = Vector3.new(1378.05, 247.43, -5189.37), [3] = Vector3.new(-4997.53, 371.35, -3197.46) }, Args = { "BuySuperhuman" } },
        ["Death Step"] = { Pos = { [2] = Vector3.new(6360.04, 296.67, -6763.93), [3] = Vector3.new(-4997.64, 314.56, -3220.37) }, Args = { "BuyDeathStep" } },
        ["Sharkman Karate"] = { Pos = { [2] = Vector3.new(-2602.4, 239.22, -10314.75), [3] = Vector3.new(-4970.48, 314.56, -3225.04) }, Args = { "BuySharkmanKarate" } },
        ["Electric Claw"] = { Pos = { [3] = Vector3.new(-10369.83, 331.69, -10126.49) }, Args = { "BuyElectricClaw" } },
        ["Dragon Talon"] = { Pos = { [3] = Vector3.new(5662.03, 1211.32, 858.6) }, Args = { "BuyDragonTalon" } },
        ["Godhuman"] = { Pos = { [3] = Vector3.new(-13775.56, 334.66, -9877.67) }, Args = { "BuyGodhuman" } },
        ["Sanguine Art"] = { Pos = { [3] = Vector3.new(-16514.86, 23.18, -190.84) }, Args = { "BuySanguineArt" } },
    }
    local list = { "Dark Step", "Electric", "Water Kung Fu", "Dragon Breath", "Superhuman", "Death Step", "Sharkman Karate", "Electric Claw", "Dragon Talon", "Godhuman", "Sanguine Art" }
    local list2 = {}
    for index, item in ipairs(list) do
        if map[item].Pos[value2] then
            table.insert(list2, item)
        end
    end
    local value3 = list2[1]

    Tabs.Shop:AddSection("Fighting Style")

    Tabs.Shop:AddDropdown("ShopStyle", {
        Title = "Select Style",
        Description = "Fighting styles available in this sea",
        Values = list2,
        Multi = false,
        Default = 1,
    }):OnChanged(function(value4) value3 = value4 end)

    Tabs.Shop:AddButton({
        Title = "Buy",
        Description = "Goes to the NPC and buys the selected style",
        Callback = function()
            local value4 = map[value3]
            if not value4 or not value4.Pos[value2] then
                helper("This style is not available in this sea")
                return
            end
            _G.AutoBuyStyle = true
        end
    })

    task.spawn(function()
        while task.wait(0.3) do
            if _G.AutoBuyStyle then
                pcall(function()
                    local value4 = map[value3]
                    local value5 = value4 and value4.Pos[value2]
                    local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not value5 or not rootPart then return end
                    if (rootPart.Position - value5).Magnitude > 20 then
                        _tp(CFrame.new(value5))
                    else
                        local success, result = pcall(function() return commF:InvokeServer(unpack(value4.Args)) end)
                        if success and result ~= false then
                            helper(value3 .. " successfully purchased!")
                            _G.AutoBuyStyle = false
                            if not isFarming() then stopFarming() end
                        end
                    end
                end)
            end
        end
    end)

    helper4("Accessory", "ShopAccessory", {
        { "Tomoe Ring",     helper3("Tomoe Ring",     { "BuyItem", "Tomoe Ring" }, true) },
        { "Black Cape",     helper3("Black Cape",     { "BuyItem", "Black Cape" }, true) },
        { "Swordsman Hat",  helper3("Swordsman Hat",  { "BuyItem", "Swordsman Hat" }, true) },
        { "Bizarre Rifle",  helper3("Bizarre Rifle",  { "Ectoplasm", "Buy", 1 }, true) },
        { "Ghoul Mask",     helper3("Ghoul Mask",     { "Ectoplasm", "Buy", 2 }, true) },
    })

    local list = { "Dragonheart", "Dragonstorm", "DinoHood", "SharkTooth", "TerrorJaw", "SharkAnchor", "LeviathanCrown", "LeviathanShield", "LeviathanBoat", "LegendaryScroll", "MythicalScroll" }
    local list2 = {}
    for index, item in ipairs(list) do
        table.insert(list2, { item, function()
            pcall(function() commF:InvokeServer("CraftItem", "Craft", item) end)
        end })
    end
    helper4("Accessory SeaEvent (Craft)", "ShopCraft", list2)

    local list = { "Cutlass", "Katana", "Iron Mace", "Duel Katana", "Triple Katana", "Pipe", "Dual-Headed Blade", "Bisento", "Soul Cane", "Slingshot", "Musket", "Dual Flintlock", "Flintlock", "Refined Flintlock", "Cannon" }
    local list2 = {}
    for index, item in ipairs(list) do
        table.insert(list2, { item, helper3(item, { "BuyItem", item }, true) })
    end
    table.insert(list2, { "Kabucha", helper3("Kabucha", { "BlackbeardReward", "Slingshot", "2" }, true) })
    helper4("Weapon", "ShopWeapon", list2)

    helper4("Fragments Shop", "ShopFragments", {
        { "Refund Stats",         helper3("Refund Stats", { "BlackbeardReward", "Refund", "2" }) },
        { "Reroll Race",          helper3("Reroll Race",  { "BlackbeardReward", "Reroll", "2" }) },
        { "Ghoul Race (2.5k)",    helper2("Ghoul",  { "Ectoplasm", "Change", 4 }) },
        { "Cyborg Race (2.5k)",   helper2("Cyborg", { "CyborgTrainer", "Buy" }) },
    })
end

            local TTKSHIP = CFrame.new(-9495.68, 453.58, 5977.34)
local TTKSLOTS = {
    { "Shizu", "Shisui" },
    { "Oroshi", "Saddi" },
    { "Saishi", "Wando" },
}
local TTKMOBS = {
    ["Reborn Skeleton"] = true,
    ["Living Zombie"] = true,
    ["Demonic Soul"] = true,
    ["Posessed Mummy"] = true,
}
local ttk = {
    prevWP = nil, farmNotified = false, beliNotified = false,
    hopNotified = false, buyTries = 0, lastHop = 0, lastTravel = 0, loaded = "",
    cfgNotified = false, errNotified = false, hopIdx = 0, lastMissing = -1,
}

local ttkCfgCache = nil
local ttkNetCache = nil

local function ttkNorm(s)
    return (tostring(s or ""):lower():gsub("[^%w]", ""))
end

local function ttkFmt(n)
    local s = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (s:gsub("^,", ""))
end

local function ttkNotify(text)
    Fluent:Notify({ Title = "Auto True Triple Katana", Content = text, Duration = 5 })
end

local function ttkCfg()
    if ttkCfgCache then return ttkCfgCache end
    local m = value:FindFirstChild("ItemConfig", true)
    if not (m and m:IsA("ModuleScript")) and getloadedmodules then
        for value2, mod in ipairs(getloadedmodules()) do
            if mod.Name == "ItemConfig" then
                m = mod
                break
            end
        end
    end
    if m and m:IsA("ModuleScript") then
        local success, result = pcall(require, m)
        if success and type(result) == "table" then
            ttkCfgCache = result
        end
    end
    return ttkCfgCache
end

local ttkScanCache, ttkScanCacheTick = nil, 0
local function ttkScan()
    if ttkScanCache and tick() - ttkScanCacheTick < 10 then
        return ttkScanCache, true
    end
    local found = {}
    local cfg = ttkCfg()
    if not cfg then return found, false end
    local success, result = pcall(function()
        ttkNetCache = ttkNetCache or require(value:WaitForChild("Modules"):WaitForChild("Net"))
        return ttkNetCache:RemoteFunction("GetAllItemValues"):InvokeServer()
    end)
    if not success or type(result) ~= "table" then return found, false end
    local groups = {}
    for value2, e in next, result do
        local k = tostring(e.ItemId) .. "_" .. tostring(e.NetworkedUID)
        groups[k] = groups[k] or { ItemId = e.ItemId, Attr = {} }
        if e.Value ~= nil then
            groups[k].Attr[e.Key] = e.Value
        end
    end
    for value2, g in next, groups do
        if g.Attr.IsOwned == true then
            local success, result = pcall(function() return cfg.match(g.ItemId) end)
            if success and result and result:isOk() then
                local label = tostring(result:unwrap().Index.DebugLabel)
                local name = label:match("^(.-)%s*%[") or label
                found[name:lower()] = { Name = name, Mastery = tonumber(g.Attr.Mastery) or 0 }
            end
        end
    end
    ttkScanCache, ttkScanCacheTick = found, tick()
    return found, true
end

local function ttkOwnsTTK(found)
    for name in pairs(found) do
        if ttkNorm(name) == "truetriplekatana" then
            return true
        end
    end
    for value2, holder in ipairs({ localPlayer.Backpack, localPlayer.Character }) do
        if holder then
            for value2, t in ipairs(holder:GetChildren()) do
                if t:IsA("Tool") and ttkNorm(t.Name) == "truetriplekatana" then
                    return true
                end
            end
        end
    end
    return false
end

local function ttkBeli()
    local success, result = pcall(function() return localPlayer.Data.Beli.Value end)
    if success and tonumber(result) then return tonumber(result) end
    return 0
end

local function ttkDealer()
    for value2, root in ipairs({ Workspace:FindFirstChild("NPCs") }) do
        if root then
            local m = root:FindFirstChild("Legendary Sword Dealer")
            if m and m:FindFirstChild("HumanoidRootPart") then
                return m
            end
        end
    end
    return nil
end

local function ttkTravel(remote)
    if tick() - ttk.lastTravel < 20 then return end
    ttk.lastTravel = tick()
    pcall(function() value.Remotes.CommF_:InvokeServer(remote) end)
end

local function ttkHop(missing)
    if tick() - ttk.lastHop < 10 then return end
    local join = getgenv().AxlHopJoin
    if not join then
        if not ttk.hopNotified then
            ttk.hopNotified = true
            ttkNotify("Hop system not found: add getgenv().AxlHopJoin = hopJoin in the Hop block")
        end
        return
    end
    ttk.lastHop = tick()
    ttk.buyTries = 0
    ttk.hopIdx = ttk.hopIdx + 1
    local word = missing[((ttk.hopIdx - 1) % #missing) + 1]
    ttkNotify("Hopping to a server with " .. word)
    task.spawn(join, "legendarysword", word, false)
end

local function ttkOn()
    return _G.AutoTtk and not farmPaused
end

local function ttkLoad(name)
    if ttk.loaded ~= name then
        pcall(function() value.Remotes.CommF_:InvokeServer("LoadItem", name) end)
        ttk.loaded = name
    end
end

local function ttkNeedBeli(need)
    if ttkBeli() < need then
        if not ttk.beliNotified then
            ttk.beliNotified = true
            ttkNotify("You need at least " .. ttkFmt(need) .. " Beli for the True Triple Katana")
        end
        return false
    end
    ttk.beliNotified = false
    return true
end

local function ttkFarm(sword)
    ttkLoad(sword)
    local ch = localPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    equipToolByName(sword)

    local target, best = nil, math.huge
    local en = Workspace:FindFirstChild("Enemies")
    if en then
        for value2, m in ipairs(en:GetChildren()) do
            if TTKMOBS[m.Name] and Mob.Alive(m) and m:FindFirstChild("HumanoidRootPart") then
                local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < best then
                    best = d
                    target = m
                end
            end
        end
    end

    if target then
        repeat
            task.wait()
            equipToolByName(sword)
            Mob.Kill(target, true)
            BringEnemy()
        until not ttkOn() or not target.Parent or not Mob.Alive(target) or not hrp.Parent
    else
        _tp(TTKSHIP)
    end
end

local function ttkStep()
    local found, ok = ttkScan()
    if not ok then
        if not ttk.cfgNotified then
            ttk.cfgNotified = true
            ttkNotify("Could not read your inventory (ItemConfig / GetAllItemValues failed)")
        end
        found = {}
    end

    if ttkOwnsTTK(found) then
        Fluent:Notify({ Title = "Auto True Triple Katana", Content = "You already have this item", Duration = 5 })
        _G.AutoTtk = false
        pcall(function() Fluent.Options.AutoTrueTripleKatana:SetValue(false) end)
        if not isFarming() then stopFarming() end
        return
    end

    if isSea1 then
        local success, result = pcall(function() return localPlayer.Data.Level.Value end)
        if success and tonumber(result) and tonumber(result) < 1500 then
            ttkNotify("You need at least level 1500 to use Auto True Triple Katana")
            _G.AutoTtk = false
            pcall(function() Fluent.Options.AutoTrueTripleKatana:SetValue(false) end)
            if not isFarming() then stopFarming() end
            return
        end
    end

    local owned, missing = {}, {}
    for value2, slot in ipairs(TTKSLOTS) do
        local hit = nil
        for value2, alias in ipairs(slot) do
            if found[alias:lower()] then
                hit = found[alias:lower()]
                break
            end
        end
        if hit then
            table.insert(owned, hit)
        else
            table.insert(missing, slot[1])
        end
    end

    if #missing ~= ttk.lastMissing then
        ttk.lastMissing = #missing
        ttk.buyTries = 0
    end

    if #missing > 0 then
        local need = (#missing + 1) * 2000000
        if not ttkNeedBeli(need) then
            task.wait(2)
            return
        end

        if not isSea2 then
            ttkTravel("TravelDressrosa")
            return
        end

        local dealer = ttkDealer()
        if not dealer then
            ttkHop(missing)
            task.wait(2)
            return
        end

        local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local cf = dealer.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
        if (hrp.Position - cf.Position).Magnitude > 25 then
            _tp(cf)
            return
        end

        ttk.buyTries = ttk.buyTries + 1
        for i = 1, 3 do
            pcall(function() value.Remotes.CommF_:InvokeServer("LegendarySwordDealer", tostring(i)) end)
        end
        task.wait(1.5)
        if ttk.buyTries >= 3 then
            ttkHop(missing)
        end
        return
    end

    if not isSea3 then
        ttkTravel("TravelZou")
        return
    end

    local lowest = nil
    for value2, it in ipairs(owned) do
        if it.Mastery < 300 then
            lowest = it.Name
            break
        end
    end

    if lowest then
        if not ttk.farmNotified then
            ttk.farmNotified = true
            ttkNotify("Farming Legendary Sword mastery")
        end
        ttkFarm(lowest)
    else
        if not ttkNeedBeli(2000000) then
            task.wait(2)
            return
        end
        pcall(function() value.Remotes.CommF_:InvokeServer("MysteriousMan", "2") end)
        task.wait(1.5)
    end
end

Tabs.Stack:AddSection("True Triple Katana")

Tabs.Stack:AddToggle("AutoTrueTripleKatana", {
    Title = "Auto True Triple Katana",
    Description = "Buys the Legendary Swords (hops to servers with the missing ones), farms mastery and trades for the True Triple Katana (Sea 2 and 3)",
    Default = false
}):OnChanged(guardToggle("AutoTrueTripleKatana", true, "", function(p)
    _G.AutoTtk = p
    ttk.farmNotified = false
    ttk.beliNotified = false
    ttk.hopNotified = false
    ttk.buyTries = 0
    ttk.lastMissing = -1
    if p then
        ttk.prevWP = _G.SelectWeapon
        _G.SelectWeapon = "Sword"
    else
        if ttk.prevWP then
            _G.SelectWeapon = ttk.prevWP
            ttk.prevWP = nil
        end
        if not isFarming() then stopFarming() end
    end

    if not farmPaused then
        task.defer(function()
            pcall(function() SaveManager:Save("AutoSave") end)
        end)
    end
end))

Tabs.Stack:AddToggle("AutoBuyLegendarySword", {
    Title = "Auto Buy Legendary Sword",
    Description = "Buys the Legendary Swords from the dealer (Sea 2)",
    Default = false
}):OnChanged(guardToggle("AutoBuyLegendarySword", isSea2, "Auto Buy Legendary Sword only works in Sea 2", function(p)
    _G.Tp_LgS = p
end))

task.spawn(function()
    while task.wait(1) do
        if _G.Tp_LgS and not farmPaused then
            pcall(function()
                for i = 1, 3 do
                    value.Remotes.CommF_:InvokeServer("LegendarySwordDealer", tostring(i))
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if not ttkOn() then continue end
        local success, result = pcall(ttkStep)
        if not success then
            warn("Auto TTK error: " .. tostring(result))
            if not ttk.errNotified then
                ttk.errNotified = true
                ttkNotify("Error: " .. tostring(result))
            end
            task.wait(2)
        end
    end
end)

local function helper()
    local localPlayer2 = game:GetService("Players").LocalPlayer
    local success, result = pcall(function() return localPlayer2.PlayerGui.Main.TopHUDList.RaidTimer.Visible end)
    local value2 = (success and result == true)
    local attribute = localPlayer2:GetAttribute("IslandRaiding")

    if value2 then return "IN_RAID" end
    if attribute then return "LOADING" end
    return "OUTSIDE"
end

local function helper2()
    local success, result = pcall(function() return workspace._WorldOrigin.Locations end)
    if not success or not result then return nil, 0 end

    for index, item in ipairs({5, 4, 3, 2, 1}) do
        for index, item2 in ipairs(result:GetChildren()) do
            if item2.Name == "Island " .. item then
                return item2, item
            end
        end
    end
    return nil, 0
end

task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaid then return end

            local localPlayer2 = game:GetService("Players").LocalPlayer
            local character = localPlayer2.Character or localPlayer2.CharacterAdded:Wait()
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            local f852064 = helper()

            if f852064 == "LOADING" then
                return
            elseif f852064 == "IN_RAID" then
                local f862070, value2 = helper2()
                if not f862070 then return end

                if _G.KillH and (value2 == 4 or value2 == 5) then
                    _tp(f862070.CFrame * CFrame.new(0, 80, 0))
                    for index, item in pairs(workspace.Enemies:GetChildren()) do
                        if not _G.AutoRaid then break end
                        if item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 and item:FindFirstChild("HumanoidRootPart") then
                            pcall(function()
                                sethiddenproperty(localPlayer2, "SimulationRadius", math.huge)
                                item:BreakJoints()
                                item.Humanoid.Health = 0
                                if item:FindFirstChild("HumanoidRootPart") then
                                    item.HumanoidRootPart.CanCollide = false
                                end
                            end)
                        end
                    end
                else
                    local current = nil
                    local huge = math.huge

                    for index, item in pairs(workspace.Enemies:GetChildren()) do
                        if item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 and item:FindFirstChild("HumanoidRootPart") then
                            local distance = (item.HumanoidRootPart.Position - f862070.Position).Magnitude
                            if distance < 3000 then
                                local distance = (rootPart.Position - item.HumanoidRootPart.Position).Magnitude
                                if distance < huge then
                                    huge = distance
                                    current = item
                                end
                            end
                        end
                    end

                    if current then
                        repeat
                            task.wait()
                            if not _G.AutoRaid then break end
                            local new = current.HumanoidRootPart.CFrame * CFrame.new(0, farmHeight, 0)
                            if Mob and Mob.Kill then
                                Mob.Kill(current, _G.AutoRaid, new)
                            end
                        until not _G.AutoRaid or not current.Parent or (current:FindFirstChild("Humanoid") and current.Humanoid.Health <= 0) or not rootPart.Parent
                    else
                        _tp(f862070.CFrame * CFrame.new(0, 80, 0))
                    end
                end
            elseif f852064 == "OUTSIDE" then
                local specialMicrochip = localPlayer2.Backpack:FindFirstChild("Special Microchip") or character:FindFirstChild("Special Microchip")
                local commF = game:GetService("ReplicatedStorage").Remotes.CommF_

                if specialMicrochip then
                    local value2, value3
                    if placeId == 4442272183 or placeId == 79091703265657 then
                        value2 = CFrame.new(-6521.95215, 307.734985, -4813.02441)
                        if workspace.Map:FindFirstChild("CircleIsland") then
                            value3 = workspace.Map.CircleIsland.RaidSummon2.Button.Main:FindFirstChild("ClickDetector")
                        end
                    elseif placeId == 7449423635 or placeId == 100117331123089 then
                        value2 = CFrame.new(-5034.36523, 315.004669, -2949.36304)
                        if workspace.Map:FindFirstChild("Boat Castle") then
                            value3 = workspace.Map["Boat Castle"].RaidSummon2.Button.Main:FindFirstChild("ClickDetector")
                        end
                    end

                    if value2 and _G.AutoRaid then
                        if (rootPart.Position - value2.Position).Magnitude > 5 then
                            _tp(value2)
                        else
                            if value3 then
                                fireclickdetector(value3)
                                task.wait(1)
                            end
                        end
                    end
                elseif _G.AutoGrabCheapFruits then

                    local humanoid = character:FindFirstChildOfClass("Humanoid")

                    local function findCheapTool()
                        for index, container in ipairs({ localPlayer2.Backpack, character }) do
                            for index2, tool in ipairs(container:GetChildren()) do
                                if tool:IsA("Tool") and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit"))
                                    and getgenv().AxlIsCheapFruit and getgenv().AxlIsCheapFruit(tool.Name) then
                                    return tool
                                end
                            end
                        end
                        return nil
                    end

                    local tool = findCheapTool()

                    if not tool and tick() - (_G.AxlCheapLoadTry or 0) > 3 then
                        _G.AxlCheapLoadTry = tick()
                        if tick() - (_G.AxlFailedReset or 0) > 60 then
                            _G.AxlFailedReset = tick()
                            _G.AxlFailedFruit = {}
                        end
                        _G.AxlFailedFruit = _G.AxlFailedFruit or {}

                        local candidates = {}
                        local function collect(source)
                            if type(source) ~= "table" then return end
                            for index, item in pairs(source) do
                                if type(item) == "table" and item.Name then
                                    local price = item.Price or (getgenv().AxlFruitPrice and getgenv().AxlFruitPrice(item.Name))
                                    if type(price) == "number" and price < 1000000 then
                                        candidates[#candidates + 1] = { key = item.StorageKey or item.Name, price = price }
                                    end
                                end
                            end
                        end
                        pcall(function() collect(commF:InvokeServer("getInventory")) end)
                        pcall(function() collect(commF:InvokeServer("GetFruits", true)) end)
                        table.sort(candidates, function(first, second) return first.price < second.price end)

                        local tried = 0
                        for index, candidate in ipairs(candidates) do
                            if tried >= 5 or not _G.AutoRaid then break end
                            if not _G.AxlFailedFruit[candidate.key] then
                                tried = tried + 1
                                commF:InvokeServer("LoadFruit", candidate.key)
                                task.wait(0.5)
                                tool = findCheapTool()
                                if tool then break end
                                _G.AxlFailedFruit[candidate.key] = true
                            end
                        end

                        if not tool and tick() - (_G.AxlCheapNotify or 0) > 30 then
                            _G.AxlCheapNotify = tick()
                            Fluent:Notify({ Title = "Axl Hub", Content = "No fruit under 1M found in your inventory", Duration = 5 })
                        end
                    end

                    if tool and humanoid then
                        humanoid:EquipTool(tool)
                        task.wait(0.3)
                        commF:InvokeServer("RaidsNpc", "Select", _G.SelectChip)
                        task.wait(1)
                    end
                else
                    commF:InvokeServer("RaidsNpc", "Select", _G.SelectChip)
                    task.wait(0.5)

                    if not (localPlayer2.Backpack:FindFirstChild("Special Microchip") or character:FindFirstChild("Special Microchip")) then
                        local server = commF:InvokeServer("GetFruits")
                        for index, item in pairs(server or {}) do
                            if not _G.AutoRaid then break end
                            if localPlayer2.Backpack:FindFirstChild("Special Microchip") or character:FindFirstChild("Special Microchip") then
                                break
                            end
                            local lower = tostring(item.Rarity or ""):lower()
                            if (item.Price or 0) <= 1150000 or lower == "common" or lower == "uncommon" or lower == "rare" then
                                commF:InvokeServer("LoadFruit", item.Name)
                                commF:InvokeServer("RaidsNpc", "Select", _G.SelectChip)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.Auto_Awakener then
                value.Remotes.CommF_:InvokeServer("Awakener", "Check")
                value.Remotes.CommF_:InvokeServer("Awakener", "Awaken")
            end
        end)
    end
end)

_G.AxlHandleQuest = function(rootPart, npcCFrame, quests, nearDistance, mobStems)
    if not _G.AcceptQuest or not isSea3 then return false end

    local active = false
    pcall(function()
        local text = Players.LocalPlayer.PlayerGui.TrackedQuestFrame.Frame.header.textLabel.textLabel.Text
        if type(text) == "string" and text ~= "" then
            text = string.lower(text)
            for index, stem in ipairs(mobStems) do
                if string.find(text, stem, 1, true) then
                    active = true
                    break
                end
            end
        end
    end)
    if not active and tick() < (_G.AxlQuestGrace or 0) then active = true end
    if active then return false end

    if (rootPart.Position - npcCFrame.Position).Magnitude > nearDistance then
        _tp(npcCFrame)
        return true
    end

    task.wait(1.5)
    local quest = quests[math.random(1, #quests)]
    value.Remotes.CommF_:InvokeServer("StartQuest", quest[1], quest[2])
    _G.AxlQuestGrace = tick() + 4
    task.wait(0.5)
    return true
end

task.spawn(function()
    while task.wait() do
        if not _G.AutoFarm_Bone or not _G.StartFarm then continue end
        pcall(function()
            local localPlayer2 = Players.LocalPlayer
            local rootPart = localPlayer2.Character and localPlayer2.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            if _G.AxlHandleQuest(rootPart, CFrame.new(-9516.99, 172.01, 6078.46), {
                { "HauntedQuest1", 1 }, { "HauntedQuest1", 2 }, { "HauntedQuest2", 1 }, { "HauntedQuest2", 2 },
            }, 10, { "reborn", "living", "demonic", "posessed", "possessed" }) then
                return
            end

            local list = { "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }
            local current, huge = nil, math.huge

            for index, item in pairs(list) do
                for index, item2 in pairs(Workspace.Enemies:GetChildren()) do
                    if item2.Name == item and item2:FindFirstChild("Humanoid") and item2.Humanoid.Health > 0 then
                        local distance = (item2.PrimaryPart.Position - rootPart.Position).Magnitude
                        if distance < huge then
                            huge = distance
                            current = item2
                        end
                    end
                end
            end

            if current then
                Mob.Kill(current, _G.AutoFarm_Bone)
            else
                _tp(CFrame.new(-9495.68, 453.58, 5977.34))
            end
        end)
    end
end)

local current = nil
task.spawn(function()
    while task.wait() do
        if not _G.AutoFarm_Cake or not _G.StartFarm then continue end
        pcall(function()
            local localPlayer2 = Players.LocalPlayer
            local rootPart = localPlayer2.Character and localPlayer2.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            local enemies = Workspace:FindFirstChild("Enemies")
            if not enemies then return end

            local cframe = CFrame.new(-2091.91, 70, -12142.83)
            local cframe2 = CFrame.new(-2151.82, 149.32, -12404.91)
            local cakeLoaf = Workspace.Map:FindFirstChild("CakeLoaf")
            cakeLoaf = cakeLoaf and cakeLoaf:FindFirstChild("BigMirror")
            local other = cakeLoaf and cakeLoaf:FindFirstChild("Other")
            local value2 = other and other.Transparency == 0
            local doughKing = enemies:FindFirstChild("Cake Prince") or enemies:FindFirstChild("Dough King")
            if _G.IgnoreBoss then

                doughKing = nil
                value2 = false
            end

            if not doughKing and not value2 and (rootPart.Position - cframe.Position).Magnitude > 3000 then
                _tp(cframe)
                return
            end

            if doughKing or value2 then
                current = nil
                if doughKing and doughKing:FindFirstChild("Humanoid") and doughKing.Humanoid.Health > 0 and doughKing.PrimaryPart then
                    repeat
                        task.wait()
                        if doughKing.Parent and doughKing:FindFirstChild("Humanoid") and doughKing.Humanoid.Health > 0 and doughKing.PrimaryPart then
                            local position = doughKing.PrimaryPart.Position
                            local value2 = lookAtCFrame(position + Vector3.new(0, farmHeight, 0), position)
                            if Mob and Mob.Kill then
                                Mob.Kill(doughKing, _G.AutoFarm_Cake, value2)
                            end
                        end
                    until not _G.StartFarm or not _G.AutoFarm_Cake or not doughKing.Parent or not doughKing:FindFirstChild("Humanoid") or doughKing.Humanoid.Health <= 0
                    return
                end
                _tp(cframe2)
                return
            end

            if _G.AxlHandleQuest(rootPart, CFrame.new(-1927.92, 37.8, -12842.54), {
                { "CakeQuest2", 2 }, { "CakeQuest2", 1 }, { "CakeQuest1", 1 }, { "CakeQuest1", 2 },
            }, 15, { "cookie", "cake guard", "baking", "head baker" }) then
                return
            end

            local list = { "Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker" }
            local current2, huge = nil, math.huge
            for index, item in ipairs(enemies:GetChildren()) do
                if table.find(list, item.Name) and item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 and item:FindFirstChild("HumanoidRootPart") then
                    local distance = (item.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    if distance < huge then
                        huge = distance
                        current2 = item
                    end
                end
            end

            if current2 then
                local value2 = current2.Name == "Head Baker"
                repeat
                    task.wait()
                    local cakeLoaf = Workspace.Map:FindFirstChild("CakeLoaf")
                    cakeLoaf = cakeLoaf and cakeLoaf:FindFirstChild("BigMirror")
                    local other = cakeLoaf and cakeLoaf:FindFirstChild("Other")
                    if not _G.IgnoreBoss and (other and other.Transparency == 0 or enemies:FindFirstChild("Cake Prince") or enemies:FindFirstChild("Dough King")) then
                        break
                    end
                    if current2.Parent and current2.Humanoid.Health > 0 then
                        local humanoidRootPart = current2.HumanoidRootPart
                        local new = humanoidRootPart.Position + Vector3.new(0, farmHeight, 0)
                        if current and not value2 then
                            new = Vector3.new(new.X, current.Position.Y, new.Z)
                        end
                        local f13137 = lookAtCFrame(new, humanoidRootPart.Position)
                        rootPart.Velocity = Vector3.zero
                        rootPart.AssemblyLinearVelocity = Vector3.zero
                        if not value2 and (not current or f13137.Position.Y > current.Position.Y) then
                            current = f13137
                        end
                        Mob.Kill(current2, _G.AutoFarm_Cake, f13137)
                    else
                        break
                    end
                until not _G.StartFarm or not _G.AutoFarm_Cake or not current2.Parent or current2.Humanoid.Health <= 0
            else
                current = nil
                _tp(CFrame.new(-1927.92, 37.8, -12842.54))
            end
        end)
    end
end)

task.spawn(function()
    local list = { "Diablo", "Urban", "Deandre" }
    local amount = 0
    local startTime = tick()
    local current = nil

    local function helper(value2)
        if type(value2) ~= "string" then return false end
        for index, item in ipairs(list) do
            if string.find(value2, item, 1, true) then
                return true
            end
        end
        return false
    end

    local function helper2(target)
        local rootPart = target:FindFirstChild("HumanoidRootPart")
        if rootPart then return rootPart end
        if target:IsA("Model") and target.PrimaryPart then return target.PrimaryPart end
        return target:FindFirstChildWhichIsA("BasePart", true)
    end

    local function helper3()
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        for index, item in ipairs(enemies:GetChildren()) do
            if helper(item.Name) and Mob.Alive(item) and item:FindFirstChild("HumanoidRootPart") then
                return item
            end
        end
        return nil
    end

    local function helper4()
        for index, item in ipairs(value:GetChildren()) do
            if helper(item.Name) then
                local f882142 = helper2(item)
                if f882142 then
                    return item, f882142
                end
            end
        end
        return nil, nil
    end

    local function helper2()
        local flag = false
        local flag2 = false

        local success, result = pcall(function()
            local quest = localPlayer.PlayerGui.Main.Quest
            if quest.Visible then
                return helper(quest.Container.QuestTitle.Title.Text)
            end
            return false
        end)
        if success then
            flag = true
            if result then flag2 = true end
        end

        local success, result = pcall(function()
            local trackedQuestFrame = localPlayer.PlayerGui.TrackedQuestFrame
            if trackedQuestFrame:IsA("ScreenGui") and not trackedQuestFrame.Enabled then return false end
            if trackedQuestFrame.Frame.Visible == false then return false end
            return helper(trackedQuestFrame.Frame.header.textLabel.textLabel.Text)
        end)
        if success then
            flag = true
            if result then flag2 = true end
        end

        return flag2, flag
    end

    local function helper()
        if tick() - amount < 3 then return end
        amount = tick()
        value.Remotes.CommF_:InvokeServer("EliteHunter")
    end

    while task.wait(0.3) do
        local success, result = pcall(function()
            if not _G.FarmEliteHunt then return end

            local f912153, value2 = helper2()
            local f892145 = helper3()
            local f902149, value3 = helper4()

            if not value2 then
                f912153 = (f892145 ~= nil) or (f902149 ~= nil)
            end

            if not f912153 then
                helper()
                return
            end

            if f892145 then
                startTime = tick()
                repeat
                    task.wait()
                    Mob.Kill(f892145, _G.FarmEliteHunt)
                until not _G.FarmEliteHunt or not f892145.Parent or not f892145:FindFirstChild("Humanoid") or f892145.Humanoid.Health <= 0
                return
            end

            if f902149 and value3 then
                startTime = tick()
                _tp(value3.CFrame)
                return
            end

            if tick() - startTime > 5 then
                helper()
            end
        end)

        if not success and result ~= current then
            current = result
            warn("[Elite Hunter] " .. tostring(result))
        end
    end
end)

do
    local currentLevelQuestMob = nil

    getgenv().World1 = isSea1
    getgenv().World2 = isSea2
    getgenv().World3 = isSea3
    getgenv().replicated = value

    pcall(function()
        loadRemote(utilitiesUrl .. "quest")()
    end)

    local function f93(p153)
        if not p153 then return false end
        local v672, v673 = pcall(function()
            return localPlayer.PlayerGui.TrackedQuestFrame.Frame.header.textLabel.textLabel.Text
        end)
        if not v672 or type(v673) ~= "string" then return false end
        return string.find(string.lower(v673), string.lower(p153), 1, true) ~= nil
    end

    local levelQuestData = nil
    local levelQuestRefresh = 0

    local function levelNormalizeMobName(name)
        name = tostring(name or "")
        name = name:gsub(" %p?Lv%.? %d+%p?", "")
        name = name:gsub("%s+$", "")
        return name
    end

    local function levelGetSpawnPosition(mobName)
        local wanted = levelNormalizeMobName(mobName)
        local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
        local spawns = worldOrigin and worldOrigin:FindFirstChild("EnemySpawns")
        if spawns then
            for _, part in ipairs(spawns:GetChildren()) do
                if part:IsA("BasePart") and levelNormalizeMobName(part.Name) == wanted then
                    return part.CFrame
                end
            end
        end
        local ok, nilInstances = pcall(function()
            return getnilinstances()
        end)
        if ok and type(nilInstances) == "table" then
            for _, part in ipairs(nilInstances) do
                if typeof(part) == "Instance" and part:IsA("BasePart") and levelNormalizeMobName(part.Name) == wanted then
                    return part.CFrame
                end
            end
        end
        return nil
    end

    local SUBMERGED_TRAVEL_CF = CFrame.new(-16269.7041, 25.2288494, 1373.65955, 0.997390985, 1.47309942e-09, -0.0721890926, -4.00651912e-09, 0.99999994, -2.51183763e-09, 0.0721890852, 5.75363091e-10, 0.997390926)
    local SUBMERGED_Q1_NPC = CFrame.new(10778.875, -2087.72437, 9265.18359, 0.934615612, -9.33109447e-08, -0.355659455, 9.17655143e-08, 1, -2.12154276e-08, 0.355659455, -1.28090019e-08, 0.934615612)
    local SUBMERGED_Q2_NPC = CFrame.new(10880.6855, -2086.20044, 10032.624, -0.321384728, 9.87648434e-08, -0.946948707, 7.13271007e-08, 1, 8.00902953e-08, 0.946948707, -4.18033075e-08, -0.321384728)
    local SUBMERGED_Q3_NPC = CFrame.new(9640.08789, -1992.44507, 9613.65234, -0.957327187, 4.11991223e-08, 0.289006323, 1.5775445e-08, 1, -9.02985846e-08, -0.289006323, -8.18860855e-08, -0.957327187)

    local function levelSubmergedQuest(level)

        if level >= 2725 then
            return { "Grand Devotee", 2, "SubmergedQuest3", CFrame.new(9611.70508, -1993.47119, 9882.68848, -0.591375351, 4.14332426e-08, -0.806396425, 4.73774868e-08, 1, 1.66361875e-08, 0.806396425, -2.83668058e-08, -0.591375351), "Grand Devotee", SUBMERGED_Q3_NPC }
        elseif level >= 2700 then
            return { "High Disciple", 1, "SubmergedQuest3", CFrame.new(9750.41602, -1966.93884, 9753.36035, -0.749824047, 5.57797613e-08, -0.661637306, 2.03500754e-08, 1, 6.1243199e-08, 0.661637306, 3.24572511e-08, -0.749824047), "High Disciple", SUBMERGED_Q3_NPC }
        elseif level >= 2675 then
            return { "Ocean Prophet", 2, "SubmergedQuest2", CFrame.new(11008.5195, -2007.72839, 10223.0791, -0.688615739, 2.33523378e-09, -0.725126445, 2.99292546e-09, 1, 3.78221315e-10, 0.725126445, -1.90980032e-09, -0.688615739), "Ocean Prophet", SUBMERGED_Q2_NPC }
        elseif level >= 2650 then
            return { "Sea Chanter", 1, "SubmergedQuest2", CFrame.new(10671.2715, -2057.59155, 10047.2588, -0.846484065, -3.11045447e-08, 0.532414079, -5.55383117e-08, 1, -2.98785316e-08, -0.532414079, -5.48610757e-08, -0.846484065), "Sea Chanter", SUBMERGED_Q2_NPC }
        elseif level >= 2625 then
            return { "Coral Pirate", 2, "SubmergedQuest1", CFrame.new(10808.6006, -2030.36145, 9364.2334, -0.775185347, -0.0359364748, 0.6307109, 0.0615428537, 0.989336014, 0.132010356, -0.628728986, 0.141148239, -0.764707148), "Coral Pirate", SUBMERGED_Q1_NPC }
        elseif level >= 2600 then
            return { "Reef Bandit", 1, "SubmergedQuest1", CFrame.new(11019.1318, -2146.06812, 9342.3916, -0.719955266, -1.74275385e-08, 0.69402045, 5.76556367e-08, 1, 8.49211546e-08, -0.69402045, 1.01153624e-07, -0.719955266), "Reef Bandit", SUBMERGED_Q1_NPC }
        end
        return nil
    end

    local function f94()
        getgenv().TeamSelf = localPlayer.Team
        if tick() - levelQuestRefresh < 1 and levelQuestData then
            return levelQuestData
        end
        levelQuestRefresh = tick()

        local level = 0
        pcall(function() level = localPlayer.Data.Level.Value end)
        if level <= 0 then
            pcall(function() level = localPlayer:FindFirstChild("Data").Level.Value end)
        end

        local questsModule, guideModule
        local okQuests, resultQuests = pcall(function()
            return require(value:WaitForChild("Quests"))
        end)
        if okQuests then questsModule = resultQuests end
        local okGuide, resultGuide = pcall(function()
            return require(value:WaitForChild("GuideModule"))
        end)
        if okGuide then guideModule = resultGuide end
        local npcList = guideModule and guideModule.Data and guideModule.Data.NPCList
        if not questsModule or type(npcList) ~= "table" then
            levelQuestData = nil
            return nil
        end

        local chosen = nil
        local bestLevel = -1
        local placeId = game.PlaceId
        local specialMob, specialQuest, specialId
        if level >= 1450 and getgenv().CheckPlaceId2 and placeId == getgenv().CheckPlaceId2 then
            specialMob, specialQuest, specialId = "Water Fighter", "ForgottenQuest", 2
        elseif level >= 700 and getgenv().CheckPlaceId3 and placeId == getgenv().CheckPlaceId3 then
            specialMob, specialQuest, specialId = "Galley Captain", "FountainQuest", 2
        end

        local submerged = (isSea3 and level >= 2600) and levelSubmergedQuest(level) or nil

        if submerged then
            chosen = submerged
        elseif specialMob then
            local quest = questsModule[specialQuest] and questsModule[specialQuest][specialId]
            local npcPosition
            for _, npc in pairs(npcList) do
                if npc.InternalQuestName == specialQuest then
                    npcPosition = npc.Position
                    break
                end
            end
            local spawnPosition = levelGetSpawnPosition(specialMob)
            chosen = { specialMob, specialId, specialQuest, spawnPosition, specialMob, npcPosition }
        else
            for _, npc in pairs(npcList) do
                local questName = npc.InternalQuestName
                local questGroup = questName and questsModule[questName]
                if questGroup and type(npc.Levels) == "table" and questName ~= "MarineQuest" then
                    for questId, questLevel in pairs(npc.Levels) do
                        local quest = questGroup[questId]
                        if quest and type(quest.Task) == "table" and type(questLevel) == "number" and questLevel <= level and questLevel >= bestLevel and questName ~= "Town Raid" then
                            local mobName = nil
                            for mob, amount in pairs(quest.Task) do
                                if type(amount) == "number" and amount > 1 then
                                    mobName = mob
                                    break
                                end
                            end
                            if mobName then
                                bestLevel = questLevel
                                local npcPosition = npc.Position
                                if typeof(npcPosition) == "Vector3" then
                                    npcPosition = CFrame.new(npcPosition)
                                end
                                local spawnPosition = levelGetSpawnPosition(mobName)
                                chosen = { mobName, questId, questName, spawnPosition, mobName, npcPosition }
                            end
                        end
                    end
                end
            end
        end

        if chosen and not submerged then
            local mobName, questId, questName = chosen[1], chosen[2], chosen[3]
            local questGroup = questsModule[questName]
            local quest = questGroup and questGroup[questId]
            local tasks = quest and quest.Task
            local mobCount = 0
            if type(tasks) == "table" then
                for _, amount in pairs(tasks) do
                    if type(amount) == "number" and amount > 1 then mobCount += 1 end
                end
            end
            if mobCount >= 2 and guideModule.Data and guideModule.Data.QuestData and guideModule.Data.QuestData.Task then
                local trackedMob = next(guideModule.Data.QuestData.Task)
                if trackedMob == mobName then
                    for otherMob, amount in pairs(tasks) do
                        if otherMob ~= mobName and type(amount) == "number" and amount > 1 then
                            chosen[1] = otherMob
                            chosen[5] = otherMob
                            chosen[4] = levelGetSpawnPosition(otherMob) or chosen[4]
                            break
                        end
                    end
                end
            end
        end

        levelQuestData = chosen
        if chosen then
            Mon, Qdata, Qname, PosM, NameMon, PosQ = chosen[1], chosen[2], chosen[3], chosen[4], chosen[5], chosen[6]
        else
            Mon, Qdata, Qname, PosM, NameMon, PosQ = nil, nil, nil, nil, nil, nil
        end
        return chosen
    end

    local function f95(p154)
        local v674 = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not v674 then return nil end
        local v675, v676 = nil, math.huge
        local v655 = Workspace:FindFirstChild("Enemies")
        if not v655 then return nil end
        for _, mob in ipairs(v655:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart")
            if mob:IsA("Model") and mob.Name == p154 and hum and hum.Health > 0 and root then
                local distance = (root.Position - v674.Position).Magnitude
                if distance < v676 then
                    v676 = distance
                    v675 = mob
                end
            end
        end
        return v675
    end

    local function GeneratePatrolPoints(mainPosM)
        local pts = {}
        local base = mainPosM.Position
        local radius = 30
        table.insert(pts, CFrame.new(base + Vector3.new(radius, 0, 0)))
        table.insert(pts, CFrame.new(base + Vector3.new(-radius, 0, 0)))
        table.insert(pts, CFrame.new(base + Vector3.new(0, 0, radius)))
        table.insert(pts, CFrame.new(base + Vector3.new(0, 0, -radius)))
        table.insert(pts, CFrame.new(base + Vector3.new(radius, 0, radius)))
        table.insert(pts, CFrame.new(base + Vector3.new(-radius, 0, -radius)))
        return pts
    end

    local patrolIndex = 0
    local patrolTarget = nil
    local patrolStarted = 0

    task.spawn(function()
        while task.wait() do
            if not ((_G.Level and _G.StartFarm) or _G.MasteryLevel) then
                currentLevelQuestMob = nil
                _G.LevelQuestMobName = nil
                continue
            end
            pcall(function()
                local v678 = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not v678 then return end

                local v679 = f94()
                if not v679 then
                    currentLevelQuestMob = nil
                    _G.LevelQuestMobName = nil
                    return
                end

                local v680 = v679[3]
                local v681 = v679[2]
                local v682 = v679[1]
                currentLevelQuestMob = v682
                _G.LevelQuestMobName = v682
                local v683 = v679[4]
                local v684 = v679[5]

                if tostring(v680):find("^SubmergedQuest") and v679[6] and (v679[6].Position - v678.Position).Magnitude > 10000 then
                    _tp(SUBMERGED_TRAVEL_CF)
                    task.wait(2)
                    pcall(function()
                        value.Modules.Net:FindFirstChild("RF/SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
                    end)
                    task.wait(3)
                    return
                end

                local v685 = f93(v684)

                if not v685 then
                    if v679[6] then
                        local v686 = v679[6] * CFrame.new(0, 1, 0)
                        _tp(v686)
                        if (v678.Position - v686.Position).Magnitude <= 30 then
                            task.wait(1.5)
                            value.Remotes.CommF_:InvokeServer("AbandonQuest")
                            task.wait(0.3)
                            value.Remotes.CommF_:InvokeServer("StartQuest", v680, v681)
                            task.wait(1)
                        end
                    end
                    return
                end

                local v687 = f95(v682)
                if not v687 then
                    if v683 then
                        local patrolPoints = GeneratePatrolPoints(v683)
                        if not patrolTarget or tick() - patrolStarted >= 1.5 then
                            patrolIndex = (patrolIndex % #patrolPoints) + 1
                            patrolTarget = patrolPoints[patrolIndex]
                            patrolStarted = tick()
                        end
                        _tp(patrolTarget)
                    end
                    return
                end

                patrolTarget = nil
                patrolStarted = 0
                repeat
                    task.wait()
                    if v687.Parent and v687:FindFirstChild("HumanoidRootPart") then
                        local currentHumanoid = v687:FindFirstChildOfClass("Humanoid")
                        if currentHumanoid and currentHumanoid.Health > 0 and v687.Name == v682 then
                            local v688 = v687.HumanoidRootPart.Position
                            if _G.MasteryLevel and _G.AxlMasteryAttack then
                                _G.AxlMasteryAttack(v687)
                            else
                                Mob.Kill(v687, _G.Level, CFrame.new(v688.X + 2, v688.Y + 15, v688.Z))
                            end
                        end
                    end
                until not ((_G.Level and _G.StartFarm) or _G.MasteryLevel) or not f93(v684) or not v687.Parent or not v687:FindFirstChild("Humanoid") or v687.Humanoid.Health <= 0
            end)
        end
    end)
end

do
    pcall(function()
        loadRemote(utilitiesUrl .. "material")()
    end)

    local cframe = CFrame.new(0, farmHeight, 0)

    local function helper(target)
        if target:FindFirstChild("Humanoid") and target:FindFirstChild("HumanoidRootPart") and target.Humanoid.Health > 0 then
            repeat
                task.wait()
                Mob.Kill(target, getgenv().AutoMaterial)
            until not getgenv().AutoMaterial or not target.Parent or target.Humanoid.Health <= 0
        end
    end

    local function helper2()
        local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local worldOrigin = Workspace:FindFirstChild("_WorldOrigin")
        local enemySpawns = worldOrigin and worldOrigin:FindFirstChild("EnemySpawns")
        if not rootPart or not enemySpawns or not MMon then return end
        for index, item in pairs(enemySpawns:GetChildren()) do
            for index, item2 in ipairs(MMon) do
                if string.find(item.Name, item2) then
                    if (rootPart.Position - item.Position).Magnitude >= 10 then
                        _tp(item.CFrame * cframe)
                    end
                end
            end
        end
    end

    task.spawn(function()
        while task.wait() do
            if getgenv().AutoMaterial then
                pcall(function()
                    local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end

                    if Options.SelectMaterial and Options.SelectMaterial.Value then
                        getgenv().SelectMaterial = Options.SelectMaterial.Value
                    end

                    MMon, MPos = nil, nil
                    MaterialMon(getgenv().SelectMaterial)
                    if not MMon or not MPos then return end

                    _tp(MPos)

                    local current, huge = nil, math.huge
                    for index, item in ipairs(MMon) do
                        for index, item2 in pairs(Workspace.Enemies:GetChildren()) do
                            if getgenv().AutoMaterial and item2.Name == item and item2:FindFirstChild("HumanoidRootPart") and item2:FindFirstChild("Humanoid") and item2.Humanoid.Health > 0 then
                                local distance = (rootPart.Position - item2.HumanoidRootPart.Position).Magnitude
                                if distance < huge then
                                    huge = distance
                                    current = item2
                                end
                            end
                        end
                    end

                    if current and getgenv().AutoMaterial then
                        helper(current)
                    end

                    if getgenv().AutoMaterial then
                        helper2()
                    end
                end)
            end
        end
    end)
end

do
    local function helper()
        local value2 = localPlayer.Data.Level.Value
        if value2 >= 2575 then
            return CFrame.new(-16709.49, 419.68, 1751.09)
        elseif value2 > 2550 then
            return CFrame.new(-16645.64, 163.09, 1352.87)
        elseif value2 >= 2525 then
            return CFrame.new(-16602.1015625, 130.38734436035, 1087.2456054688)
        elseif value2 >= 2500 then
            return CFrame.new(-16347, 64, 984)
        elseif value2 >= 2475 then
            return CFrame.new(-16670, 43, -270)
        else
            return CFrame.new(-16350, 45, -180)
        end
    end

    local function helper2()
        local amount = 0
        local map = workspace:FindFirstChild("Map")
        local tikiOutpost = map and map:FindFirstChild("TikiOutpost")
        local islandModel = tikiOutpost and tikiOutpost:FindFirstChild("IslandModel")
        if not islandModel then return 0 end
        local islandChunks = islandModel:FindFirstChild("IslandChunks")
        local e = islandChunks and islandChunks:FindFirstChild("E")
        local list = {
            islandModel:FindFirstChild("Eye1"),
            islandModel:FindFirstChild("Eye2"),
            e and e:FindFirstChild("Eye3"),
            e and e:FindFirstChild("Eye4"),
        }
        for item = 1, 4 do
            if list[item] and list[item].Transparency == 0 then
                amount = amount + 1
            end
        end
        return amount
    end

    local list = { "Melee", "Blox Fruit", "Sword", "Gun" }
    local list2 = { "Z", "X", "C" }

    local function helper3(value2)
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local VirtualUser = game:GetService("VirtualUser")
        pcall(function()
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, workspace.CurrentCamera.CFrame.Position + Vector3.new(0, -1, 0))
        end)
        for index, item in ipairs(list) do
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            local current = nil
            for index, item2 in ipairs(localPlayer.Backpack:GetChildren()) do
                if item2:IsA("Tool") and item2.ToolTip == item then
                    current = item2
                    break
                end
            end
            if not current then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool and tool.ToolTip == item then
                    current = tool
                end
            end
            if current then
                humanoid:EquipTool(current)
                task.wait(.1)
                for item = 1, 3 do
                    if not (_G.StartFarm and _G.AutoTyrant) then return end
                    local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if value2 and rootPart then
                        rootPart.CFrame = value2
                    end
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new(851, 158))
                        local value2 = list2[item]
                        if value2 then
                            _G.AxlKeyGuard = (_G.AxlKeyGuard or 0) + 1
                            task.delay(0.6, function()
                                _G.AxlKeyGuard = math.max((_G.AxlKeyGuard or 1) - 1, 0)
                            end)
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[value2], false, game)
                            task.wait(.05)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[value2], false, game)
                        end
                    end)
                    task.wait(.1)
                end
            end
        end
    end

    local list = {
        CFrame.new(-16335.1, 158.1, 1465.6),
        CFrame.new(-16288.6, 158.1, 1470.3),
        CFrame.new(-16258, 156.7, 1461.4),
        CFrame.new(-16212.4, 158.1, 1466.3),
        CFrame.new(-16335, 159.3, 1324.8),
        CFrame.new(-16286, 155.9, 1323.8),
        CFrame.new(-16250.3, 159.3, 1316.3),
    }
    local list2 = { "Skull Slayer", "Serpent Hunter", "Isle Champion", "Sun-kissed Warrior", "Island Boy", "Isle Outlaw" }
    local amount = 1

    task.spawn(function()
        while task.wait() do
            if not _G.AutoTyrant or not _G.StartFarm then continue end
            pcall(function()
                local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                if not rootPart or not humanoid or humanoid.Health <= 0 then return end

                local enemies = Workspace:FindFirstChild("Enemies")
                local tyrantoftheSkies = enemies and enemies:FindFirstChild("Tyrant of the Skies")
                local f992215 = helper2()

                if not _G.IgnoreBoss and tyrantoftheSkies and tyrantoftheSkies:FindFirstChild("Humanoid") and tyrantoftheSkies.Humanoid.Health > 0 and tyrantoftheSkies:FindFirstChild("HumanoidRootPart") then
                    repeat
                        task.wait()
                        Mob.Kill(tyrantoftheSkies, _G.AutoTyrant)
                    until not _G.StartFarm or not _G.AutoTyrant or not tyrantoftheSkies.Parent
                        or not tyrantoftheSkies:FindFirstChild("Humanoid") or tyrantoftheSkies.Humanoid.Health <= 0
                        or not rootPart.Parent or humanoid.Health <= 0
                    return
                end

                if f992215 == 4 and not _G.IgnoreBoss then
                    local value2 = list[amount]
                    if value2 then
                        if (rootPart.Position - value2.Position).Magnitude < 10 then
                            rootPart.CFrame = value2
                            helper3(value2)
                            local amount2 = 0
                            repeat
                                task.wait(.1)
                                if character:FindFirstChild("HumanoidRootPart") then
                                    character.HumanoidRootPart.CFrame = value2
                                end
                                amount2 = amount2 + .1
                            until amount2 >= 1.5 or not _G.AutoTyrant or not _G.StartFarm
                            amount = amount + 1
                            if amount > #list then amount = 1 end
                        else
                            _tp(value2)
                        end
                    end
                    return
                end

                if _G.AcceptQuest then
                    local level = localPlayer.Data.Level.Value
                    local questName, questId, questPos
                    if level >= 2575 then questName, questId = "TikiQuest3", 2
                    elseif level > 2550 then questName, questId = "TikiQuest3", 1
                    elseif level >= 2525 then questName, questId = "TikiQuest2", 2
                    elseif level >= 2500 then questName, questId = "TikiQuest2", 1
                    elseif level >= 2475 then questName, questId = "TikiQuest1", 2
                    else questName, questId = "TikiQuest1", 1 end
                    if questName == "TikiQuest3" then
                        questPos = CFrame.new(-16665.0879, 105.27478, 1577.61743)
                    else
                        questPos = CFrame.new(-16546.748, 55.7216759, -172.865311)
                    end
                    if _G.AxlHandleQuest(rootPart, questPos, { { questName, questId } }, 10, { "skull slayer", "serpent", "isle", "sun-kissed", "island" }) then
                        return
                    end
                end

                local current, huge = nil, math.huge
                if enemies then
                    for index, item in ipairs(enemies:GetChildren()) do
                        if table.find(list2, item.Name) and item:FindFirstChild("Humanoid") and item.Humanoid.Health > 0 and item:FindFirstChild("HumanoidRootPart") then
                            local distance = (rootPart.Position - item.HumanoidRootPart.Position).Magnitude
                            if distance < huge then
                                huge = distance
                                current = item
                            end
                        end
                    end
                end

                if current then
                    repeat
                        task.wait()
                        Mob.Kill(current, _G.AutoTyrant)
                    until not _G.StartFarm or not _G.AutoTyrant or not current.Parent
                        or not current:FindFirstChild("Humanoid") or current.Humanoid.Health <= 0
                        or not rootPart.Parent or humanoid.Health <= 0
                else
                    _tp(helper())
                end
            end)
        end
    end)
end

local list = {
    value:WaitForChild("Util"),
    value:WaitForChild("Common"),
    value:WaitForChild("Remotes"),
    value:WaitForChild("Assets"),
    value:WaitForChild("FX")
}

local current, current2 = nil, nil

local function helper(value2)
    if value2:IsA("RemoteEvent") and value2:GetAttribute("Id") then
        current2 = value2:GetAttribute("Id")
        current = value2
    end
end

task.spawn(function()
    for index, item in ipairs(list) do
        for index, item2 in ipairs(item:GetChildren()) do helper(item2) end
        item.ChildAdded:Connect(helper)
    end
end)

task.spawn(function()
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local WS = workspace
    local LP = Players.LocalPlayer

    local CombatUtil = require(RS.Modules.CombatUtil)
    local Net = require(RS.Modules.Net)
    local RegisterAttack = RS.Modules.Net:WaitForChild("RE/RegisterAttack")
    local RegisterHit = Net:RemoteEvent("RegisterHit", true)
    local validator2 = RS.Remotes:WaitForChild("Validator2")

    _G.AttackRange = _G.AttackRange or 60
    _G.AttackDelay = _G.AttackDelay or 0.05
    if _G.PlayAnimation == nil then _G.PlayAnimation = true end
    if _G.AttackPlayers == nil then _G.AttackPlayers = false end
    if _G.FastAttackEnabled == nil then _G.FastAttackEnabled = true end

    local BODY_PARTS = {
        RightUpperArm = true, RightLowerArm = true, RightHand = true,
        RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
        LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
        LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
        UpperTorso = true, LowerTorso = true, Head = true,
    }

    local combatAttackUps
    local function getCombatUpvalues()
        if combatAttackUps then return combatAttackUps end
        local ok, fn = pcall(function()
            return getupvalue(require(RS.Controllers.CombatController).Attack, 9)
        end)
        if ok and fn then combatAttackUps = fn end
        return combatAttackUps
    end

    local function advanceValidator()
        local fn = getCombatUpvalues()
        if not fn then return end
        pcall(function()
            local u15 = getupvalue(fn, 15)
            local u13 = getupvalue(fn, 13)
            local u16 = getupvalue(fn, 16)
            local u17 = getupvalue(fn, 17)
            local u14 = getupvalue(fn, 14)
            local u12 = getupvalue(fn, 12)
            local u18 = getupvalue(fn, 18)
            if not u15 or not u13 or not u16 or not u17 then return end
            u12 = u12 or 0
            u14 = u14 or 0
            u18 = u18 or 0
            local q = u12 * u13
            local d = ((u14 * u13 + u12 * u15) % u16 * u16 + q) % u17
            u14 = math.floor(d / u16)
            u12 = d - u14 * u16
            u18 = u18 + 1
            setupvalue(fn, 15, u15)
            setupvalue(fn, 13, u13)
            setupvalue(fn, 16, u16)
            setupvalue(fn, 17, u17)
            setupvalue(fn, 14, u14)
            setupvalue(fn, 12, u12)
            setupvalue(fn, 18, u18)
            validator2:FireServer(math.floor(d / u17 * 16777215), u18)
        end)
    end

    local function getBladeHits(character, rootList, range, includePlayers)
        local hits = {}
        local rootPos = rootList[1].Position
        local folders = { WS:FindFirstChild("Enemies") }
        if includePlayers then
            table.insert(folders, WS:FindFirstChild("Characters"))
        end
        for _, folder in ipairs(folders) do
            if folder then
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob ~= character and mob:FindFirstChild("HumanoidRootPart") then
                        local hrp = mob.HumanoidRootPart
                        local checkPos = { hrp.Position }
                        if hrp.Size.Y > 5 then
                            table.insert(checkPos, (hrp.CFrame * CFrame.new(0, -hrp.Size.Y * 1.5 + 3, 0)).Position)
                        end
                        local hitRadius = range
                        if Players:GetPlayerFromCharacter(mob) then
                            hitRadius = range / 1.5
                        end
                        for _, pos in ipairs(checkPos) do
                            if (pos - rootPos).Magnitude < 10 + hitRadius + hrp.Size.X / 2 then
                                for _, part in ipairs(mob:GetChildren()) do
                                    if part:IsA("BasePart") and (part.Position - rootPos).Magnitude <= hitRadius + hrp.Size.X / 2 then
                                        table.insert(hits, part)
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
        return hits
    end

    local function AttackAOE(character, range, includePlayers)
        local hits, seen = {}, {}
        local rootList = { character.HumanoidRootPart }
        for _, part in ipairs(getBladeHits(character, rootList, range, includePlayers)) do
            local rig = CombatUtil:GetRigOfHitPart(part)
            if rig and not seen[rig] and BODY_PARTS[part.Name] and CombatUtil:IsVulnerable(rig) then
                local myPlayer = Players:GetPlayerFromCharacter(character)
                local summoner = rig:FindFirstChild("Summoner")
                local mySummoner = character:FindFirstChild("Summoner")
                local valid = rig ~= character
                    and (not mySummoner or rig ~= mySummoner.Value.Character)
                    and (not myPlayer or not summoner or summoner.Value ~= myPlayer)
                local hold = _G.MasteryHold
                if valid and hold and not Players:GetPlayerFromCharacter(rig) then
                    local rigHumanoid = rig:FindFirstChildOfClass("Humanoid")
                    if rigHumanoid and rigHumanoid.Health <= rigHumanoid.MaxHealth * hold then
                        valid = false
                    end
                end
                if valid then
                    table.insert(hits, { rig, part })
                    seen[rig] = true
                end
            end
        end
        return #hits > 0 and hits or nil
    end

    local animState = { comboIndex = 0, lastComboTime = 0, currentAnim = nil }

    local function getMovesetAnimCache(character)
        local ok, res = pcall(function()
            return CombatUtil:GetMovesetAnimCache(character.Humanoid)
        end)
        return ok and res or nil
    end

    local function attackMelee(character, tool, range)
        if not tool then return end
        local hits = AttackAOE(character, range or _G.AttackRange, _G.AttackPlayers)
        if not hits then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local ok, wname = pcall(function() return CombatUtil:GetWeaponName(tool) end)
        if not ok or not wname then return end
        local ok2, wdata = pcall(function() return CombatUtil:GetWeaponData(wname) end)
        if not ok2 or not wdata then return end
        local root = humanoid.RootPart
        local rig = root and root.Parent
        if not CombatUtil:CanAttack(rig, wdata.WeaponType) then return end
        local cache = getMovesetAnimCache(character)
        if not cache then return end

        local moveset = wdata.Moveset
        local now = tick()
        if now - animState.lastComboTime > 0.8 then animState.comboIndex = 0 end
        animState.comboIndex = animState.comboIndex % #moveset.Basic + 1
        animState.lastComboTime = now

        local pureName = CombatUtil:GetPureWeaponName(wname)
        local anim = cache[pureName .. "-basic" .. animState.comboIndex]
        if not anim then return end

        local speedMult = anim:GetAttribute("SpeedMult") or 1
        local duration = anim.Length / speedMult

        RegisterAttack:FireServer(duration)
        RegisterHit:FireServer(table.remove(hits, 1)[2], hits)

        pcall(function()
            if animState.currentAnim and animState.currentAnim ~= anim then
                animState.currentAnim:Stop()
            end
            anim:Play(0.1, 1, speedMult)
            animState.currentAnim = anim
        end)

        table.clear(hits)
        return true
    end

    local function attackNoAnim(character, range)
        if character.Stun and character.Stun.Value ~= 0 then return end
        local hits = AttackAOE(character, range or _G.AttackRange, _G.AttackPlayers)
        if not hits then return end
        advanceValidator()
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(table.remove(hits, 1)[2], hits)
        table.clear(hits)
        return true
    end

    getgenv().AttackFunction = function(range)
        local character = LP.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if character.Stun and character.Stun.Value ~= 0 then return end
        local tool = character:FindFirstChildOfClass("Tool")
        if _G.PlayAnimation and tool and tool:GetAttribute("WeaponType") then
            attackMelee(character, tool, range)
        else
            attackNoAnim(character, range)
        end
    end

    getgenv().AttackFunctionSuper = function()
        local character = LP.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if character.Stun and character.Stun.Value ~= 0 then return end
        local hits = AttackAOE(character, 80, true)
        if not hits then return end
        advanceValidator()
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(table.remove(hits, 1)[2], hits)
        table.clear(hits)
    end

    while true do
        if _G.FastAttackEnabled and _G.OtherAutoAttack and isFarming(true) then
            pcall(function()
                local character = LP.Character
                if not character or not character:FindFirstChild("HumanoidRootPart") then return end
                if _G.UseDragonstorm and not _G.AutoTtk then return end
                if _G.MasteryFinish then return end
                local want = _G.MasteryWeapon or _G.SeaWeapon or _G.SelectWeapon

                if isFarming(true) and not _G.AutoMasterySwords and not _G.AutoTtk then
                    local tool0 = character:FindFirstChildOfClass("Tool")
                    local wt0 = tool0 and (tool0:GetAttribute("WeaponType") or tool0.ToolTip)
                    local alreadyOk = wt0 == want or (want == "Fruit" and tool0 and tool0.ToolTip == "Blox Fruit")
                    if not alreadyOk and AttackAOE(character, _G.AttackRange, _G.AttackPlayers) then
                        equipWeaponType(want)
                    end
                end

                local tool = character:FindFirstChildOfClass("Tool")
                if not tool then return end

                if not _G.OtherDoubleAttack then
                    local wt = tool:GetAttribute("WeaponType") or tool.ToolTip

                    if wt ~= "Melee" and wt ~= "Sword" then return end
                end
                if want == "Fruit" and not _G.AutoTtk and not _G.OtherDoubleAttack then return end

                getgenv().AttackFunction()
            end)
            task.wait(_G.AttackDelay)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    local value2 = cloneref or function(value3) return value3 end

    local value3 = value2(game:GetService("Players"))
    local value4 = value2(game:GetService("Workspace"))

    local localPlayer2 = value3.LocalPlayer
    local character = localPlayer2.Character or localPlayer2.CharacterAdded:Wait()
    local waitForChild = character:WaitForChild("HumanoidRootPart", 10)

    localPlayer2.CharacterAdded:Connect(function(value2)
        character = value2
        waitForChild = value2:WaitForChild("HumanoidRootPart", 10)
    end)

    local value2 = getgenv().AttackConfig or {
        Range = 60,
        DoubleAttack = false,
    }
    getgenv().AttackConfig = value2

    local enemies = value4:WaitForChild("Enemies")
    local map = { ["Blade-Blade"] = true, ["Gas-Gas"] = true }

    local amount = 0
    local amount2 = 0

    local function helper(target)
        if not target or not target.Parent then return false end
        if not target:IsDescendantOf(enemies) then return false end
        if target:GetAttribute("IsBoat") then return false end

        local humanoid = target:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end

        local rootPart = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        if not rootPart then return false end
        return true, humanoid, rootPart
    end

    local function helper2(target)
        local leftClickRemote = target:FindFirstChild("LeftClickRemote")
        if not leftClickRemote then return end

        pcall(function()
            leftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
        end)
    end

    local function helper3(target)
        local leftClickRemote = target:FindFirstChild("LeftClickRemote")
        if not leftClickRemote then return end

        if tick() - amount2 > 0.65 then
            amount = 0
        end
        amount = (amount >= 5) and 1 or (amount + 1)
        amount2 = tick()

        if not waitForChild then return end

        for index, item in ipairs(enemies:GetChildren()) do
            local f1022312, value3, value3 = helper(item)
            if f1022312 then
                if (value3.Position - waitForChild.Position).Magnitude <= value2.Range then
                    local unit = (value3.Position - waitForChild.Position).Unit
                    pcall(function()
                        leftClickRemote:FireServer(unit, amount)
                    end)
                end
            end
        end
    end

    local GAS_RANGE = 100
    local GAS_MAX_TARGETS = 6
    local gasParts, gasHumanoids, gasScanned, gasIndex = {}, {}, 0, 0
    local gasActive = false

    local function gasScan()
        if tick() - gasScanned < 0.1 then return end
        gasScanned = tick()
        table.clear(gasParts)
        table.clear(gasHumanoids)
        if not waitForChild then return end
        local origin = waitForChild.Position
        local found = {}
        for index, item in ipairs(enemies:GetChildren()) do
            local ok, humanoid, rootPart = helper(item)
            if ok then
                local distance = (rootPart.Position - origin).Magnitude
                if distance <= GAS_RANGE then
                    found[#found + 1] = { part = rootPart, humanoid = humanoid, distance = distance }
                end
            end
        end
        table.sort(found, function(first, second) return first.distance < second.distance end)
        for index = 1, math.min(#found, GAS_MAX_TARGETS) do
            gasParts[index] = found[index].part
            gasHumanoids[index] = found[index].humanoid
        end
    end

    local function helperGas(tool)
        local leftClickRemote = tool:FindFirstChild("LeftClickRemote")
        if not leftClickRemote or not waitForChild then return end
        gasScan()
        local total = #gasParts
        if total > 0 then
            local origin = waitForChild.Position
            for attempt = 1, total do
                gasIndex = (gasIndex % total) + 1
                local part = gasParts[gasIndex]
                if part.Parent and gasHumanoids[gasIndex].Health > 0 then
                    local offset = part.Position - origin
                    if offset.Magnitude > 0.01 and offset.Magnitude <= GAS_RANGE then
                        leftClickRemote:FireServer(offset.Unit, 1)
                        return
                    end
                end
            end
        end
        leftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
    end

    local function helper4()
        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool and tool:GetAttribute("ServerState") ~= nil then return end
        if not tool or tool.ToolTip ~= "Blox Fruit" then
            tool = nil
            if _G.OtherDoubleAttack then
                for index, item in ipairs(localPlayer2.Backpack:GetChildren()) do
                    if item:IsA("Tool") and item.ToolTip == "Blox Fruit" and item:FindFirstChild("LeftClickRemote") then
                        tool = item
                        break
                    end
                end
            end
        end
        if not tool then return end
        if not tool:FindFirstChild("LeftClickRemote") then return end
        if not waitForChild then return end

        if value2.DoubleAttack then
            for index, item in ipairs(localPlayer2.Backpack:GetChildren()) do
                if item:IsA("Tool") and item.ToolTip == "Blox Fruit"
                   and item ~= tool and item:FindFirstChild("LeftClickRemote") then
                    if item.Name == "Gas-Gas" then
                        gasActive = true
                        helperGas(item)
                    elseif map[item.Name] then
                        local leftClickRemote = item:FindFirstChild("LeftClickRemote")
                        for index, item2 in ipairs(enemies:GetChildren()) do
                            local f1022312, value3, value3 = helper(item2)
                            if f1022312 and (value3.Position - waitForChild.Position).Magnitude <= value2.Range then
                                local unit = (value3.Position - waitForChild.Position).Unit
                                pcall(function() leftClickRemote:FireServer(unit, 1) end)
                            end
                        end
                    else
                        helper2(item)
                    end
                    break
                end
            end
        end

        gasActive = tool.Name == "Gas-Gas"
        if gasActive then
            helperGas(tool)
        elseif map[tool.Name] then
            helper3(tool)
        else
            helper2(tool)
        end
    end

    getgenv().FruitAttack = helper4

    while true do
        if _G.OtherAutoAttack and isFarming(true) then
            gasActive = false
            pcall(helper4)
            task.wait(gasActive and 0.03 or 0.05)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    local value2 = cloneref or function(value3) return value3 end

    local value3 = value2(game:GetService("Players"))
    local value4 = value2(game:GetService("Workspace"))
    local value5 = value2(game:GetService("ReplicatedStorage"))

    local localPlayer2 = value3.LocalPlayer
    local character = localPlayer2.Character or localPlayer2.CharacterAdded:Wait()

    localPlayer2.CharacterAdded:Connect(function(value2)
        character = value2
    end)

    local enemies = value4:WaitForChild("Enemies")
    local remotes = value5:WaitForChild("Remotes")
    local modules = value5:WaitForChild("Modules")
    local net = modules:WaitForChild("Net")

    local function helper(target)
        if not target or not target.Parent then return false end
        if not target:IsDescendantOf(enemies) then return false end
        if target:GetAttribute("IsBoat") then return false end

        local humanoid = target:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end

        local rootPart = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        if not rootPart then return false end
        return true, humanoid, rootPart
    end

    pcall(function()
        local module = require(modules:WaitForChild("CombatUtil"))
        if module and module.CanAttack and hookfunction then
            local map = {
                ["Fishing Rod"] = true,
                ["Gold Rod"] = true,
                ["Shark Rod"] = true,
                ["Shell Rod"] = true,
                ["Treasure Rod"] = true,
                ["Shell (Celestial)"] = true,
                ["Shark (Corrupted)"] = true,
            }
            local value2
            value2 = hookfunction(module.CanAttack, function(...)
                local character2 = localPlayer2.Character
                local tool = character2 and character2:FindFirstChildOfClass("Tool")
                if tool and (map[tool.Name] or tool:GetAttribute("ServerState") ~= nil) then
                    return value2(...)
                end
                return true
            end)
        end
    end)

    local okCC, module = pcall(function() return require(value5.Controllers.CombatController) end)
    if not okCC or not module then module = { Attack = function() end } end
    local validator2 = remotes:WaitForChild("Validator2")
    local firstChild = net:FindFirstChild("RE/ShootGunEvent")

    local map = { ["Dual Flintlock"] = 2 }
    local map2 = {
        ["Skull Guitar"] = "TAP",
        Bazooka = "Position",
        Cannon = "Position",
        Dragonstorm = "Overheat",
    }
    local map3 = {
        ["Skull Guitar"] = function(value2, value3)
            value2.RemoteEvent:FireServer("TAP", value3)
        end,
    }

    local success, result = pcall(function()
        return getupvalue(module.Attack, 9)
    end)

    local function helper2()
        if not result then
            pcall(function() result = getupvalue(module.Attack, 9) end)
        end
        if not result then return 0, 0 end

        local upvalue = getupvalue(result, 15)
        local upvalue2 = getupvalue(result, 13)
        local upvalue3 = getupvalue(result, 16)
        local upvalue4 = getupvalue(result, 17)
        local upvalue5 = getupvalue(result, 14)
        local upvalue6 = getupvalue(result, 18)
        local upvalue7 = getupvalue(result, 19)

        if not upvalue or not upvalue2 or not upvalue3 or not upvalue4 or not upvalue5 or not upvalue6 or not upvalue7 then
            return 0, 0
        end

        local value2 = ((upvalue * upvalue5 + upvalue2 * upvalue3) % upvalue4 * upvalue4 + upvalue2 * upvalue5) % upvalue6
        local floor = math.floor(value2 / upvalue4)
        local value3 = value2 - floor * upvalue4
        local value4 = upvalue7 + 1

        pcall(function()
            setupvalue(result, 15, floor)
            setupvalue(result, 13, value3)
            setupvalue(result, 19, value4)
        end)

        return math.floor(value2 / upvalue6 * 16777215), value4
    end

    local function helper3(value2)
        value2 = value2 or 500
        local list = {}
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
        if not rootPart then return list end

        for index, item in ipairs(enemies:GetChildren()) do
            local f1062353, value3, value3 = helper(item)
            if f1062353 then
                local distance = (value3.Position - rootPart.Position).Magnitude
                if distance <= value2 then
                    table.insert(list, { item, value3, distance })
                end
            end
        end
        table.sort(list, function(value2, value3) return value2[3] < value3[3] end)
        return list
    end

    local function helper(target, target2)
        local position = target2.Position

        if map3[target.Name] then
            map3[target.Name](target, position)
            return
        end

        local value2 = map2[target.Name]
        if not value2 then
            value2 = target:FindFirstChild("RemoteEvent") and "TAP" or "Normal"
        end

        local value3 = map[target.Name] or 1

        pcall(function()
            local f1072372, value4 = helper2()
            validator2:FireServer(f1072372, value4)

            if target:FindFirstChild("RemoteEvent") and value2 == "TAP" then
                target.RemoteEvent:FireServer("TAP", position)
            elseif firstChild then
                for item = 1, value3 do
                    firstChild:FireServer(position, { target2 })
                end
            end
        end)
    end

    getgenv().AxlGunShoot = function(value2, value3)
        if not value2 or not value3 then return end
        value2:SetAttribute("IsReloading_Client", false)
        value2:SetAttribute("LocalShotsLeft", 100)
        value2:SetAttribute("LocalTotalShots", (value2:GetAttribute("LocalTotalShots") or 0) + 1)
        helper(value2, value3)
    end

    local function helper2()
        local tool = character and character:FindFirstChildOfClass("Tool")
        if not tool or tool.ToolTip ~= "Gun" then return end
        if not tool.Enabled then return end

        tool:SetAttribute("IsReloading_Client", false)
        tool:SetAttribute("LocalShotsLeft", 100)
        tool:SetAttribute("LocalTotalShots", (tool:GetAttribute("LocalTotalShots") or 0) + 1)

        local f1082384 = helper3(500)
        if #f1082384 == 0 then return end

        helper(tool, f1082384[1][2])
    end

    while true do
        if _G.OtherAutoAttack and isFarming(true) then
            pcall(helper2)
            task.wait(0.05)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if not _G.UseDragonstorm then return end

            local localPlayer2 = Players.LocalPlayer
            local character = localPlayer2.Character
            local backpack = localPlayer2:FindFirstChild("Backpack")
            if not character or not backpack then return end

            local dragonstorm = backpack:FindFirstChild("Dragonstorm") or character:FindFirstChild("Dragonstorm")

            if not dragonstorm then
                pcall(function()
                    value.Remotes.CommF_:InvokeServer("LoadItem", "Dragonstorm")
                end)
                task.wait(1)
                dragonstorm = backpack:FindFirstChild("Dragonstorm") or (localPlayer2.Character and localPlayer2.Character:FindFirstChild("Dragonstorm"))
                if not dragonstorm then
                    Fluent:Notify({
                        Title = "Axl Hub",
                        Content = "You don't have Dragonstorm",
                        Duration = 5
                    })
                    _G.UseDragonstorm = false
                    pcall(function()
                        Fluent.Options.UseDragonstorm:SetValue(false)
                    end)
                    return
                end
            end

            if isFarming() and not _G.AutoTtk and not character:FindFirstChild("Dragonstorm") then
                local dragonstorm = backpack:FindFirstChild("Dragonstorm")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if dragonstorm and humanoid then
                    humanoid:EquipTool(dragonstorm)
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(loopDelay) do
        pcall(function()
            if autoBuso then
                local list = {"HasBuso", "Buso"}
                if not localPlayer.Character:FindFirstChild(list[1]) then
                    value.Remotes.CommF_:InvokeServer(list[2])
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(.2) do
        pcall(function()
            if _G.RaceClickAutov3 then
                while _G.RaceClickAutov3 do
                    value.Remotes.CommE:FireServer("ActivateAbility")
                    task.wait(30)
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(.5) do
        pcall(function()
            if not _G.RaceClickAutov4 then return end

            local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
            local raceTransformed = character:FindFirstChild("RaceTransformed")
            local raceEnergy = character:FindFirstChild("RaceEnergy")

            if raceEnergy and raceEnergy.Value >= 1 and raceTransformed and not raceTransformed.Value then
                local awakening = localPlayer.Backpack:FindFirstChild("Awakening") or character:FindFirstChild("Awakening")
                if awakening and awakening:FindFirstChild("RemoteFunction") then
                    awakening.RemoteFunction:InvokeServer(true)
                end
            end
        end)
    end
end)

local list = {};
local amount = 350;
local Players2 = game:GetService("Players");
local localPlayer2 = Players2.LocalPlayer;
local list = {
    "Gorilla King",
    "Bobby",
    "Yeti",
    "Mob Leader",
    "Vice Admiral",
    "Warden",
    "Chief Warden",
    "Swan",
    "Magma Admiral",
    "Fishman Lord",
    "Wysper",
    "Thunder God",
    "Cyborg",
    "Saber Expert",
    "Greybeard",
    "Diamond",
    "Jeremy",
    "Fajita",
    "Don Swan",
    "Smoke Admiral",
    "Cursed Captain",
    "Darkbeard",
    "Order",
    "Awakened Ice Admiral",
    "Tide Keeper",
    "Stone",
    "Island Empress",
    "Kilo Admiral",
    "Captain Elephant",
    "Beautiful Pirate",
    "Longma",
    "Cake Queen",
    "Soul Reaper",
    "rip_indra",
    "Cake Prince",
    "Dough King",
    "Tyrant Of The Skies",
    "Tyrant of the Skies",
};
local function helper(target)
    if not list then
        return false;
    end;
    for index, item in ipairs(list) do
        if target.Name == item then
            return true;
        end;
    end;
    return false;
end;
BringEnemy = function()
    local BRING_MAX_MOBS = 3;
    if not bringMobsEnabled then
        return;
    end;
    if _G.SeaFarm2 or _G.SeaFarm3 then
        return;
    end;
    if not lockedPosition then
        return;
    end;
    local character = localPlayer2.Character;
    local rootPart = character and character:FindFirstChild("HumanoidRootPart");
    if not rootPart then
        return;
    end;
    pcall(function()
        sethiddenproperty(localPlayer2, "SimulationRadius", 500);
    end);
    local enemies = workspace:FindFirstChild("Enemies");
    if not enemies then
        return;
    end;

    local targetName = nil;
    if _G.Level then
        targetName = _G.LevelQuestMobName;
        if not targetName then
            return;
        end;
    end;

    local candidates = {};
    for index, item in ipairs(enemies:GetChildren()) do
        if helper(item) then
            continue;
        end;
        if targetName and item.Name ~= targetName then
            continue;
        end;
        local rootPart2 = item:FindFirstChild("HumanoidRootPart");
        local humanoid = item:FindFirstChildOfClass("Humanoid");
        if rootPart2 and humanoid and humanoid.Health > 0 then
            local distance = (rootPart2.Position - lockedPosition).Magnitude;
            if distance <= amount and (rootPart2.Position - rootPart.Position).Magnitude <= amount then
                candidates[#candidates + 1] = { item = item, root = rootPart2, humanoid = humanoid, distance = distance };
            end;
        end;
    end;

    table.sort(candidates, function(first, second)
        return first.distance < second.distance;
    end);
    for index = 1, math.min(#candidates, BRING_MAX_MOBS) do
        local entry = candidates[index];
        local rootPart2, humanoid = entry.root, entry.humanoid;

        if not rootPart2:FindFirstChild("LockMob") then
            local bodyVelocity = Instance.new("BodyVelocity");
            bodyVelocity.Parent = rootPart2;
            bodyVelocity.Name = "LockMob";
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            bodyVelocity.Velocity = Vector3.zero;
            for index2, item2 in ipairs(entry.item:GetDescendants()) do
                if item2:IsA("BasePart") then
                    item2.CanCollide = false;
                end;
            end;
            local animator = humanoid:FindFirstChild("Animator");
            if animator then
                animator:Destroy();
            end;
            humanoid:ChangeState(Enum.HumanoidStateType.Physics);
        end;
        humanoid.WalkSpeed = 0;
        humanoid.JumpPower = 0;

        if entry.distance > 5 then
            if type(isnetworkowner) == "function" then
                if isnetworkowner(rootPart2) then
                    rootPart2.CFrame = CFrame.new(lockedPosition);
                end;
            else
                rootPart2.CFrame = CFrame.new(lockedPosition);
            end;
        end;
    end;
end;
task.spawn(function()
    while true do
        if bringMobsEnabled then
            pcall(BringEnemy);
            task.wait(0.3);
        else
            task.wait(2);
        end;
    end;
end);

local cacheChar, cacheParts, cacheT = nil, {}, 0

RunService.Stepped:Connect(function()
    local character = Players.LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Sit then
            humanoid.AutoRotate = true
            return
        end

        if getgenv().OnFarm and isFarming() then
            if humanoid then humanoid.AutoRotate = false end
            if rootPart then
                rootPart.Velocity = Vector3.zero
                rootPart.RotVelocity = Vector3.zero
                rootPart.AssemblyLinearVelocity = Vector3.zero
                rootPart.AssemblyAngularVelocity = Vector3.zero
                if rootPart.CFrame.UpVector.Y < 0.98 then
                    rootPart.CFrame = facingCFrame(rootPart.CFrame, rootPart)
                end
            end
            if character ~= cacheChar or tick() - cacheT > 2 then
                cacheChar, cacheT, cacheParts = character, tick(), {}
                for value2, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        cacheParts[#cacheParts + 1] = part
                    end
                end
            end
            for value2, part in ipairs(cacheParts) do
                if part.Parent then part.CanCollide = false end
            end
        else
            if humanoid then humanoid.AutoRotate = true end
        end
    end
end)

task.spawn(function()
    while task.wait(loopDelay) do
        pcall(function()
            if _G.RemoveDamage then
                if value:FindFirstChild("Assets") and value.Assets:FindFirstChild("GUI") and value.Assets.GUI:FindFirstChild("DamageCounter") then
                    value.Assets.GUI.DamageCounter.Enabled = false
                end
                if localPlayer.PlayerGui:FindFirstChild("Notifications") then
                    localPlayer.PlayerGui.Notifications.Enabled = false
                end
            else
                if value:FindFirstChild("Assets") and value.Assets:FindFirstChild("GUI") and value.Assets.GUI:FindFirstChild("DamageCounter") then
                    value.Assets.GUI.DamageCounter.Enabled = true
                end
                if localPlayer.PlayerGui:FindFirstChild("Notifications") then
                    localPlayer.PlayerGui.Notifications.Enabled = true
                end
            end
        end)
    end
end)

do
    local list = { "Fishing Rod", "Gold Rod", "Shark Rod", "Shell Rod", "Treasure Rod", "Shell (Celestial)", "Shark (Corrupted)" }
    local list2 = { "Basic Bait", "Kelp Bait", "Good Bait", "Abyssal Bait", "Frozen Bait", "Epic Bait", "Carnivore Bait" }

    _G.SelectedBait = "Basic Bait"
    _G.AutoBuyBait = false
    _G.AutoFishing = false
    _G.AutoOpenSunkenChest = false
    _G.AutoFishingQuest = false
    _G.AutoQuestComplete = false
    _G.FishSlap = false
    _G.AutoSellFish = false
    _G.AutoSkillRod = false

    local list3 = {}

    local function helper(value2, value3)
        Fluent:Notify({ Title = "Axl Hub", Content = value2, Duration = value3 or 4 })
    end

    local function helper2()
        pcall(function()
            if list3.Craft and _G.SelectedBait then
                list3.Craft:InvokeServer("Craft", _G.SelectedBait, 1, {})
            end
        end)
    end

    Tabs.Fish:AddSection("Bait")

    Tabs.Fish:AddDropdown("FishBait", {
        Title = "Select Bait",
        Description = "Bait used by Auto Fishing (the rod in your backpack is used automatically)",
        Values = list2,
        Multi = false,
        Default = 1,
    }):OnChanged(function(value2)
        _G.SelectedBait = value2
        if _G.AutoBuyBait and not farmPaused then
            helper2()
        end
        if list3.EquipBait and not farmPaused then
            task.spawn(list3.EquipBait, false, true)
        end
    end)

    Tabs.Fish:AddSection("Fishing")

    Tabs.Fish:AddToggle("FishAutoBuyBait", {
        Title = "Auto Buy Bait",
        Description = "Crafts the selected bait over and over",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoBuyBait = value2
        if value2 and not farmPaused then
            helper2()
        end
    end)

    Tabs.Fish:AddToggle("FishAutoFishing", {
        Title = "Auto Fishing",
        Description = "Casts the line and catches fish automatically",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoFishing = value2
        if value2 and _G.FishingPosition then
            task.spawn(function()
                local target = _G.FishingPosition
                local startTime = tick()
                _G.FishingTp = true
                while _G.AutoFishing and _G.FishingPosition == target and tick() - startTime < 90 do
                    local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart and (rootPart.Position - target.Position).Magnitude <= 8 then break end
                    _tp(target)
                    task.wait(0.1)
                end
                _G.FishingTp = false
                if not isFarming() then stopFarming() end
            end)
        end
        if not value2 and list3.Request then
            task.spawn(function()
                pcall(function()
                    list3.Request:InvokeServer("Catching", false)
                end)
            end)
        end
    end)

    Tabs.Fish:AddButton({
        Title = "Save Position Fishing",
        Description = "Saves your current position; Auto Fishing will tween you there",
        Callback = function()
            local character = localPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                helper("Could not save the position (character not found)")
                return
            end
            _G.FishingPosition = rootPart.CFrame
            helper("Fishing position saved")
        end
    })

    Tabs.Fish:AddButton({
        Title = "Reset Position Fishing",
        Description = "Clears the saved fishing position",
        Callback = function()
            _G.FishingPosition = nil
            helper("Fishing position reset")
        end
    })

    Tabs.Fish:AddToggle("FishAutoSunkenChest", {
        Title = "Auto Open Sunken Chest",
        Description = "Opens Sunken Chests automatically once caught while fishing",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoOpenSunkenChest = value2
    end)

    Tabs.Fish:AddToggle("FishAutoSlap", {
        Title = "Auto Fish Slap",
        Description = "Completes the Fish Slap minigame automatically",
        Default = false
    }):OnChanged(function(value2)
        _G.FishSlap = value2
    end)

    Tabs.Fish:AddSection("Quests")

    Tabs.Fish:AddToggle("FishAutoQuest", {
        Title = "Auto Quest Fishing",
        Description = "Asks the Angler for a fishing quest",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoFishingQuest = value2
    end)

    Tabs.Fish:AddToggle("FishAutoCompleteQuest", {
        Title = "Auto Complete Quest",
        Description = "Turns in the fishing quest when it is done",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoQuestComplete = value2
        if value2 and not farmPaused then
            pcall(function()
                list3.Jobs:InvokeServer("FishingNPC", "Angler", "CheckQuest")
            end)
        end
    end)

    Tabs.Fish:AddSection("Misc")

    Tabs.Fish:AddToggle("FishAutoSell", {
        Title = "Auto Sell Fish",
        Description = "Sells every fish you catch",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoSellFish = value2
        if value2 and not farmPaused then
            pcall(function()
                list3.Jobs:InvokeServer("FishingNPC", "SellFish")
            end)
        end
    end)

    Tabs.Fish:AddToggle("FishAutoSkillRod", {
        Title = "Auto Skill Rod",
        Description = "Uses the rod skill automatically",
        Default = false
    }):OnChanged(function(value2)
        _G.AutoSkillRod = value2
    end)

    Tabs.Fish:AddButton({
        Title = "Open Fish Index",
        Description = "Opens the fish index window",
        Callback = function()
            pcall(function()
                localPlayer:WaitForChild("PlayerGui"):SetAttribute("FishIndexVisible", true)
            end)
        end
    })

    local amount = 0
    local amount2 = 0
    local amount3 = 0
    local amount4 = 0

    local function helper3(target)
        if table.find(list, target.Name) then return true end
        return string.find(target.Name, "Rod", 1, true) ~= nil
    end

    local function helper4()
        local success, result = pcall(function()
            local playerGui = localPlayer:FindFirstChild("PlayerGui")
            local main = playerGui and playerGui:FindFirstChild("Main")
            local bottomHUDList = main and main:FindFirstChild("BottomHUDList")
            local currentBait = bottomHUDList and bottomHUDList:FindFirstChild("CurrentBait")
            if not currentBait then return nil end
            return tostring(currentBait.Text):match("Selected Bait: (.-) x%d+")
        end)
        if success then return result end
        return nil
    end

    local function helper5(value2)
        local success, result = pcall(function()
            return value.Remotes.CommF_:InvokeServer("getInventory")
        end)
        if not success or typeof(result) ~= "table" then return false end
        for index, item in pairs(result) do
            if typeof(item) == "table" and item.Name then
                local name = item.Name
                if type(name) == "string" and string.find(name, "-") then
                    name = string.split(name, "-")[1]
                end
                if name == value2 then
                    local value2 = item.Count or item.Amount or 0
                    if value2 and value2 > 0 then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function helper6()
        if tick() - amount > 5 then
            amount = tick()
            helper("You don't have " .. tostring(_G.SelectedBait) .. " to use")
        end
    end

    local function helper7(silent, force)
        if not _G.SelectedBait then return end
        if helper4() == _G.SelectedBait then return end
        if not force and tick() - amount2 < 3 then return end
        amount2 = tick()
        if not helper5(_G.SelectedBait) then
            if not silent then helper6() end
            return
        end
        pcall(function()
            value.Remotes.CommF_:InvokeServer("LoadItem", _G.SelectedBait, { "Usables" })
        end)
        task.wait(.5)
        if helper4() ~= _G.SelectedBait and not silent then
            helper6()
        end
    end

    list3.EquipBait = helper7

    task.spawn(function()
        while task.wait(.3) do
            if not farmPaused and not _G.AutoFishing then
                pcall(function()
                    local character = localPlayer.Character
                    local tool = character and character:FindFirstChildOfClass("Tool")
                    if tool and helper3(tool) then
                        helper7(true)
                    end
                end)
            end
        end
    end)

    local function helper4()
        local amount = 0
        local success, result = pcall(function()
            return value.Remotes.CommF_:InvokeServer("getInventory")
        end)
        if not success or type(result) ~= "table" then return 0 end
        for index, item in pairs(result) do
            if type(item) == "table" and item.Type == "Fish" then
                amount = amount + (item.Count or item.Amount or 1)
            end
        end
        return amount
    end

    local function helper5()
        local playerGui = localPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local questGui = playerGui:FindFirstChild("Quest") or playerGui:FindFirstChild("QuestGui")
            if questGui and questGui:FindFirstChild("Container") and questGui.Container:FindFirstChild("QuestTitle") then
                return true
            end
        end
        return false
    end

    task.spawn(function()
        local waitForChild = value:WaitForChild("FishReplicated", 30)
        local net = value:WaitForChild("Modules"):WaitForChild("Net")
        list3.Craft = net:WaitForChild("RF/Craft", 30)
        list3.Jobs = net:WaitForChild("RF/JobsRemoteFunction", 30)
        list3.Abilities = net:WaitForChild("RF/JobToolAbilities", 30)

        local waitForChild2 = waitForChild and waitForChild:WaitForChild("FishingRequest", 30)
        list3.Request = waitForChild2
        local amount = 0
        local current = nil
        local current2 = nil
        pcall(function()
            local waitForChild3 = waitForChild:WaitForChild("FishingClient", 30)
            current = require(waitForChild3:WaitForChild("Config"))
            current2 = require(value:WaitForChild("Util"):WaitForChild("GetWaterHeightAtLocation"))
        end)

        task.spawn(function()
            while task.wait(2) do
                if _G.AutoBuyBait and not farmPaused then
                    helper2()
                end
            end
        end)

        task.spawn(function()
            while task.wait(1.5) do
                if _G.AutoOpenSunkenChest and not farmPaused then
                    pcall(function()
                        local backpack = localPlayer:FindFirstChild("Backpack")
                        local sunkenChest = backpack and backpack:FindFirstChild("Sunken Chest")
                        if not sunkenChest and localPlayer.Character then
                            sunkenChest = localPlayer.Character:FindFirstChild("Sunken Chest")
                        end
                        if sunkenChest then
                            if sunkenChest.Parent == backpack then
                                local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
                                if humanoid then
                                    humanoid:EquipTool(sunkenChest)
                                    task.wait(.5)
                                end
                            end
                            local remoteEvent = sunkenChest:FindFirstChild("RemoteEvent")
                            if remoteEvent then
                                remoteEvent:FireServer("Visual")
                                task.wait(.3)
                                remoteEvent:FireServer("Open")
                            end
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while task.wait(.5) do
                if _G.AutoFishing and not _G.FishingTp and not farmPaused and waitForChild2 and current and current2 then
                    pcall(function()
                        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if not rootPart or not humanoid then return end

                        local tool = character:FindFirstChildOfClass("Tool")

                        if not tool or not helper3(tool) then
                            tool = nil
                            for index, item in ipairs(localPlayer.Backpack:GetChildren()) do
                                if item:IsA("Tool") and helper3(item) then
                                    humanoid:EquipTool(item)
                                    tool = item
                                    break
                                end
                            end
                            if not tool then
                                if tick() - amount3 > 5 then
                                    amount3 = tick()
                                    helper("You don't have any fishing rod in your backpack")
                                end
                                return
                            end
                            task.wait(.3)
                        end

                        helper7()

                        if tool then
                            local maxLaunchDistance = current.Rod.MaxLaunchDistance
                            local v8862506 = current2(rootPart.Position)
                            local position = character.Head.Position
                            local value2 = rootPart.CFrame.LookVector * maxLaunchDistance
                            local list = { character }
                            local characters = Workspace:FindFirstChild("Characters")
                            local enemies = Workspace:FindFirstChild("Enemies")
                            if characters then table.insert(list, characters) end
                            if enemies then table.insert(list, enemies) end
                            local value3, value3 = Workspace:FindPartOnRayWithIgnoreList(Ray.new(position, value2), list)
                            local value2 = value3 and Vector3.new(value3.X, math.max(value3.Y, v8862506), value3.Z)
                            local attribute = tool:GetAttribute("State")
                            local attribute2 = tool:GetAttribute("ServerState")

                            if value2 and (attribute == "ReeledIn" or attribute2 == "ReeledIn") and tick() - amount > 2.5 then
                                amount = tick()
                                waitForChild2:InvokeServer("StartCasting")
                                task.wait()
                                waitForChild2:InvokeServer("CastLineAtLocation", value2, 100, true)
                            elseif attribute2 == "Biting" then
                                waitForChild2:InvokeServer("Catching", true)
                                task.wait(.1)
                                local success, result = pcall(function()
                                    return waitForChild2:InvokeServer("Catch", 1, 1, 1)
                                end)
                                task.wait(.1)
                                pcall(function()
                                    waitForChild2:InvokeServer("Catching", false)
                                end)
                                if success and result ~= false and tick() - amount4 > 3 then
                                    amount4 = tick()
                                    helper("New Fish Caught!", 3)
                                end
                                local amount2 = 0
                                while amount2 < 3 and _G.AutoFishing and tool.Parent and tool:GetAttribute("ServerState") == "Biting" do
                                    task.wait(.1)
                                    amount2 = amount2 + .1
                                end
                                amount = tick() - 1.5
                            end
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while task.wait(1) do
                if _G.AutoFishingQuest and not farmPaused then
                    pcall(function()
                        if not helper5() then
                            list3.Jobs:InvokeServer("FishingNPC", "Angler", "AskQuest")
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while task.wait(5) do
                if _G.AutoQuestComplete and not farmPaused then
                    pcall(function()
                        local f1202498 = helper5()
                        local success, result = pcall(function()
                            return list3.Jobs:InvokeServer("FishingNPC", "Angler", "CheckQuest")
                        end)
                        if success and result ~= false and f1202498 and not helper5() then
                            helper("Fishing Quest Completed!", 5)
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while task.wait(5) do
                if _G.AutoSellFish and not farmPaused then
                    pcall(function()
                        local f1192492 = helper4()
                        list3.Jobs:InvokeServer("FishingNPC", "SellFish")
                        task.wait(.8)
                        local f11924922 = f1192492 - helper4()
                        if f11924922 > 0 then
                            helper(f11924922 .. " fish sold successfully!")
                        end
                    end)
                end
            end
        end)

        task.spawn(function()
            while task.wait(.5) do
                if _G.AutoSkillRod and not farmPaused then
                    pcall(function()
                        list3.Abilities:InvokeServer("Z", true)
                    end)
                end
            end
        end)

        RunService.RenderStepped:Connect(function()
            if not _G.FishSlap or farmPaused then return end
            pcall(function()
                local firstChildOfClass = localPlayer:FindFirstChildOfClass("PlayerGui")
                local fishSlapMinigame = firstChildOfClass:FindFirstChild("FishSlapMinigame")
                if not fishSlapMinigame then return end
                local bar = fishSlapMinigame:FindFirstChild("Bar")
                if not bar then return end
                local greenZone = bar:FindFirstChild("GreenZone")
                local tick2 = bar:FindFirstChild("Tick")
                local slapButton = fishSlapMinigame:FindFirstChild("SlapButton")
                if not greenZone or not tick2 or not slapButton then return end

                local absolutePosition = tick2.AbsolutePosition
                local absoluteSize = tick2.AbsoluteSize
                local absolutePosition2 = greenZone.AbsolutePosition
                local absoluteSize2 = greenZone.AbsoluteSize
                local x = absolutePosition.X < absolutePosition2.X + absoluteSize2.X and absolutePosition2.X < absolutePosition.X + absoluteSize.X
                local y = absolutePosition.Y < absolutePosition2.Y + absoluteSize2.Y and absolutePosition2.Y < absolutePosition.Y + absoluteSize.Y
                if x and y then
                    firesignal(slapButton.Activated)
                end

                local continueScreen = firstChildOfClass:FindFirstChild("ContinueScreen")
                if continueScreen then
                    local continue2 = continueScreen:FindFirstChild("Continue")
                    if continue2 and continue2.Visible then
                        firesignal(continue2.Activated)
                    end
                end
            end)
        end)
    end)
end

do
    local VIM = game:GetService("VirtualInputManager")
    local RunService = game:GetService("RunService")
    local seaRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")

    local seaOk = isSea2 or isSea3
    local seaMode = "skills"
    local seaLock = false
    local seaWantsDragon = false
    local seaBoatName = nil
    local seaLevel = "Lv 1"
    local seaKeys = {}
    local seaSkills = { Melee = {}, Sword = {}, Gun = {}, ["Blox Fruit"] = {} }
    local seaBoat = nil
    local seaArrived = false
    local seaHadBoat = false
    local seaCurrent = nil
    local seaCurrentKey = nil
    local seaRaise = 0
    local seaStuckCount = 0
    local seaStuckUntil = 0
    local seaLastExpected = nil
    local lastClick = 0
    local lastShot = 0
    local SEA_SPEED = 170
    local BOAT_SPEED = 350
    local seaAllIndex = 1
    local levelOrder = { "Lv 1", "Lv 2", "Lv 3", "Lv 4", "Lv 5", "Lv 6", "Lv Infinite" }
    _G.SeaSafeMode = false

    local boatList = {
        "Guardian",
        "PirateGrandBrigade",
        "MarineGrandBrigade",
        "PirateBrigade",
        "MarineBrigade",
        "PirateSloop",
        "MarineSloop",
        "Beast Hunter",
    }

    local labelKeys2 = {
        ["Ships"] = "Ships2",
        ["Sea Beast"] = "SeaBeast",
        ["Shark"] = "Shark",
        ["Piranha"] = "Piranha",
    }
    local labelKeys3 = {
        ["Sea Beast"] = "SeaBeast",
        ["Pirate Brigade"] = "PirateBrigade",
        ["Shark"] = "Shark",
        ["Terror Shark"] = "TerrorShark",
        ["Piranha"] = "Piranha",
        ["Fish Crew"] = "FishCrew",
        ["Haunted Crew"] = "HauntedCrew",
        ["Fish Boat"] = "FishBoat",
    }
    local labelKeys = isSea2 and labelKeys2 or labelKeys3

    local seaTargetDefs = {
        Shark = { kind = "mob", names = { "Shark" } },
        Piranha = { kind = "mob", names = { "Piranha" } },
        TerrorShark = { kind = "mob", names = { "Terrorshark" }, killType = "sea" },
        FishCrew = { kind = "mob", names = { "Fish Crew Member" } },
        HauntedCrew = { kind = "mob", names = { "Haunted Crew Member" } },
        SeaBeast = { kind = "beast" },
        Ships2 = { kind = "ship", names = { "PirateBrigade", "PirateGrandBrigade", "MarineBrigade", "MarineGrandBrigade" } },
        PirateBrigade = { kind = "ship", names = { "PirateBrigade", "PirateGrandBrigade" } },
        FishBoat = { kind = "ship", names = { "FishBoat" } },
    }

    local shipOffsets = {
        PirateBrigade = CFrame.new(0, -30, -10),
        PirateGrandBrigade = CFrame.new(0, -50, -50),
        MarineBrigade = CFrame.new(0, -30, -10),
        MarineGrandBrigade = CFrame.new(0, -50, -50),
        FishBoat = CFrame.new(0, -50, -25),
    }

    local boatNpc2 = CFrame.new(-5327.10791, 4.74625063, -714.39856, 0.428315967, 2.35534596e-08, -0.903629005, -4.71714294e-08, 1, 3.70636966e-09, 0.903629005, 4.10379748e-08, 0.428315967)
    local destination2 = CFrame.new(-9414.80273, -4.3215313, 2379.2959, -0.69609648, 5.83368909e-11, -0.717948258, 2.51885318e-11, 1, 5.6833125e-11, 0.717948258, 2.14772766e-11, -0.69609648)
    local boatNpc3 = CFrame.new(-16927.451, 9.086, 433.864)

    local levelDestinations = {
        ["Lv 1"] = CFrame.new(-21998.375, 30.0006084, -682.309143),
        ["Lv 2"] = CFrame.new(-26779.5215, 30.0005474, -822.858032),
        ["Lv 3"] = CFrame.new(-31171.957, 30.0001011, -2256.93774),
        ["Lv 4"] = CFrame.new(-34054.6875, 30.2187767, -2560.12012),
        ["Lv 5"] = CFrame.new(-38887.5547, 30.0004578, -2162.99023),
        ["Lv 6"] = CFrame.new(-44541.7617, 30.0003204, -1244.8584),
        ["Lv Infinite"] = CFrame.new(-10000000, 31, 37016.25),
    }

    local function seaFarmOn()
        return _G.SeaFarm2 or _G.SeaFarm3
    end

    local function toSet(p)
        local out = {}
        if type(p) == "table" then
            for k, v in pairs(p) do
                if type(k) == "number" then
                    out[v] = true
                elseif v then
                    out[k] = true
                end
            end
        end
        return out
    end

    local function waterLevel()
        local map = Workspace:FindFirstChild("Map")
        local plane = map and map:FindFirstChild("WaterBase-Plane")
        return plane and plane.Position.Y or nil
    end

    local function pressKey(key)
        _G.AxlKeyGuard = (_G.AxlKeyGuard or 0) + 1
        task.delay(0.6, function()
            _G.AxlKeyGuard = math.max((_G.AxlKeyGuard or 1) - 1, 0)
        end)
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode[key], false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        end)
    end

    local function equipTip(tip)
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return nil end
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == tip then return tool end
        for index, item in ipairs(localPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and item.ToolTip == tip then
                humanoid:EquipTool(item)
                task.wait(0.15)
                if item.Parent == character then return item end
                return nil
            end
        end
        return nil
    end

    local function holdDragonstorm()
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return nil end
        local tool = character:FindFirstChild("Dragonstorm")
        if tool then return tool end
        local item = localPlayer.Backpack:FindFirstChild("Dragonstorm")
        if item then
            humanoid:EquipTool(item)
            task.wait(0.1)
            return character:FindFirstChild("Dragonstorm")
        end
        return nil
    end

    local function hasDragonstorm()
        local character = localPlayer.Character
        if (character and character:FindFirstChild("Dragonstorm")) or localPlayer.Backpack:FindFirstChild("Dragonstorm") then
            return true
        end
        pcall(function()
            seaRemote:InvokeServer("LoadItem", "Dragonstorm")
        end)
        task.wait(1)
        character = localPlayer.Character
        return ((character and character:FindFirstChild("Dragonstorm")) or localPlayer.Backpack:FindFirstChild("Dragonstorm")) ~= nil
    end

    local function useSkillSet(kind, aim)
        local keys = seaSkills[kind]
        if not keys then return end
        local order = { "Z", "X", "C", "V", "F" }
        local any = false
        for index, key in ipairs(order) do
            if keys[key] then
                any = true
                break
            end
        end
        if not any then return end
        local tool = equipTip(kind)
        if not tool then return end
        for index, key in ipairs(order) do
            if keys[key] then
                _G.SeaAim = aim
                pressKey(key)
                task.wait(0.05)
            end
        end
        _G.SeaAim = nil
    end

    local function fruitClick()
        equipWeaponType("Fruit")
    end

    local function dragonShot(part)
        local tool = holdDragonstorm()
        local shoot = getgenv().AxlGunShoot
        if not tool or not shoot or not part then return end
        if tick() - lastShot < 0.05 then return end
        lastShot = tick()
        pcall(shoot, tool, part)
    end

    local function engage(kind, part, aim)
        local dragon = seaMode == "dragon" or (seaMode == "combo" and kind == "ship")
        seaWantsDragon = dragon
        if dragon then
            dragonShot(part)
        elseif seaMode == "fruit" or seaMode == "combo" then
            fruitClick()
        elseif kind ~= "mob" then
            useSkillSet("Melee", aim)
            useSkillSet("Sword", aim)
            useSkillSet("Blox Fruit", aim)
            useSkillSet("Gun", aim)
        end
    end

    local function aliveTargets(def)
        local out = {}
        if def.kind == "beast" then
            local folder = Workspace:FindFirstChild("SeaBeasts")
            if folder then
                for index, item in ipairs(folder:GetChildren()) do
                    local health = item:FindFirstChild("Health")
                    if item:FindFirstChild("HumanoidRootPart") and health and health.Value > 0 and (not isSea3 or item.Name == "SeaBeast1") then
                        table.insert(out, item)
                    end
                end
            end
            return out
        end
        local enemies = Workspace:FindFirstChild("Enemies")
        if not enemies then return out end
        for index, item in ipairs(enemies:GetChildren()) do
            if table.find(def.names, item.Name) then
                if def.kind == "ship" then
                    local health = item:FindFirstChild("Health")
                    if item:FindFirstChild("VehicleSeat") and item:FindFirstChild("Engine") and health and health.Value > 0 then
                        table.insert(out, item)
                    end
                else
                    local humanoid = item:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 and item:FindFirstChild("HumanoidRootPart") then
                        table.insert(out, item)
                    end
                end
            end
        end
        return out
    end

    local function hasAlive(key)
        return #aliveTargets(seaTargetDefs[key]) > 0
    end

    local function anyActive()
        for key in pairs(seaKeys) do
            if hasAlive(key) then return true end
        end
        return false
    end

    local function targetAlive(model, def)
        if not model or not model.Parent then return false end
        if def.kind == "mob" then
            local humanoid = model:FindFirstChild("Humanoid")
            return humanoid ~= nil and humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") ~= nil
        end
        local health = model:FindFirstChild("Health")
        if def.kind == "ship" then
            return health ~= nil and health.Value > 0 and model:FindFirstChild("Engine") ~= nil and model:FindFirstChild("VehicleSeat") ~= nil
        end
        return health ~= nil and health.Value > 0 and model:FindFirstChild("HumanoidRootPart") ~= nil
    end

    local function nearestTarget()
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return nil, nil end
        local bestModel, bestKey, bestDistance = nil, nil, 4500
        for key in pairs(seaKeys) do
            local def = seaTargetDefs[key]
            for index, model in ipairs(aliveTargets(def)) do
                local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Engine")
                if part then
                    local distance = (part.Position - rootPart.Position).Magnitude
                    if distance <= bestDistance then
                        bestDistance = distance
                        bestModel = model
                        bestKey = key
                    end
                end
            end
        end
        return bestModel, bestKey
    end

    local TweenService = game:GetService("TweenService")
    local seaHoverCF = nil
    local seaTween = nil
    local seaTweenGoal = nil

    local function setSeaHover(cf)
        seaHoverCF = cf
    end

    RunService.Heartbeat:Connect(function()
        if not seaHoverCF or not seaFarmOn() then
            if seaTween then
                seaTween:Cancel()
                seaTween = nil
            end
            return
        end
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local distance = (rootPart.Position - seaHoverCF.Position).Magnitude
        if distance > 250 and isSea2 then
            if seaTween then
                seaTween:Cancel()
                seaTween = nil
            end
            rootPart.CFrame = seaHoverCF
        elseif distance > 6 then
            local far = distance > 250
            local threshold = far and 30 or 4
            if not seaTween or seaTween.PlaybackState ~= Enum.PlaybackState.Playing or (seaTweenGoal.Position - seaHoverCF.Position).Magnitude > threshold then
                if seaTween then
                    seaTween:Cancel()
                end
                seaTweenGoal = seaHoverCF
                local duration = far and (distance / SEA_SPEED) or math.clamp(distance / 700, 0.08, 0.35)
                seaTween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = seaHoverCF })
                seaTween:Play()
            end
        else
            if seaTween then
                seaTween:Cancel()
                seaTween = nil
            end
            rootPart.CFrame = seaHoverCF
        end
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end)

    local function fightMob(model, def)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root then return end
        seaHoverCF = nil
        if def.killType == "sea" then
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            if humanoid.Health <= 2500 then
                _G.SeaSafeMode = true
            end
            if humanoid.Health >= 8000 then
                _G.SeaSafeMode = false
            end
            local tool = character:FindFirstChildOfClass("Tool")
            if not tool then
                equipWeaponType(_G.SeaWeapon or _G.SelectWeapon)
                return
            end
            local height = 40
            if _G.SeaSafeMode then
                height = 400
            elseif tool.ToolTip == "Blox Fruit" then
                height = 15
            end
            Mob.Kill(model, true, CFrame.new(root.Position + Vector3.new(0, height, 0)))
        else
            Mob.Kill(model, true)
        end
        if seaMode ~= "skills" then
            engage("mob", root, root.Position)
        end
    end

    local function fightBeast(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        local character = localPlayer.Character
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not myRoot then return end
        local level = waterLevel()
        local fixedY = level and (level + 200) or 220
        local target = Vector3.new(root.Position.X, fixedY, root.Position.Z)
        setSeaHover(CFrame.new(target))
        if (myRoot.Position - target).Magnitude <= 15 then
            engage("beast", root, root.Position)
        end
    end

    local function fightShip(model)
        local engine = model:FindFirstChild("Engine")
        local character = localPlayer.Character
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not engine or not myRoot then return end
        local offset = shipOffsets[model.Name] or CFrame.new(0, -30, -10)
        setSeaHover(engine.CFrame * offset)
        if (myRoot.Position - engine.Position).Magnitude <= 150 then
            engage("ship", engine, engine.Position)
        end
    end

    task.spawn(function()
        while task.wait() do
            if seaFarmOn() then
                pcall(function()
                    if seaCurrent and not (seaKeys[seaCurrentKey] and targetAlive(seaCurrent, seaTargetDefs[seaCurrentKey])) then
                        seaCurrent = nil
                    end
                    if not seaCurrent then
                        seaCurrent, seaCurrentKey = nearestTarget()
                    end
                    if not seaCurrent then
                        seaWantsDragon = false
                        seaHoverCF = nil
                        _G.SeaWeapon = nil
                        _G.SeaAim = nil
                        return
                    end
                    local def = seaTargetDefs[seaCurrentKey]
                    if seaMode == "fruit" or (seaMode == "combo" and def.kind ~= "ship") then
                        _G.SeaWeapon = "Fruit"
                    else
                        _G.SeaWeapon = nil
                    end
                    local character = localPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Sit then
                        humanoid.Sit = false
                        task.wait(0.1)
                    end
                    if def.kind == "mob" then
                        fightMob(seaCurrent, def)
                    elseif def.kind == "beast" then
                        fightBeast(seaCurrent)
                    else
                        fightShip(seaCurrent)
                    end
                end)
            else
                seaCurrent = nil
                seaHoverCF = nil
                _G.SeaWeapon = nil
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.2) do
            local miscValue = Options.UseDragonstorm and Options.UseDragonstorm.Value or false
            _G.UseDragonstorm = (seaFarmOn() and seaWantsDragon) or miscValue
        end
    end)

    local function snapshotBoats()
        local snapshot = {}
        local boats = Workspace:FindFirstChild("Boats")
        if boats then
            for index, boat in ipairs(boats:GetChildren()) do
                snapshot[boat] = true
            end
        end
        return snapshot
    end

    local function findNewBoat(snapshot)
        local boats = Workspace:FindFirstChild("Boats")
        if not boats then return nil end
        for index, boat in ipairs(boats:GetChildren()) do
            if not snapshot[boat] and boat:FindFirstChild("VehicleSeat", true) then
                return boat
            end
        end
        return nil
    end

    local function buyBoat()
        local snapshot = snapshotBoats()
        seaRemote:InvokeServer("BuyBoat", seaBoatName)
        local newBoat = nil
        local attempts = 0
        repeat
            task.wait(0.5)
            newBoat = findNewBoat(snapshot)
            attempts = attempts + 1
        until newBoat or attempts >= 10
        if newBoat then
            seaBoat = newBoat
        end
    end

    local function ownBoat()
        local boats = Workspace:FindFirstChild("Boats")
        if boats then
            for index, boat in ipairs(boats:GetChildren()) do
                local owner = boat:FindFirstChild("Owner")
                if owner and tostring(owner.Value) == localPlayer.Name then
                    return boat
                end
            end
        end
        if seaBoat and seaBoat.Parent then return seaBoat end
        return nil
    end

    local function zeroSeat(seat)
        seat.AssemblyLinearVelocity = Vector3.zero
        seat.AssemblyAngularVelocity = Vector3.zero
    end

    local function stepBoat(boat, targetPosition, speed, dt)
        local pivot = boat:GetPivot()
        local delta = targetPosition - pivot.Position
        local distance = delta.Magnitude
        if distance < 1 then return true end
        local move = math.min(distance, speed * dt)
        local position = pivot.Position + delta.Unit * move
        local flat = Vector3.new(delta.X, 0, delta.Z)
        if flat.Magnitude > 0.1 then
            boat:PivotTo(CFrame.lookAt(position, position + flat.Unit) * CFrame.Angles(0, math.rad(-90), 0))
        else
            boat:PivotTo(CFrame.new(position) * pivot.Rotation)
        end
        return false
    end

    local function sea2Step(dt)
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then return end
        if anyActive() then return end

        if seaBoat and not seaBoat.Parent then
            seaBoat = nil
            seaArrived = false
        end

        if seaArrived then
            local seat = seaBoat and seaBoat:FindFirstChild("VehicleSeat", true)
            if not seat then
                seaBoat = nil
                seaArrived = false
                return
            end
            if not humanoid.Sit then
                _tp(seat.CFrame * CFrame.new(0, 1, 0))
            else
                local pivot = seaBoat:GetPivot()
                seaBoat:PivotTo(CFrame.new(destination2.X, pivot.Y, destination2.Z) * pivot.Rotation)
                zeroSeat(seat)
            end
            return
        end

        if not seaBoat then
            if not seaBoatName then return end
            if (boatNpc2.Position - rootPart.Position).Magnitude > 15 then
                _tp(boatNpc2)
            else
                buyBoat()
            end
            return
        end

        local seat = seaBoat:FindFirstChild("VehicleSeat", true)
        if not seat then
            seaBoat = nil
            return
        end
        if not humanoid.Sit then
            _tp(seat.CFrame * CFrame.new(0, 1, 0))
            return
        end
        local pivot = seaBoat:GetPivot()
        local reached = stepBoat(seaBoat, Vector3.new(destination2.X, pivot.Y, destination2.Z), BOAT_SPEED, dt)
        zeroSeat(seat)
        local flat = (Vector3.new(destination2.X, 0, destination2.Z) - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude
        if reached or flat <= 15 then
            seaArrived = true
        end
    end

    local function sea3Step(dt)
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then
            seaHadBoat = false
            return
        end

        local boat = ownBoat()
        local seat = boat and boat:FindFirstChild("VehicleSeat", true)
        if seat then
            if (rootPart.Position - seat.Position).Magnitude > 2500 then
                boat = nil
                seat = nil
            else
                seaHadBoat = true
            end
        else
            boat = nil
        end

        if anyActive() then
            seaLastExpected = nil
            seaStuckCount = 0
            return
        end

        if not boat then
            if _G.ResetWhenBoatBreaks and seaHadBoat then
                humanoid.Health = 0
                seaHadBoat = false
                task.wait(2)
            elseif not seaBoatName then
                return
            elseif (boatNpc3.Position - rootPart.Position).Magnitude > 15 then
                _tp(boatNpc3)
            else
                buyBoat()
                task.wait(1)
            end
            return
        end

        if not humanoid.Sit then
            local seatCFrame = seat.CFrame * CFrame.new(0, 1, 0)
            if (rootPart.Position - seat.Position).Magnitude <= 30 then
                rootPart.CFrame = seatCFrame
                task.wait(0.1)
            else
                _tp(seatCFrame)
            end
            return
        end

        local levelName = seaLevel
        if seaLevel == "All Levels" then
            levelName = levelOrder[seaAllIndex]
        end
        local destination = levelDestinations[levelName] or levelDestinations["Lv 1"]
        local danger = (not seaKeys.FishBoat and hasAlive("FishBoat")) or (not seaKeys.PirateBrigade and hasAlive("PirateBrigade")) or (not seaKeys.TerrorShark and hasAlive("TerrorShark"))
        local pivot = boat:GetPivot()
        if seaLastExpected then
            local drift = Vector3.new(pivot.X - seaLastExpected.X, 0, pivot.Z - seaLastExpected.Z).Magnitude
            if drift > 6 then
                seaStuckCount = seaStuckCount + 1
            else
                seaStuckCount = math.max(seaStuckCount - 1, 0)
            end
            if seaStuckCount >= 6 then
                seaStuckUntil = tick() + 2.5
                seaStuckCount = 0
            end
        end
        seaRaise = (danger and 150 or 0) + (tick() < seaStuckUntil and 200 or 0)
        local flat = (Vector3.new(destination.X, 0, destination.Z) - Vector3.new(pivot.X, 0, pivot.Z)).Magnitude
        if flat > 150 then
            stepBoat(boat, Vector3.new(destination.X, pivot.Y, destination.Z), BOAT_SPEED, dt)
            seaLastExpected = boat:GetPivot().Position
            zeroSeat(seat)
        elseif seaLevel == "All Levels" and seaAllIndex < #levelOrder then
            seaLastExpected = nil
            seaAllIndex = seaAllIndex + 1
        else
            seaLastExpected = nil
        end
    end

    local lastStep = tick()
    task.spawn(function()
        while true do
            local now = tick()
            local dt = math.min(now - lastStep, 0.1)
            lastStep = now
            if _G.SeaFarm2 then
                pcall(sea2Step, dt)
            elseif _G.SeaFarm3 then
                pcall(sea3Step, dt)
            end
            task.wait()
        end
    end)

    localPlayer.CharacterAdded:Connect(function()
        seaArrived = false
        seaHadBoat = false
    end)

    local seaFixedY = nil
    RunService.Heartbeat:Connect(function()
        if not isSea3 then return end
        if not (_G.SeaFarm3 or _G.SpinBoatState) then
            seaFixedY = nil
            return
        end
        if _G.SpinBoatState and anyActive() then return end
        pcall(function()
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid or not humanoid.Sit then
                seaFixedY = nil
                return
            end
            local boats = Workspace:FindFirstChild("Boats")
            if not boats then return end
            for index, boat in ipairs(boats:GetChildren()) do
                local seat = boat:FindFirstChildWhichIsA("VehicleSeat")
                if seat and seat.Occupant == humanoid then
                    if not seaFixedY then
                        seaFixedY = (waterLevel() or seat.Position.Y) + 175
                    end
                    local cf = seat.CFrame
                    seat.CFrame = CFrame.new(cf.X, seaFixedY + seaRaise, cf.Z) * cf.Rotation
                    seat.AssemblyLinearVelocity = Vector3.new(seat.AssemblyLinearVelocity.X, 0, seat.AssemblyLinearVelocity.Z)
                    seat.AssemblyAngularVelocity = Vector3.new(0, seat.AssemblyAngularVelocity.Y, 0)
                end
            end
        end)
    end)

    local noclipWas = false
    task.spawn(function()
        while task.wait(0.5) do
            if seaOk then
                local active = _G.SeaFarm2 or _G.SeaFarm3 or _G.SpinBoatState
                if active or noclipWas then
                    pcall(function()
                        local boats = Workspace:FindFirstChild("Boats")
                        if not boats then return end
                        for index, boat in ipairs(boats:GetChildren()) do
                            for index2, part in ipairs(boat:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = not active
                                end
                            end
                        end
                    end)
                    noclipWas = active and true or false
                end
            end
        end
    end)

    local spinBoat = nil
    local spinParts = {}
    local spinPivot = nil
    local spinCenter = nil
    local spinAngle = 0
    local spinY = 0
    local spinMaxY = 0
    local spinActive = false

    local function nearestBoat()
        local boats = Workspace:FindFirstChild("Boats")
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not boats or not rootPart then return nil end
        local best, bestDistance = nil, math.huge
        for index, boat in ipairs(boats:GetChildren()) do
            local part = boat.PrimaryPart or boat:FindFirstChildWhichIsA("BasePart")
            if part then
                local distance = (part.Position - rootPart.Position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    best = boat
                end
            end
        end
        return best
    end

    local function restoreSpin()
        if spinBoat and spinBoat.Parent and spinPivot then
            pcall(function()
                for part, state in pairs(spinParts) do
                    if part and part.Parent then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                        part.Anchored = state.Anchored
                        part.CanCollide = state.CanCollide
                    end
                end
                local level = waterLevel()
                local base = level and (level + 15) or 20
                local y = math.max(spinPivot.Y + 5, base)
                spinBoat:PivotTo(CFrame.new(spinPivot.X, y, spinPivot.Z) * spinPivot.Rotation)
            end)
        end
        spinParts = {}
        spinPivot = nil
        spinBoat = nil
        spinCenter = nil
    end

    RunService.Heartbeat:Connect(function(dt)
        if not seaOk then return end
        if _G.SpinBoatState and anyActive() then
            if not spinActive then
                local boat = nearestBoat()
                if boat then
                    spinBoat = boat
                    spinParts = {}
                    spinPivot = boat:GetPivot()
                    for index, part in ipairs(boat:GetDescendants()) do
                        if part:IsA("BasePart") then
                            spinParts[part] = { Anchored = part.Anchored, CanCollide = part.CanCollide }
                        end
                    end
                    spinCenter = spinPivot.Position
                    spinY = spinCenter.Y
                    spinMaxY = spinCenter.Y + 450
                    for part in pairs(spinParts) do
                        part.Anchored = true
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                    spinActive = true
                end
            end
            if spinActive and spinBoat and spinBoat.Parent and spinCenter then
                spinY = math.min(spinY + 250 * dt, spinMaxY)
                spinAngle = spinAngle + (_G.SpinBoatSpeed or 2.8) * dt
                local position = Vector3.new(spinCenter.X + math.cos(spinAngle) * 120, spinY, spinCenter.Z + math.sin(spinAngle) * 120)
                local look = Vector3.new(spinCenter.X, spinY, spinCenter.Z)
                pcall(function()
                    spinBoat:PivotTo(CFrame.new(position, look))
                    local character = localPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if humanoid and rootPart and humanoid.Sit then
                        local seat = spinBoat:FindFirstChildWhichIsA("VehicleSeat")
                        if seat then
                            rootPart.CFrame = seat.CFrame * CFrame.new(0, 1, 0)
                        end
                    end
                end)
            end
        elseif spinActive then
            spinActive = false
            restoreSpin()
        end
    end)

    local modeToggles = {
        SeaUseM1Fruit = "fruit",
        SeaUseDragonstorm = "dragon",
        SeaDragonCombo = "combo",
    }

    local function setMode(optionId, enabled)
        if seaLock then return end
        local mode = modeToggles[optionId]
        if enabled then
            if mode == "dragon" or mode == "combo" then
                if not hasDragonstorm() then
                    Fluent:Notify({ Title = "Axl Hub", Content = "You don't have Dragonstorm", Duration = 5 })
                    seaLock = true
                    pcall(function() Options[optionId]:SetValue(false) end)
                    seaLock = false
                    return
                end
            end
            seaMode = mode
            seaLock = true
            for id in pairs(modeToggles) do
                if id ~= optionId then
                    pcall(function() Options[id]:SetValue(false) end)
                end
            end
            seaLock = false
        elseif seaMode == mode then
            seaMode = "skills"
        end
    end

    local seaMessage = "Sea Events only work in Sea 2 and Sea 3"

    local function addCombat()
        Tabs.Sea:AddSection("Combat Settings")

        Tabs.Sea:AddToggle("SeaUseM1Fruit", {
            Title = "Use M1 Fruit For Sea Event",
            Description = "Attacks every sea event with the fruit click",
            Default = false
        }):OnChanged(guardToggle("SeaUseM1Fruit", seaOk, seaMessage, function(value2)
            task.spawn(setMode, "SeaUseM1Fruit", value2)
        end))

        Tabs.Sea:AddToggle("SeaUseDragonstorm", {
            Title = "Use Dragonstorm For Sea Event",
            Description = "Attacks every sea event with the Dragonstorm",
            Default = false
        }):OnChanged(guardToggle("SeaUseDragonstorm", seaOk, seaMessage, function(value2)
            task.spawn(setMode, "SeaUseDragonstorm", value2)
        end))

        Tabs.Sea:AddToggle("SeaDragonCombo", {
            Title = "Dragonstorm On Boats, Fruit M1 On Others",
            Description = "Uses the Dragonstorm against boats and the fruit click against every other sea event",
            Default = false
        }):OnChanged(guardToggle("SeaDragonCombo", seaOk, seaMessage, function(value2)
            task.spawn(setMode, "SeaDragonCombo", value2)
        end))
    end

    local function addSkills()
        Tabs.Sea:AddSection("Configure Skills for Sea Events")

        Tabs.Sea:AddDropdown("SeaMeleeSkills", {
            Title = "Melee Skills",
            Values = { "Z", "X", "C" },
            Multi = true,
            Default = { "Z", "X", "C" },
        }):OnChanged(function(p)
            seaSkills.Melee = toSet(p)
        end)

        Tabs.Sea:AddDropdown("SeaSwordSkills", {
            Title = "Sword Skills",
            Values = { "Z", "X" },
            Multi = true,
            Default = { "Z", "X" },
        }):OnChanged(function(p)
            seaSkills.Sword = toSet(p)
        end)

        Tabs.Sea:AddDropdown("SeaGunSkills", {
            Title = "Gun Skills",
            Values = { "Z", "X" },
            Multi = true,
            Default = { "Z", "X" },
        }):OnChanged(function(p)
            seaSkills.Gun = toSet(p)
        end)

        Tabs.Sea:AddDropdown("SeaFruitSkills", {
            Title = "Blox Fruit Skills",
            Values = { "Z", "X", "C", "V", "F" },
            Multi = true,
            Default = { "Z", "X", "C" },
        }):OnChanged(function(p)
            seaSkills["Blox Fruit"] = toSet(p)
        end)
    end

    local function addEventsDropdown(values)
        Tabs.Sea:AddDropdown("SeaEvents", {
            Title = "Select Sea Events",
            Values = values,
            Multi = true,
            Default = {},
        }):OnChanged(function(p)
            seaKeys = {}
            for label in pairs(toSet(p)) do
                local key = labelKeys[label]
                if key then
                    seaKeys[key] = true
                end
            end
        end)
    end

    local function addStartToggle()
        Tabs.Sea:AddToggle("SeaStartFarm", {
            Title = "Start Farm",
            Description = "Buys a boat, sails and farms the selected sea events",
            Default = false
        }):OnChanged(guardToggle("SeaStartFarm", seaOk, seaMessage, function(value2)
            if value2 and not seaBoatName then
                Fluent:Notify({ Title = "Axl Hub", Content = "Please select a boat", Duration = 5 })
                task.defer(function()
                    pcall(function() Options.SeaStartFarm:SetValue(false) end)
                end)
                return
            end
            seaAllIndex = 1
            _G.SeaFarm2 = (isSea2 and value2) and true or false
            _G.SeaFarm3 = (isSea3 and value2) and true or false
            if not value2 then
                seaWantsDragon = false
                seaCurrent = nil
                _G.SeaAim = nil
                if not isFarming() then stopFarming() end
            end
        end))
    end

    local function addSpin()
        Tabs.Sea:AddSection("Spin Boat Settings")

        Tabs.Sea:AddToggle("SpinBoatState", {
            Title = "Spin Boat",
            Description = "Lifts and spins the boat while sea events are active",
            Default = false
        }):OnChanged(guardToggle("SpinBoatState", seaOk, seaMessage, function(value2)
            _G.SpinBoatState = value2
        end))

        Tabs.Sea:AddSlider("SpinBoatSpeed", {
            Title = "Speed Spin Boat",
            Min = 1,
            Max = 20,
            Default = 2.8,
            Rounding = 1,
            Callback = function(value2)
                _G.SpinBoatSpeed = tonumber(value2) or 2.8
            end
        })
    end

    if isSea2 then
        Tabs.Sea:AddSection("Sea 2 Events")

        Tabs.Sea:AddDropdown("SeaBoat", {
            Title = "Select Boat",
            Values = boatList,
            Multi = false,
        }):OnChanged(function(value2)
            seaBoatName = value2
        end)

        addEventsDropdown({ "Ships", "Sea Beast", "Shark", "Piranha" })
        addStartToggle()
        addCombat()
        addSkills()
        addSpin()
    else
        Tabs.Sea:AddSection(isSea3 and "Sea 3 Events" or "Only Sea 2 And 3")

        Tabs.Sea:AddDropdown("SeaBoat", {
            Title = "Select Boat",
            Values = boatList,
            Multi = false,
        }):OnChanged(function(value2)
            seaBoatName = value2
        end)

        Tabs.Sea:AddDropdown("SeaLevel", {
            Title = "Select Level Sea",
            Values = { "Lv 1", "Lv 2", "Lv 3", "Lv 4", "Lv 5", "Lv 6", "Lv Infinite", "All Levels" },
            Multi = false,
            Default = 1,
        }):OnChanged(function(value2)
            seaLevel = value2
            seaAllIndex = 1
        end)

        addEventsDropdown({ "Sea Beast", "Pirate Brigade", "Shark", "Terror Shark", "Piranha", "Fish Crew", "Haunted Crew", "Fish Boat" })
        addStartToggle()

        Tabs.Sea:AddToggle("SeaResetBoat", {
            Title = "Reset If Boat Breaks",
            Description = "Resets your character when your boat is destroyed",
            Default = false
        }):OnChanged(function(value2)
            _G.ResetWhenBoatBreaks = value2
        end)

        addCombat()
        addSkills()

        addSpin()
    end
end


SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "ServerJobId" })

local text = "FarmHub/" .. tostring(Players.LocalPlayer.UserId)
InterfaceManager:SetFolder("FarmHub")
SaveManager:SetFolder(text .. "/Config")

do
    Tabs.Misc:AddSection("Statistics Point")

    local list = {
        Melee = "Melee",
        Defense = "Defense",
        Sword = "Sword",
        Gun = "Gun",
        Fruit = "Demon Fruit",
    }
    local text = "Melee"
    local amount = 1
    local flag = false

    Tabs.Misc:AddDropdown("SelectStat", {
        Title = "Select Stat",
        Description = "Choose the stat to upgrade",
        Values = { "Melee", "Defense", "Sword", "Gun", "Fruit" },
        Multi = false,
        Default = 1,
    }):OnChanged(function(value2)
        text = value2
    end)

    Tabs.Misc:AddSlider("PointsAmount", {
        Title = "Points Amount",
        Description = "How many points to add each time",
        Default = 1,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = function(value2)
            amount = math.floor(tonumber(value2) or 1)
        end
    })

    Tabs.Misc:AddToggle("AutoAddPoints", {
        Title = "Auto Add Points",
        Description = "Automatically adds your points to the selected stat",
        Default = false
    }):OnChanged(function(value2)
        flag = value2
    end)

    task.spawn(function()
        while task.wait(0.25) do
            if flag then
                pcall(function()
                    local value2 = localPlayer.Data.Points.Value
                    local value3 = list[text]
                    if value2 > 0 and value3 then
                        value.Remotes.CommF_:InvokeServer("AddPoint", value3, math.min(amount, value2))
                    end
                end)
            end
        end
    end)
end

do
    Tabs.Misc:AddSection("Others")

    Tabs.Misc:AddButton({
        Title = "Redeem All Codes",
        Description = "Redeems every available code",
        Callback = function()
            local list = {
                "KITT_RESET",
                "Sub2UncleKizaru",
                "SUB2GAMERROBOT_RESET1",
                "Sub2Fer999",
                "Enyu_is_Pro",
                "JCWK",
                "StarcodeHEO",
                "MagicBus",
                "KittGaming",
                "Sub2CaptainMaui",
                "Sub2OfficalNoobie",
                "TheGreatAce",
                "Sub2NoobMaster123",
                "Sub2Daigrock",
                "Axiore",
                "StrawHatMaine",
                "TantaiGaming",
                "Bluxxy",
                "SUB2GAMERROBOT_EXP1",
                "Chandler",
                "NOMOREHACK",
                "BANEXPLOIT",
                "WildDares",
                "BossBuild",
                "GetPranked",
                "EARN_FRUITS",
                "FIGHT4FRUIT",
                "NOEXPLOITER",
                "NOOB2ADMIN",
                "CODESLIDE",
                "ADMINHACKED",
                "ADMINDARES",
                "fruitconcepts",
                "krazydares",
                "TRIPLEABUSE",
                "SEATROLLING",
                "24NOADMIN",
                "REWARDFUN",
                "NEWTROLL",
                "fudd10_v2",
                "Fudd10",
                "Bignews",
                "SECRET_ADMIN"
            }
            for index, item in ipairs(list) do
                pcall(function()
                    value.Remotes.Redeem:InvokeServer(item)
                end)
            end
        end
    })

    Tabs.Misc:AddButton({
        Title = "No Fog",
        Description = "Removes the fog and sky effects",
        Callback = function()
            local Lighting = game:GetService("Lighting")
            if Lighting:FindFirstChild("LightingLayers") then
                Lighting.LightingLayers:Destroy()
            end
            if Lighting:FindFirstChild("SeaTerrorCC") then
                Lighting.SeaTerrorCC:Destroy()
            end
            if Lighting:FindFirstChild("FantasySky") then
                Lighting.FantasySky:Destroy()
            end
        end
    })

    Tabs.Misc:AddButton({
        Title = "Set Pirate Team",
        Description = "Switches your team to Pirates",
        Callback = function()
            pcall(function()
                value.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
            end)
        end
    })

    Tabs.Misc:AddButton({
        Title = "Set Marine Team",
        Description = "Switches your team to Marines",
        Callback = function()
            pcall(function()
                value.Remotes.CommF_:InvokeServer("SetTeam", "Marines")
            end)
        end
    })
end

InterfaceManager:BuildInterfaceSection(Tabs.Misc)
SaveManager:BuildConfigSection(Tabs.Misc)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Axl Hub",
    Content = "Loading config...",
    Duration = 4
})

task.spawn(function()

do
    local GLOBAL_G, GLOBAL_GENV = 1, 2
    local function flag(kind, name)
        return { kind = kind, name = name, key = kind .. ":" .. name }
    end
    local function envOf(spec)
        return spec.kind == GLOBAL_GENV and getgenv() or _G
    end

    local function hasTool(name)
        local character = localPlayer.Character
        return localPlayer.Backpack:FindFirstChild(name) ~= nil or (character ~= nil and character:FindFirstChild(name) ~= nil)
    end
    local function aliveEnemy(name)
        return findEnemyByName(name) ~= nil
    end

    local castleMobs = {
        "Galley Pirate", "Galley Captain", "Raider", "Mercenary", "Vampire", "Zombie",
        "Snow Trooper", "Winter Warrior", "Lab Subordinate", "Horned Warrior", "Magma Ninja", "Lava Pirate",
        "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer", "Arctic Warrior", "Snow Lurker",
        "Sea Soldier", "Water Fighter",
    }

    local tasks = {
        { name = "Berry", kind = "trigger", limit = 45, flags = { flag(GLOBAL_G, "AutoBerry") },
            busy = function() return _G.AxlBerryHasWork ~= nil and _G.AxlBerryHasWork() end },
        { name = "Elite Hunter", kind = "trigger", flags = { flag(GLOBAL_G, "FarmEliteHunt") },
            busy = function() return aliveEnemy("Diablo") or aliveEnemy("Deandre") or aliveEnemy("Urban") end },
        { name = "Fruit", kind = "trigger", limit = 45, flags = { flag(GLOBAL_G, "AutoCollectFruit") },
            busy = function()
                for index, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Tool") and (item.ToolTip == "Blox Fruit" or item.Name:find("Fruit")) then
                        if item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart") then return true end
                    end
                end
                return false
            end },
        { name = "Factory", kind = "camp", flags = { flag(GLOBAL_G, "AutoFactory") },
            busy = function() return aliveEnemy("Core") end },
        { name = "Raid Pirate", kind = "trigger", flags = { flag(GLOBAL_G, "AutoRaidCastle") },
            busy = function()
                for index, item in ipairs(value:GetChildren()) do
                    if table.find(castleMobs, item.Name) then return true end
                end
                local rootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                local enemies = Workspace:FindFirstChild("Enemies")
                if rootPart and enemies and (Vector3.new(-5539.31, 313.8, -2972.37) - rootPart.Position).Magnitude <= 500 then
                    for index, item in ipairs(enemies:GetChildren()) do
                        if Mob.Alive(item) then return true end
                    end
                end
                return false
            end },
        { name = "Rip Indra", kind = "camp", flags = { flag(GLOBAL_G, "AutoRipIndra") },
            busy = function() return aliveEnemy("rip_indra True Form") or hasTool("God's Chalice") end },
        { name = "Darkbeard", kind = "camp", flags = { flag(GLOBAL_G, "AutoDarkbeard") },
            busy = function() return aliveEnemy("Darkbeard") or hasTool("Fist of Darkness") end },
        { name = "Cursed Captain", kind = "camp", flags = { flag(GLOBAL_G, "AutoCursedCaptain") },
            busy = function() return aliveEnemy("Cursed Captain") end },
        { name = "Soul Reaper", kind = "camp", flags = { flag(GLOBAL_G, "AutoHytHallow") },
            busy = function() return aliveEnemy("Soul Reaper") or hasTool("Hallow Essence") end },
    }

    local order = { "Rip Indra", "Soul Reaper", "Darkbeard", "Cursed Captain", "Raid Pirate", "Factory", "Elite Hunter", "Fruit", "Berry" }
    local rank = {}
    for index, name in ipairs(order) do rank[name] = index end
    table.sort(tasks, function(first, second) return rank[first.name] < rank[second.name] end)

    local eliteKey = flag(GLOBAL_G, "FarmEliteHunt").key

    local baseFlags = {
        flag(GLOBAL_G, "StartFarm"), flag(GLOBAL_GENV, "AutoMaterial"), flag(GLOBAL_G, "AutoRaid"),
        flag(GLOBAL_G, "AutoBoss"), flag(GLOBAL_G, "FarmAllBoss"), flag(GLOBAL_G, "AutoMasterySwords"),
        flag(GLOBAL_G, "FarmMastery_Dev"), flag(GLOBAL_G, "FarmMastery_G"),
        flag(GLOBAL_G, "AutoLawKak"),
        flag(GLOBAL_G, "Tp_MasterA"), flag(GLOBAL_G, "AutoTtk"), flag(GLOBAL_G, "AutoFarmChest"),
    }

    local allSpecs = {}
    for index, spec in ipairs(baseFlags) do allSpecs[#allSpecs + 1] = spec end
    for index, task2 in ipairs(tasks) do
        for index2, spec in ipairs(task2.flags) do allSpecs[#allSpecs + 1] = spec end
    end

    local saved = {}
    local blacklist = {}
    local holderName, holderSince = nil, 0

    local function isWanted(spec)
        local current = envOf(spec)[spec.name]
        if current ~= nil then
            saved[spec.key] = nil
            return current and true or false
        end
        return saved[spec.key] ~= nil
    end

    local function taskWanted(task2)
        local wanted = false
        for index, spec in ipairs(task2.flags) do
            if isWanted(spec) then wanted = true end
        end
        return wanted
    end

    local function suspend(spec)
        local env = envOf(spec)
        if env[spec.name] then
            saved[spec.key] = env[spec.name]
            env[spec.name] = nil
        end
    end

    local function restore(spec)
        if saved[spec.key] ~= nil then
            local env = envOf(spec)
            if env[spec.name] == nil then env[spec.name] = saved[spec.key] end
            saved[spec.key] = nil
        end
    end

    local function apply(runSet)
        for index, spec in ipairs(allSpecs) do
            if runSet == true or runSet[spec.key] then
                restore(spec)
            else
                suspend(spec)
            end
        end
    end

    local function safeBusy(task2)
        local success, result = pcall(task2.busy)
        return success and result and true or false
    end

    while true do
        task.wait(0.25)
        pcall(function()
            if farmPaused or localPlayer:GetAttribute("IslandRaiding") then
                holderName = nil
                apply(true)
                return
            end

            local exclusive = nil
            if _G.AutoTushita and _G.AxlTushitaDoing then
                exclusive = {}
            elseif _G.AutoYama then
                if _G.AxlYamaState == "katana" then
                    exclusive = {}
                elseif _G.AxlYamaState == "elite" then
                    exclusive = { [eliteKey] = true }
                end
            end
            if exclusive then
                holderName = nil
                apply(exclusive)
                return
            end

            local holder = nil
            for index, task2 in ipairs(tasks) do
                local blocked = blacklist[task2.name] and tick() < blacklist[task2.name]
                if not blocked and taskWanted(task2) and safeBusy(task2) then
                    holder = task2
                    break
                end
            end

            local runSet = {}
            if holder then
                if holderName ~= holder.name then
                    holderName = holder.name
                    holderSince = tick()
                end

                if holder.limit and tick() - holderSince > holder.limit then
                    blacklist[holder.name] = tick() + 60
                    holderName = nil
                end
                for index, spec in ipairs(holder.flags) do runSet[spec.key] = true end
            else
                holderName = nil
                local baseActive = false
                for index, spec in ipairs(baseFlags) do
                    runSet[spec.key] = true
                    if isWanted(spec) then baseActive = true end
                end
                local campChosen = false
                for index, task2 in ipairs(tasks) do
                    local blocked = blacklist[task2.name] and tick() < blacklist[task2.name]
                    if not blocked then
                        if task2.kind == "trigger" then
                            for index2, spec in ipairs(task2.flags) do runSet[spec.key] = true end
                        elseif not baseActive and not campChosen and taskWanted(task2) then

                            campChosen = true
                            for index2, spec in ipairs(task2.flags) do runSet[spec.key] = true end
                        end
                    end
                end
            end
            apply(runSet)
        end)
    end
end

end)

task.spawn(function()
    pcall(function()
        SaveManager:Load("AutoSave")
    end)
    pcall(function()
        SaveManager:LoadAutoloadConfig()
    end)

    task.wait(0.5)
    pcall(function() TweenControl.CancelCurrent() end)
    farmPaused = false
    pcall(syncFarmMode)
    pcall(function()
        if _G.AxlRefreshBoss then _G.AxlRefreshBoss() end
    end)

    Fluent:Notify({
        Title = "Axl Hub",
        Content = "Interface loaded successfully.",
        Duration = 5
    })

    while task.wait(60) do
        pcall(function()
            SaveManager:Save("AutoSave")
        end)
    end
end)
