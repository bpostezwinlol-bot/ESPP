local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

------------------------------------------------------------------------
-- РќРђРЎРўР РћР™РљР
------------------------------------------------------------------------
local CYBER_COLORS = {
    Cyan     = Color3.fromRGB(0, 240, 255),
    DarkBg   = Color3.fromRGB(15, 15, 20),
    Visible  = Color3.fromRGB(0, 255, 0),   -- Р—РµР»РµРЅС‹Р№ (РІРёРґРЅРѕ)
    Hidden   = Color3.fromRGB(255, 0, 0),   -- РљСЂР°СЃРЅС‹Р№ (Р·Р° СЃС‚РµРЅРѕР№)
    Default  = Color3.fromRGB(255, 255, 255),
    SelfDot  = Color3.fromRGB(0, 100, 255),
}

local settings_tbl = {
    ESP_Enabled = true,
    Box_Enabled = true,   -- РћС‚РґРµР»СЊРЅС‹Р№ С‚СѓРјР±Р»РµСЂ РґР»СЏ Р±РѕРєСЃРѕРІ
    TeamCheck = false,
    Skeleton = true,
    ViewAngle = true,  -- Р›РёРЅРёСЏ РЅР°РїСЂР°РІР»РµРЅРёСЏ РІР·РіР»СЏРґР°
    Tracers = true,
    Radar = true,
    WallColor_Enabled = true,
    Max_Distance = 1500,
}

local BOX_SCALE = 1.10

if CoreGui:FindFirstChild("UniversalEspGui") then
    CoreGui.UniversalEspGui:Destroy()
end

local espCache = {}

local function createDrawing(className, properties)
    local obj = Drawing.new(className)
    for k, v in pairs(properties) do
        obj[k] = v
    end
    return obj
end

-- Р РђР”РђР  
local radarRadius = 90
local radarBackground = Drawing.new("Circle")
radarBackground.Visible = false
radarBackground.Radius = radarRadius
radarBackground.Color = Color3.fromRGB(0, 0, 0)
radarBackground.Transparency = 0.6
radarBackground.Filled = true

local radarSelfDot = Drawing.new("Circle")
radarSelfDot.Visible = false
radarSelfDot.Radius = 4
radarSelfDot.Color = CYBER_COLORS.SelfDot
radarSelfDot.Filled = true

local radarDots = {}
local function getRadarDot(index)
    if not radarDots[index] then
        local dot = Drawing.new("Circle")
        dot.Visible = false
        dot.Radius = 4.5
        dot.Filled = true
        radarDots[index] = dot
    end
    return radarDots[index]
end

local function addPlayerESP(player)
    if espCache[player] then return end
    
    local drawings = {
        Box = createDrawing("Square", {Thickness = 1 * BOX_SCALE, Filled = false, Visible = false}),
        Info = createDrawing("Text", {Size = 13, Center = true, Outline = true, Visible = false}),
        TracerLine = createDrawing("Line", {Thickness = 1, Transparency = 0.7, Visible = false}),
        
        HeadCircle = createDrawing("Circle", {Thickness = 2, Filled = false, Visible = false, NumSides = 20}),
        ViewAngleLine = createDrawing("Line", {Thickness = 1.5, Visible = false}),
        
        SkeletonLines = {
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
        }
    }
    
    espCache[player] = drawings
end

local function hidePlayerESP(drawings)
    drawings.Box.Visible = false
    drawings.Info.Visible = false
    drawings.TracerLine.Visible = false
    drawings.HeadCircle.Visible = false
    drawings.ViewAngleLine.Visible = false
    for _, line in ipairs(drawings.SkeletonLines) do line.Visible = false end
end

local function removePlayerESP(player)
    if espCache[player] then
        for k, obj in pairs(espCache[player]) do
            if k == "SkeletonLines" then
                for _, line in ipairs(obj) do pcall(function() line:Remove() end) end
            elseif typeof(obj) == "table" then
                for _, subObj in pairs(obj) do pcall(function() subObj:Remove() end) end
            else
                pcall(function() obj:Remove() end)
            end
        end
        espCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then addPlayerESP(p) end
end
Players.PlayerAdded:Connect(addPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

local function IsVisible(part)
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 5000)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function IsTeammate(player)
    if not settings_tbl.TeamCheck then return false end
    if player == LocalPlayer then return true end
    if player.Team and LocalPlayer.Team then return player.Team == LocalPlayer.Team end
    if player.TeamColor and LocalPlayer.TeamColor then return player.TeamColor == LocalPlayer.TeamColor end
    return false
end

------------------------------------------------------------------------
-- Р Р•РќР”Р•Р  Р›РЈРџ
------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    -- Р—Р°С‰РёС‚Р° РѕС‚ Р±Р°РіР° РґРёСЃС‚Р°РЅС†РёРё, РµСЃР»Рё РїРµСЂСЃ РµС‰Рµ РЅРµ РїСЂРѕРіСЂСѓР·РёР»СЃСЏ
    if not myHrp then return end

    local radarCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2 + 160)
    radarBackground.Position = radarCenter
    radarSelfDot.Position = radarCenter
    
    local radarActive = settings_tbl.Radar and settings_tbl.ESP_Enabled
    radarBackground.Visible = radarActive
    radarSelfDot.Visible = radarActive
    
    if not radarActive then
        for _, dot in pairs(radarDots) do dot.Visible = false end
    end

    local dotIndex = 1

    for _, player in ipairs(Players:GetPlayers()) do 
        if player ~= LocalPlayer then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local drawings = espCache[player]
            
            if drawings then
                local rendered = false
                
                if settings_tbl.ESP_Enabled and char and hrp and hum and hum.Health > 0 then
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    
                    if not IsTeammate(player) and distance <= settings_tbl.Max_Distance then
                        local head = char:FindFirstChild("Head")
                        
                        if head then
                            local current_color = CYBER_COLORS.Default
                            if settings_tbl.WallColor_Enabled then
                                if IsVisible(head) then
                                    current_color = CYBER_COLORS.Visible
                                else
                                    current_color = CYBER_COLORS.Hidden
                                end
                            end

                            -- Р Р°РґР°СЂ РѕР±РЅРѕРІР»РµРЅРёРµ
                            if radarActive then
                                local relativePos = myHrp.CFrame:PointToObjectSpace(hrp.Position)
                                local radarPos = radarCenter + Vector2.new(relativePos.X * 0.25, relativePos.Z * 0.25)
                                
                                if (radarPos - radarCenter).Magnitude < radarRadius then
                                    local dot = getRadarDot(dotIndex)
                                    dot.Visible = true
                                    dot.Position = radarPos
                                    dot.Color = current_color
                                    dotIndex = dotIndex + 1
                                end
                            end

                            local rootScreenPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position)
                            local headScreenPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legScreenPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            
                            if rootOnScreen then
                                rendered = true
                                
                                local height = math.abs(headScreenPos.Y - legScreenPos.Y) * BOX_SCALE
                                local width = (height / 2) * BOX_SCALE
                                local boxPos = Vector2.new(rootScreenPos.X - width / 2, headScreenPos.Y)

                                -- РџСЂРѕРІРµСЂРєР° РѕС‚РґРµР»СЊРЅРѕРіРѕ С‚СѓРјР±Р»РµСЂР° Р‘РѕРєСЃР°
                                if settings_tbl.Box_Enabled then
                                    drawings.Box.Size = Vector2.new(width, height)
                                    drawings.Box.Position = boxPos
                                    drawings.Box.Color = current_color
                                    drawings.Box.Visible = true
                                else
                                    drawings.Box.Visible = false
                                end
                                
                                -- РўРµРєСЃС‚ РїСЂРёРІСЏР·Р°РЅ С‡С‘С‚РєРѕ Рє РІРµСЂС…СѓС€РєРµ Р±РѕРєСЃР° (Р°РєРєСѓСЂР°С‚РЅС‹Р№ РѕС‚СЃС‚СѓРї -35)
                                local hpInt = math.floor(hum.Health)
                                drawings.Info.Text = string.format("%s\n[%d HP] [%dm]", player.Name, hpInt, math.floor(distance))
                                drawings.Info.Position = Vector2.new(boxPos.X + (width / 2), boxPos.Y - 35)
                                drawings.Info.Color = current_color
                                drawings.Info.Visible = true
                                
                                -- Р›РёРЅРёСЏ РЅР°РїСЂР°РІР»РµРЅРёСЏ РІР·РіР»СЏРґР°
                                if settings_tbl.ViewAngle then
                                    local headPos = head.Position
                                    local lookVectorEnd = headPos + (head.CFrame.LookVector * 4)
                                    local headScr, headOnS = Camera:WorldToViewportPoint(headPos)
                                    local lookScr, lookOnS = Camera:WorldToViewportPoint(lookVectorEnd)
                                    
                                    if headOnS and lookOnS then
                                        drawings.ViewAngleLine.From = Vector2.new(headScr.X, headScr.Y)
                                        drawings.ViewAngleLine.To = Vector2.new(lookScr.X, lookScr.Y)
                                        drawings.ViewAngleLine.Color = current_color
                                        drawings.ViewAngleLine.Visible = true
                                    else
                                        drawings.ViewAngleLine.Visible = false
                                    end
                                else
                                    drawings.ViewAngleLine.Visible = false
                                end
                                
                                -- РўСЂРµР№СЃРµСЂС‹
                                if settings_tbl.Tracers then
                                    local vpSize = Camera.ViewportSize
                                    drawings.TracerLine.From = Vector2.new(vpSize.X / 2, vpSize.Y)
                                    drawings.TracerLine.To = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
                                    drawings.TracerLine.Color = current_color
                                    drawings.TracerLine.Visible = true
                                else
                                    drawings.TracerLine.Visible = false
                                end
                                
                                -- РЎРєРµР»РµС‚ + Р“РѕР»РѕРІР°
                                if settings_tbl.Skeleton then
                                    local function getJoint(name)
                                        local part = char:FindFirstChild(name)
                                        if part then
                                            local pos, onS = Camera:WorldToViewportPoint(part.Position)
                                            return onS and Vector2.new(pos.X, pos.Y) or nil
                                        end
                                        return nil
                                    end
                                    
                                    local headJoint = getJoint("Head")
                                    local upperTorso = getJoint("UpperTorso") or getJoint("Torso")
                                    local lowerTorso = getJoint("LowerTorso") or upperTorso
                                    local leftUpperArm = getJoint("LeftUpperArm") or getJoint("Left Arm")
                                    local leftLowerArm = getJoint("LeftLowerArm") or getJoint("LeftUpperArm")
                                    local rightUpperArm = getJoint("RightUpperArm") or getJoint("Right Arm")
                                    local rightLowerArm = getJoint("RightLowerArm") or getJoint("RightUpperArm")
                                    local leftLeg = getJoint("LeftLowerLeg") or getJoint("Left Leg") or getJoint("LeftUpperLeg")
                                    local rightLeg = getJoint("RightLowerLeg") or getJoint("Right Leg") or getJoint("RightUpperLeg")
                                    
                                    if headJoint then
                                        drawings.HeadCircle.Visible = true
                                        drawings.HeadCircle.Radius = math.clamp((height / 8) * 2, 8, 30)
                                        drawings.HeadCircle.Position = headJoint
                                        drawings.HeadCircle.Color = current_color
                                    else
                                        drawings.HeadCircle.Visible = false
                                    end

                                    local pairs_list = {
                                        {headJoint, upperTorso},
                                        {upperTorso, leftUpperArm}, {leftUpperArm, leftLowerArm},
                                        {upperTorso, rightUpperArm}, {rightUpperArm, rightLowerArm},
                                        {upperTorso, lowerTorso},
                                        {lowerTorso, leftLeg},
                                        {lowerTorso, rightLeg}
                                    }
                                    
                                    for i, line in ipairs(drawings.SkeletonLines) do
                                        local pPair = pairs_list[i]
                                        if pPair and pPair[1] and pPair[2] then
                                            line.From = pPair[1]
                                            line.To = pPair[2]
                                            line.Color = current_color
                                            line.Visible = true
                                        else
                                            line.Visible = false
                                        end
                                    end
                                else
                                    drawings.HeadCircle.Visible = false
                                    for _, line in ipairs(drawings.SkeletonLines) do line.Visible = false end
                                end
                            end
                        end
                    end
                end
                
                if not rendered then
                    hidePlayerESP(drawings)
                end
            end
        end
    end
    
    for i = dotIndex, #radarDots do
        radarDots[i].Visible = false
    end
end)

------------------------------------------------------------------------
-- РњРћР‘РР›Р¬РќРћР• РњР•РќР®
------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalEspGui"
ScreenGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 70, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
ToggleBtn.BackgroundColor3 = CYBER_COLORS.Cyan
ToggleBtn.Text = "MENU"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.Font = Enum.Font.RobotoMono
ToggleBtn.TextSize = 12
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = CYBER_COLORS.DarkBg
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 180, 0, 335)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = CYBER_COLORS.Cyan
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local function createButton(name, posY, key)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.Size = UDim2.new(0.9, 0, 0, 25)
    btn.Position = UDim2.new(0.05, 0, posY, 0)
    btn.Font = Enum.Font.RobotoMono
    btn.TextSize = 10
    
    local function updateState()
        if settings_tbl[key] then
            btn.BackgroundColor3 = CYBER_COLORS.Cyan
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            btn.Text = name .. ": [ON]"
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = CYBER_COLORS.Cyan
            btn.Text = name .. ": [OFF]"
        end
    end
    
    updateState()
    
    btn.MouseButton1Click:Connect(function()
        settings_tbl[key] = not settings_tbl[key]
        updateState()
    end)
end

createButton("ESP", 0.03, "ESP_Enabled")
createButton("BOX", 0.12, "Box_Enabled")      -- РћС‚РґРµР»СЊРЅР°СЏ РєРЅРѕРїРєР° РґР»СЏ Р±РѕРєСЃРѕРІ
createButton("TEAM CHECK", 0.21, "TeamCheck")
createButton("SKELETON", 0.30, "Skeleton")
createButton("VIEW ANGLE", 0.39, "ViewAngle")
createButton("TRACERS", 0.48, "Tracers")
createButton("RADAR", 0.57, "Radar")
createButton("WALL COLOR", 0.66, "WallColor_Enabled")

local DistBox = Instance.new("TextBox")
DistBox.Parent = MainFrame
DistBox.Size = UDim2.new(0.9, 0, 0, 25)
DistBox.Position = UDim2.new(0.05, 0, 0.78, 0)
DistBox.Font = Enum.Font.RobotoMono
DistBox.TextSize = 10
DistBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
DistBox.TextColor3 = CYBER_COLORS.Cyan
DistBox.Text = tostring(settings_tbl.Max_Distance)
DistBox.ClearTextOnFocus = false

DistBox.FocusLost:Connect(function()
    local num = tonumber(DistBox.Text)
    if num then
        settings_tbl.Max_Distance = num
        DistBox.Text = tostring(num)
    else
        DistBox.Text = tostring(settings_tbl.Max_Distance)
    end
end)
